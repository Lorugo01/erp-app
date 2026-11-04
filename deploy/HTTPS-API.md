# HTTPS para a API do ERP

Hoje os apps falam com a API em `http://IP:3150`, então senhas e tokens
trafegam sem criptografia. Este guia coloca a API atrás do Nginx com
certificado gratuito (Let's Encrypt).

Troque `api.seu-dominio.com` pelo domínio escolhido em todos os passos.

## 1. DNS

Crie um registro **A** apontando `api.seu-dominio.com` para o IP da VPS.
Confira antes de seguir (deve mostrar o IP da VPS):

```bash
dig +short api.seu-dominio.com
```

## 2. Nginx

Na VPS, crie `/etc/nginx/sites-available/erp-api.conf`:

```nginx
server {
    listen 80;
    server_name api.seu-dominio.com;
    client_max_body_size 20M;

    location / {
        proxy_pass http://127.0.0.1:3150;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
ln -s /etc/nginx/sites-available/erp-api.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

## 3. Certificado

```bash
apt install -y certbot python3-certbot-nginx
certbot --nginx -d api.seu-dominio.com
```

O certbot configura o HTTPS e a renovação automática. Teste:

```bash
curl -s https://api.seu-dominio.com/health
```

## 4. Apps

1. No `erp/.env`, troque `API_BASE_URL` e `UPLOADS_BASE_URL` para
   `https://api.seu-dominio.com` e `ENABLE_HTTPS=true`.
2. No Teca, troque `API_BASE_URL` do `.env` para o mesmo endereço.
3. Gere e instale os APKs novos.

## 5. Fechar a porta HTTP (só depois que todos os apps usarem HTTPS)

No `.env` da raiz da VPS:

```
API_BIND=127.0.0.1
```

```bash
docker compose up -d
```

Assim a porta 3150 só aceita conexões do próprio servidor (do Nginx), e o
acesso por `http://IP:3150` deixa de funcionar. Se usar `ufw`, remova a
regra da porta:

```bash
ufw delete allow 3150/tcp
```

Depois disso, `android:usesCleartextTraffic="true"` pode sair do
`AndroidManifest.xml` do ERP.
