# Referência de Variáveis de Ambiente (.env)

Baseado no `.env.example` oficial: https://github.com/EvolutionAPI/evolution-api/blob/main/.env.example

## Servidor

| Variável | Padrão | Descrição |
|---|---|---|
| `SERVER_URL` | `http://localhost:8080` | URL pública da API (use HTTPS em produção) |
| `SERVER_PORT` | `8080` | Porta interna da aplicação |
| `LOG_LEVEL` | `ERROR,WARN,DEBUG,INFO,LOG` | Níveis de log ativos |

## Autenticação

| Variável | Padrão | Descrição |
|---|---|---|
| `AUTHENTICATION_API_KEY` | *(obrigatório)* | Chave de acesso global da API |
| `AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES` | `true` | Expor API key no fetch de instâncias |

## Banco de Dados

| Variável | Padrão | Descrição |
|---|---|---|
| `DATABASE_ENABLED` | `true` | Habilitar banco de dados |
| `DATABASE_PROVIDER` | `postgresql` | Provider: `postgresql` ou `mysql` |
| `DATABASE_CONNECTION_URI` | *(obrigatório)* | URI completa de conexão |
| `DATABASE_CONNECTION_CLIENT_NAME` | `evolution_v2` | Nome do cliente Prisma |
| `DATABASE_SAVE_DATA_INSTANCE` | `true` | Salvar dados das instâncias |
| `DATABASE_SAVE_DATA_NEW_MESSAGE` | `true` | Salvar novas mensagens |
| `DATABASE_SAVE_MESSAGE_UPDATE` | `true` | Salvar atualizações de status |
| `DATABASE_SAVE_DATA_CONTACTS` | `true` | Salvar contatos |
| `DATABASE_SAVE_DATA_CHATS` | `true` | Salvar conversas |
| `DATABASE_SAVE_DATA_LABELS` | `true` | Salvar labels |
| `DATABASE_SAVE_DATA_HISTORIC` | `true` | Salvar histórico |

## Cache (Redis)

| Variável | Padrão | Descrição |
|---|---|---|
| `CACHE_REDIS_ENABLED` | `false` | Habilitar Redis |
| `CACHE_REDIS_URI` | `redis://localhost:6379/6` | URI do Redis |
| `CACHE_REDIS_PREFIX_KEY` | `evolution` | Prefixo das chaves no Redis |
| `CACHE_REDIS_SAVE_INSTANCES` | `false` | Salvar instâncias no Redis |
| `CACHE_REDIS_TTL` | `604800` | TTL em segundos (7 dias) |
| `CACHE_LOCAL_ENABLED` | `false` | Cache local em memória (sem Redis) |

## Instâncias

| Variável | Padrão | Descrição |
|---|---|---|
| `DEL_INSTANCE` | `false` | Deletar instância desconectada automaticamente |
| `DEL_TEMP_INSTANCES` | `true` | Deletar instâncias temporárias |

## RabbitMQ (opcional)

| Variável | Padrão | Descrição |
|---|---|---|
| `RABBITMQ_ENABLED` | `false` | Habilitar RabbitMQ para filas |
| `RABBITMQ_URI` | — | URI de conexão amqp:// |
| `RABBITMQ_EXCHANGE_NAME` | `evolution_exchange` | Nome do exchange |

## S3 / MinIO (armazenamento de mídia, opcional)

| Variável | Padrão | Descrição |
|---|---|---|
| `S3_ENABLED` | `false` | Habilitar armazenamento S3 |
| `S3_ACCESS_KEY` | — | Access key S3/MinIO |
| `S3_SECRET_KEY` | — | Secret key S3/MinIO |
| `S3_BUCKET` | `evolution` | Nome do bucket |
| `S3_PORT` | `443` | Porta do endpoint |
| `S3_ENDPOINT` | — | Endpoint S3 (ex: s3.amazonaws.com) |
| `S3_USE_SSL` | `true` | Usar SSL |

## Webhook Global

| Variável | Padrão | Descrição |
|---|---|---|
| `WEBHOOK_GLOBAL_URL` | — | URL para receber todos os eventos |
| `WEBHOOK_GLOBAL_ENABLED` | `false` | Habilitar webhook global |
| `WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS` | `false` | Um webhook por tipo de evento |

## .env Mínimo para Produção

```env
AUTHENTICATION_API_KEY=uuid-gerado-com-openssl-rand-hex-32
SERVER_URL=https://evo.seudominio.com.br
DATABASE_ENABLED=true
DATABASE_PROVIDER=postgresql
DATABASE_CONNECTION_URI=postgresql://evolution_user:SENHA@postgres:5432/evolution_db
DATABASE_CONNECTION_CLIENT_NAME=evolution_v2
DATABASE_SAVE_DATA_INSTANCE=true
DATABASE_SAVE_DATA_NEW_MESSAGE=true
DATABASE_SAVE_MESSAGE_UPDATE=true
DATABASE_SAVE_DATA_CONTACTS=true
DATABASE_SAVE_DATA_CHATS=true
DATABASE_SAVE_DATA_LABELS=true
DATABASE_SAVE_DATA_HISTORIC=true
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://redis:6379/1
CACHE_REDIS_PREFIX_KEY=evolution_v2
CACHE_REDIS_SAVE_INSTANCES=false
CACHE_LOCAL_ENABLED=false
DEL_INSTANCE=false
LOG_LEVEL=ERROR,WARN,INFO,LOG
```


---

← [[README|Evolution API WhatsApp]]
