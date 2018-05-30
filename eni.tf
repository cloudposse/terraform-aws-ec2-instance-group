locals {
  additional_ips_count = "${var.associate_public_ip_address == "true" && var.instance_enabled == "true" && var.additional_ips_count > 0 ? var.additional_ips_count : 0}"
}

resource "aws_network_interface" "additional" {
  count     = "${local.additional_ips_count * var.instance_count}"
  subnet_id = "${var.subnet}"

  security_groups = [
    "${compact(concat(list(var.create_default_security_group == "true" ? join("", aws_security_group.default.*.id) : ""), var.security_groups))}",
  ]

  tags       = "${module.label.tags}"
  depends_on = ["aws_instance.default"]
}

resource "aws_network_interface_attachment" "additional" {
  count                = "${local.additional_ips_count * var.instance_count}"
  instance_id          = "${element(aws_instance.default.*.id, count.index % var.instance_count)}"
  network_interface_id = "${element(aws_network_interface.additional.*.id, count.index)}"
  device_index         = "${1 + count.index}"
  depends_on           = ["aws_instance.default"]
}

resource "aws_eip" "additional" {
  count             = "${local.additional_ips_count * var.instance_count}"
  vpc               = "true"
  network_interface = "${element(aws_network_interface.additional.*.id, count.index)}"
  depends_on        = ["aws_instance.default"]
}
