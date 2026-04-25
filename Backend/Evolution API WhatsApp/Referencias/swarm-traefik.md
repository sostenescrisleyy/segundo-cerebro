# Docker Swarm + Traefik (Produção Avançada)

Use este método para alta disponibilidade, múltiplos workers e SSL automático via Traefik.

## Arquitetura

```
Internet → Traefik (Manager) → Evolution API (Workers)
                ↕
         PostgreSQL + Redis (externos ou no Swarm)
```

## Passo 1: Inicializar o Swarm no Manager

```bash
docker swarm init --advertise-addr IP_DO_SERVIDOR
# Guarde o token de join gerado!
```

## Passo 2: Criar a rede overlay

```bash
docker network create --driver=overlay network_public
```

## Passo 3: Deploy do Traefik

Crie `traefik.yaml`:

```yaml
version: "3.7"
services:
  traefik:
    image: traefik:2.11.2
    command:
      - "--api.dashboard=true"
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.endpoint=unix:///var/run/docker.sock"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=network_public"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencryptresolver.acme.email=seu@email.com"
      - "--certificatesresolvers.letsencryptresolver.acme.storage=/etc/traefik/letsencrypt/acme.json"
    deploy:
      placement:
        constraints:
          - node.role == manager
      restart_policy:
        condition: on-failure
    ports:
      - target: 80
        published: 80
        mode: host
      - target: 443
        published: 443
        mode: host
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - traefik_certificates:/etc/traefik/letsencrypt
    networks:
      - network_public

volumes:
  traefik_certificates:
    external: true

networks:
  network_public:
    external: true
    name: network_public
```

```bash
# Criar volume para certificados
docker volume create traefik_certificates

# Deploy do Traefik
docker stack deploy -c traefik.yaml traefik
```

## Passo 4: Deploy da Evolution API

Crie `evolution.yaml`:

```yaml
version: "3.7"
services:
  evolution_v2:
    image: atendai/evolution-api:v2.1.1
    volumes:
      - evolution_instances:/evolution/instances
    networks:
      - network_public
    environment:
      - SERVER_URL=https://evo.seudominio.com.br
      - AUTHENTICATION_API_KEY=SUA_KEY_AQUI
      - DATABASE_ENABLED=true
      - DATABASE_PROVIDER=postgresql
      - DATABASE_CONNECTION_URI=postgresql://user:pass@postgres:5432/evolution_db
      - CACHE_REDIS_ENABLED=true
      - CACHE_REDIS_URI=redis://redis:6379/1
      - CACHE_REDIS_PREFIX_KEY=evolution_v2
      - DEL_INSTANCE=false
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.evolution_v2.rule=Host(`evo.seudominio.com.br`)"
        - "traefik.http.routers.evolution_v2.entrypoints=websecure"
        - "traefik.http.routers.evolution_v2.tls.certresolver=letsencryptresolver"
        - "traefik.http.services.evolution_v2.loadbalancer.server.port=8080"
        - "traefik.http.services.evolution_v2.loadbalancer.passHostHeader=true"

volumes:
  evolution_instances:
    external: true

networks:
  network_public:
    external: true
    name: network_public
```

```bash
# Criar volumes externos
docker volume create evolution_instances

# Deploy
docker stack deploy -c evolution.yaml evolution
```

## Verificar o stack

```bash
docker stack ls
docker service ls
docker service logs evolution_evolution_v2
```


---

← [[README|Evolution API WhatsApp]]
