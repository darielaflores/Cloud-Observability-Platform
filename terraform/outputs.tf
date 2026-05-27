# =============================================================
# OUTPUTS.TF
# =============================================================

output "vm_public_ip" {
  description = "IP pública de la VM para acceso SSH"
  value       = azurerm_public_ip.main.ip_address
}

output "vm_ssh_command" {
  description = "Comando SSH directo para conectarte a la VM"
  value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "grafana_url" {
  description = "URL del dashboard de Grafana Managed"
  value       = azurerm_dashboard_grafana.main.endpoint
}

output "log_analytics_workspace_id" {
  description = "ID del Log Analytics Workspace (para conectar data sources en Grafana)"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

output "log_analytics_workspace_key" {
  description = "Primary Key del Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "azure_monitor_workspace_id" {
  description = "ID del Azure Monitor Workspace"
  value       = azurerm_monitor_workspace.main.id
}

output "grafana_principal_id" {
  description = "Principal ID de la identidad de Grafana (para asignar roles adicionales)"
  value       = azurerm_dashboard_grafana.main.identity[0].principal_id
}

output "resource_group_name" {
  description = "Nombre del Resource Group creado"
  value       = azurerm_resource_group.main.name
}

output "automation_account_name" {
  description = "Nombre del Automation Account para runbooks"
  value       = azurerm_automation_account.main.name
}

output "webapp_url" {
  description = "URL de la aplicación web desplegada"
  value       = "http://${azurerm_public_ip.main.ip_address}"
}
