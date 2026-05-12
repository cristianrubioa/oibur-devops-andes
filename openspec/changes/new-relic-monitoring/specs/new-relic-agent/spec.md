## ADDED Requirements

### Requirement: Agente New Relic instalado como dependencia

El proyecto SHALL incluir `newrelic` como dependencia de runtime en `requirements.txt` y `pyproject.toml`.

#### Scenario: Build Docker exitoso con agente instalado
- **WHEN** se ejecuta `docker build` con el `Dockerfile` del proyecto
- **THEN** la imagen resultante contiene el binario `newrelic-admin` disponible en PATH

### Requirement: Arranque del servidor bajo newrelic-admin

El `Dockerfile` SHALL arrancar gunicorn mediante `newrelic-admin run-program gunicorn ...` para que el agente instrumente todas las peticiones.

#### Scenario: Contenedor arranca con agente activo
- **WHEN** el contenedor ECS arranca con `NEW_RELIC_LICENSE_KEY` presente en el entorno
- **THEN** el proceso gunicorn corre bajo supervisión del agente New Relic y envía telemetría a la cuenta configurada

#### Scenario: Contenedor arranca sin license key
- **WHEN** el contenedor arranca sin `NEW_RELIC_LICENSE_KEY`
- **THEN** `newrelic-admin` arranca gunicorn igualmente (el agente se desactiva silenciosamente) y la aplicación responde con normalidad

### Requirement: License key almacenado en SSM SecureString

El `NEW_RELIC_LICENSE_KEY` SHALL almacenarse en SSM Parameter Store como `SecureString` bajo el path `/blacklist/NEW_RELIC_LICENSE_KEY` y nunca en el repositorio de código.

#### Scenario: Terraform crea el parámetro SSM
- **WHEN** se ejecuta `terraform apply` con la variable `new_relic_license_key` definida en `terraform.tfvars`
- **THEN** existe en SSM el parámetro `/blacklist/NEW_RELIC_LICENSE_KEY` de tipo `SecureString` con el valor correcto

### Requirement: Secreto inyectado al contenedor ECS desde SSM

La task definition de ECS SHALL incluir `NEW_RELIC_LICENSE_KEY` en la sección `secrets`, referenciando el ARN del parámetro SSM.

#### Scenario: ECS inyecta el license key al contenedor
- **WHEN** ECS lanza una nueva tarea (task) del servicio blacklist-microservice
- **THEN** la variable de entorno `NEW_RELIC_LICENSE_KEY` está disponible dentro del contenedor con el valor almacenado en SSM

### Requirement: Variables de configuración del agente como env vars

La task definition SHALL incluir las siguientes variables de entorno no sensibles:
- `NEW_RELIC_APP_NAME=blacklist-microservice`
- `NEW_RELIC_DISTRIBUTED_TRACING_ENABLED=true`
- `NEW_RELIC_LOG=stdout`

#### Scenario: App name visible en New Relic
- **WHEN** el agente envía telemetría a New Relic
- **THEN** la aplicación aparece en la consola de New Relic con el nombre `blacklist-microservice`

### Requirement: Telemetría recibida desde ambiente cloud

Una vez desplegado via pipeline CI/CD, New Relic SHALL recibir eventos de la aplicación corriendo en AWS Fargate.

#### Scenario: Tráfico HTTP genera trazas en New Relic
- **WHEN** se realizan peticiones HTTP a los endpoints de la API (a través del ALB)
- **THEN** New Relic muestra trazas, tiempos de respuesta y métricas Apdex para `blacklist-microservice`
