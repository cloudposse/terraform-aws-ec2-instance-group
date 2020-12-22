output "public_subnet_cidrs" {
  description = "Public subnet CIDRs"
  value       = module.subnets.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "Private subnet CIDRs"
  value       = module.subnets.private_subnet_cidrs
}

output "vpc_cidr" {
  description = "VPC CIDR"
  value       = module.vpc.vpc_cidr_block
}

output "public_ips" {
  description = "List of Public IPs of instances (or EIP)"
  value       = module.ec2_instance_group.public_ips
}

output "private_ips" {
  description = "Private IPs of instances"
  value       = module.ec2_instance_group.private_ips
}

output "private_dns" {
  description = "Private DNS records of instances"
  value       = module.ec2_instance_group.private_dns
}

output "public_dns" {
  value       = module.ec2_instance_group.public_dns
  description = "All public DNS records for the public interfaces and ENIs"
}

output "ids" {
  description = "Disambiguated IDs list"
  value       = module.ec2_instance_group.ids
}

output "aws_key_pair_name" {
  description = "Name of AWS key pair"
  value       = module.ec2_instance_group.aws_key_pair_name
}

output "new_ssh_keypair_generated" {
  value       = module.ec2_instance_group.new_ssh_keypair_generated
  description = "Was a new ssh_key_pair generated"
}

output "ssh_key_pem_path" {
  description = "Path where SSH key pair was created (if applicable)"
  value       = module.ec2_instance_group.ssh_key_pem_path
}

output "security_group_ids" {
  description = "ID on the new AWS Security Group associated with creating instance"
  value       = module.ec2_instance_group.security_group_ids
}

output "role_names" {
  description = "Names of AWS IAM Roles associated with creating instance"
  value       = module.ec2_instance_group.role_names
}

output "alarm_ids" {
  description = "CloudWatch Alarm IDs"
  value       = module.ec2_instance_group.alarm_ids
}

output "eni_to_eip_map" {
  description = "Map of ENI with EIP"
  value       = module.ec2_instance_group.eni_to_eip_map
}

output "ebs_ids" {
  description = "IDs of EBSs"
  value       = module.ec2_instance_group.ebs_ids
}

output "primary_network_interface_ids" {
  description = "IDs of the instance's primary network interface"
  value       = module.ec2_instance_group.primary_network_interface_ids
}

output "eip_per_instance_count" {
  value       = module.ec2_instance_group.eip_per_instance_count
  description = "Number of EIPs per instance"
}

output "instance_count" {
  value       = module.ec2_instance_group.instance_count
  description = "Total number of instances created"
}
