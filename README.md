# ByLAB ERP

Monorepo: **app Flutter Web** + **API REST**. Configuração unificada em **`erp-app/.env`**.

```
erp-app/
├── .env              ← único arquivo de configuração (não commitar)
├── .env.example      ← template
├── docker-compose.yml
├── erp/              → App Flutter
└── bylab-new-api/    → API Node.js + PostgreSQL
```

---

## Configuração inicial

```powershell
cd erp-app
.\scripts\init-env.ps1
# Edite .env na raiz
```

O script copia `.env` → `erp/.env` (Flutter precisa do asset local).

Após alterar `.env` na raiz:

```powershell
.\scripts\sync-env.ps1
```

---

## Deploy VPS com domínio (Luditeca)

**https://erp.luditeca.com** + **https://api.luditeca.com**

Guia completo: [deploy/DEPLOY-LUDITECA.md](deploy/DEPLOY-LUDITECA.md)

```bash
cp deploy/env.luditeca.example .env
nano .env
docker compose build --no-cache web
docker compose up -d
# Configurar Nginx + certbot (ver guia)
```

---

## Deploy VPS (IP direto)

```bash
cp .env.example .env
# Edite API_BASE_URL com IP/domínio público
docker compose up -d --build
```

| Serviço | URL |
|---------|-----|
| **ERP Web** | http://SEU_IP:8080 |
| **API** | http://SEU_IP:3040 |

---

## Desenvolvimento local

**API** (lê `erp-app/.env`):

```bash
cd bylab-new-api
npm install
npm run migrate:dev
npm run seed
npm run dev
```

**App Web**:

```powershell
.\scripts\sync-env.ps1
cd erp
flutter run -d chrome
```

Ou: `erp\scripts\run_web.ps1`

**Trocar ambiente** (local / development / production):

```powershell
.\scripts\change_environment.ps1 local
```

---

## Usuários demo

| Email | Senha |
|-------|-------|
| admin@globaltec.com | admin123 |
| prof@globaltec.com | prof123 |
| aluno@globaltec.com | aluno123 |
