# · Cloud Monitoring Platform — Terraform + Grafana + Azure

Infraestructura como código para desplegar una plataforma de monitoring completa en Azure con Grafana, Application Insights, Log Analytics y alertas automatizadas.

---


## 📁 Estructura del proyecto

```
infra/terraform/
├── main.tf                    # Provider, backend, recursos base
├── variables.tf               # Definición de variables
├── outputs.tf                 # Outputs del despliegue
├── terraform.tfvars           # variables
└── .github/
    └── workflows/
        └── terraform-deploy.yml  # Pipeline de GitHub Actions
```

---


## 🔄 Flujo del pipeline de GitHub Actions

```
Push ──▶ validate ──▶ plan
                        │
Push main ────────────────────────────▶ apply
                                      │
workflow_dispatch (destroy) ──────────▶ destroy (requiere aprobación)
```

| Evento | Resultado |
|--------|-----------|
| `workflow_dispatch` → apply | Apply en entorno seleccionado |
| `workflow_dispatch` → destroy | Destroy con aprobación manual |

---

## 📊 Conectar Grafana con Azure Monitor

1. **Accede a Grafana** en la URL del output `grafana_url`
2. Ve a **Configuration → Data Sources → Add data source → Azure Monitor**
3. Rellena con los valores del output:
   - **Tenant ID**
   - **Client ID**
   - **Client Secret**
     
4. Pulsa **Save & Test** → debería confirmar la conexión

---

