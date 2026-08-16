# AL Motos

Monorepo da concessionária **AL Motos** (Caruaru/PE): painel interno, catálogo público, orquestrador de IA (MCP) e bot de WhatsApp.

Cada pasta de produto é um **Git submodule** com repositório próprio. Este repositório pai só guarda a composição e a governança.

## Arquitetura

```
Cliente (site / WhatsApp)              Operador (painel)
        │                                      │
        ▼                                      ▼
almotos-catalog  ou  almotos-ai-bot      almotos-front
        │                               (proxy + JWT)
        ▼                                      │
   almotos-ai                                  │
   MCP + POST /v1/chat                         │
        │                                      │
        └──────────────┬───────────────────────┘
                       ▼
        vehicle-sales-manager-v2-kotlin  (SoR)
                       │
                       ▼
                   PostgreSQL
```

- **Kotlin** é o System of Record: único serviço com PostgreSQL, regras de estoque e JWT do painel.
- **`almotos-ai`** é a anti-corruption layer: prompts, tools Zod e chat. Catálogo e WhatsApp **não** chamam OpenAI nem o banco.
- **Admin não passa pelo MCP.** O painel fala com o Kotlin via `/api/proxy`.
- Tools públicas (`searchInventory`, `getVehiclePhotos`, `handoffToSeller`) são só leitura e **não** devolvem placa, CPF, custo nem preço. Negociação = handoff humano (`wa.me`).

Fluxo de IA: `Cliente → catálogo ou bot → almotos-ai → tools → GET /api/public/vehicles → Postgres`.

Guardrails: [`CLAUDE.md`](./CLAUDE.md).

## Submódulos

| Pasta | Papel | Stack | Porta | Deploy típico |
|---|---|---|---|---|
| [`vehicle-sales-manager-v2-kotlin`](./vehicle-sales-manager-v2-kotlin) | SoR — REST, JWT, catálogo público | Kotlin, Spring Boot 3.2, PostgreSQL 15 | `8080` | Railway |
| [`almotos-front`](./almotos-front) | Painel admin | Next.js 15, React 19 | `3000` | Vercel |
| [`almotos-catalog`](./almotos-catalog) | Vitrine + assistente (Generative UI) | Next.js 14, React 18 | `3001` | Vercel |
| [`almotos-ai`](./almotos-ai) | MCP Server + `/v1/chat` | Node 20, TypeScript, Express, Zod | `3100` | Railway |
| [`almotos-ai-bot`](./almotos-ai-bot) | Adapter WhatsApp (Meta Cloud API) | FastAPI, Python 3.12 | `8000` | Railway |

Remotes: `vehicle-sales-manager-v2-kotlin`, `almotos-front`, `almotos-catalog`, `almotos-ai`, `almotos-ai-bot` em `https://github.com/PedroHRoseno/`.

## Clonar

```bash
git clone --recurse-submodules <url-deste-repositorio>
cd full-stack-almotos
```

Clone já feito sem submódulos:

```bash
git submodule update --init --recursive
```

Trabalho do dia a dia: commit **dentro** do submodule; no pai, commit só o ponteiro (SHA).

## Pré-requisitos

- Java 17+, Docker Compose, wrapper `./gradlew` (Windows: `gradlew.bat`)
- Node.js 20+ e npm
- Python 3.12+ (bot)
- `OPENAI_API_KEY` **somente** no `almotos-ai`

## Rodar localmente

Ordem: Postgres → Kotlin → `almotos-ai` → painel / catálogo / bot.

### 1. Kotlin

```bash
cd vehicle-sales-manager-v2-kotlin
docker compose up -d
./gradlew bootRun
```

- API: http://localhost:8080
- Swagger: http://localhost:8080/swagger-ui.html
- Público (sem JWT): `GET /api/public/vehicles`  
  Query opcional: `?brand=HONDA&maxKm=20000&yearMin=2020`  
  Sem query o JSON é o de sempre (marca, modelo, ano, cor, km, fotos, descrição — **sem placa e sem preço**).

### 2. `almotos-ai`

```bash
cd almotos-ai
cp .env.example .env
# OPENAI_API_KEY e KOTLIN_BASE_URL=http://localhost:8080
npm install
npm run dev
```

| Rota | Uso |
|------|-----|
| `GET /health` | Healthcheck |
| `GET /v1/inventory` | Estoque projetado (`slug`, `colorLabel`, sem PII) |
| `POST /v1/chat` | Agent runtime (`channel`: `web` ou `whatsapp`) |
| `POST /mcp` | MCP Streamable HTTP |
| `npm run mcp:stdio` | MCP no Cursor |

### 3. Painel (`almotos-front`)

```bash
cd almotos-front
echo NEXT_PUBLIC_API_URL=http://localhost:8080 > .env.local
npm install
npm run dev
```

http://localhost:3000 — o browser usa `/api/proxy/*` → Kotlin.

### 4. Catálogo (`almotos-catalog`)

Porta **3001** para não colidir com o admin:

```bash
cd almotos-catalog
cp .env.example .env.local
# ALMOTOS_AI_URL=http://localhost:3100
npm install
npx next dev -p 3001
```

http://localhost:3001 — listagem via BFF `/api/catalog/vehicles`; chat via `/api/chat` → `almotos-ai`.  
O browser **não** chama o Kotlin. Em produção `ALMOTOS_AI_URL` é obrigatória; `KOTLIN_BASE_URL` só como fallback em dev.

Não use `NEXT_PUBLIC_API_BASE_URL` (nome antigo, o código não lê).

### 5. Bot (`almotos-ai-bot`)

```bash
cd almotos-ai-bot
cp .env.example .env
# ALMOTOS_AI_URL=http://localhost:3100 + credenciais Meta
python -m venv .venv
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- `GET /health` · webhook `GET/POST /webhook`
- Em prod: `WHATSAPP_APP_SECRET` (assinatura `X-Hub-Signature-256`). Sem secret e `DEBUG=false`, o POST retorna 403.
- Não configure `OPENAI_API_KEY` nem `VEHICLES_API_URL` neste serviço.

## Variáveis (resumo)

| Serviço | Obrigatórias (local) |
|---------|----------------------|
| Kotlin | perfil `local` + Postgres do Compose |
| `almotos-ai` | `KOTLIN_BASE_URL`, `OPENAI_API_KEY`, `SELLER_*_PHONE` |
| Catálogo | `ALMOTOS_AI_URL`; `NEXT_PUBLIC_WHATSAPP_URL`; `NEXT_PUBLIC_SITE_URL` |
| Admin | `NEXT_PUBLIC_API_URL` (Kotlin) |
| Bot | `ALMOTOS_AI_URL`, `WHATSAPP_VERIFY_TOKEN`, `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID` |

`OPENAI_API_KEY` não vai para Vercel do catálogo. Redis no `almotos-ai` (`REDIS_URL`) é só memória de thread WhatsApp, não espelho de estoque.

## Funcionalidades

**Painel + Kotlin:** JWT, veículos/parceiros, compra/venda/troca (estoque: compra → `DISPONIVEL`, venda → `VENDIDO`), custos, caixa, relatórios, upload S3, publicação no catálogo (`published`).

**Catálogo + IA:** vitrine das motos `DISPONIVEL` + `published=true`, `/motos/[slug]`, filtros, assistente com grid gerado por tool, handoff WhatsApp.

## Entidades (SoR)

Partner, Vehicle, Purchase, Sale, Exchange, VehicleCost, StoreTransaction, User.

## Documentação

- ADRs / agentes: [`CLAUDE.md`](./CLAUDE.md)
- Changelog: [`docs/ai/CHANGELOG.md`](./docs/ai/CHANGELOG.md)
- [`vehicle-sales-manager-v2-kotlin/README.md`](./vehicle-sales-manager-v2-kotlin/README.md)
- [`almotos-front/README.md`](./almotos-front/README.md)
- [`almotos-ai/README.md`](./almotos-ai/README.md)
- [`almotos-catalog/README.md`](./almotos-catalog/README.md)
- Bot: [`almotos-ai-bot/RAILWAY.md`](./almotos-ai-bot/RAILWAY.md)

## Troubleshooting

**Kotlin não sobe** — `docker compose ps` na pasta do backend.

**Painel sem API** — Kotlin na `8080`, `NEXT_PUBLIC_API_URL=http://localhost:8080`, JWT válido.

**Catálogo vazio / chat 503** — `almotos-ai` na `3100`, `ALMOTOS_AI_URL` no `.env.local`, motos publicadas. Em prod, 502 `fetch failed` costuma ser env antiga (`NEXT_PUBLIC_API_BASE_URL`) ou AI inacessível.

**Bot não responde** — `ALMOTOS_AI_URL`; App Secret em prod; não recolocar `VEHICLES_API_*`.

**Submódulo vazio** — `git submodule update --init --recursive`.

## Licença

Projeto privado, de uso interno.
