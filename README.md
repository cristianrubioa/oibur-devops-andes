# oibur-devops-andes

Microservicio Flask para gestionar una lista negra global de emails.

## Requisitos

- Python 3.11+
- Poetry 1.8+

## Configuración local

```bash
poetry install
cp .env.example .env
```

Edita `.env` con tus valores locales (PostgreSQL):

```env
DATABASE_URL=postgresql+psycopg2://postgres:postgres@localhost:5432/blacklist_db
AUTH_BEARER_TOKEN=static-token
JWT_SECRET_KEY=dev-jwt-secret
```

Puedes levantar PostgreSQL con Docker:

```bash
docker run --name blacklist-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=blacklist_db -p 5432:5432 -d postgres:15
```

## Ejecutar local

```bash
poetry run flask --app app run --host 0.0.0.0 --port 5000
```

## Ejecutar pruebas

```bash
poetry run pytest -q
```

## Endpoints

- `GET /health`
- `POST /blacklists` (Bearer Token)
- `GET /blacklists/<string:email>` (Bearer Token)

Header requerido para endpoints protegidos:

```text
Authorization: Bearer static-token
```

## Postman

Importa estos archivos en Postman:

- `postman/blacklist-microservice.collection.json`
- `postman/local.postman_environment.json`

Luego selecciona el environment `Blacklist Local` y ejecuta la colección completa.

### Sincronización automática de colección (Postman API)

Puedes crear/actualizar la colección en tu workspace sin hacerlo manualmente:

```bash
POSTMAN_API_KEY="<tu_api_key>" \
POSTMAN_WORKSPACE_ID="<tu_workspace_id>" \
./postman/sync_postman_collection.sh
```

Después de sincronizar, entra a Postman y publica la documentación de la colección para obtener la URL pública.
