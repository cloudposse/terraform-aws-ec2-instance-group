# terraform-aws-ec2-instance-group [![Build Status](https://travis-ci.org/cloudposse/terraform-aws-ec2-instance-group.svg?branch=master)](https://travis-ci.org/cloudposse/terraform-aws-ec2-instance-group)

Terraform Module for providing N general purpose EC2 hosts.

If you only need to provision a single EC2 instance, consider using the [terraform-aws-ec2-instance](https://github.com/cloudposse/terraform-aws-ec2-instance) module instead.

**IMPORTANT** This module by-design does not provision an AutoScaling group. It was designed to provision a discrete number of instances suitable for running stateful services such as databases (E.g. Kafka, Redis, etc). 


Included features:
* Automatically create a Security Group
* Option to switch EIP attachment
* CloudWatch monitoring and automatic reboot if instance hangs
* Assume Role capability

## Usage

Note: add `${var.ssh_key_pair}` private key to the `ssh agent`.

Include this repository as a module in your existing terraform code.


### Simple example:

```hcl
module "instance" {
  source                      = "git::https://github.com/cloudposse/terraform-aws-ec2-instance-group.git?ref=master"
  namespace                   = "cp"
  stage                       = "prod"
  name                        = "app"
  ami                         = "ami-a4dc46db"
  ssh_key_pair                = "${var.ssh_key_pair}"
  instance_type               = "${var.instance_type}"
  vpc_id                      = "${var.vpc_id}"
  security_groups             = ["${var.security_groups}"]
  subnet                      = "${var.subnet}"

  instance_count              = "3"
}
```

### Example with additional volumes and EIP

```hcl
module "kafka_instance" {
  source                      = "git::https://github.com/cloudposse/terraform-aws-ec2-instance-group.git?ref=master"
  namespace                   = "cp"
  stage                       = "prod"
  name                        = "app"
  ami                         = "ami-a4dc46db"
  ssh_key_pair                = "${var.ssh_key_pair}"
  vpc_id                      = "${var.vpc_id}"
  security_groups             = ["${var.security_groups}"]
  subnet                      = "${var.subnet}"
  associate_public_ip_address = "true"
  additional_ips_count        = "1"
  ebs_volume_count            = "2"
  allowed_ports               = ["22", "80", "443"]

  instance_count              = "3"
}
```

### Additional complete working example with variations of how to use the module
In /examples directory

This module depends on these modules:

* [terraform-terraform-label](https://github.com/cloudposse/terraform-terraform-label)

It is necessary to run `terraform get` or `terraform init` to download this module.

Now reference the label when creating an instance (for example):
```hcl
resource "aws_ami_from_instance" "example" {
  count              = "${length(module.instance.*.id)}"
  name               = "terraform-example"
  source_instance_id = "${element(module.instance.*.id, count.index)}"
}
```

## Variables

| Name                            |                    Default                     | Description                                                                                            | Required |
|:--------------------------------|:----------------------------------------------:|:-------------------------------------------------------------------------------------------------------|:--------:|
| `region`                        |                       ``                       | AWS Region the instance is launched in. Optional. If not provided, the current region will be used     |   No     |
| `namespace`                     |                       ``                       | Namespace (e.g. `cp` or `cloudposse`)                                                                  |   Yes    |
| `stage`                         |                       ``                       | Stage (e.g. `prod`, `dev`, `staging`                                                                   |   Yes    |
| `name`                          |                       ``                       | Name  (e.g. `bastion` or `db`)                                                                         |   Yes    |
| `attributes`                    |                      `[]`                      | Additional attributes (e.g. `policy` or `role`)                                                        |    No    |
| `tags`                          |                      `{}`                      | Additional tags  (e.g. `map("BusinessUnit","XYZ")`                                                     |    No    |
| `ami`                           |                       ``                       | The AMI id                                         |    Yes    |
| `instance_enabled`              |                     `true`                     | Flag to control the instance creation. Set to false if it is necessary to skip instance creation       |    No    |
| `create_default_security_group` |                     `true`                     | Create default Security Group with only Egress traffic allowed                                         |    No    |
| `ssh_key_pair`                  |                       ``                       | SSH key pair to be provisioned on the instance. If none provided, and `generate_ssh_key_pair` is true a new keypair is generated                                                         |   No    |
| `generate_ssh_key_pair`         |                    `false`                     | Should a new SSH key pair be generated.                                                                |    No    |
| `ssh_key_pair_path`             |                       ``                       | Path to where SSH key pair should be generated. Defaults to ${path.cwd}                                |    No    |
| `instance_type`                 |                   `t2.micro`                   | The type of the instance (e.g. `t2.micro`)                                                             |    No    |
| `vpc_id`                        |                       ``                       | The ID of the VPC that the instance security group belongs to                                          |   Yes    |
| `security_groups`               |                      `[]`                      | List of Security Group IDs allowed to connect to the instance                                          |   Yes    |
| `allowed_ports`                 |                      `[]`                      | List of allowed ingress ports, _e.g._ ["22", "80", "443"]                                              |    No    |
| `subnet`                        |                       ``                       | VPC Subnet ID the instance is launched in                                                              |   Yes    |
| `associate_public_ip_address`   |                     `true`                     | Associate a public IP address with the instance                                                        |    No    |
| `assign_eip_address`            |                     `true`                     | Assign an Elastic IP address to the instance                                                           |    No    |
| `additional_ips_count`          |                      `0`                       | Count of additional EIPs                                                                               |    No    |
| `private_ip`                    |                       ``                       | Private IP address to associate with the instance in the VPC                                           |    No    |
| `source_dest_check`             |                     `true`                     | Controls if traffic is routed to the instance when the destination address does not match the instance |    No    |
| `ipv6_address_count`            |                      `0`                       | Number of IPv6 addresses to associate with the primary network interface                               |    No    |
| `ipv6_addresses`                |                      `[]`                      | List of IPv6 addresses from the range of the subnet to associate with the primary network interface    |    No    |
| `root_volume_type`              |                     `gp2`                      | Type of the root volume. Can be `standard`, `gp2` or `io1`                                             |    No    |
| `root_volume_size`              |                      `10`                      | Size of the root volume in gigabytes                                                                   |    No    |
| `root_iops`                     |                      `0`                       | Amount of provisioned IOPS. This must be set with a `root_volume_type` of `io1`                        |    No    |
| `ebs_device_name`               |                 `[/dev/xvdb]`                  | Name of the EBS device to mount                                                                        |    No    |
| `ebs_volume_type`               |                     `gp2`                      | Type of EBS volume. Can be `standard`, `gp2` or `io1`                                                  |    No    |
| `ebs_volume_size`               |                      `10`                      | Size of the EBS volume in gigabytes                                                                    |    No    |
| `ebs_iops`                      |                      `0`                       | Amount of provisioned IOPS. This must be set if `ebs_volume_type` is set to `io1`                      |    No    |
| `ebs_volume_count`              |                      `0`                       | Count of EBS volumes that will be attached to the instance                                             |    No    |
| `delete_on_termination`         |                     `true`                     | Whether the volume should be destroyed on instance termination                                         |    No    |
| `comparison_operator`           |        `GreaterThanOrEqualToThreshold`         | Arithmetic operation to use when comparing the specified Statistic and Threshold                       |    No    |
| `metric_name`                   |          `StatusCheckFailed_Instance`          | Name for the alarm's associated metric                                                                 |    No    |
| `evaluation_periods`            |                      `5`                       | Number of periods over which data is compared to the specified threshold                               |    No    |
| `metric_namespace`              |                   `AWS/EC2`                    | Namespace for the alarm's associated metric                                                            |    No    |
| `applying_period`               |                      `60`                      | Period in seconds over which the specified statistic is applied                                        |    No    |
| `statistic_level`               |                   `Maximum`                    | Statistic to apply to the alarm's associated metric                                                    |    No    |
| `metric_threshold`              |                      `1`                       | Value against which the specified statistic is compared                                                |    No    |
| `default_alarm_action`          | `action/actions/AWS_EC2.InstanceId.Reboot/1.0` | String of action to execute when this alarm transitions into an ALARM state                            |    No    |
| `instance_count`                |                      `1`                       | Number of EC2 instances to create - each will have the same settings                                   |    No    |


## Outputs

| Name                            |  Type  |  Description                                                        |
|:-------------------------------:|:------:|:-------------------------------------------------------------------:|
| `ids`                           |  list  | Disambiguated IDs                                                   |
| `private_dns`                   |  list  | Private DNS records of the instances                                |
| `private_ips`                   |  list  | Private IPs of the instances                                        |
| `public_ips`                    |  list  | Public IPs of the instance (or EIP )                                |
| `aws_key_pair`                  | string | Name of AWS key                                                     |
| `ssh_key_pem_path`              | string | Local path to SSH pem key                                           |
| `security_group_id`             | string | ID of the AWS Security Group associated with the instance           |
| `role_names`                    |  list  | Name of the AWS IAM Roles associated with the instance              |
| `alarm_ids`                     |  list  | CloudWatch Alarm IDs                                                |
| `eni_to_eip_map`                |  map   | ENI to EIP                                                          |
| `ebs_ids`                       |  list  | IDs of EBSs                                                         |
| `primary_network_interface_ids` |  list  | IDs of the instances primary network interfaces                     |
| `network_interface_id`          |  list  | IDs of the network interface that was created with the instance     |
| `public_dns`                    |  list  | Public DNS of the instances (or DNS of EIP)                         |
| `eip_per_instance_count`        | string | Number of EIP's per instance                                        |


## License

## References
* https://github.com/cloudposse/terraform-aws-ec2-bastion-server

## Help

**Got a question?**

Review the [docs](docs/), file a GitHub [issue](https://github.com/cloudposse/terraform-aws-ec2-instance/issues), send us an [email](mailto:hello@cloudposse.com) or reach out to us on [Gitter](https://gitter.im/cloudposse/).


## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/cloudposse/terraform-aws-ec2-instance/issues) to report any bugs or file feature requests.

### Developing

In general, PRs are welcome. We follow the typical "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull request** so that we can review your changes

**NOTE:** Be sure to merge the latest from "upstream" before making a pull request!

## License

[APACHE 2.0](LICENSE) © 2016-2018 [Cloud Posse, LLC](https://cloudposse.com)

    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.


## About

This module is maintained and funded by [Cloud Posse, LLC][website]. Like it? Please let us know at <hello@cloudposse.com>

We love [Open Source Software](https://github.com/cloudposse/)!

See [our other projects][community]
or [hire us][hire] to help build your next cloud-platform.

  [website]: http://cloudposse.com/
  [community]: https://github.com/cloudposse/
  [hire]: http://cloudposse.com/contact/

### Contributors

| [![Erik Osterman][erik_img]][erik_web]<br/>[Erik Osterman][erik_web]        | [![Igor Rodionov][igor_img]][igor_web]<br/>[Igor Rodionov][igor_web] | [![Andriy Knysh][andriy_img]][andriy_web]<br/>[Andriy Knysh][andriy_web]  | [![Sergey Vasilyev][sergey_img]][sergey_web]<br/>[Sergey Vasilyev][sergey_web] | [![Konstantin B][konstantin_img]][konstantin_web]<br/>[Konstantin B][konstantin_web] | [![Valeriy][valeriy_img]][valeriy_web]<br/>[Valeriy][valeriy_web]      | [![Vladimir][vladimir_img]][vladimir_web]<br/>[Vladimir][vladimir_web] |
|---------------------------------------------------------------------------- | ------------------------------------------------------------------   | ------------------------------------------------------------------------- | ----------------------------------------------------------------------         | ----------------------------------------------------------------------               | ---------------------------------------------------------------------- | -----------------------------------------------------------------------|

  [erik_img]: http://s.gravatar.com/avatar/88c480d4f73b813904e00a5695a454cb?s=144
  [erik_web]: https://github.com/osterman/
  [igor_img]: http://s.gravatar.com/avatar/bc70834d32ed4517568a1feb0b9be7e2?s=144
  [igor_web]: https://github.com/goruha/
  [andriy_img]: https://avatars0.githubusercontent.com/u/7356997?v=4&u=ed9ce1c9151d552d985bdf5546772e14ef7ab617&s=144
  [andriy_web]: https://github.com/aknysh/
  [sergey_img]: https://avatars1.githubusercontent.com/u/1134449?v=4&u=ed9ce1c9151d552d985bdf5546772e14ef7ab617&s=144
  [sergey_web]: https://github.com/s2504s/
  [konstantin_img]: https://avatars1.githubusercontent.com/u/11299538?v=4&u=ed9ce1c9151d552d985bdf5546772e14ef7ab617&s=144
  [konstantin_web]: https://github.com/comeanother/
  [valeriy_img]: https://avatars1.githubusercontent.com/u/10601658?v=4&u=ed9ce1c9151d552d985bdf5546772e14ef7ab617&s=144
  [valeriy_web]: https://github.com/drama17/
  [vladimir_img]: https://avatars1.githubusercontent.com/u/26582191?v=4&u=ed9ce1c9151d552d985bdf5546772e14ef7ab617&s=144
  [vladimir_web]: https://github.com/SweetOps/
