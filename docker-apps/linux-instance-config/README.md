# Linux Instance Config

This folder is a configuration for Linux machines such as EC2 instances.
It has web server, postgresql db (and a migrator service), rabbitmq, orchestrator (that publish messages), consumer and monitoring stack (Grafana, Prometheus, Loki).

## Environment variables

Copy `.env.example` to `.env` and fill in your values before starting:

```bash
cp .env.example .env
```

```env
RABBITMQ_USER=your_user
RABBITMQ_PASS=your_strong_password
GRAFANA_USER=admin
GRAFANA_PASS=your_grafana_password
```

## Starting the stack

```bash
# Allow docker to read configuration files
chmod 644 rabbitmq.conf rabbitmq_enabled_plugins
chmod 644 prometheus.yml
chmod 644 grafana/provisioning/datasources/prometheus.yml 
chmod 644 loki-config.yml

# Run
./start.sh

# Stop
./stop.sh

# Run without rebuilding Docker images
./start_no_build.sh

# Run database migrations without restarting the other containers
./migrate.sh
```

## Accessing the UIs

Only two ports are exposed to the host:

- **Web Server** → http://localhost:3000
- **Grafana** → http://localhost:3020

RabbitMQ Management and Prometheus are not exposed. Access them via SSH tunnel:

```bash
ssh -L 15672:localhost:15672 -L 9090:localhost:9090 user@host
```

Then open:
- **RabbitMQ Management** → http://localhost:15672
- **Prometheus** → http://localhost:9090

## Run Database Migrations

When running `start.sh` script, migrations run by default.
It is possible to only run migrations file by running `migrate.sh` script.

## Opening additional ports for local development

Use `docker-compose.override.yml` to expose ports that are intentionally blocked in production. The file is automatically picked up by `docker compose` alongside the main compose file.

Example — expose RabbitMQ, Prometheus, Loki, Orchestrator, and Postgres:

```yaml
services:
  db:
    ports:
      - "5432:5432"
  rabbitmq:
    ports:
      - "5672:5672"
      - "15672:15672"
      - "15692:15692"
  prometheus:
    ports:
      - "9090:9090"
  loki:
    ports:
      - "3100:3100"
  orchestrator:
    ports:
      - "3010:3010"
```
