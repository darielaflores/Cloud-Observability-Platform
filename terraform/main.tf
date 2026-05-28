# =============================================================
# MAIN.TF — Despliegue y Monitorización en Azure con Grafana
# Incluye: VM + AMA Agent + Log Analytics + Grafana + Alerts
# =============================================================

# ------------------------------------------------------------------
# RESOURCE GROUP
# ------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# ------------------------------------------------------------------
# VIRTUAL NETWORK
# ------------------------------------------------------------------
resource "azurerm_virtual_network" "main" {
  name                = "vnet-monitoring"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]

  tags = var.tags
}

# ------------------------------------------------------------------
# SUBNET
# ------------------------------------------------------------------
resource "azurerm_subnet" "main" {
  name                 = "subnet-monitoring"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ------------------------------------------------------------------
# PUBLIC IP
# ------------------------------------------------------------------
resource "azurerm_public_ip" "main" {
  name                = "public-ip-monitoring"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

# ------------------------------------------------------------------
# NETWORK SECURITY GROUP
# ------------------------------------------------------------------
resource "azurerm_network_security_group" "main" {
  name                = "nsg-monitoring"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# ------------------------------------------------------------------
# NSG RULE — SSH
# ------------------------------------------------------------------
resource "azurerm_network_security_rule" "ssh" {
  name                        = "AllowSSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.allowed_ssh_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

# ------------------------------------------------------------------
# NSG RULE — HTTP
# ------------------------------------------------------------------

resource "azurerm_network_security_rule" "http" {
  name                        = "AllowHTTP"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

# ------------------------------------------------------------------
# NSG RULE — Deny All Inbound (resto del tráfico bloqueado)
# ------------------------------------------------------------------
resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "DenyAllInbound"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

# ------------------------------------------------------------------
# NETWORK INTERFACE
# ------------------------------------------------------------------
resource "azurerm_network_interface" "main" {
  name                = "nic-monitoring"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = var.tags
}

# ------------------------------------------------------------------
# NIC ↔ NSG ASSOCIATION
# ------------------------------------------------------------------
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# ------------------------------------------------------------------
# LOG ANALYTICS WORKSPACE
# ------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-monitoring-demo"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30   # Mínimo para suscripción estudiante

  tags = var.tags
}

# ------------------------------------------------------------------
# DATA COLLECTION RULE (DCR) — Recopila métricas y logs de la VM
# ------------------------------------------------------------------
resource "azurerm_monitor_data_collection_rule" "main" {
  name                = "dcr-vm-monitoring"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      name                  = "lawdest"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["lawdest"]
  }

  data_sources {
    syslog {
      streams        = ["Microsoft-Syslog"]
      facility_names = ["auth", "authpriv", "daemon", "kern", "syslog"]
      log_levels     = ["Warning", "Error", "Critical", "Alert", "Emergency"]
      name           = "syslogDataSource"
    }
  }
}

# ------------------------------------------------------------------
# DATA COLLECTION RULE ASSOCIATION — vincula DCR con la VM
# ------------------------------------------------------------------
resource "azurerm_monitor_data_collection_rule_association" "main" {
  name                    = "dcr-association-vm"
  target_resource_id      = azurerm_linux_virtual_machine.main.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.main.id
}

# ------------------------------------------------------------------
# LINUX VIRTUAL MACHINE
# ------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "main" {
  name                = "vm-monitor-demo"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username

  # Deshabilitar contraseña (solo SSH key)
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.main.id
  ]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.ssh_public_key != "" ? var.ssh_public_key : file(var.public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Script de arranque: instala dependencias básicas
  custom_data = base64encode(<<-EOT
    #!/bin/bash
    apt-get update -y
    apt-get install -y stress-ng sysstat curl wget docker.io
    systemctl enable docker
    systemctl start docker
    systemctl enable sysstat
    systemctl start sysstat

    # Lanza Nginx como aplicación web
    docker run -d \
      --name webapp \
      --restart always \
      -p 80:80 \
      nginx:latest

    # Página personalizada para demostrar que funciona
    docker exec webapp bash -c 'echo "<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><title>Azure Monitoring Lab</title></head><body style="background:#0f1117;color:#fff;font-family:sans-serif;text-align:center;padding:80px"><h1>Despliegue y Monitorización Automatizada en Azure con Terraform y Grafana</h1><p>Aplicación desplegada automáticamente con Terraform</p><p>Monitorizada en tiempo real con Grafana</p></body></html>" > /usr/share/nginx/html/index.html'
  EOT
  )

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# ------------------------------------------------------------------
# AZURE MONITOR LINUX AGENT (AMA)
# ------------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.main.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.29"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    "authentication" = {
      "managedIdentity" = {
        "identifier-name"  = "mi_res_id"
        "identifier-value" = azurerm_linux_virtual_machine.main.id
      }
    }
  })

  tags = var.tags

  depends_on = [azurerm_monitor_data_collection_rule_association.main]
}

# ------------------------------------------------------------------
# MANAGED GRAFANA
# ------------------------------------------------------------------
resource "azurerm_dashboard_grafana" "main" {
  name                              = "grafana-monitoring-lab"
  location                          = azurerm_resource_group.main.location
  resource_group_name               = azurerm_resource_group.main.name
  grafana_major_version             = "11"
  api_key_enabled                   = true
  deterministic_outbound_ip_enabled = false
  public_network_access_enabled     = true

  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.main.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# ------------------------------------------------------------------
# AZURE MONITOR WORKSPACE (necesario para métricas en Grafana)
# ------------------------------------------------------------------
resource "azurerm_monitor_workspace" "main" {
  name                = "amw-monitoring-lab"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# ------------------------------------------------------------------
# ROLE ASSIGNMENT — Grafana puede leer métricas del RG
# ------------------------------------------------------------------
resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.main.identity[0].principal_id
}

# ------------------------------------------------------------------
# ROLE ASSIGNMENT — Grafana puede leer desde Log Analytics
# ------------------------------------------------------------------
resource "azurerm_role_assignment" "grafana_law_reader" {
  scope                = azurerm_log_analytics_workspace.main.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = azurerm_dashboard_grafana.main.identity[0].principal_id
}

# ------------------------------------------------------------------
# ROLE ASSIGNMENT — Grafana puede leer desde Azure Monitor Workspace
# ------------------------------------------------------------------
resource "azurerm_role_assignment" "grafana_amw_reader" {
  scope                = azurerm_monitor_workspace.main.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_dashboard_grafana.main.identity[0].principal_id
}

# ------------------------------------------------------------------
# ACTION GROUP — Canal de notificaciones para alertas
# ------------------------------------------------------------------
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-monitoring-alerts"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "MonAlerts"

  email_receiver {
    name                    = "admin-email"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = var.tags
}

# ------------------------------------------------------------------
# ALERT RULE — CPU > 80% durante 5 minutos
# ------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "cpu_high" {
  name                = "alert-cpu-high"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine.main.id]
  description         = "Alerta cuando el uso de CPU supera el 80% durante 5 minutos"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# ------------------------------------------------------------------
# ALERT RULE — Memoria disponible < 500 MB
# ------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "memory_low" {
  name                = "alert-memory-low"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_linux_virtual_machine.main.id]
  description         = "Alerta cuando la memoria disponible baja de 500 MB"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 524288000  # 500 MB en bytes
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# ------------------------------------------------------------------
# ALERT RULE — VM apagada (Heartbeat perdido)
# ------------------------------------------------------------------
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "vm_heartbeat" {
  name                = "alert-vm-heartbeat"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  scopes              = [azurerm_log_analytics_workspace.main.id]
  description         = "Alerta si la VM no envía heartbeat en los últimos 5 minutos"
  severity            = 1
  enabled             = true
  evaluation_frequency = "PT5M"
  window_duration      = "PT10M"

  criteria {
    query = <<-QUERY
      Heartbeat
      | where Computer == "${azurerm_linux_virtual_machine.main.name}"
      | summarize LastHeartbeat = max(TimeGenerated)
      | extend HeartbeatAge = now() - LastHeartbeat
      | where HeartbeatAge > 5m
    QUERY

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.main.id]
  }

  tags = var.tags
}
