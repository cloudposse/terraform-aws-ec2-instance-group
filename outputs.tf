output "public_ips" {
  description = "List of Public IPs of instances (or EIP)"
  value       = "${distinct(compact(concat(aws_eip.default.*.public_ip,aws_instance.default.*.public_ip, aws_eip.additional.*.public_ip, list() )))}"
}

output "private_ips" {
  description = "Private IPs of instances"
  value       = "${aws_instance.default.*.private_ip}"
}

output "private_dns" {
  description = "Private DNS records of instances"
  value       = "${aws_instance.default.*.private_dns}"
}

locals {
  # Split/Join used here so that the replace can be used inbetween.
  ip_dns_list = "${split(",", replace(join(",", distinct(compact(concat(aws_eip.default.*.public_ip,aws_instance.default.*.public_ip, aws_eip.additional.*.public_ip, list() )))), ".", "-"))}"
  dns_names   = "${formatlist("%v.${var.region == "us-east-1" ? "compute-1" : "${var.region}.compute"}.amazonaws.com", distinct(compact(local.ip_dns_list)))}"
}

output "public_dns" {
  value = "${local.dns_names}"
}

output "id" {
  description = "Disambiguated IDs list"
  value       = "${aws_instance.default.*.id}"
}

output "aws_key_pair_name" {
  description = "Name of AWS key pair"
  value       = "${signum(length(var.ssh_key_pair)) == 1 ? var.ssh_key_pair : "${var.generate_ssh_key_pair == "true" ? module.ssh_key_pair.key_name : ""}"}"
}

output "new_ssh_keypair_generated" {
  value = "${signum(length(var.ssh_key_pair)) == 1 ? "false" : "true" }"
}

output "ssh_key_pem_path" {
  description = "Path where SSH key pair was created (if applicable)"
  value       = "${local.ssh_key_pair_path}/${module.ssh_key_pair.key_name}.pem"
}

output "security_group_ids" {
  description = "ID on the new AWS Security Group associated with creating instance"
  value       = "${compact(concat(list(var.create_default_security_group == "true" ? join("", aws_security_group.default.*.id) : ""), var.security_groups))}"
}

output "roles" {
  description = "Name of AWS IAM Role associated with creating instance"
  value       = "${compact(aws_iam_role.default.*.name)}"
}

output "alarms" {
  description = "CloudWatch Alarm IDs"
  value       = "${aws_cloudwatch_metric_alarm.default.*.id}"
}

output "additional_eni_ids" {
  description = "Map of ENI with EIP"
  value       = "${zipmap(aws_network_interface.additional.*.id, aws_eip.additional.*.public_ip)}"
}

output "ebs_ids" {
  description = "IDs of EBSs"
  value       = "${aws_ebs_volume.default.*.id}"
}

output "primary_network_interface_ids" {
  description = "IDs of the instance's primary network interface"
  value       = "${aws_instance.default.*.primary_network_interface_id}"
}

output "network_interface_ids" {
  description = "IDs of the network interface that was created with the instance"
  value       = "${aws_instance.default.*.network_interface_id}"
}

output "eips_per_instance" {
  value       = "${local.count_default_ips + local.additional_ips_count}"
  description = "Number of EIPs per instance."
}

output "instance_count" {
  value       = "${local.instance_count}"
  description = "Total number of instances created."
}
