output "action_group_id" {
  description = "ID of the action group alerts are sent to."
  value       = azurerm_monitor_action_group.alerts.id
}

output "alert_id" {
  description = "ID of the 5xx metric alert."
  value       = azurerm_monitor_metric_alert.server_errors.id
}
