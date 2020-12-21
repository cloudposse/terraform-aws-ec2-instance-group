provider "aws" {
  region = var.region
}

module "vpc" {
  source     = "cloudposse/vpc/aws"
  version    = "0.18.1"
  cidr_block = "172.16.0.0/16"

  context = module.this.context
}

module "subnets" {
  source               = "cloudposse/dynamic-subnets/aws"
  version              = "0.33.0"
  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = false
  nat_instance_enabled = false

  context = module.this.context
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = [var.ami_owner]
}

module "ec2_instance_group" {
  source                        = "../../"
  region                        = var.region
  ami                           = data.aws_ami.ubuntu.id
  ami_owner                     = var.ami_owner
  vpc_id                        = module.vpc.vpc_id
  subnet                        = module.subnets.private_subnet_ids[0]
  security_groups               = [module.vpc.vpc_default_security_group_id]
  assign_eip_address            = var.assign_eip_address
  associate_public_ip_address   = var.associate_public_ip_address
  instance_type                 = var.instance_type
  instance_count                = var.instance_count
  allowed_ports                 = var.allowed_ports
  create_default_security_group = var.create_default_security_group
  generate_ssh_key_pair         = var.generate_ssh_key_pair
  root_volume_type              = var.root_volume_type
  root_volume_size              = var.root_volume_size
  delete_on_termination         = var.delete_on_termination

  context = module.this.context
}
