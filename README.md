# ByLAB ERP

Monorepo: **app Flutter (mobile)** + **API REST**. Configuração unificada em **`erp-app/.env`**.

```
erp-app/
├── .env              ← configuração (não commitar)
├── .env.example      ← template
├── docker-compose.yml   ← VPS: só PostgreSQL + API
├── erp/              → App Flutter (mobile/web local)
└── bylab-new-api/    → API Node.js + PostgreSQL
```

---

## Configuração inicial

```powershell
cd erp-app
.\scripts\init-env.ps1
# Edite .env na raiz
.\scripts\sync-env.ps1   # copia → erp/.env (asset do Flutter)
```

---

## Deploy VPS (Docker: db + API)

```bash
cp deploy/env.luditeca.example .env
nano .env
docker compose up -d --build
```

Guia completo: [deploy/DEPLOY-LUDITECA.md](deploy/DEPLOY-LUDITECA.md)

| Serviço | URL (exemplo Luditeca) |
|---------|-------------------------|
| **API** | https://bylab-api.luditeca.com |
| **Health** | https://bylab-api.luditeca.com/health |

---

## App mobile (build local)

Configure URLs no `.env` da raiz e sincronize:

```powershell
.\scripts\sync-env.ps1
cd erp
flutter run
# ou: flutter build apk
```

---

## Desenvolvimento local

**API**:

```bash
cd bylab-new-api
npm install
npm run migrate:dev
npm run seed
npm run dev
```

**App Flutter**:

```powershell
.\scripts\sync-env.ps1
cd erp
flutter run
```

**Trocar ambiente**:

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
