data "aws_region" "default" {}

data "aws_subnet" "default" {
  id = data.aws_subnet_ids.all.ids[0]
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "all" {
  vpc_id = data.aws_vpc.default.id
}

provider "aws" {
  region = "us-east-1"
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

  owners = ["099720109477"] # Canonical
}

module "zero_servers" {
  source = "../../"

  instance_count = 0
  ami            = data.aws_ami.ubuntu.id
  ami_owner      = "099720109477"
  namespace      = "eg"
  stage          = "prod"
  name           = "zero"

  create_default_security_group = true
  region                        = data.aws_region.default.name
  availability_zone             = data.aws_subnet.default.availability_zone
  subnet                        = data.aws_subnet.default.id
  vpc_id                        = data.aws_vpc.default.id
  generate_ssh_key_pair         = true
}

module "one_server" {
  source = "../../"

  instance_count = 1
  ami            = data.aws_ami.ubuntu.id
  ami_owner      = "099720109477"
  namespace      = "eg"
  stage          = "prod"
  name           = "one"

  create_default_security_group = true
  region                        = data.aws_region.default.name
  availability_zone             = data.aws_subnet.default.availability_zone
  subnet                        = data.aws_subnet.default.id
  vpc_id                        = data.aws_vpc.default.id
  additional_ips_count          = 1
  generate_ssh_key_pair         = true
  instance_type                 = "m1.large" // Allows up to 3 ENI, the default t2.micro allows only 1
}

module "two_servers" {
  source = "../../"

  instance_count = 2
  ami            = data.aws_ami.ubuntu.id
  ami_owner      = "099720109477"
  namespace      = "eg"
  stage          = "prod"
  name           = "two"

  create_default_security_group = true
  region                        = data.aws_region.default.name
  availability_zone             = data.aws_subnet.default.availability_zone
  subnet                        = data.aws_subnet.default.id
  vpc_id                        = data.aws_vpc.default.id
  additional_ips_count          = 1
  generate_ssh_key_pair         = true
  instance_type                 = "m1.large" // Allows up to 3 ENI, the default t2.micro allows only 1
}

output "public_dns" {
  value = {
    zero = module.zero_servers.public_dns
    one  = module.one_server.public_dns
    two  = module.two_servers.public_dns
  }
}

output "public_ips" {
  value = {
    zero = module.zero_servers.public_ips
    one  = module.one_server.public_ips
    two  = module.two_servers.public_ips
  }
}

output "instance_count" {
  value = {
    zero = module.zero_servers.instance_count
    one  = module.one_server.instance_count
    two  = module.two_servers.instance_count
  }
}

output "eni_to_eip_map" {
  value = {
    zero = module.zero_servers.eni_to_eip_map
    one  = module.one_server.eni_to_eip_map
    two  = module.two_servers.eni_to_eip_map
  }
}

output "eip_per_instance_count" {
  value = {
    zero = module.zero_servers.eip_per_instance_count
    one  = module.one_server.eip_per_instance_count
    two  = module.two_servers.eip_per_instance_count
  }
}

output "private_ips" {
  value = {
    zero = module.zero_servers.private_ips
    one  = module.one_server.private_ips
    two  = module.two_servers.private_ips
  }
}

output "private_dns" {
  value = {
    zero = module.zero_servers.private_dns
    one  = module.one_server.private_dns
    two  = module.two_servers.private_dns
  }
}

output "aws_key_pair_name" {
  value = {
    zero = module.zero_servers.aws_key_pair_name
    one  = module.one_server.aws_key_pair_name
    two  = module.two_servers.aws_key_pair_name
  }
}

output "alarm" {
  value = {
    zero = module.zero_servers.alarm_ids
    one  = module.one_server.alarm_ids
    two  = module.two_servers.alarm_ids
  }
}

output "ssh_key_pem_path" {
  value = {
    zero = module.zero_servers.ssh_key_pem_path
    one  = module.one_server.ssh_key_pem_path
    two  = module.two_servers.ssh_key_pem_path
  }
}
