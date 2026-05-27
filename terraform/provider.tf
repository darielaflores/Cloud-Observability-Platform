# =============================================================
# PROVIDER.TF — Configuración del provider y backend remoto
# =============================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # ---------------------------------------------------------------
  # BACKEND REMOTO — Almacena el state en Azure Blob Storage
  # Descomenta y configura tras crear el Storage Account manualmente
  # o ejecutar el script bootstrap/init-backend.sh
  # ---------------------------------------------------------------
  # backend "azurerm" {
  #   resource_group_name  = "RG-Terraform-State"
  #   storage_account_name = "sttfstatemonitorlab"   # debe ser único globalmente
  #   container_name       = "tfstate"
  #   key                  = "monitoring-lab.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      # Evita borrar el RG si aún tiene recursos no gestionados por Terraform
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      # No borra discos OS automáticamente al destruir la VM
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }

  # En CI/CD estas variables se inyectan como env vars:
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
}
