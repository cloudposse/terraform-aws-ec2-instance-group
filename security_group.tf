module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "2.1.0"

  use_name_prefix = var.security_group_use_name_prefix
  rules           = var.security_group_rules
  description     = var.security_group_description
  vpc_id          = var.vpc_id

  enabled = local.security_group_enabled
  context = module.this.context
}
