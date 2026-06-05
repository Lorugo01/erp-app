# Deploy ByLAB — VPS Luditeca (API + PostgreSQL)

O **app Flutter** (mobile) **não** roda na VPS. Só **db** + **api** via Docker.
Configure as URLs no `.env` local e faça build do app no seu PC.

## 1. DNS na Hostinger

| Tipo | Nome       | Valor     |
|------|------------|-----------|
| A    | bylab-api  | IP da VPS |
| A    | ia         | IP da VPS |

> `api.luditeca.com` e `erp.luditeca.com` pertencem ao **luditeca-vps** — não use para ByLAB.

## 2. `.env` na VPS

```bash
cd /opt/erp-app
cp deploy/env.luditeca.example .env
nano .env   # senhas
```

## 3. Docker (só API + banco)

```bash
docker compose up -d --build
docker compose ps
curl -s http://127.0.0.1:3150/health
```

## 4. Nginx + HTTPS

```bash
sudo cp deploy/nginx/bylab-api.luditeca.com.conf /etc/nginx/sites-available/
sudo cp deploy/nginx/ia.luditeca.com.conf /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/bylab-api.luditeca.com.conf /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/ia.luditeca.com.conf /etc/nginx/sites-enabled/

sudo nginx -t
sudo systemctl reload nginx

sudo certbot --nginx -d bylab-api.luditeca.com -d ia.luditeca.com
```

## 5. App mobile (seu PC)

No `erp-app/.env` (local):

```env
ENVIRONMENT=production
API_BASE_URL=https://bylab-api.luditeca.com
UPLOADS_BASE_URL=https://bylab-api.luditeca.com
TECAAI_BASE_URL=https://ia.luditeca.com
TECAAI_PATH_PREFIX=/bylab
ENABLE_HTTPS=true
```

```powershell
.\scripts\sync-env.ps1
cd erp
flutter build apk
# ou flutter run
```

## URLs

| Serviço | URL |
|---------|-----|
| **API ByLAB** | https://bylab-api.luditeca.com |
| **Health** | https://bylab-api.luditeca.com/health |
| **TecaAI** | https://ia.luditeca.com/bylab |

## Login demo

| Email | Senha |
|-------|-------|
| admin@globaltec.com | admin123 |
