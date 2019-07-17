region = "us-west-1"

namespace = "eg"

stage = "test"

name = "instance-group-test"

availability_zones = ["us-west-1b", "us-west-1c"]

instance_type = "t2.micro"

instance_count = 2

allowed_ports = [22, 80, 443]

ssh_public_key_path = "/secrets"

generate_ssh_key_pair = true

associate_public_ip_address = false

assign_eip_address = false

ami_owner = "099720109477"

root_volume_type = "gp2"

root_volume_size = 10

delete_on_termination = true

create_default_security_group = true
