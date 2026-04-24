---
tags: [backend]
categoria: "⚙️ Backend"
---

# Evolution API — Guia Completo de Instalação

## Visão Geral

A **Evolution API v2** é uma API REST open source para integração com o WhatsApp via protocolo Baileys.
Ela expõe endpoints HTTP para criar instâncias, enviar e receber mensagens, gerenciar webhooks, e se integrar com ferramentas como n8n, Chatwoot, Typebot e outros.

**Repositório oficial:** https://github.com/EvolutionAPI/evolution-api  
**Documentação oficial:** https://doc.evolution-api.com/v2/en  
**Imagem Docker:** `atendai/evolution-api:v2.1.1`  
**Porta padrão:** `8080`

---

## Escolha o Método de Instalação

| Método | Ideal para | Complexidade |
|---|---|---|
| **Docker Compose (Standalone)** | Servidor único, desenvolvimento, produção simples | ⭐ Fácil |
| **Docker Swarm + Traefik** | Multi-servidor, alta disponibilidade, produção avançada | ⭐⭐⭐ Avançado |
| **NVM / Node.js nativo** | Desenvolvimento local sem Docker | ⭐⭐ Médio |
| **Coolify** | Deploy gerenciado com UI, ideal para iniciantes | ⭐ Fácil |

**Recomendação para maioria dos casos:** Docker Compose Standalone (veja abaixo).

---

## Pré-requisitos Obrigatórios

Antes de instalar a Evolution API, configure:

1. **PostgreSQL** — banco de dados principal (v14+ recomendado)
2. **Redis** — cache de sessões e filas (v7+ recomendado)
3. **Docker Engine** — v24+ com Docker Compose v2

> Para detalhes de configuração de banco e Redis, leia: `references/prerequisites.md`

---

## Método 1: Docker Compose Standalone (Recomendado)

### Estrutura de Arquivos

```
evolution/
├── docker-compose.yml
└── .env
```

### docker-compose.yml

```yaml
version: '3.9'

services:
  evolution-api:
    container_name: evolution_api
    image: atendai/evolution-api:v2.1.1
    restart: always
    ports:
      - "8080:8080"
    env_file:
      - .env
    volumes:
      - evolution_instances:/evolution/instances
    networks:
      - evolution-net
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  postgres:
    container_name: evolution_postgres
    image: postgres:15
    restart: always
    environment:
      POSTGRES_DB: evolution_db
      POSTGRES_USER: evolution_user
      POSTGRES_PASSWORD: TROQUE_AQUI_senha_segura
    volumes:
      - evolution_postgres:/var/lib/postgresql/data
    networks:
      - evolution-net
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U evolution_user -d evolution_db"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    container_name: evolution_redis
    image: redis:7-alpine
    restart: always
    command: redis-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - evolution_redis:/data
    networks:
      - evolution-net
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  evolution_instances:
  evolution_postgres:
  evolution_redis:

networks:
  evolution-net:
    driver: bridge
```

### .env (variáveis mínimas)

```env
# ============================================
# AUTENTICAÇÃO — troque antes de subir!
# ============================================
AUTHENTICATION_API_KEY=gere-uma-chave-uuid-aqui

# ============================================
# SERVIDOR
# ============================================
SERVER_URL=https://seudominio.com.br
# (em dev local use: http://localhost:8080)

# ============================================
# BANCO DE DADOS — PostgreSQL
# ============================================
DATABASE_ENABLED=true
DATABASE_PROVIDER=postgresql
DATABASE_CONNECTION_URI=postgresql://evolution_user:TROQUE_AQUI_senha_segura@postgres:5432/evolution_db
DATABASE_CONNECTION_CLIENT_NAME=evolution_v2
DATABASE_SAVE_DATA_INSTANCE=true
DATABASE_SAVE_DATA_NEW_MESSAGE=true
DATABASE_SAVE_MESSAGE_UPDATE=true
DATABASE_SAVE_DATA_CONTACTS=true
DATABASE_SAVE_DATA_CHATS=true
DATABASE_SAVE_DATA_LABELS=true
DATABASE_SAVE_DATA_HISTORIC=true

# ============================================
# CACHE — Redis
# ============================================
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://redis:6379/1
CACHE_REDIS_PREFIX_KEY=evolution_v2
CACHE_REDIS_SAVE_INSTANCES=false
CACHE_LOCAL_ENABLED=false

# ============================================
# LOGS
# ============================================
LOG_LEVEL=ERROR,WARN,DEBUG,INFO,LOG

# ============================================
# INSTÂNCIAS
# ============================================
DEL_INSTANCE=false
```

### Comandos

```bash
# Subir tudo
docker compose up -d

# Ver logs em tempo real
docker logs -f evolution_api

# Parar
docker compose down

# Atualizar imagem
docker compose pull && docker compose up -d
```

### Verificar se está funcionando

```bash
curl http://localhost:8080
# Deve retornar: {"status":200,"message":"Welcome to the Evolution API!"}
```

---

## Método 2: Docker Swarm + Traefik (Produção Avançada)

Para ambientes multi-servidor com SSL automático e alta disponibilidade.  
→ Leia o guia completo em: `references/swarm-traefik.md`

---

## Método 3: NVM / Node.js Nativo

Para desenvolvimento local sem Docker.  
→ Leia o guia completo em: `references/nvm-install.md`

---

## Método 4: Coolify (Deploy Gerenciado)

O Coolify possui template oficial que sobe Evolution API + PostgreSQL + Redis + Evolution Manager em um clique.  
→ Acesse: https://coolify.io/docs/services/evolution-api

---

## Proxy Reverso com Nginx + SSL

Para expor a API com HTTPS em produção.  
→ Leia o guia completo em: `references/nginx-ssl.md`

---

## Primeiros Passos Após a Instalação

### 1. Criar uma instância WhatsApp

```bash
curl -X POST http://localhost:8080/instance/create \
  -H "apikey: SUA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"instanceName": "minha-instancia", "integration": "WHATSAPP-BAILEYS"}'
```

### 2. Conectar via QR Code

```bash
curl http://localhost:8080/instance/connect/minha-instancia \
  -H "apikey: SUA_API_KEY"
# Retorna QR code em base64 — escaneie pelo WhatsApp
```

### 3. Enviar mensagem de teste

```bash
curl -X POST http://localhost:8080/message/sendText/minha-instancia \
  -H "apikey: SUA_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"number": "5511999999999", "text": "Olá! Funcionou."}'
```

---

## Problemas Comuns e Soluções

| Problema | Causa | Solução |
|---|---|---|
| `redis disconnected` em loop | Versão com bug (v2.3.x) ou URI errada | Use v2.1.1 ou verifique `CACHE_REDIS_URI` |
| `P1001: Can't reach database` | API sobe antes do Postgres | Adicione `depends_on` com `service_healthy` |
| `401 Unauthorized` | API key errada | Confira `AUTHENTICATION_API_KEY` no `.env` |
| QR Code não aparece | Instância não criada | Verifique logs e recrie a instância |
| Porta 8080 ocupada | Conflito de porta | Mude para `"8081:8080"` no compose |

→ Mais troubleshooting em: `references/troubleshooting.md`

---

## Segurança — Boas Práticas

- **Nunca** use a API key padrão `change-me` em produção
- Gere uma chave UUID forte: `openssl rand -hex 32`
- Use HTTPS em produção (Nginx + Let's Encrypt ou Traefik)
- Não exponha a porta 5432 (PostgreSQL) ou 6379 (Redis) publicamente
- Configure firewall para aceitar apenas portas 80 e 443 externamente
- Faça backup regular do volume `evolution_postgres`

---

## Referências

| Arquivo | Conteúdo |
|---|---|
| `references/prerequisites.md` | Configuração detalhada de PostgreSQL e Redis |
| `references/swarm-traefik.md` | Deploy em Docker Swarm com Traefik |
| `references/nvm-install.md` | Instalação via NVM/Node.js |
| `references/nginx-ssl.md` | Proxy reverso Nginx com SSL Let's Encrypt |
| `references/troubleshooting.md` | Erros comuns e soluções detalhadas |
| `references/env-reference.md` | Referência completa de variáveis de ambiente |


---

## Relacionado

[[Baileys WhatsApp SDK]] | [[Node.js]]


---

## Referencias

- [[Referencias/env-reference]]
- [[Referencias/nginx-ssl]]
- [[Referencias/nvm-install]]
- [[Referencias/prerequisites]]
- [[Referencias/swarm-traefik]]
- [[Referencias/troubleshooting]]
