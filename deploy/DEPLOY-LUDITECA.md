# Deploy ByLAB — VPS (IP + porta)

O **app Flutter (mobile)** roda no seu PC com `.env` apontando para **IP:porta** da VPS.
Na VPS só sobem **PostgreSQL + API** via Docker — **sem Nginx, DNS ou HTTPS**.

## 1. `.env` na VPS

```bash
cd /opt/erp-app
cp deploy/env.luditeca.example .env
nano .env   # senhas + confirme VPS_IP
```

Remova do `.env` da VPS variáveis que só servem ao mobile (`API_BASE_URL`, etc.) se quiser — o Docker usa só a seção API.

## 2. Docker

```bash
docker compose up -d --build
docker compose ps
curl -s http://127.0.0.1:3150/health
curl -s http://187.127.0.245:3150/health
```

## 3. Firewall (se usar ufw)

```bash
sudo ufw allow 3150/tcp
sudo ufw allow OpenSSH
sudo ufw enable
```

## 4. App mobile (seu PC)

Edite **`erp/.env`** (template: `erp/.env.example`):

```env
ENVIRONMENT=production
API_BASE_URL=http://187.127.0.245:3150
UPLOADS_BASE_URL=http://187.127.0.245:3150
TECAAI_BASE_URL=http://187.127.0.245:5010
ENABLE_HTTPS=false
```

```powershell
cd erp
flutter run
```

## URLs

| Serviço | URL |
|---------|-----|
| **API** | http://187.127.0.245:3150 |
| **Health** | http://187.127.0.245:3150/health |
| **TecaAI** | http://187.127.0.245:5010 |

## Login demo

| Email | Senha |
|-------|-------|
| admin@globaltec.com | admin123 |
