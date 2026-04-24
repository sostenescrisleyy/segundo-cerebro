# Docker Compose — Produção, Secrets e Profiles

## Secrets (senhas sem expor em env vars)

```yaml
services:
  app:
    secrets:
      - db_password
      - jwt_secret
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
  jwt_secret:
    file: ./secrets/jwt_secret.txt
```

## Profiles (ambientes separados)

```yaml
services:
  app:
    profiles: ["prod", "dev"]
    
  mailhog:           # só no dev
    image: mailhog/mailhog
    profiles: ["dev"]
    
  prometheus:        # só em prod
    image: prom/prometheus
    profiles: ["prod"]
```

```bash
docker compose --profile dev up
docker compose --profile prod up
```

## Health Check Avançado

```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval:     30s   # checa a cada 30s
  timeout:       5s   # timeout da verificação
  retries:        3   # tentativas antes de unhealthy
  start_period:  40s  # espera antes de começar checagens
```

## Limitar Recursos

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M
```

## Multi-arquivo (override por ambiente)

```bash
# docker-compose.yml         → base
# docker-compose.override.yml → dev (automático)
# docker-compose.prod.yml     → produção

docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```


---

← [[README|Docker e Compose]]
