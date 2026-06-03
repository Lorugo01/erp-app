# Deploy erp.luditeca.com (Hostinger VPS)

## 1. DNS na Hostinger

No painel **DNS** do domínio `luditeca.com`, crie registros **A**:

| Tipo | Nome | Valor        | TTL |
|------|------|--------------|-----|
| A    | erp  | IP da VPS    | 300 |
| A    | api  | IP da VPS    | 300 |

Exemplo: `187.127.0.245`

Aguarde propagação (5–30 min). Teste:

```bash
ping erp.luditeca.com
ping api.luditeca.com
```

## 2. `.env` na VPS

```bash
cd /opt/erp-app
cp deploy/env.luditeca.example .env
nano .env   # senhas + IP TecaAI se houver
```

## 3. Subir Docker

```bash
docker compose build --no-cache web
docker compose up -d
docker compose ps
```

## 4. Nginx no host (Ubuntu)

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx

sudo cp deploy/nginx/erp.luditeca.com.conf /etc/nginx/sites-available/
sudo cp deploy/nginx/api.luditeca.com.conf /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/erp.luditeca.com.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/api.luditeca.com.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

sudo nginx -t
sudo systemctl reload nginx
```

## 5. HTTPS (Let's Encrypt)

```bash
sudo certbot --nginx -d erp.luditeca.com -d api.luditeca.com
```

Renovação automática já vem configurada.

## 6. Firewall

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow OpenSSH
sudo ufw enable
```

Portas **9050** (web) e **3040** (API) ficam só em `127.0.0.1` (Nginx faz o proxy).

## URLs finais

| Serviço | URL |
|---------|-----|
| **ERP** | https://erp.luditeca.com |
| **API** | https://api.luditeca.com |
| **Health** | https://api.luditeca.com/health |

## Login demo

| Email | Senha |
|-------|-------|
| admin@globaltec.com | admin123 |

## Alterou API_BASE_URL?

```bash
# Incremente CONFIG_HASH no .env, depois:
docker compose build --no-cache web
docker compose up -d web
```
