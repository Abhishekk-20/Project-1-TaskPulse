# Cost notification only. AWS Budgets alerts do NOT stop or cap spending.
variable "budget_alert_email" {
  description = "Email address to receive monthly AWS cost alerts"
  type        = string
}

resource "aws_budgets_budget" "taskpulse_monthly_learning" {
  name         = "taskpulse-monthly-learning-budget"
  budget_type  = "COST"
  limit_amount = "18"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }
}
