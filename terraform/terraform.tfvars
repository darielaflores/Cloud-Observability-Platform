# =============================================================
# TERRAFORM.TFVARS — Valores por defecto del proyecto
# ⚠️  NO incluir este archivo en producción con datos sensibles.
#     Los secrets se inyectan desde GitHub Actions.
# =============================================================

location            = "francecentral"
resource_group_name = "RG-Monitoring-Lab"
vm_admin_username   = "azureuser"
vm_size             = "Standard_B1s"
public_key_path     = "~/.ssh/id_rsa.pub"

# Tu email para recibir alertas
alert_email = "dariela.flores@tajamar365.com"

# IP permitida para SSH (reemplaza por tu IP real para mayor seguridad)
# Ejemplo: allowed_ssh_ip = "83.45.123.10/32"
allowed_ssh_ip = "*"

tags = {
  Environment = "Lab"
  Project     = "Monitoring"
  ManagedBy   = "Terraform"
  Owner       = "Student"
}
