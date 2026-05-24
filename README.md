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

---

