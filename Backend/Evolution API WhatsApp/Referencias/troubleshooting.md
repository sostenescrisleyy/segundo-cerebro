# Troubleshooting — Problemas Comuns

## 1. `ERROR [Redis] redis disconnected` em loop infinito

**Versões afetadas:** v2.3.x  
**Causa:** Bug no cliente Redis da Evolution API  

**Soluções:**

```bash
# Opção A: Usar versão estável
# Altere no docker-compose.yml:
image: atendai/evolution-api:v2.1.1

# Opção B: Desabilitar Redis (single-instance apenas)
# No .env:
CACHE_REDIS_ENABLED=false
CACHE_LOCAL_ENABLED=true
```

**Verificação manual do Redis:**
```bash
docker exec -it evolution_redis redis-cli PING
# Deve retornar PONG
```

---

## 2. `P1001: Can't reach database server at 'postgres:5432'`

**Causa:** A Evolution API sobe antes do PostgreSQL estar pronto  

**Solução:** Adicione `depends_on` com healthcheck no compose:

```yaml
evolution-api:
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
```

E certifique-se que o serviço `postgres` tem `healthcheck` configurado (veja SKILL.md principal).

---

## 3. `401 Unauthorized` em todas as requisições

**Causa:** API key incorreta ou não definida  

**Solução:**
```bash
# Verifique a variável no .env:
grep AUTHENTICATION_API_KEY .env

# Teste com a chave correta:
curl -H "apikey: SUA_KEY_AQUI" http://localhost:8080/instance/fetchInstances
```

---

## 4. Container reinicia em loop (CrashLoop)

**Diagnóstico:**
```bash
docker logs evolution_api --tail 50
```

**Causas comuns:**
- URI do banco incorreta → verifique `DATABASE_CONNECTION_URI`
- Senha com caracteres especiais sem escape na URI
- Porta do banco bloqueada → teste `nc -zv postgres 5432` de dentro do container

---

## 5. QR Code não aparece / instância não conecta

```bash
# 1. Verifique se a instância existe
curl -H "apikey: KEY" http://localhost:8080/instance/fetchInstances

# 2. Delete e recrie
curl -X DELETE -H "apikey: KEY" http://localhost:8080/instance/delete/NOME_INSTANCIA
curl -X POST -H "apikey: KEY" -H "Content-Type: application/json" \
  http://localhost:8080/instance/create \
  -d '{"instanceName":"NOME_INSTANCIA","integration":"WHATSAPP-BAILEYS"}'

# 3. Solicite o QR
curl -H "apikey: KEY" http://localhost:8080/instance/connect/NOME_INSTANCIA
```

---

## 6. Porta 8080 já em uso

```bash
# Verifique qual processo usa a porta
sudo lsof -i :8080

# Solução: mude no docker-compose.yml
ports:
  - "8081:8080"   # expõe na 8081 externamente
```

---

## 7. Volumes não persistem após restart

Verifique se está usando volumes nomeados (não bind mounts ad-hoc):

```yaml
# ✅ Correto — volume nomeado
volumes:
  - evolution_instances:/evolution/instances

# ❌ Errado — sem declarar no bloco volumes:
volumes:
  - ./instances:/evolution/instances  # pode ter problemas de permissão
```

---

## Comandos Úteis de Diagnóstico

```bash
# Ver todos os containers e status
docker ps -a

# Inspecionar rede
docker network inspect evolution-net

# Entrar no container da API
docker exec -it evolution_api sh

# Checar variáveis de ambiente carregadas
docker exec evolution_api env | grep DATABASE

# Ver uso de recursos
docker stats evolution_api evolution_postgres evolution_redis
```


---

← [[README|Evolution API WhatsApp]]
