locals {
  instance_count         = module.this.enabled ? var.instance_count : 0
  region                 = var.region != "" ? var.region : data.aws_region.default.name
  root_iops              = var.root_volume_type == "io1" ? var.root_iops : 0
  ebs_iops               = var.ebs_volume_type == "io1" ? var.ebs_iops : 0
  availability_zone      = var.availability_zone
  root_volume_type       = var.root_volume_type != "" ? var.root_volume_type : data.aws_ami.info.root_device_type
  count_default_ips      = var.associate_public_ip_address && var.assign_eip_address && module.this.enabled ? var.instance_count : 0
  ssh_key_pair_path      = var.ssh_key_pair_path == "" ? path.cwd : var.ssh_key_pair_path
  security_group_enabled = module.this.enabled && var.security_group_enabled
}

locals {
  public_ips = try(compact(
    concat(
      coalescelist(aws_eip.default.*.public_ip, aws_instance.default.*.public_ip),
      coalescelist(aws_eip.additional.*.public_ip, [""])
    )
  ), [""])

  ip_dns_list = split(",", replace(join(",", local.public_ips), ".", "-"))

  dns_names = formatlist(
    "%v.${var.region == "us-east-1" ? "compute-1" : "${var.region}.compute"}.amazonaws.com", compact(local.ip_dns_list)
  )
}

data "aws_region" "default" {
}

data "aws_caller_identity" "default" {
}

data "aws_iam_policy_document" "default" {
  statement {
    sid = ""

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    effect = "Allow"
  }
}

data "aws_ami" "info" {
  filter {
    name   = "image-id"
    values = [var.ami]
  }

  owners = [var.ami_owner]
}

module "label" {
  source  = "cloudposse/label/null"
  version = "0.24.1"
  tags    = { AZ = local.availability_zone }

  context = module.this.context
}

resource "aws_iam_instance_profile" "default" {
  count = signum(local.instance_count)
  name  = module.label.id
  role  = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role" "default" {
  count                = signum(local.instance_count)
  name                 = module.label.id
  path                 = "/"
  assume_role_policy   = data.aws_iam_policy_document.default.json
  permissions_boundary = length(var.permissions_boundary_arn) > 0 ? var.permissions_boundary_arn : null
  tags                 = module.this.tags
}

resource "aws_instance" "default" {
  #bridgecrew:skip=BC_AWS_GENERAL_31: Skipping `Ensure Instance Metadata Service Version 1 is not enabled` check until BridgeCrew supports conditional evaluation. See https://github.com/bridgecrewio/checkov/issues/793
  count                       = local.instance_count
  ami                         = data.aws_ami.info.id
  availability_zone           = local.availability_zone
  instance_type               = var.instance_type
  ebs_optimized               = var.ebs_optimized
  disable_api_termination     = var.disable_api_termination
  user_data                   = var.user_data
  iam_instance_profile        = join("", aws_iam_instance_profile.default.*.name)
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = var.ssh_key_pair
  subnet_id                   = var.subnet
  monitoring                  = var.monitoring
  #private_ip                  = concat(var.private_ips, [""])[min(length(var.private_ips), count.index)]
  source_dest_check           = var.source_dest_check
  ipv6_address_count          = var.ipv6_address_count < 0 ? null : var.ipv6_address_count
  ipv6_addresses              = length(var.ipv6_addresses) > 0 ? var.ipv6_addresses : null
  vpc_security_group_ids      = compact(concat(module.security_group.*.id, var.security_groups))

  root_block_device {
    volume_type           = local.root_volume_type
    volume_size           = var.root_volume_size
    iops                  = local.root_iops
    delete_on_termination = var.delete_on_termination
    encrypted             = var.root_block_device_encrypted
    kms_key_id            = var.kms_key_id
  }

  metadata_options {
    http_endpoint = var.metadata_http_endpoint_enabled ? "enabled" : "disabled"
    http_tokens   = var.metadata_http_tokens_required ? "required" : "optional"
  }

  tags = merge(
    module.label.tags,
    {
      instance_index = count.index
    }
  )
}

##
## Create keypair if one isn't provided
##

#module "ssh_key_pair" {
#  source                = "cloudposse/key-pair/aws"
#  version               = "0.18.2"
#  ssh_public_key_path   = local.ssh_key_pair_path
#  private_key_extension = ".pem"
#  generate_ssh_key      = var.generate_ssh_key_pair
#
#  context = module.this.context
#}

resource "aws_eip" "default" {
  count             = local.count_default_ips
  network_interface = aws_instance.default.*.primary_network_interface_id[count.index]
  vpc               = true
  depends_on        = [aws_instance.default]
  tags              = module.this.tags
}

resource "aws_ebs_volume" "default" {
  count             = var.ebs_volume_count * local.instance_count
  availability_zone = local.availability_zone
  size              = var.ebs_volume_size
  iops              = local.ebs_iops
  type              = var.ebs_volume_type
  tags              = module.label.tags
  encrypted         = var.ebs_volume_encrypted
  kms_key_id        = var.kms_key_id
}

resource "aws_volume_attachment" "default" {
  count       = signum(local.instance_count) == 1 ? var.ebs_volume_count * local.instance_count : 0
  device_name = element(slice(var.ebs_device_names, 0, floor(var.ebs_volume_count * local.instance_count / max(local.instance_count, 1))), count.index)
  volume_id   = aws_ebs_volume.default.*.id[count.index]
  instance_id = aws_instance.default.*.id[count.index]
}
