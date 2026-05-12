## Why

La Entrega 4 requiere integrar monitoreo continuo al microservicio de blacklist desplegado en AWS Fargate. New Relic es la herramienta designada para observar el desempeño en producción: tiempos de respuesta, métricas de DB, Apdex, errores y alertas.

## What Changes

- Agregar el agente Python de New Relic (`newrelic`) como dependencia del proyecto
- Modificar el `Dockerfile` para arrancar gunicorn bajo `newrelic-admin run-program`
- Almacenar el `NEW_RELIC_LICENSE_KEY` en SSM SecureString e inyectarlo al contenedor ECS como secreto
- Exponer `NEW_RELIC_APP_NAME`, `NEW_RELIC_DISTRIBUTED_TRACING_ENABLED` y `NEW_RELIC_LOG` como variables de entorno en la task definition
- Actualizar `terraform.tfvars` con el license key leído del `.env` local
- Actualizar el tag `Course` en locals.tf de `Entrega3` a `Entrega4`

## Capabilities

### New Capabilities

- `new-relic-agent`: Instrumentación del microservicio Flask con el agente Python de New Relic para captura automática de trazas, métricas de aplicación, tiempos de respuesta de DB y registro de errores

### Modified Capabilities

- (ninguna — no cambian requisitos funcionales existentes)

## Impact

- **requirements.txt / pyproject.toml**: nueva dependencia `newrelic`
- **Dockerfile**: cambio en CMD
- **terraform/**: tres archivos modificados (`variables.tf`, `ssm.tf`, `ecs.tf`, `locals.tf`) + `terraform.tfvars`
- **taskdef.json**: nuevo secreto y nuevas variables de entorno
- **Sin cambios en la lógica de la aplicación**: el agente se inyecta a nivel de proceso, no a nivel de código
- **Pipeline CI/CD**: el próximo push dispara build → image nueva → deploy Blue/Green con New Relic activo
