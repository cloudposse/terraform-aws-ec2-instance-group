output "public_ips" {
  description = "List of Public IPs of instances (or EIP)"
  value       = local.public_ips
}

output "private_ips" {
  description = "Private IPs of instances"
  value       = aws_instance.default.*.private_ip
}

output "private_dns" {
  description = "Private DNS records of instances"
  value       = aws_instance.default.*.private_dns
}

output "public_dns" {
  value       = local.dns_names
  description = "All public DNS records for the public interfaces and ENIs"
}

output "ids" {
  description = "Disambiguated IDs list"
  value       = aws_instance.default.*.id
}

output "name" {
  description = "Instance(s) name"
  value       = module.label.id
}

/* output "aws_key_pair_name" {
  description = "Name of AWS key pair"
  value       = signum(length(var.ssh_key_pair)) == 1 ? var.ssh_key_pair : var.generate_ssh_key_pair ? module.ssh_key_pair.key_name : ""
} */

output "new_ssh_keypair_generated" {
  value       = signum(length(var.ssh_key_pair)) == 1 ? false : true
  description = "Was a new ssh_key_pair generated"
}

output "security_group_ids" {
  description = "ID on the new AWS Security Group associated with creating instance"
  value       = compact(concat(module.security_group.*.id, var.security_groups))
}

output "security_group_id" {
  value       = module.security_group.id
  description = "EC2 instances Security Group ID"
}

output "security_group_arn" {
  value       = module.security_group.arn
  description = "EC2 instances Security Group ARN"
}

output "security_group_name" {
  value       = module.security_group.name
  description = "EC2 instances Security Group name"
}

output "role_names" {
  description = "Names of AWS IAM Roles associated with creating instance"
  value       = compact(aws_iam_role.default.*.name)
}

output "alarm_ids" {
  description = "CloudWatch Alarm IDs"
  value       = aws_cloudwatch_metric_alarm.default.*.id
}

output "eni_to_eip_map" {
  description = "Map of ENI with EIP"
  value = zipmap(
    aws_network_interface.additional.*.id,
    aws_eip.additional.*.public_ip
  )
}

output "ebs_ids" {
  description = "IDs of EBSs"
  value       = aws_ebs_volume.default.*.id
}

output "primary_network_interface_ids" {
  description = "IDs of the instance's primary network interface"
  value       = aws_instance.default.*.primary_network_interface_id
}

output "eip_per_instance_count" {
  value       = local.count_default_ips + local.additional_ips_count
  description = "Number of EIPs per instance."
}

output "instance_count" {
  value       = local.instance_count
  description = "Total number of instances created"
}
