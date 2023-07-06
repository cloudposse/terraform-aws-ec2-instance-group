module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "2.2.0"

  security_group_name        = var.security_group_name
  rules                      = var.security_group_rules
  security_group_description = var.security_group_description
  vpc_id                     = var.vpc_id

  enabled = local.security_group_enabled
  context = module.this.context
}
