# Tutorial — submódulos e CI/CD do SoR FastAPI

**Para quê:** clonar o monorepo, trabalhar no `almotos-backend` e entender o que o GitHub Actions publica depois que o Kotlin saiu da composição.

O repositório Kotlin (`https://github.com/PedroHRoseno/vehicle-sales-manager-v2-kotlin`) **continua no GitHub** para rollback. Não faz mais parte deste monorepo e o CI/CD do pai **não** o constrói nem o faz deploy.

---

## 1. O que mudou

| Antes | Depois |
|---|---|
| Submódulo `vehicle-sales-manager-v2-kotlin` | Fora do pai; standby só no Railway se você ainda não desligou o serviço |
| SoR no CI/CD = job `ci-kotlin` / `cd-kotlin` | SoR = `ci-backend` / `cd-backend` (`almotos-backend`) |
| Postgres local no Compose do Kotlin | `almotos-backend/docker-compose.yml` |
| Painel CI usava `NEXT_PUBLIC_API_URL=http://localhost:8080` | `http://localhost:8081` |

Pastas no pai hoje: `almotos-backend`, `almotos-ai`, `almotos-front`, `almotos-catalog`, `almotos-ai-bot`.

---

## 2. Clonar o monorepo

```bash
git clone --recurse-submodules https://github.com/PedroHRoseno/full-stack-almotos.git
cd full-stack-almotos
```

Clone já feito sem submódulos:

```bash
git submodule update --init --recursive
```

Se `almotos-backend/` estiver vazio, o ponteiro SHA existe mas o conteúdo não foi baixado — rode o comando acima.

---

## 3. Trabalho do dia a dia no SoR

Commit **dentro** do submodule; no pai, só o ponteiro.

```bash
cd almotos-backend
git checkout master
git pull
# ... altera código, testa ...
python -m uv run pytest
git add -A
git commit -m "mensagem"
git push origin master

cd ..
git add almotos-backend
git commit -m "Atualiza ponteiro do almotos-backend"
git push
```

O push no pai dispara CI (`almotos-backend` no path filter) e, em `main`/`master`, o CD `railway up` na pasta do submodule.

---

## 4. Rodar o SoR local

```bash
cd almotos-backend
docker compose up -d
copy .env.example .env
python -m uv sync
python -m uv run uvicorn almotos_backend.main:app --reload --host 0.0.0.0 --port 8081
```

Painel: `NEXT_PUBLIC_API_URL=http://localhost:8081` no `.env.local` do `almotos-front`.  
`almotos-ai`: `KOTLIN_BASE_URL=http://localhost:8081` (o **nome** da env não mudou).

Este FastAPI **não cria tabelas**. O Postgres local precisa do schema já existente (dump ou volume antigo).

---

## 5. CI/CD (GitHub Actions)

Arquivo: `.github/workflows/ci-cd.yml`.

Ordem de CD em `main`: **FastAPI (SoR) → `almotos-ai` → front / catálogo / bot**.

Secrets/variáveis no repositório **pai** (Settings → Secrets and variables):

| Nome | Uso |
|---|---|
| `RAILWAY_TOKEN` ou `RAILWAY_TOKEN_BACKEND` | Deploy do SoR |
| `RAILWAY_SERVICE_BACKEND` | Nome do serviço FastAPI no Railway |
| `RAILWAY_PROJECT_ID`, `RAILWAY_ENVIRONMENT` | Projeto/ambiente Railway |
| `GH_PAT` | Checkout com submodules privados |

Pode apagar `RAILWAY_SERVICE_KOTLIN` / `RAILWAY_TOKEN_KOTLIN` quando não for mais fazer deploy do Spring.

O job faz `actions/checkout` **com `submodules: recursive`** e `railway up` a partir de `almotos-backend/`. Não depende do Railway clonar o pai com root directory.

No Railway, o serviço FastAPI **SHOULD** apontar para o repo `PedroHRoseno/almotos-backend` (não para o pai). O domínio `api.almotoscaruaru.com.br` permanece nesse serviço.

---

## 6. Como este submodule foi criado (referência)

Se precisar recriar do zero (repo GitHub vazio `almotos-backend`):

```bash
# 1. Publicar o código do SoR (branch default do remoto: master)
cd almotos-backend
git init -b master
git add -A
git commit -m "Initial commit — SoR FastAPI"
git remote add origin https://github.com/PedroHRoseno/almotos-backend.git
git push -u origin master
cd ..

# 2. Trocar pasta normal por submodule (a pasta não pode existir)
mv almotos-backend almotos-backend.bak
git submodule add -b master https://github.com/PedroHRoseno/almotos-backend.git almotos-backend
git add .gitmodules almotos-backend
git commit -m "Adiciona submodule almotos-backend"

# 3. Remover o Kotlin da composição
git submodule deinit -f vehicle-sales-manager-v2-kotlin
git rm -f vehicle-sales-manager-v2-kotlin
# opcional: rm -rf .git/modules/vehicle-sales-manager-v2-kotlin
git commit -m "Remove submodule vehicle-sales-manager-v2-kotlin"
```

Não apague o repositório GitHub do Kotlin. Rollback de produção é DNS/domínio de volta ao serviço Spring no Railway, não re-adicionar o submodule.

---

## 7. Atualizar o ponteiro no pai (“atualizar o módulo”)

Depois que `master` do `almotos-backend` avançar:

```bash
cd full-stack-almotos
git submodule update --remote almotos-backend
git add almotos-backend
git commit -m "Atualiza almotos-backend"
git push
```

`update --remote` segue o branch configurado no `.gitmodules` (`master`). Sem `--remote`, o pai restaura o SHA já commitado.
