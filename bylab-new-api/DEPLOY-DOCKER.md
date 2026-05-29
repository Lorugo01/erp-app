# Deploy Docker — ByLAB API (demonstração VPS)

## Pré-requisitos na VPS

- Docker e Docker Compose instalados
- Porta **3000** liberada no firewall

## Deploy rápido

```bash
cd bylab-new-api
cp .env.docker.example .env
# Edite .env: POSTGRES_PASSWORD e JWT_SECRET
docker compose up -d --build
```

API disponível em: `http://SEU_IP_VPS:3000`

Health check: `http://SEU_IP_VPS:3000/health`

## Usuários de demonstração (seed)

| Papel     | Email              | Senha    |
|-----------|--------------------|----------|
| DEVELOPER | dev@globaltec.com  | dev123   |
| ADMIN     | admin@globaltec.com| admin123 |
| TEACHER   | prof@globaltec.com | prof123  |
| STUDENT   | aluno@globaltec.com| aluno123 |

## Comandos úteis

```bash
# Ver logs
docker compose logs -f api

# Reexecutar seed (com API parada ou em outro terminal)
docker compose exec api node prisma/seed.js

# Parar
docker compose down

# Parar e apagar volumes (reset total do banco)
docker compose down -v
```

## App Flutter apontando para a VPS

No `erp/.env`:

```env
ENVIRONMENT=production
API_BASE_URL=http://SEU_IP_VPS:3000
TECAAI_BASE_URL=http://SEU_IP_VPS:5001
UPLOADS_BASE_URL=http://SEU_IP_VPS:3000
```

Com domínio e HTTPS (recomendado em produção), use Nginx/Caddy na frente e `https://api.globaltec.com`.

## Variáveis importantes (.env)

| Variável           | Descrição                          |
|--------------------|------------------------------------|
| POSTGRES_PASSWORD  | Senha do PostgreSQL                |
| JWT_SECRET         | Chave JWT (obrigatório alterar)    |
| API_PORT           | Porta exposta no host (padrão 3000)|
| RUN_SEED           | `true` roda seed ao subir container|
| CORS_ORIGIN        | `*` ou URLs permitidas separadas por vírgula |
