locals {
  instance_count       = var.instance_enabled ? var.instance_count : 0
  security_group_count = var.create_default_security_group ? 1 : 0
  region               = var.region != "" ? var.region : data.aws_region.default.name
  root_iops            = var.root_volume_type == "io1" ? var.root_iops : 0
  ebs_iops             = var.ebs_volume_type == "io1" ? var.ebs_iops : 0
  availability_zone    = var.availability_zone
  root_volume_type     = var.root_volume_type != "" ? var.root_volume_type : data.aws_ami.info.root_device_type
  count_default_ips    = var.associate_public_ip_address && var.assign_eip_address && var.instance_enabled && var.instance_count > 0 ? 1 : 0
  ssh_key_pair_path    = var.ssh_key_pair_path == "" ? path.cwd : var.ssh_key_pair_path
}

locals {
  public_ips = compact(
    concat(
      coalescelist(aws_eip.default.*.public_ip, [""]),
      coalescelist(aws_instance.default.*.public_ip, [""]),
      coalescelist(aws_eip.additional.*.public_ip, [""])
    )
  )

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
  source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=tags/0.14.1"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  attributes = var.attributes
  delimiter  = var.delimiter
  tags = merge(
    {
      AZ = local.availability_zone
    },
    var.tags
  )
  enabled = true
}

resource "aws_iam_instance_profile" "default" {
  count = signum(local.instance_count)
  name  = module.label.id
  role  = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role" "default" {
  count              = signum(local.instance_count)
  name               = module.label.id
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.default.json
}

resource "aws_instance" "default" {
  count                       = local.instance_count
  ami                         = data.aws_ami.info.id
  availability_zone           = local.availability_zone
  instance_type               = var.instance_type
  ebs_optimized               = var.ebs_optimized
  disable_api_termination     = var.disable_api_termination
  user_data                   = var.user_data
  iam_instance_profile        = join("", aws_iam_instance_profile.default.*.name)
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = signum(length(var.ssh_key_pair)) == 1 ? var.ssh_key_pair : module.ssh_key_pair.key_name
  subnet_id                   = var.subnet
  monitoring                  = var.monitoring
  private_ip                  = concat(var.private_ips, [""])[min(length(var.private_ips), count.index)]
  source_dest_check           = var.source_dest_check
  ipv6_address_count          = var.ipv6_address_count
  ipv6_addresses              = var.ipv6_addresses

  vpc_security_group_ids = compact(
    concat(
      [
        var.create_default_security_group ? join("", aws_security_group.default.*.id) : ""
      ],
      var.security_groups
    )
  )

  root_block_device {
    volume_type           = local.root_volume_type
    volume_size           = var.root_volume_size
    iops                  = local.root_iops
    delete_on_termination = var.delete_on_termination
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

module "ssh_key_pair" {
  source                = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=tags/0.4.0"
  namespace             = var.namespace
  stage                 = var.stage
  name                  = var.name
  ssh_public_key_path   = local.ssh_key_pair_path
  private_key_extension = ".pem"
  generate_ssh_key      = var.generate_ssh_key_pair
}

resource "aws_eip" "default" {
  count             = local.count_default_ips
  network_interface = aws_instance.default.*.primary_network_interface_id[count.index]
  vpc               = true
  depends_on        = [aws_instance.default]
}

resource "aws_ebs_volume" "default" {
  count             = var.ebs_volume_count * local.instance_count
  availability_zone = local.availability_zone
  size              = var.ebs_volume_size
  iops              = local.ebs_iops
  type              = var.ebs_volume_type
  tags              = module.label.tags
}

resource "aws_volume_attachment" "default" {
  count = signum(local.instance_count) == 1 ? var.ebs_volume_count * local.instance_count : 0

  device_name = slice(
    var.ebs_device_names,
    0,
    floor(
      var.ebs_volume_count * local.instance_count / max(local.instance_count, 1),
    ),
  )[count.index]

  volume_id   = aws_ebs_volume.default.*.id[count.index]
  instance_id = aws_instance.default.*.id[count.index]
}
