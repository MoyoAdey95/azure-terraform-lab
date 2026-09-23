# Alerting for the app.
#
# The obvious alert, no healthy replicas, is wrong here. This app scales to
# zero on purpose, so zero replicas is the normal idle state and an alert on
# it would fire every time nobody used the app. The signal that means users
# are affected is requests coming back as 5xx.

resource "azurerm_monitor_action_group" "alerts" {
  name                = "ag-${var.name_prefix}"
  resource_group_name = var.resource_group_name
  short_name          = "azlab"

  email_receiver {
    name                    = "owner"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = var.tags
}

# Requests carries a statusCodeCategory dimension, confirmed with
# az monitor metrics list-definitions against the app.
resource "azurerm_monitor_metric_alert" "server_errors" {
  name                = "alert-${var.name_prefix}-5xx"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_id]
  description         = "The app returned a server error."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "Requests"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 0

    dimension {
      name     = "statusCodeCategory"
      operator = "Include"
      values   = ["5xx"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.alerts.id
  }

  tags = var.tags
}
