# =============================================================
# VARIABLES.TF
# =============================================================

variable "location" {
  description = "Región Azure donde se despliega la infraestructura"
  type        = string
  default     = "francecentral"
}

variable "resource_group_name" {
  description = "Nombre del Resource Group principal"
  type        = string
  default     = "RG-Monitoring-Lab"
}

variable "vm_admin_username" {
  description = "Usuario administrador de la VM Linux"
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "Tamaño de la VM (optimizado para suscripción estudiante)"
  type        = string
  default     = "Standard_B1s"
  # Opciones válidas para estudiante: Standard_B1s, Standard_B1ms, Standard_B2s
}

variable "public_key_path" {
  description = "Ruta local a tu clave SSH pública (uso local, no en CI/CD)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_public_key" {
  description = "Contenido de la clave SSH pública (usado en CI/CD via secret)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "allowed_ssh_ip" {
  description = "IP permitida para SSH. Usa '*' para cualquiera o una IP específica ej: '1.2.3.4/32'"
  type        = string
  default     = "*"
}

variable "alert_email" {
  description = "Email donde se enviarán las alertas de Azure Monitor"
  type        = string
  default     = "dariela.flores@tajamar365.com"
}

variable "tags" {
  description = "Tags aplicados a todos los recursos"
  type        = map(string)
  default = {
    Environment = "Lab"
    Project     = "Monitoring"
    ManagedBy   = "Terraform"
    Owner       = "Student"
  }
}
