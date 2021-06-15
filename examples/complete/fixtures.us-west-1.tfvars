region = "us-west-1"

namespace = "eg"

stage = "test"

name = "ec2-group-test"

availability_zones = ["us-west-1b", "us-west-1c"]

instance_type = "t2.micro"

instance_count = 2

ssh_public_key_path = "/secrets"

generate_ssh_key_pair = true

associate_public_ip_address = false

assign_eip_address = false

ami_owner = "099720109477"

root_volume_type = "gp2"

root_volume_size = 10

delete_on_termination = true
