# ByLAB ERP

Monorepo: **app Flutter (mobile)** + **API REST**.

```
erp-app/
├── .env              ← API + Docker (não commitar)
├── .env.example
├── erp/.env          ← Flutter mobile (não commitar)
├── erp/.env.example
├── docker-compose.yml
├── erp/              → App Flutter
└── bylab-new-api/    → API Node.js + PostgreSQL
```

---

## Configuração inicial

```powershell
cd erp-app
.\scripts\init-env.ps1
# Edite .env (API) e erp/.env (Flutter)
```

---

## Deploy VPS (Docker: db + API)

```bash
cp deploy/env.luditeca.example .env
nano .env
docker compose up -d --build
```

Guia completo: [deploy/DEPLOY-LUDITECA.md](deploy/DEPLOY-LUDITECA.md)

| Serviço | URL (exemplo) |
|---------|----------------|
| **API** | http://SEU_IP:3150 |
| **Health** | http://SEU_IP:3150/health |

---

## App mobile (build local)

Configure **`erp/.env`**:

```powershell
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
