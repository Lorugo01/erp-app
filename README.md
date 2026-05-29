# ByLAB ERP

Monorepo com o **app Flutter** e a **API REST** do sistema de gestão escolar.

```
erp-app/
├── erp/              → App Flutter (Android, iOS, Web, Windows...)
└── bylab-new-api/    → API Node.js + PostgreSQL (Docker Compose)
```

Pastas **Servidor/** e **localizações/** ficam fora do Git (uso local apenas).

---

## Deploy rápido (VPS)

### 1. API

```bash
cd bylab-new-api
cp .env.docker.example .env
# Edite POSTGRES_PASSWORD e JWT_SECRET
docker compose up -d --build
```

Documentação: [bylab-new-api/DEPLOY-DOCKER.md](bylab-new-api/DEPLOY-DOCKER.md)

### 2. App Flutter

```bash
cd erp
cp .env.example .env
# Aponte API_BASE_URL para http://SEU_IP_VPS:3000
flutter pub get
flutter run
```

---

## Usuários demo (seed)

| Papel | Email | Senha |
|-------|-------|-------|
| DEVELOPER | dev@globaltec.com | dev123 |
| ADMIN | admin@globaltec.com | admin123 |
| TEACHER | prof@globaltec.com | prof123 |
| STUDENT | aluno@globaltec.com | aluno123 |

---

## Desenvolvimento local

**API**

```bash
cd bylab-new-api
cp .env.docker.example .env   # ou crie .env com DATABASE_URL local
npm install
npx prisma migrate dev
npm run seed
npm run dev
```

**Flutter**

```bash
cd erp
cp .env.example .env
flutter pub get
flutter run
```
