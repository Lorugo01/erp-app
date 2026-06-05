# Deploy Docker — ByLAB API

> **Configuração unificada:** `erp-app/.env` na raiz do repositório.

## Deploy VPS (PostgreSQL + API)

Na raiz `erp-app/`:

```bash
cp .env.example .env
docker compose up -d --build
```

O app Flutter **não** entra no Docker — build mobile local com `erp/.env`.

## Desenvolvimento local (só API)

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
