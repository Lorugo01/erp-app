#!/bin/sh
set -e

echo "Aguardando banco de dados..."
TRIES=0
MAX_TRIES=30

until node <<'NODE'
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
prisma.$queryRaw`SELECT 1`
  .then(() => prisma.$disconnect())
  .then(() => process.exit(0))
  .catch(async () => {
    await prisma.$disconnect();
    process.exit(1);
  });
NODE
do
  TRIES=$((TRIES + 1))
  if [ "$TRIES" -ge "$MAX_TRIES" ]; then
    echo "Banco indisponível após ${MAX_TRIES} tentativas."
    exit 1
  fi
  echo "Tentativa ${TRIES}/${MAX_TRIES}..."
  sleep 2
done

echo "Aplicando migrações..."
npx prisma migrate deploy

if [ "$RUN_SEED" = "true" ]; then
  echo "Executando seed..."
  node prisma/seed.js
fi

echo "Iniciando API..."
exec "$@"
