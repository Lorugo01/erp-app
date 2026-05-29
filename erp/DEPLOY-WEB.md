# Deploy Web — ByLAB ERP (Flutter)

> Configuração: **apenas** `erp-app/.env` na raiz. Rode `.\scripts\sync-env.ps1` após editar.

## Desenvolvimento local

```powershell
cd erp-app
.\scripts\init-env.ps1
.\scripts\sync-env.ps1
cd erp
flutter run -d chrome
```

Ou: `erp\scripts\run_web.ps1`

## Deploy na VPS

Use o `docker-compose.yml` na **raiz** — lê `erp-app/.env` automaticamente.

```bash
cp .env.example .env
docker compose up -d --build
```

App Web: http://SEU_IP:8080
