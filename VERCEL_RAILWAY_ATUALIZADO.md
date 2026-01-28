# O que alterar na Vercel e no Railway (após as mudanças do projeto)

Este documento resume **exatamente** o que configurar na Vercel e no Railway depois das alterações (YAML, perfis, `NEXT_PUBLIC_API_URL` único, etc.).

---

## 1. Vercel (frontend)

### O que mudou no projeto

- O proxy usa **somente** `NEXT_PUBLIC_API_URL` (não há mais fallback para `API_URL`).
- Se o repositório conectado for o **pai** (monorepo/submodules), o build do front deve usar **Root Directory** = `almotos-front`.

### O que configurar na Vercel

| Onde | O quê | Valor |
|------|--------|--------|
| **Settings → Environment Variables** | `NEXT_PUBLIC_API_URL` | URL pública do backend no Railway, **sem** barra no final. Ex.: `https://vehicle-sales-manager-v2-kotlin-production.up.railway.app` |
| **Settings → General → Root Directory** | (se for monorepo) | `almotos-front` |
| **Build** | Framework / comando | Next.js e `npm run build` (padrão) |

### Checklist Vercel

1. [ ] `NEXT_PUBLIC_API_URL` definida com a URL do backend no Railway.
2. [ ] Se o repo é o monorepo, **Root Directory** = `almotos-front`.
3. [ ] Depois de mudar variáveis, fazer **Redeploy** (Deployments → ⋮ → Redeploy).

Nada mais é obrigatório na Vercel para essas mudanças.

---

## 2. Railway (backend)

### O que mudou no projeto

- Configuração passou de `application.properties` para **YAML** e **perfis** (`local` / `prod`).
- Em produção o backend usa o perfil **prod**, que lê:
  - `DB_URL` (JDBC)
  - `DB_USER`
  - `DB_PASSWORD`
  - `CORS_ALLOWED_ORIGINS`
- As antigas `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD` **não** são mais usadas no perfil prod.

### O que configurar no Railway

No **serviço do backend** (não no PostgreSQL), em **Variables**:

| Variável | Obrigatória? | Descrição |
|----------|----------------|-----------|
| `SPRING_PROFILES_ACTIVE` | **Sim** (em prod) | `prod` |
| `DB_URL` | **Sim** | URL JDBC do PostgreSQL. Ex.: `jdbc:postgresql://host:5432/railway` |
| `DB_USER` | **Sim** | Usuário do banco (ex.: `postgres`) |
| `DB_PASSWORD` | **Sim** | Senha do banco |
| `CORS_ALLOWED_ORIGINS` | Recomendado | URL do front na Vercel. Ex.: `https://almotos-front.vercel.app` ou `https://seu-projeto.vercel.app`. Várias origens: separar por vírgula (ex.: `https://app.vercel.app,http://localhost:3000`) |
| `PORT` | Não | Railway define automaticamente |
| `JWT_SECRET` | Não | Padrão no `application.yml`; em produção é melhor definir um valor forte |
| `JWT_EXPIRATION` | Não | Padrão 86400000 (24h) |

### De onde pegar DB_URL, DB_USER, DB_PASSWORD (PostgreSQL no Railway)

No **serviço PostgreSQL** do Railway, abra **Variables** ou **Connect** e use:

- **DB_URL**: montar em formato JDBC  
  `jdbc:postgresql://PGHOST:PGPORT/PGDATABASE`  
  Ex.: se `PGHOST=monolith.proxy.rlwy.net`, `PGPORT=12345`, `PGDATABASE=railway` →  
  `DB_URL=jdbc:postgresql://monolith.proxy.rlwy.net:12345/railway`
- **DB_USER**: mesmo valor de `PGUSER` (em geral `postgres`).
- **DB_PASSWORD**: mesmo valor de `PGPASSWORD`.

O Railway às vezes expõe `DATABASE_URL` no formato `postgresql://user:password@host:port/database`. Aí:

- **DB_USER** = usuário dessa URL  
- **DB_PASSWORD** = senha dessa URL  
- **DB_URL** = `jdbc:postgresql://host:port/database` (sem user:password na URL; user/senha vão em DB_USER/DB_PASSWORD).

### Exemplo de Variables no Railway (backend)

```
SPRING_PROFILES_ACTIVE=prod
DB_URL=jdbc:postgresql://monolith.proxy.rlwy.net:12345/railway
DB_USER=postgres
DB_PASSWORD=senha_gerada_pelo_railway
CORS_ALLOWED_ORIGINS=https://almotos-front.vercel.app
```

Substitua host, porta, usuário, senha e domínio do front pelos seus.

### Checklist Railway

1. [ ] `SPRING_PROFILES_ACTIVE=prod`.
2. [ ] `DB_URL`, `DB_USER`, `DB_PASSWORD` preenchidos a partir do PostgreSQL (Railway ou externo).
3. [ ] `CORS_ALLOWED_ORIGINS` com a URL (ou URLs) do front na Vercel.
4. [ ] Serviço reiniciado depois de alterar variáveis (deploy novo ou “Redeploy”).

---

## 3. Resumo rápido

**Vercel**

- Uma variável importa: `NEXT_PUBLIC_API_URL` = URL pública do backend no Railway.
- Monorepo → Root Directory = `almotos-front`.
- Depois de mudar variável → Redeploy.

**Railway**

- Perfil prod: `SPRING_PROFILES_ACTIVE=prod`.
- Banco: `DB_URL`, `DB_USER`, `DB_PASSWORD` (não use mais `SPRING_DATASOURCE_*` no prod).
- Front permitido: `CORS_ALLOWED_ORIGINS` = URL do app na Vercel.

---

## 4. Se você já tinha tudo configurado antes

- **Vercel**: continua igual; só garantir que usa **apenas** `NEXT_PUBLIC_API_URL` e, em monorepo, Root Directory = `almotos-front`.
- **Railway**: trocar variáveis de datasource para o perfil prod:
  - `SPRING_DATASOURCE_URL` → **`DB_URL`** (mesmo valor em formato JDBC)
  - `SPRING_DATASOURCE_USERNAME` → **`DB_USER`**
  - `SPRING_DATASOURCE_PASSWORD` → **`DB_PASSWORD`**
  - Adicionar **`SPRING_PROFILES_ACTIVE=prod`**
  - Manter **`CORS_ALLOWED_ORIGINS`** com a URL do front.

Depois disso, ajuste fino (JWT, etc.) pode seguir nos arquivos de deploy de cada projeto (`almotos-front/VERCEL_DEPLOY.md` e `vehicle-sales-manager-v2-kotlin/DEPLOY.md`).
