# Restart dead or hung instance

locals {
  action = "arn:aws:swf:${local.region}:${data.aws_caller_identity.default.account_id}:${var.default_alarm_action}"
}

resource "aws_cloudwatch_metric_alarm" "default" {
  count               = local.instance_count
  alarm_name          = "${module.label.id}-${count.index}"
  comparison_operator = var.comparison_operator
  evaluation_periods  = var.evaluation_periods
  metric_name         = var.metric_name
  namespace           = var.metric_namespace
  period              = var.applying_period
  statistic           = var.statistic_level
  threshold           = var.metric_threshold

  dimensions = {
    InstanceId = element(sort(aws_instance.default.*.id), count.index)
  }

  # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
  # force an interpolation expression to be interpreted as a list by wrapping it
  # in an extra set of list brackets. That form was supported for compatibilty in
  # v0.11, but is no longer supported in Terraform v0.12.
  #
  # If the expression in the following list itself returns a list, remove the
  # brackets to avoid interpretation as a list of lists. If the expression
  # returns a single list item then leave it as-is and remove this TODO comment.
  alarm_actions = [
    local.action,
  ]
}

