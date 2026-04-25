# Pré-requisitos: PostgreSQL e Redis

## PostgreSQL

### Versão recomendada: 15 ou 16

### Via Docker (parte do compose)

```yaml
postgres:
  image: postgres:15
  environment:
    POSTGRES_DB: evolution_db
    POSTGRES_USER: evolution_user
    POSTGRES_PASSWORD: senha_segura_aqui
  volumes:
    - evolution_postgres:/var/lib/postgresql/data
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U evolution_user -d evolution_db"]
    interval: 10s
    timeout: 5s
    retries: 5
```

### Instalação nativa no Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib

# Iniciar serviço
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Criar banco e usuário
sudo -u postgres psql <<EOF
CREATE USER evolution_user WITH PASSWORD 'senha_segura';
CREATE DATABASE evolution_db OWNER evolution_user;
GRANT ALL PRIVILEGES ON DATABASE evolution_db TO evolution_user;
EOF
```

### URI de conexão

```
postgresql://evolution_user:senha_segura@localhost:5432/evolution_db
# No Docker Compose, use o nome do serviço como host:
postgresql://evolution_user:senha_segura@postgres:5432/evolution_db
```

---

## Redis

### Versão recomendada: 7+

### Via Docker (parte do compose)

```yaml
redis:
  image: redis:7-alpine
  command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
  volumes:
    - evolution_redis:/data
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 5s
    retries: 5
```

> **Importante:** O flag `--appendonly yes` ativa persistência AOF, garantindo que os dados
> não sejam perdidos em restart do container.

### Instalação nativa no Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y redis-server

sudo systemctl start redis-server
sudo systemctl enable redis-server

# Verificar
redis-cli ping  # deve retornar PONG
```

### URI de conexão

```
# Sem senha:
redis://localhost:6379/1

# No Docker Compose, use o nome do serviço:
redis://redis:6379/1

# Com senha (se configurado):
redis://:senha@redis:6379/1
```

### Solução: Redis disconnected em loop (v2.3.x)

Se você ver `ERROR [Redis] redis disconnected` em loop, é um bug conhecido das versões
v2.3.x. Soluções:

1. **Use a versão estável v2.1.1** (recomendado):
   ```
   image: atendai/evolution-api:v2.1.1
   ```

2. **Ou desabilite o Redis temporariamente** (modo single-instance):
   ```env
   CACHE_REDIS_ENABLED=false
   CACHE_LOCAL_ENABLED=true
   ```


---

← [[README|Evolution API WhatsApp]]
