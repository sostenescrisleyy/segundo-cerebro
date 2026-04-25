# Instalação via NVM / Node.js Nativo

Use este método apenas para desenvolvimento local ou quando Docker não estiver disponível.

## Pré-requisitos
- Ubuntu 20.04+ / Debian / macOS
- PostgreSQL e Redis já instalados e rodando nativamente

## Passo 1: Instalar NVM

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc  # ou ~/.zshrc no Mac
```

## Passo 2: Instalar Node.js

```bash
nvm install 20
nvm use 20
node --version  # deve mostrar v20.x.x
```

## Passo 3: Clonar o repositório

```bash
git clone https://github.com/EvolutionAPI/evolution-api.git
cd evolution-api
git checkout v2.1.1  # use a versão estável
```

## Passo 4: Instalar dependências

```bash
npm install
```

## Passo 5: Configurar o .env

```bash
cp .env.example .env
nano .env
# Configure as variáveis conforme references/env-reference.md
# Ajuste as URIs para apontar para localhost:
# DATABASE_CONNECTION_URI=postgresql://evolution_user:senha@localhost:5432/evolution_db
# CACHE_REDIS_URI=redis://localhost:6379/1
```

## Passo 6: Rodar as migrations

```bash
npm run db:generate
npm run db:deploy
```

## Passo 7: Iniciar em desenvolvimento

```bash
npm run start:dev
```

## Passo 8: Build para produção

```bash
npm run build
npm run start:prod
```

## Manter rodando com PM2 (produção)

```bash
npm install -g pm2

# Iniciar
pm2 start npm --name "evolution-api" -- run start:prod

# Auto-start no boot
pm2 startup
pm2 save

# Monitorar
pm2 logs evolution-api
pm2 status
```


---

← [[README|Evolution API WhatsApp]]
