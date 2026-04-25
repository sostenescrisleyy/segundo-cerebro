---
tags: [backend]
categoria: "Backend"
---

# Docker — Containerização Moderna

**Versão:** Docker 27+ | Docker Compose v2  
**Princípio:** Imagens pequenas, camadas cacheadas, never run as root.

---

## Dockerfile — Node.js/Next.js Otimizado

```dockerfile
# syntax=docker/dockerfile:1

# ── Estágio 1: dependências ──────────────────────────────────
FROM node:22-alpine AS deps
WORKDIR /app

# Copiar apenas manifests primeiro (melhor cache)
COPY package.json package-lock.json ./
RUN npm ci --frozen-lockfile

# ── Estágio 2: build ─────────────────────────────────────────
FROM node:22-alpine AS builder
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# ── Estágio 3: produção (imagem final mínima) ─────────────────
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Criar usuário não-root
RUN addgroup --system --gid 1001 nodejs \
 && adduser  --system --uid 1001 nextjs

# Copiar apenas o necessário do build
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT=3000 HOSTNAME=0.0.0.0

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget -qO- http://localhost:3000/api/health || exit 1

CMD ["node", "server.js"]
```

---

## Dockerfile — Python/FastAPI

```dockerfile
FROM python:3.12-slim AS base
WORKDIR /app

# Dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
 && rm -rf /var/lib/apt/lists/*

# Dependências Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN adduser --disabled-password --gecos '' appuser
USER appuser

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -f http://localhost:8000/health || exit 1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

---

## Docker Compose — Stack Completa

```yaml
# docker-compose.yml
services:

  # ── App principal ──────────────────────────────────────────
  app:
    build:
      context: .
      target: runner          # estágio do multi-stage
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://user:pass@postgres:5432/mydb
      REDIS_URL:    redis://redis:6379
    depends_on:
      postgres: { condition: service_healthy }
      redis:    { condition: service_healthy }
    restart: unless-stopped
    networks:
      - internal

  # ── PostgreSQL ─────────────────────────────────────────────
  postgres:
    image: postgres:16-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_USER:     user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB:       mydb
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d mydb"]
      interval: 5s
      timeout: 5s
      retries: 10
    networks:
      - internal

  # ── Redis ──────────────────────────────────────────────────
  redis:
    image: redis:7-alpine
    command: redis-server --requirepass redispass --save 60 1
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "redispass", "ping"]
      interval: 5s
      retries: 10
    networks:
      - internal

  # ── Nginx (reverse proxy) ──────────────────────────────────
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
    depends_on: [app]
    networks:
      - internal

volumes:
  pgdata:
  redisdata:

networks:
  internal:
    driver: bridge
```

---

## Comandos Essenciais

```bash
# ── Build ─────────────────────────────────────────────────────
docker build -t minha-app:latest .
docker build -t minha-app:latest --no-cache .
docker build --target runner -t minha-app:prod .

# ── Run ──────────────────────────────────────────────────────
docker run -d \
  --name minha-app \
  -p 3000:3000 \
  -e NODE_ENV=production \
  --restart unless-stopped \
  minha-app:latest

# ── Compose ──────────────────────────────────────────────────
docker compose up -d              # sobe em background
docker compose up -d --build      # rebuilda e sobe
docker compose down -v            # derruba + remove volumes
docker compose logs -f app        # logs em tempo real
docker compose exec app sh        # shell no container

# ── Imagem ───────────────────────────────────────────────────
docker images
docker rmi minha-app:latest
docker system prune -af           # limpa tudo não usado

# ── Registry ─────────────────────────────────────────────────
docker tag  minha-app:latest usuario/minha-app:1.0.0
docker push usuario/minha-app:1.0.0
docker pull usuario/minha-app:1.0.0

# ── Debug ────────────────────────────────────────────────────
docker logs -f --tail 100 minha-app
docker exec -it minha-app sh
docker inspect minha-app
docker stats                      # uso de CPU/RAM em tempo real
```

---

## .dockerignore

```
node_modules
.next
.git
*.log
.env*
!.env.example
dist
coverage
README.md
```

---

## Referências

→ `references/compose-prod.md` — Docker Compose em produção: secrets, profiles, deploy


---

## Relacionado

[[Node.js]] | [[FastAPI Python]] | [[PostgreSQL]]


---

## Referencias

- [[Referencias/compose-prod]]
