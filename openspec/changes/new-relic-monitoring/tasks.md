## 1. Dependencias y configuración de la aplicación

- [x] 1.1 Agregar `newrelic` a `requirements.txt` (versión pinned, ej: `newrelic==10.4.0`)
- [x] 1.2 Agregar `newrelic = "^10.0.0"` a `[tool.poetry.dependencies]` en `pyproject.toml`
- [x] 1.3 Actualizar `Dockerfile` CMD: `newrelic-admin run-program gunicorn --bind 0.0.0.0:5000 --workers 2 --timeout 60 app:application`

## 2. Infraestructura Terraform

- [x] 2.1 Agregar variable `new_relic_license_key` (sensitive = true) en `terraform/variables.tf`
- [x] 2.2 Agregar recurso `aws_ssm_parameter` para `/blacklist/NEW_RELIC_LICENSE_KEY` (SecureString) en `terraform/ssm.tf`
- [x] 2.3 Agregar secret `NEW_RELIC_LICENSE_KEY` (desde SSM) en la sección `secrets` del contenedor en `terraform/ecs.tf`
- [x] 2.4 Agregar env vars `NEW_RELIC_APP_NAME`, `NEW_RELIC_DISTRIBUTED_TRACING_ENABLED`, `NEW_RELIC_LOG` en la sección `environment` del contenedor en `terraform/ecs.tf`
- [x] 2.5 Actualizar tag `Course` de `Entrega3` a `Entrega4` en `terraform/locals.tf`

## 3. Task definition para CodeDeploy

- [x] 3.1 Agregar secret `NEW_RELIC_LICENSE_KEY` en `taskdef.json` (ARN: `arn:aws:ssm:us-east-1:171109859830:parameter/blacklist/NEW_RELIC_LICENSE_KEY`)
- [x] 3.2 Agregar env vars `NEW_RELIC_APP_NAME`, `NEW_RELIC_DISTRIBUTED_TRACING_ENABLED`, `NEW_RELIC_LOG` en `taskdef.json`

## 4. Secrets locales y despliegue de infraestructura

- [x] 4.1 Leer `NEW_RELIC_LICENSE_KEY` del archivo `.env` y agregar `new_relic_license_key = "<valor>"` a `terraform/terraform.tfvars`
- [x] 4.2 Ejecutar `terraform apply` (previa confirmación del usuario) para crear la nueva infra: RDS, SSM params, ECS task definition actualizada
- [x] 4.3 Verificar que el ALB esté accesible y que el servicio ECS tenga la tarea corriendo

## 5. Despliegue via pipeline CI/CD

- [ ] 5.1 Hacer push del código a CodeCommit (previa confirmación del usuario) para disparar el pipeline
- [ ] 5.2 Verificar que CodeBuild compile exitosamente y la imagen con `newrelic` se suba a ECR
- [ ] 5.3 Verificar que CodeDeploy complete el deploy Blue/Green sin errores

## 6. Verificación de New Relic

- [ ] 6.1 Confirmar que la aplicación `blacklist-microservice` aparece en la consola de New Relic
- [ ] 6.2 Generar tráfico de prueba (usando la colección Postman existente) y verificar que llegan trazas a New Relic
