# SkillBridge Infrastructure

Local infrastructure for SkillBridge. The default stack runs PostgreSQL, Redis, RabbitMQ and MinIO. Development credentials in `.env.example` must never be reused outside local development.

## Start core services

```powershell
Copy-Item .env.example .env
docker compose up -d
docker compose ps
```

Or run `./scripts/start.ps1`.

## Endpoints

| Service | Address |
|---|---|
| PostgreSQL | `localhost:5432` |
| Redis | `localhost:6379` |
| RabbitMQ AMQP | `localhost:5672` |
| RabbitMQ UI | `http://localhost:15672` |
| MinIO API | `http://localhost:9000` |
| MinIO Console | `http://localhost:9001` |

## Run the full stack

Clone `skillbridge-api`, `skillbridge-web` and `skillbridge-infra` as sibling directories, then run:

```powershell
docker compose --profile apps up -d --build
```

The web app is available at `http://localhost:3000` and the API at `http://localhost:8080`.

## Data ownership

PostgreSQL is the source of truth. Each module owns one schema. Redis is disposable acceleration/state, RabbitMQ transports integration events, and MinIO emulates cloud blob storage locally.

Stopping the stack preserves named volumes. Do not use `docker compose down --volumes` unless destroying local data is intentional.
