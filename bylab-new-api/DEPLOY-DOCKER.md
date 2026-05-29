# Deploy Docker — ByLAB API

> **Configuração unificada:** `erp-app/.env` na raiz do repositório.

## Deploy completo (API + ERP Web + PostgreSQL)

Na raiz `erp-app/`:

```bash
cp .env.example .env
docker compose up -d --build
```

## Desenvolvimento local (só API)

A API lê `erp-app/.env` automaticamente:

```bash
cd bylab-new-api
npm install
npm run migrate:dev
npm run seed
npm run dev
```

## Usuários demo

| Email | Senha |
|-------|-------|
| admin@globaltec.com | admin123 |
| prof@globaltec.com | prof123 |
| aluno@globaltec.com | aluno123 |
