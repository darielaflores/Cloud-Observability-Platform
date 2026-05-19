# 🌩️ Cloud Monitoring Platform — Terraform + Grafana + Azure

Infraestructura como código para desplegar una plataforma de monitoring completa en Azure con Grafana, Application Insights, Log Analytics y alertas automatizadas.

---


## 📁 Estructura del proyecto

```
infra/terraform/
├── main.tf                    # Provider, backend, recursos base
├── variables.tf               # Definición de variables
├── locals.tf                  # Variables calculadas
├── grafana.tf                 # Grafana en ACI + Service Principal
├── alerts.tf                  # Azure Monitor alerts
├── outputs.tf                 # Outputs del despliegue
├── terraform.tfvars.example   # Plantilla de variables (NO subir .tfvars)
├── .gitignore
├── scripts/
│   └── bootstrap.sh           # Script inicial para el backend de estado
└── .github/
    └── workflows/
        └── terraform-deploy.yml  # Pipeline de GitHub Actions
```

---

## 🚀 Configuración inicial (una sola vez)

### 1. Prerrequisitos

```bash
# Instalar Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Instalar Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Login en Azure
az login
```

### 2. Ejecutar bootstrap

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh tu-sufijo-unico   # ej: ./bootstrap.sh abc123
```

Este script:
- Crea el Resource Group y Storage Account para el estado remoto
- Crea un Service Principal con los permisos necesarios
- **Muestra los secretos que debes añadir a GitHub**

### 3. Configurar variables locales

```bash
cp terraform.tfvars.example terraform.tfvars
# Edita terraform.tfvars con tus valores reales
```

### 4. Primer despliegue local

```bash
terraform init
terraform plan
terraform apply
```

---

## 🔐 Secretos de GitHub Actions

Ve a tu repo → **Settings → Secrets and variables → Actions** y añade:

| Secret | Descripción |
|--------|-------------|
| `ARM_SUBSCRIPTION_ID` | ID de tu suscripción Azure Student |
| `ARM_TENANT_ID` | Tenant ID de Azure AD |
| `ARM_CLIENT_ID` | Client ID del Service Principal |
| `ARM_CLIENT_SECRET` | Client Secret del Service Principal |
| `TF_STATE_STORAGE_ACCOUNT` | Nombre del storage account del estado |
| `OWNER_EMAIL` | Tu email universitario |
| `ALERT_EMAIL` | Email para recibir alertas |
| `INFRACOST_API_KEY` | *(Opcional)* API key de Infracost para costes |

---

## 🔄 Flujo del pipeline de GitHub Actions

```
Push/PR ──▶ validate ──▶ plan ──▶ (PR comment) 
                                      │
Push main ────────────────────────────▶ apply
                                      │
workflow_dispatch (destroy) ──────────▶ destroy (requiere aprobación)
```

| Evento | Resultado |
|--------|-----------|
| PR a `main` | Validate + Plan + comentario en PR |
| Push a `develop` | Validate + Plan |
| Push a `main` | Validate + Plan + **Apply automático** |
| `workflow_dispatch` → apply | Apply en entorno seleccionado |
| `workflow_dispatch` → destroy | Destroy con aprobación manual |

---

## 📊 Conectar Grafana con Azure Monitor

Después del primer `apply`, sigue los pasos del output de Terraform:

1. **Accede a Grafana** en la URL del output `grafana_url`
2. Ve a **Configuration → Data Sources → Add data source → Azure Monitor**
3. Rellena con los valores del output:
   - **Tenant ID**: `grafana_service_principal_tenant_id`
   - **Client ID**: `grafana_service_principal_client_id`
   - **Client Secret**: obtén el valor del Key Vault:
     ```bash
     az keyvault secret show \
       --vault-name <key_vault_name> \
       --name grafana-sp-client-secret \
       --query value -o tsv
     ```
4. Pulsa **Save & Test** → debería confirmar la conexión

### Dashboards recomendados (importar por ID en Grafana)

| ID | Descripción |
|----|-------------|
| `187` | Azure Monitor — Overview |
| `10956` | Application Insights — Full |
| `13139` | Log Analytics Workspace |

---

## 💰 Costes estimados (suscripción estudiante)

| Recurso | Coste aproximado/mes |
|---------|---------------------|
| Log Analytics (30 días, < 5GB/día) | ~$0 (free tier) |
| Application Insights | ~$0 (free tier 5GB) |
| Azure Container Instance (Grafana) | ~$10-15 |
| Storage Account (estado + Grafana) | ~$1 |
| Key Vault | ~$0.03 |
| **Total estimado** | **~$12-17/mes** |

> 💡 Para reducir costes, para el contenedor de Grafana cuando no lo uses:
> ```bash
> az container stop --name aci-grafana-dev --resource-group rg-cloudmon-dev
> ```

---

## 🛠️ Comandos útiles

```bash
# Ver estado actual
terraform show

# Refrescar estado sin aplicar cambios
terraform refresh

# Destruir solo Grafana (mantener monitoring)
terraform destroy -target=azurerm_container_group.grafana

# Ver logs de Grafana en tiempo real
az container logs --name aci-grafana-dev \
  --resource-group rg-cloudmon-dev --follow

# Obtener contraseña de Grafana
az keyvault secret show \
  --vault-name <kv-name> \
  --name grafana-admin-password \
  --query value -o tsv
```
