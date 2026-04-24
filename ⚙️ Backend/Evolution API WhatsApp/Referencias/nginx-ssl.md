# Proxy Reverso: Nginx + SSL (Let's Encrypt)

## Pré-requisitos
- Domínio apontando para o IP do servidor (ex: `evo.seudominio.com.br`)
- Portas 80 e 443 abertas no firewall

## Instalação

```bash
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx
```

## Configuração do Nginx

Crie o arquivo `/etc/nginx/sites-available/evolution`:

```nginx
server {
    server_name evo.seudominio.com.br;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Timeout generoso para SSE/Websocket
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
    }

    # Aumentar limite de upload (para envio de mídia)
    client_max_body_size 100M;
}
```

Ative e teste:

```bash
sudo ln -s /etc/nginx/sites-available/evolution /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Certificado SSL com Certbot

```bash
sudo certbot --nginx -d evo.seudominio.com.br
# Siga as instruções e escolha redirecionar HTTP para HTTPS
```

## Renovação automática (já configurada pelo certbot)

```bash
# Verificar renovação automática
sudo systemctl status certbot.timer
```

## Após o SSL, atualize o .env

```env
SERVER_URL=https://evo.seudominio.com.br
```

E reinicie:

```bash
docker compose restart evolution-api
```


---

← [[README|Evolution API WhatsApp]]
