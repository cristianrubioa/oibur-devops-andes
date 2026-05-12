## Context

El microservicio de blacklist corre en AWS ECS Fargate con gunicorn como servidor WSGI. Los secretos se almacenan en SSM Parameter Store (SecureString) y se inyectan al contenedor como variables de entorno en el momento del arranque. La infraestructura es gestionada por Terraform; el pipeline CI/CD usa CodeBuild → ECR → CodeDeploy (Blue/Green).

El agente Python de New Relic se integra a nivel de proceso: envuelve el comando de arranque del servidor (`newrelic-admin run-program`) sin requerir cambios en el código de la aplicación.

## Goals / Non-Goals

**Goals:**
- Instrumentar el microservicio Flask con el agente New Relic sin modificar código de aplicación
- Almacenar el license key de forma segura en SSM, nunca en el repositorio
- Que el pipeline CI/CD existente lleve automáticamente la nueva imagen instrumentada a producción
- Habilitar distributed tracing para trazas de extremo a extremo

**Non-Goals:**
- Custom instrumentation manual (decoradores, métricas custom)
- Alertas configuradas via Terraform (se hacen desde la consola de New Relic)
- Cambios al pipeline CI/CD (buildspec.yml, appspec.yaml)

## Decisions

### D1: Configuración por variables de entorno, sin `newrelic.ini`

**Decisión**: Usar solo env vars (`NEW_RELIC_LICENSE_KEY`, `NEW_RELIC_APP_NAME`, etc.) en lugar de un archivo `newrelic.ini` en el repo.

**Rationale**: El archivo `.ini` requeriría o bien hardcodear el license key (inseguro) o leerlo en runtime desde SSM antes de arrancar el agente (complejidad adicional). Las env vars las inyecta ECS desde SSM automáticamente, consistent con el patrón ya establecido para `DATABASE_URL` y `AUTH_BEARER_TOKEN`.

**Alternativa descartada**: `newrelic.ini` con `license_key = <%= ENV['NEW_RELIC_LICENSE_KEY'] %>` — requiere soporte de templating adicional.

### D2: `newrelic-admin run-program` como wrapper del CMD del Dockerfile

**Decisión**: Cambiar el CMD de:
```
gunicorn --bind 0.0.0.0:5000 ...
```
a:
```
newrelic-admin run-program gunicorn --bind 0.0.0.0:5000 ...
```

**Rationale**: Es el método recomendado por New Relic para Python con WSGI. Inyecta el agente antes de que el servidor cargue la aplicación, garantizando instrumentación completa de todas las peticiones sin cambios en `app.py` ni en el factory `create_app`.

**Alternativa descartada**: `import newrelic.agent; newrelic.agent.initialize()` en `app.py` — acopla la observabilidad al código de aplicación.

### D3: License key en SSM SecureString + nueva variable Terraform

**Decisión**: Añadir variable `new_relic_license_key` en `variables.tf` y recurso `aws_ssm_parameter` en `ssm.tf`. El valor se provee via `terraform.tfvars` (gitignoreado).

**Rationale**: Patrón idéntico al de `auth_bearer_token`. Garantiza que el secret nunca toque el repositorio y que Terraform gestione su ciclo de vida.

## Risks / Trade-offs

- **Overhead de arranque**: `newrelic-admin` añade ~1-2s al startup del contenedor → impacto mínimo, solo afecta deploys Blue/Green.
- **License key en `terraform.tfvars`**: el archivo es gitignoreado pero existe en disco en texto plano → aceptable para entorno de laboratorio; en producción usaría AWS Secrets Manager.
- **Account ID hardcodeado en `taskdef.json`**: el ARN del nuevo parámetro SSM debe usar el mismo account ID (`171109859830`) → válido mientras no cambie la sesión de AWS Academy.

## Migration Plan

1. Agregar `new_relic_license_key` a `terraform.tfvars`
2. Aplicar cambios de código (requirements, Dockerfile, terraform, taskdef)
3. `terraform apply` — crea SSM parameter, actualiza task definition en ECS
4. Push a CodeCommit — pipeline construye nueva imagen con `newrelic` instalado y la despliega via Blue/Green
5. Verificar en consola de New Relic que llegan eventos desde el ambiente cloud

**Rollback**: Revertir el CMD del Dockerfile al original y hacer push — el pipeline despliega la versión sin agente.
