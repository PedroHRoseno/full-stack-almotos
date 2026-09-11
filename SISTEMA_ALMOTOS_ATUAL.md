# Sistema AL Motos — Fonte de Verdade Arquitetural

**Status:** vigente  
**Data de referência:** 2026-09-10  
**Escopo:** estado atual do monorepo `full-stack-almotos` e dos cinco submódulos de produto  
**Governança normativa:** [`docs/ai/CLAUDE.md`](./docs/ai/CLAUDE.md) (ADRs) · memória do agente: [`docs/ai/CHANGELOG.md`](./docs/ai/CHANGELOG.md)

Este arquivo descreve o sistema **como ele está implementado hoje**, não um roadmap. Quando o código e READMEs divergirem, o código (e este documento, após auditoria) prevalece.

---

## 1. Visão Geral e Objetivo do Sistema

### 1.1 Propósito

A **AL Motos** (razão social **ROSENO E SILVA COMERCIO DE VEICULOS LTDA**, CNPJ `68.967.245/0001-26`) é uma revenda de motocicletas em Caruaru/PE (Rua Visconde de Inhaúma, 725 — Maurício de Nassau).

O sistema é o **ERP + vitrine + pré-vendas por IA** da loja. Ele cobre:

| Papel | Quem usa | Superfície |
|-------|----------|------------|
| Operação interna | Donos e atendentes | Painel admin (`almotos-front`) |
| Vitrine pública | Cliente final | Site (`almotos-catalog`) — landing Instagram + estoque |
| Pré-vendas omnichannel | Cliente no WhatsApp | Chatwoot + bot (`almotos-ai-bot`) + orquestrador (`almotos-ai`) |
| System of Record | Todos os serviços | API FastAPI (`almotos-backend`) + PostgreSQL |

**Não existe módulo de locação/aluguel de motos.** “Aluguel” no painel aparece só como exemplo de despesa da loja no fluxo de caixa (aluguel do ponto, luz, salário). O negócio modelado é **compra, venda, troca e consignação**.

### 1.2 Casos de uso principais

1. **Cadastrar e publicar motos** — placa, FIPE, fotos S3, tags internas/públicas, preço sugerido, origem própria ou de terceiro.
2. **Registrar o ciclo comercial** — compra (entra no estoque), venda (sai do estoque), troca (entra uma / sai outra), cancelamento com reversão de status.
3. **Consignação** — moto `THIRD_PARTY` com dono cadastrado; na venda, o operador informa **à mão** o valor de repasse e o lucro da loja (sem percentual automático).
4. **Caixa e relatórios** — lançamentos da loja, custos por veículo, KPIs de lucro próprio vs. terceiros, relatório por contato.
5. **Catálogo público** — motos `DISPONIVEL` + `published=true`, landing para Instagram, SEO, política de privacidade (LGPD).
6. **Assistente de pré-vendas** — busca estoque, mostra fotos, informa preço de tabela cadastrado e transfere para humano **na mesma conversa**. Não negocia desconto nem calcula parcela.

### 1.3 Funcionalidades atualmente ativas e funcionais

**Painel + SoR (produção em `https://api.almotoscaruaru.com.br`)**

- Login JWT (HS256, compatível com o Spring legado).
- CRUD de veículos (PK UUID; lookup HTTP por placa; edição de placa sem quebrar FKs).
- Publicação no catálogo (fotos, descrição, `published`).
- Contatos unificados (CPF/CNPJ) — a mesma pessoa compra, vende e consigna.
- Compras, vendas (próprio + consignado), trocas, custos por moto.
- Fluxo de caixa unificado + CRUD de lançamentos da loja.
- Cancelar venda devolve a moto ao estoque e **estorna** lançamentos de caixa ligados (`source_sale_id`).
- Relatórios: dashboard, financeiro por período, por contato (dono/repasse/comprador/fornecedor).
- Consulta FIPE (Brasil API) no cadastro e em tela avulsa.
- Gestão de usuários internos (ADMIN).
- Tema claro/escuro; identidade vermelha `#eb0b0b`.

**Catálogo (`almotoscaruaru.com.br` + `catalogo.almotoscaruaru.com.br`)**

- Landing estilo Linktree no apex; estoque em `/estoque`.
- Rewrite: `catalogo.almotoscaruaru.com.br/` → `/estoque`.
- Ficha `/motos/[slug]`, sitemap, JSON-LD, `/privacidade`.
- Widget de chat com Generative UI (cards, fotos, handoff).

**WhatsApp (caminho de produção)**

- Cliente → Meta Cloud API → **Chatwoot** → `POST /webhook/chatwoot` → debounce 4s → `almotos-ai` → resposta outgoing no Chatwoot (texto + anexo de foto).
- Handoff abre a conversa (`status: open`) e deixa nota privada; **não** manda `wa.me` para outro número.

**Fora do produto (explícito)**

- App de fluxo pessoal (`personal-finance`) **não** faz parte do monorepo.
- Backend Spring/Kotlin **não** é mais writer; fica em repositório GitHub próprio só para rollback no Railway.

---

## 2. Stack Tecnológica e Arquitetura

### 2.1 Diagrama de serviços

```
Cliente (site / WhatsApp)                         Operador (painel)
        │                                                │
        ▼                                                ▼
almotos-catalog  ou  almotos-ai-bot                 almotos-front
(Next.js 14 / FastAPI thin client)                  (Next.js 15 + /api/proxy + JWT)
        │                                                │
        ▼                                                │
   almotos-ai                                            │
   MCP + POST /v1/chat                                   │
   (Anti-Corruption Layer)                               │
        │                                                │
        └────────────────────┬───────────────────────────┘
                             ▼
                    almotos-backend  (SoR FastAPI)
                    único writer do PostgreSQL
                             │
                             ▼
                         PostgreSQL 15
```

Fluxo obrigatório de IA (ADR-001 / ADR-003):

`Cliente → Chatwoot ou catálogo → interface thin → almotos-ai → tools MCP → GET /api/public/vehicles no SoR → PostgreSQL`

O painel **MUST NOT** passar pelo MCP. Catálogo e bot **MUST NOT** chamar OpenAI nem o banco.

### 2.2 Padrão arquitetural

Arquitetura **distribuída por serviços**, com:

- **System of Record (SoR)** — FastAPI, regras de negócio e persistência.
- **Anti-Corruption Layer (ACL)** — `almotos-ai` projeta o estoque público (sem PII) e concentra prompts/tools.
- **Thin clients** — catálogo e bot só encaminham intenção.
- **BFF** — admin via `/api/proxy`; catálogo via `/api/catalog/vehicles` e `/api/chat`.
- Camadas no SoR: `routers` (HTTP fino) → `services` (domínio) → `models` (ORM) / `schemas` (Pydantic). Não é Clean Architecture completa (sem ports/adapters formais), mas **há isolamento de persistência**.
- Schema: **somente Alembic** (nunca `Base.metadata.create_all()` no startup).
- Paginação HTTP no estilo Spring Data (`page`, `size`, `sort`) para o painel legado.

Não é Event-Driven nem Serverless no núcleo: Railway roda processos contínuos (uvicorn/Node); Vercel hospeda os Next.js.

### 2.3 Linguagens, frameworks e versões

| Serviço | Linguagem | Framework | Versões de referência |
|---------|-----------|-----------|------------------------|
| `almotos-backend` | Python ≥ 3.12 | FastAPI ≥ 0.115 (lock ~0.141), Uvicorn, SQLAlchemy 2.0 async, Alembic, Pydantic 2, asyncpg, PyJWT, bcrypt, boto3, httpx | Gerenciador: **uv** (`pyproject.toml` + `uv.lock`) |
| `almotos-front` | TypeScript 5.7 | **Next.js 15.1.9**, React 19, Tailwind 3.4, Zod 3.24, RHF, Radix/shadcn, Sonner | Node 20 (CI) |
| `almotos-catalog` | TypeScript 5 | **Next.js 14.2.25**, React 18.2, Tailwind 4, Vercel AI SDK `ai` ^4.3.19, Embla, Framer Motion | Node 20 (CI) |
| `almotos-ai` | TypeScript 5.9 | Node 20, Express 4.21, `@ai-sdk/openai` ^1.3.22, `ai` ^4.3.19, MCP SDK ^1.17.5, Zod 3.25, ioredis 5.6 | ESM |
| `almotos-ai-bot` | Python 3.12.7 | FastAPI ≥ 0.115, Uvicorn, httpx, Pydantic 2 | `requirements.txt` |

CI do monorepo: GitHub Actions, Node **20**, Python **3.12**.

### 2.4 Banco de dados, ORM e persistência

| Item | Valor |
|------|--------|
| SGBD | **PostgreSQL 15** (Compose local Alpine; produção no Railway) |
| Nome do banco (local) | `vehicle-sales-manager` |
| ORM | SQLAlchemy 2.0 **async** + `asyncpg` |
| Migrações | Alembic — revisões `001`, `002`, `003` sobre schema legado Hibernate/Flyway |
| DDL no startup | **Proibido** (ADR-001) |
| Release (Railway) | `uv run --no-dev alembic upgrade head` **antes** do novo processo receber tráfego |
| Relacionamentos ORM | FKs por coluna; **sem** `relationship()` declarados |
| Redis | **Opcional** só no `almotos-ai` (memória de thread WhatsApp). **MUST NOT** espelhar estoque |

O volume local do Compose **não cria tabelas**. Precisa de dump de produção (ou schema já migrado) + `alembic upgrade head`.

### 2.5 Integrações externas

| Integração | Quem usa | Função |
|------------|----------|--------|
| **PostgreSQL** | `almotos-backend` | Persistência única |
| **AWS S3** | `almotos-backend` | Upload de fotos (máx. 10 MB); URL pública regional |
| **Brasil API (FIPE)** | `almotos-backend` | Proxy autenticado, tipo `motos`, timeout 2,5 s, cache in-memory 6 h; falha não bloqueia cadastro |
| **ViaCEP** | `almotos-front` (browser) | Autocomplete de endereço no contato |
| **OpenAI** | **somente** `almotos-ai` | `gpt-4o-mini` (default via `OPENAI_MODEL`); tool calling (Vercel AI SDK) |
| **Chatwoot** | `almotos-ai-bot` | Caixa omnichannel; AgentBot webhook + REST (mensagens, anexos, `toggle_status`) |
| **Meta Cloud API** | Via Chatwoot (prod); rota direta `/webhook` no bot é **legado** | Entrega WhatsApp |
| **Evolution API v2** | `almotos-ai-bot` | **Legado/fallback**; inbound **ignorado** se Chatwoot estiver configurado |
| **Redis** | `almotos-ai` (opcional) | Histórico de thread WhatsApp (`almotos:thread:{id}`, TTL 24 h, máx. 20 turnos) |
| **Vercel** | front + catalog | Hospedagem Next.js |
| **Railway** | backend, ai, bot | Processos + Postgres |
| **MCP** | `almotos-ai` | Streamable HTTP `/mcp` e stdio (`npm run mcp:stdio`) para Cursor/Inspector |

**Não há** gateway de pagamento, PIX, boleto nem cálculo de financiamento no sistema. Condições (“48x / cartão 18x”) são copy informativo; simulação vai para WhatsApp humano.

Nome histórico: a env `KOTLIN_BASE_URL` no `almotos-ai` e no catálogo **aponta para o FastAPI** (`https://api.almotoscaruaru.com.br` ou `http://localhost:8081`). O cliente HTTP ainda se chama `kotlin-client.ts`.

### 2.6 Guardrails (ADRs vigentes)

| ADR | Decisão |
|-----|---------|
| **ADR-001** | FastAPI é o único writer do Postgres (cutover 2026-08-20). Sem segundo writer, sem Prisma/psycopg2 nos outros serviços, sem Redis de estoque. |
| **ADR-002** | Tools públicas são read-only e **não** devolvem placa, CPF/CNPJ, custo de aquisição. |
| **ADR-003** | Prompts e tools só no `almotos-ai`. Catálogo/bot não chamam LLM. |
| **ADR-004** | Inputs das tools validados com Zod. |
| **ADR-005** | Mudança de contrato/arquitetura vai para `docs/ai/CHANGELOG.md`. |
| Financeiro | IA **não** calcula desconto, entrada, parcela nem preço à vista. |

### 2.7 Domínios de produção

| Superfície | URL típica |
|------------|------------|
| SoR | `https://api.almotoscaruaru.com.br` |
| Landing | `https://almotoscaruaru.com.br` |
| Catálogo (rewrite) | `https://catalogo.almotoscaruaru.com.br` → `/estoque` |
| Painel | projeto Vercel `almotos-front` |
| Docs SoR | `https://api.almotoscaruaru.com.br/docs` |

---

## 3. Estrutura do Projeto

O repositório pai **só** versiona composição (Gitlinks), CI, governança e este tipo de documento. Cada produto é **submódulo** em `https://github.com/PedroHRoseno/<nome>`.

```
full-stack-almotos/
├── .gitmodules
├── .github/workflows/ci-cd.yml      # CI/CD condicional por submodule
├── .cursor/                         # mcp.json (stdio do almotos-ai) + rules
├── docs/ai/CLAUDE.md                # ADRs (normativo)
├── docs/ai/CHANGELOG.md             # memória do agente
├── docs/scratch/                    # gitignored — tutoriais locais
├── almotos-backend/                 # SoR FastAPI
├── almotos-front/                   # Painel Next.js 15
├── almotos-catalog/                 # Vitrine Next.js 14
├── almotos-ai/                      # Orquestrador MCP
├── almotos-ai-bot/                  # Adapter WhatsApp/Chatwoot
├── scripts/                         # pasta local vazia (não versionada)
└── personal-finance/                # app pessoal separado; não é produto AL Motos
```

O Kotlin (`vehicle-sales-manager-v2-kotlin`) **não está neste workspace**. Código em repositório próprio, standby no Railway.

### 3.1 `almotos-backend` — System of Record

```
almotos-backend/
├── alembic/versions/          # 001 UUID PK · 002 FIPE/tags · 003 ownership/repasse · 004 partner UUID
├── src/almotos_backend/
│   ├── main.py                # App, CORS, JWT middleware, /health, routers
│   ├── config.py              # Settings
│   ├── db.py                  # Engine asyncpg; commit incondicional no sucesso
│   ├── models/                # ORM (13 tabelas)
│   ├── schemas/               # DTOs Pydantic (camelCase no JSON)
│   ├── routers/               # HTTP
│   ├── services/              # Regras de negócio
│   ├── security/              # JWT HS256(SHA-256(secret)), BCrypt $2a$
│   └── utils/
├── tests/                     # ~13 arquivos pytest
├── docker-compose.yml         # Postgres 15
├── Dockerfile · railway.json
└── pyproject.toml
```

Porta local documentada: **8081** (`PORT` no `.env.example`; default da classe Settings ainda é 8080). Produção: variável `PORT` do Railway.

### 3.2 `almotos-front` — Painel admin

```
almotos-front/src/
├── app/                       # App Router (quase todas as páginas "use client")
│   ├── api/proxy/[...path]/   # BFF → SoR
│   ├── login/ motos/ contatos/ compras/ vendas/ trocas/
│   ├── fluxo-caixa/ relatorios/ consulta-fipe/ configuracoes/ guia/
│   └── clientes/              # redirect legado → /contatos
├── components/forms|layout|ui|vehicle|auth
├── contexts/                  # Auth + refresh do dashboard
├── lib/api.ts                 # Cliente HTTP único
└── types/index.ts
```

Porta **3000**. Auth 100% client-side (`localStorage` + `AuthGuard`). `middleware.ts` **não** bloqueia rotas.

### 3.3 `almotos-catalog` — Vitrine

```
almotos-catalog/src/
├── middleware.ts              # multi-domínio (só matcher "/")
├── app/page.tsx               # landing
├── app/estoque/page.tsx       # grade
├── app/motos/[slug]/          # ficha + not-found
├── app/privacidade/
├── app/api/chat/              # BFF stream → almotos-ai
├── app/api/catalog/vehicles/  # BFF estoque
├── components/assistant/      # widget + tool-renderers (Generative UI)
├── components/landing/
└── lib/catalog.ts             # fetch /v1/inventory (prod) ou SoR (dev)
```

Porta local **3001** (para não colidir com o admin).

### 3.4 `almotos-ai` — Orquestrador

```
almotos-ai/src/
├── index.ts                   # Express: health, inventory, chat, /mcp
├── stdio.ts                   # MCP para Cursor
├── chat/runtime.ts            # web stream vs whatsapp JSON
├── chat/system-prompt.ts      # regras de pré-venda
├── chat/memory.ts             # Redis ou Map
├── chat/whatsapp-format.ts    # Markdown → texto puro + URLs de foto
├── tools/                     # searchInventory, getVehiclePhotos, handoffToSeller
├── inventory/kotlin-client.ts # HTTP SoR + cache + slug
└── contracts/public-vehicle.ts
```

Porta **3100**.

### 3.5 `almotos-ai-bot` — Thin client WhatsApp

```
almotos-ai-bot/app/
├── main.py                    # FastAPI 1.3.0
├── routes/                    # health, chatwoot, evolution, webhook Meta
└── services/                  # buffer, reply_guard, clientes Chatwoot/Evolution/AI
```

Porta **8000**. Sem Postgres/Redis neste processo (ADR-001).

### 3.6 CI/CD do pai

Ordem de CD em `main`/`master`: **SoR → almotos-ai → (front ∥ catalog ∥ bot)**.

Cada job faz `git submodule update --init` **só** da pasta que usa (token `GH_PAT`). Path filter observa o Gitlink do submodule.

---

## 4. Modelos de Dados e Entidades

Baseline legado (Hibernate/Flyway) + três revisões Alembic. Identificadores mistos de propósito:

- `vehicles.id` — **UUID** (PK desde `001`)
- `vehicles.license_plate` — UNIQUE; ainda é a chave de URL do admin
- `partners.id` — **UUID** (PK desde `004`)
- `partners.document` — CPF/CNPJ sanitizado, UNIQUE NULLABLE (vários NULL permitidos)
- Compras/vendas/trocas/caixa/custos/histórico/users — `BigInteger` autoincrement

### 4.1 Diagrama de relacionamentos (lógico)

```
users
partners ──< vehicles.owner_partner_id          (consignação)
partners ──< purchases.partner_id               (fornecedor)
partners ──< sales.partner_id                   (comprador)
partners ──< sales.owner_partner_id             (snapshot dono)
partners ──< sales.payout_partner_id            (quem recebe o repasse)
partners ──< exchanges.partner_id
addresses  ··· partners.address_id              (sem FK ORM)

vehicles ──< vehicle_images                     (PK composta vehicle_id + url)
vehicles ──< vehicle_tags >── tags              (N:N)
vehicles ──< purchases | sales | vehicle_costs
vehicles ──< exchanges (entrada e saída)

sales.id ··· store_transactions.source_sale_id  (repasse automático)
```

### 4.2 Enums de domínio

| Enum | Valores |
|------|---------|
| `Role` | `ADMIN`, `USER` |
| `VehicleStatus` | `DISPONIVEL`, `VENDIDO`, `INACTIVE` |
| `OwnershipKind` | `OWN`, `THIRD_PARTY` |
| `TagVisibility` | `INTERNAL`, `PUBLIC` |
| `TransactionStatus` | `ACTIVE`, `CANCELLED` |
| `TransactionType` (auditoria) | `PURCHASE`, `SALE`, `EXCHANGE`, `STORE_TRANSACTION` |
| `CashFlowType` | `ENTRY`, `EXIT` |
| `TransactionCategory` | `OPERACIONAL`, `ADMINISTRATIVO`, `MARKETING`, `INFRAESTRUTURA`, `PESSOAL`, `SERVICOS_PRESTADOS`, `REPASSE_PARCEIRO`, `OUTROS` |
| `ActionType` | `CREATED`, `EDITED`, `CANCELLED` |
| `ContactReportRole` | `buyer`, `owner`, `payout`, `supplier` |
| `VehicleBrand` | 37 marcas (carros + motos: HONDA, YAMAHA, KAWASAKI, SUZUKI, HARLEY_DAVIDSON, BMW_MOTORRAD, DUCATI, APRILIA, TRIUMPH, KTM, …) |

### 4.3 Tabelas

#### `users`

| Campo | Tipo | Notas |
|-------|------|--------|
| `id` | BigInteger PK | |
| `username` | String(255) UNIQUE | |
| `password` | String(255) | BCrypt `$2a$` (compatível Spring) |
| `role` | String(32) | `ADMIN` / `USER` |

#### `vehicles`

| Campo | Tipo | Notas |
|-------|------|--------|
| `id` | UUID PK | default uuid4 |
| `license_plate` | String UNIQUE | lookup HTTP |
| `brand` | String(64) | enum `VehicleBrand` |
| `model_name` | String | |
| `codigo_fipe` | String(16) nullable | |
| `manufacture_year`, `model_year` | Integer | |
| `color` | String | frequentemente hex |
| `kilometers_driven` | Integer | |
| `suggested_price` | Float nullable | preço de **tabela** da loja; catálogo/IA podem ver |
| `published` | Boolean default false | vitrine |
| `description` | String(1000) nullable | |
| `status` | String | default `DISPONIVEL` |
| `ownership_kind` | String | default `OWN` |
| `owner_partner_id` | UUID nullable | FK `partners.id` se terceiro |
| `created_at` | DateTime | ordenação do catálogo “mais recentes” |

Sair de `DISPONIVEL` força `published=false`.

#### `tags` / `vehicle_tags`

- `tags`: UUID, `name`, `slug`, `visibility`, `created_at`; unique `(visibility, slug)`.
- `vehicle_tags`: PK composta `(vehicle_id, tag_id)`, CASCADE.

Catálogo e IA só enxergam tags `PUBLIC`.

#### `vehicle_images`

PK composta `(vehicle_id, image_url)`. Substituição da lista é total no update de catálogo.

#### `partners` (contatos)

| Campo | Tipo | Notas |
|-------|------|--------|
| `id` | UUID PK | default uuid4 |
| `document` | String UNIQUE NULLABLE | CPF ou CNPJ sanitizado; vários NULL ok |
| `name` | String | |
| `phone_number1`, `phone_number2` | String nullable | |
| `address_id` | BigInteger nullable | aponta logicamente para `addresses` |

#### `addresses`

`id`, `street_name` nullable, `number`, `city`, `state`, `reference` nullable, `zip_code`. City/number/state/zip obrigatórios no service.

#### `purchases`

`id`, `vehicle_id` → vehicles, `partner_id` (fornecedor), `purchase_price`, `purchase_date`, `deleted`, `status`.

Registrar compra: veículo → `DISPONIVEL`, `ownership_kind=OWN`, `owner_partner_id=null`.

#### `sales`

| Campo | Notas |
|-------|--------|
| `partner_id` | comprador |
| `sale_price` / `sale_date` | |
| `ownership_kind` / `owner_partner_id` | **snapshot** do veículo no momento da venda |
| `payout_partner_id` / `payout_amount` | OWN → 0 e sem contato |
| `store_profit` | obrigatório em THIRD_PARTY; nulo em OWN |
| `deleted` / `status` | |

Não há percentual automático. Operador informa repasse e lucro.

#### `exchanges`

`vehicle_entrada_id`, `vehicle_saida_id`, `partner_id`, `diferenca_valor` (sinal: positivo = cliente paga / entrada de caixa), `exchange_date`, `deleted`, `status`.

Entrada → `DISPONIVEL`; saída → `VENDIDO`.

#### `vehicle_costs`

Custos da moto (`cost`, `description`, `cost_date`). Soft-delete `deleted=true`.

#### `store_transactions`

Lançamentos da loja: `description`, `value`, `date`, `type` (ENTRY/EXIT), `category`, `status`, `deleted`, `source_sale_id` (repasse gerado pela venda).

`DELETE /store-transactions/{id}` **cancela** (não apaga fisicamente).

#### `transaction_history`

Auditoria: `transaction_type`, `transaction_id`, `action_type`, `action_date`, `description`, `old_value`, `new_value`, `performed_by`. **Não há endpoint de leitura**; o histórico operacional da moto agrega compras/vendas/trocas/custos em `/vehicles/{placa}/history`.

### 4.4 Contrato público (sem PII)

`GET /api/public/vehicles` devolve apenas: `brand`, `model`, `year`, `color`, `kilometersDriven`, `suggestedPrice?`, `imageUrlList`, `description?`, `tags` (públicas). Sem placa, sem dono, sem custo.

O `almotos-ai` projeta `PublicVehicle`: adiciona `slug`, `colorLabel`, `catalogUrl`.

---

## 5. Interfaces, Rotas e Webhooks

### 5.1 SoR FastAPI — autenticação

**Público (sem JWT):** `OPTIONS`, `/health`, `/docs`, `/redoc`, `/openapi.json`, `POST /api/auth/login`, prefixo `/api/public/*`.

**Demais rotas:** `Authorization: Bearer <JWT>`.

**ADMIN** (`require_admin`): somente `/users/*`. Role `USER` acessa o restante do ERP autenticado.

Paginação: `page`, `size` (máx. 200 no client), `sort` (ex.: `saleDate,desc`).

### 5.2 Endpoints do SoR

#### Infra e auth

| Método | Path | Auth | Função |
|--------|------|------|--------|
| GET | `/health` | público | `{ status, database }` — 503 se Postgres down |
| POST | `/api/auth/login` | público | JWT + username + role |
| PATCH | `/api/auth/me/password` | JWT | troca senha (204) |
| GET/POST | `/users` | ADMIN | lista / cria |
| PATCH | `/users/{id}` | ADMIN | role |
| PATCH | `/users/{id}/password` | ADMIN | redefine senha |
| DELETE | `/users/{id}` | ADMIN | não apaga o último ADMIN nem a si mesmo |

#### Catálogo público e mídia

| Método | Path | Função |
|--------|------|--------|
| GET | `/api/public/vehicles` | `?brand&maxKm&yearMin&q=` — Cache-Control 30s |
| POST | `/api/vehicles/images/upload` | multipart → S3 |

Busca `q`: tokens ILIKE (`honda` AND `start`), não substring contínua.

#### Veículos

| Método | Path | Função |
|--------|------|--------|
| GET | `/vehicles` | lista (`search`, `inStock`, `published`, `ownershipKind`, `ownerId`, `ownerDocument`) |
| GET | `/vehicles/available` | só estoque |
| POST | `/vehicles` | cria (201) |
| GET/PUT | `/vehicles/{placa}` | detalhe / update (placa nova no body; UUID interno) |
| PATCH | `/vehicles/{placa}/catalog` | published, fotos, descrição |
| GET | `/vehicles/{placa}/history` | compras, vendas, trocas, custos |
| GET/POST | `/vehicles/{placa}/costs` | custos |
| DELETE | `/vehicles/{placa}/costs/{id}` | soft-delete |

#### FIPE e tags

| Método | Path |
|--------|------|
| GET | `/fipe/models?brand&q` |
| GET | `/fipe/codigo?brand&codigoModelo&year` |
| GET | `/fipe/anos?brand&codigoModelo` |
| GET | `/fipe/consulta?brand&codigoModelo&year` |
| GET | `/tags?visibility&q` |

Não há CRUD HTTP isolado de tags: upsert ocorre no create/update do veículo.

#### Contatos, comércio, caixa, relatórios

| Recurso | Métodos |
|---------|---------|
| `/partners` | GET lista, GET `{partner_id}` UUID, POST (201 + summary; documento opcional; 409 se duplicado), PUT `{partner_id}`, DELETE (bloqueado se houver vínculos) |
| `/purchases` | GET, POST, PUT `{id}`, POST `{id}/cancel`, DELETE `{id}?deleteVehicle=` |
| `/sales` | GET, POST, PUT `{id}`, POST `{id}/cancel`, DELETE `{id}` (= cancel) |
| `/exchanges` | GET, POST, PUT `{id}`, POST `{id}/cancel`, DELETE `{id}?deleteIncomingVehicle=` |
| `/store-transactions` | GET, POST, PUT `{id}`, POST `{id}/cancel`, DELETE `{id}` (= cancel) |
| `/financial/movements` | GET unificado (venda/compra/troca/custo/loja); paginação **em memória** |
| `/reports/dashboard` | KPIs globais |
| `/reports/financial` | `startDate`, `endDate` (default 30 dias) |
| `/reports/by-contact` | `partnerId` e/ou `document`, `role`, `ownershipKind`, período |

O client do admin ainda declara métodos Kotlin antigos (`/sales/search`, `/sales/profit`, …) **sem UI**; o FastAPI **não** replica esses paths.

### 5.3 `almotos-ai`

| Método | Path | Função |
|--------|------|--------|
| GET | `/health` | `{ ok, service, memory: redis \| in-memory }` |
| GET | `/v1/inventory` | `PublicVehicle[]` |
| GET | `/v1/inventory/:slug` | detalhe ou 404 |
| POST | `/v1/chat` | agent runtime |
| ALL | `/mcp` | MCP Streamable HTTP |

**Body `/v1/chat`**

```json
{ "channel": "web", "messages": [...], "stream": true }
{ "channel": "whatsapp", "threadId": "chatwoot:123", "text": "...", "stream": false }
```

WhatsApp responde `{ text, images, handoff }`. Sem `OPENAI_API_KEY` → 503.

#### Tools MCP / AI SDK

| Tool | Input (Zod) | Comportamento |
|------|-------------|---------------|
| `searchInventory` | `brand?`, `model?`, `color?`, `maxKilometers?`, `yearMin?` | SoR público + filtro client-side; até 8 matches; inclui `suggestedPrice` e tags públicas |
| `getVehiclePhotos` | `slug?`, `model?` | até 3 URLs **distintas** |
| `handoffToSeller` | `reason?`, `model?` | payload `{ handoff: true, sameThread: true }` — sem HTTP externo |

Resource MCP: `inventory://available`.

### 5.4 Painel — rotas de página

| Rota | Função |
|------|--------|
| `/login` | autenticação |
| `/` | dashboard |
| `/motos`, `/motos/[placa]` | estoque e ficha (edição + vitrine + custos + histórico) |
| `/contatos`, `/contatos/[cpf]` | cadastro unificado |
| `/clientes` | redirect → `/contatos` |
| `/consulta-fipe` | consulta avulsa |
| `/compras`, `/vendas`, `/trocas` | comércio |
| `/fluxo-caixa` | movimentações + lançamentos |
| `/relatorios` | financeiro + por contato |
| `/guia` | documentação in-app |
| `/configuracoes` | senha; ADMIN gerencia usuários |
| `/api/proxy/*` | BFF (`BACKEND_URL` > `API_URL` > `NEXT_PUBLIC_API_URL`) |

### 5.5 Catálogo — rotas

| Rota | Função |
|------|--------|
| `/` | landing (hero, busca, 3 motos recentes, atalhos) |
| `/estoque` | grade + filtros |
| `/motos/[slug]` | ficha ISR/SSG |
| `/privacidade` | LGPD |
| `/sitemap.xml` | URLs dinâmicas |
| `/api/chat` | BFF stream `channel=web` |
| `/api/catalog/vehicles` | BFF JSON, revalidate 60s |

Middleware: hostname `catalogo.almotoscaruaru.com.br` reescreve `/` para `/estoque`. Apex (`almotoscaruaru.com.br`, `www.`) mostra a landing.

### 5.6 Bot — webhooks

| Método | Path | Status |
|--------|------|--------|
| GET | `/health` | ativo |
| POST | `/webhook/chatwoot` | **produção** — AgentBot `message_created` incoming |
| GET/POST | `/webhook` | **legado** Meta Cloud API (verify token + HMAC `X-Hub-Signature-256`) |
| POST | `/webhook/evolution` | **legado**; inbound descartado se Chatwoot configurado |

Chatwoot: ACK 200 imediato; worker espera `CHATWOOT_DEBOUNCE_SECONDS` (4s), junta textos do mesmo `conversation_id`, chama `/v1/chat` com `threadId=chatwoot:{id}`.

Filtros anti-loop: ignora outgoing, evento ≠ `message_created`, conversa já `open` (humano), sender `user/agent/agent_bot`, mídia sem caption, dedup por fingerprint (TTL 180s).

---

## 6. Regras de Negócio e Fluxos Principais

### 6.1 Cadastro de contato

Uma pessoa = um `partners.id` (UUID). CPF/CNPJ é opcional e UNIQUE quando preenchido (409 se outro contato já tiver o mesmo dígito). Serve como comprador, fornecedor, dono consignado e destinatário de repasse. Delete só se não houver vendas/compras/trocas/motos/repasses. Endereço via ViaCEP no formulário.

### 6.2 Cadastro de moto e publicação

1. Operador preenche placa (máscara Mercosul), marca, modelo (autocomplete FIPE opcional), anos, cor, km, preço sugerido, tags, origem.
2. `OWN`: sem dono. `THIRD_PARTY`: exige contato existente em `ownerId`.
3. `inStock=false` na criação grava status `VENDIDO`.
4. Fotos: pipeline no admin (crop/compress) → `POST /api/vehicles/images/upload` → URLs no PATCH de catálogo.
5. Vitrine pública exige `status=DISPONIVEL` **e** `published=true`.
6. FIPE indisponível: cadastro segue com modelo livre e `codigo_fipe` nulo.

### 6.3 Compra (entrada de estoque)

1. Contato fornecedor + veículo + valor.
2. Veículo vira `DISPONIVEL`, propriedade `OWN` (o “dono” consignado é limpo — a loja passou a ser dona).
3. Cancelar: status `CANCELLED`, veículo `INACTIVE`.
4. Delete com `deleteVehicle=true` tenta remover o veículo se não houver outras refs.

### 6.4 Venda

1. Só moto `DISPONIVEL`.
2. Snapshot de `ownership_kind` / `owner_partner_id`.
3. **OWN:** `payout_amount=0`, `store_profit=null`.
4. **THIRD_PARTY:** exige `payout_amount ≥ 0`, `store_profit` e contato de repasse. Se `payout_amount > 0`, cria `StoreTransaction` EXIT `REPASSE_PARCEIRO` com `source_sale_id`.
5. Veículo → `VENDIDO` (`published` cai).
6. **Cancelar:** 400 se já `CANCELLED`; senão marca cancelada, moto volta `DISPONIVEL`, **estorna todos** os lançamentos ativos com aquele `source_sale_id` (não só categoria `REPASSE_PARCEIRO`).

A UI de vendas **não** edita venda (embora exista `PUT /sales/{id}` para preço/data).

### 6.5 Troca

- Saída precisa estar disponível.
- Entrada entra no estoque; saída é vendida.
- `diferenca_valor` entra no lucro bruto com sinal.
- Cancelar reverte a saída para `DISPONIVEL`. UI lista/cancela; sem busca textual.

### 6.6 Caixa e fórmulas financeiras

**Lucro estoque próprio** = soma vendas `OWN` − soma compras (ativas).

**Lucro bruto** = lucro próprio + soma `store_profit` de vendas `THIRD_PARTY` + soma `diferenca_valor` das trocas − custos de veículos.

**Despesas operacionais (dashboard)** = saídas de caixa ativas nas categorias OPERACIONAL, ADMINISTRATIVO, MARKETING, INFRAESTRUTURA.

**Lucro líquido** = lucro bruto − despesas operacionais.

Repasses `REPASSE_PARCEIRO` gerados pela venda são imutáveis na UI do caixa (estão amarrados à venda). Lançamentos manuais (aluguel, salário, marketing…) têm criar/editar/excluir (excluir = cancelar).

Movimentações unificadas misturam os cinco tipos para a tela de fluxo de caixa.

### 6.7 Fluxo do bot (produção)

```
WhatsApp  →  Chatwoot inbox  →  POST /webhook/chatwoot
                                    │
                                    ├─ filtros (incoming, não humano, não eco)
                                    ├─ reply_guard.claim_inbound
                                    ├─ buffer.push(conversation_id)  → 200 OK
                                    │
                                    └─ BackgroundTasks: sleep 4s
                                         se generation ainda vigente:
                                           POST almotos-ai /v1/chat
                                           format_whatsapp_reply
                                           send_message e/ou send_attachment
                                           se handoff: toggle_status open + nota privada
```

Regras do system prompt (canal WhatsApp):

- Máximo **3 motos** por turno; CTA híbrida (continuar no chat ou abrir catálogo) se houver mais.
- Preço de tabela: **sempre** `searchInventory` antes; informar `suggestedPrice` em R$; handoff **só** se o preço não existir após a busca.
- Sem Markdown `[texto](url)`; negrito `*texto*`; fotos só via tool (o bot anexa a URL pública).
- Sem `wa.me`. Negociação/financiamento/visita/fechar → `handoffToSeller`.
- Não oferece oficina/revisão. Não inventa moto fora da tool.
- Busca fuzzy: `"honda start"` casa `"HONDA CG 160 START"`.

Canal **web** (widget): 1–2 frases; cards/fotos/handoff na Generative UI; texto Markdown de catálogo é ocultado se a tool já renderizou.

### 6.8 Fluxo do catálogo

1. SSR busca `GET {ALMOTOS_AI_URL}/v1/inventory` (prod). Dev pode cair em `KOTLIN_BASE_URL` + slug local.
2. Landing mostra 3 mais recentes (`created_at` desc no SoR).
3. Chat: `useChat` → `/api/chat` → stream `almotos-ai`.
4. CTA “Tenho interesse” / simulação monta `wa.me` com telefone da loja (`NEXT_PUBLIC_WHATSAPP_URL` ou `company.ts`). **Não calcula parcela.**

### 6.9 Auth do painel

Login → `POST /api/proxy/api/auth/login` → `localStorage` (`auth_token`, `auth_user`). Requests levam Bearer. 401 limpa sessão. JWT: HS256 da **SHA-256** do `JWT_SECRET` (mesmo esquema do Kotlin), claims `sub`, `role`, `exp`. Default 24 h (`JWT_EXPIRATION` em ms). Seed de admin no startup **só** se tabela `users` vazia **e** `ADMIN_USERNAME` + `ADMIN_PASSWORD` definidos.

---

## 7. Configurações e Variáveis de Ambiente

**Nenhum valor secreto está listado abaixo — apenas nomes.**

### 7.1 `almotos-backend`

| Variável | Obrigatória | Uso |
|----------|-------------|-----|
| `PORT` | Railway injeta | listen (local exemplo 8081) |
| `DB_URL` | sim em prod | JDBC ou `postgresql://` |
| `DB_USER` | sim em prod | |
| `DB_PASSWORD` | sim em prod | |
| `JWT_SECRET` | sim em prod | |
| `JWT_EXPIRATION` | não | ms, default 86400000 |
| `CORS_ALLOWED_ORIGINS` | não | CSV ou `*` |
| `ADMIN_USERNAME` | não | seed se users vazio |
| `ADMIN_PASSWORD` | não | seed se users vazio |
| `AWS_REGION` | não | default `us-east-1` |
| `AWS_BUCKET_NAME` | para upload | |
| `AWS_ACCESS_KEY_ID` | chain boto3 | fora da classe Settings |
| `AWS_SECRET_ACCESS_KEY` | chain boto3 | fora da classe Settings |
| `RAILWAY_ENVIRONMENT` | plataforma | se presente, exige DB_* e JWT_SECRET |

### 7.2 `almotos-ai`

| Variável | Uso |
|----------|-----|
| `PORT` | default 3100 |
| `KOTLIN_BASE_URL` | base do SoR FastAPI (nome histórico) |
| `OPENAI_API_KEY` | obrigatória para `/v1/chat` |
| `OPENAI_MODEL` | default `gpt-4o-mini` |
| `CATALOG_PUBLIC_URL` | links `catalogUrl` / CTA |
| `SELLER_1_PHONE` | presente no config; **não usada** no código atual (handoff same-thread) |
| `SELLER_2_PHONE` | idem |
| `INVENTORY_CACHE_TTL_MS` | default 60000 |
| `REDIS_URL` | opcional — memória de thread |
| `CORS_ORIGINS` | CSV |

`OPENAI_API_KEY` **não** vai para Vercel do catálogo nem para o bot.

### 7.3 `almotos-front`

| Variável | Uso |
|----------|-----|
| `NEXT_PUBLIC_API_URL` | origem do SoR (documentada) |
| `BACKEND_URL` | prioridade no proxy (server-only, Vercel) |
| `API_URL` | fallback do proxy |
| `NODE_ENV` | warn se prod sem API URL |

### 7.4 `almotos-catalog`

| Variável | Uso |
|----------|-----|
| `ALMOTOS_AI_URL` | **obrigatória em produção** (BFF chat + inventory) |
| `KOTLIN_BASE_URL` | fallback **dev** direto ao SoR |
| `NEXT_PUBLIC_WHATSAPP_URL` | telefone/CTA wa.me |
| `NEXT_PUBLIC_SITE_URL` | sitemap / OG |

Não usar `NEXT_PUBLIC_API_BASE_URL` (nome antigo, o código não lê).

### 7.5 `almotos-ai-bot`

| Variável | Canal |
|----------|--------|
| `HOST`, `PORT`, `DEBUG` | servidor |
| `ALMOTOS_AI_URL` | orquestrador (**obrigatória**) |
| `CHATWOOT_BASE_URL` | produção |
| `CHATWOOT_API_TOKEN` | produção |
| `CHATWOOT_ACCOUNT_ID` | default 1 |
| `CHATWOOT_DEBOUNCE_SECONDS` | default 4 |
| `WHATSAPP_VERIFY_TOKEN` | legado Meta GET `/webhook` |
| `WHATSAPP_ACCESS_TOKEN` | legado Graph API |
| `WHATSAPP_PHONE_NUMBER_ID` | legado |
| `WHATSAPP_API_VERSION` | default `v21.0` |
| `WHATSAPP_APP_SECRET` | HMAC; sem secret e `DEBUG=false` o POST Meta retorna 403 |
| `EVOLUTION_API_URL` | legado |
| `EVOLUTION_API_KEY` | legado |
| `EVOLUTION_INSTANCE` | legado |
| `EVOLUTION_WEBHOOK_SECRET` | token da instância (body) |
| `EVOLUTION_WEBHOOK_AUTH_REQUIRED` | default `false` |

**Removidas / não usar neste serviço:** `OPENAI_API_KEY`, `VEHICLES_API_URL`, `VEHICLES_API_TOKEN`.

### 7.6 GitHub Actions (nomes)

Secrets/vars do workflow: `GH_PAT`, `RAILWAY_TOKEN` (ou `RAILWAY_TOKEN_BACKEND` / `_AI` / `_BOT`), `RAILWAY_PROJECT_ID`, `RAILWAY_ENVIRONMENT`, `RAILWAY_SERVICE_BACKEND`, `RAILWAY_SERVICE_AI`, `RAILWAY_SERVICE_BOT`, `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID_FRONT`, `VERCEL_PROJECT_ID_CATALOG`.

Runtime de OpenAI/Chatwoot/DB **não** entra na pipeline — fica nos painéis Railway/Vercel.

---

## 8. Estado Atual e Funcionalidades

### 8.1 Concluído e em produção

- Cutover SoR Kotlin → FastAPI (2026-08-20); domínio `api.almotoscaruaru.com.br`.
- PK UUID em veículos; placa UNIQUE e editável.
- FIPE, preço sugerido, tags INTERNAL/PUBLIC.
- Contatos unificados + consignação (`OWN`/`THIRD_PARTY`) + repasse manual + lucro da loja.
- Relatórios que somam próprio, terceiros e repasses.
- Cancelamento de venda com commit correto (fix 2026-08-21) e estorno de caixa por `source_sale_id` (2026-09-10).
- Edição de lançamentos de caixa e edição de contato na listagem (2026-09-10).
- Catálogo: landing Instagram, `/estoque`, multi-domínio, tema, rodapé LGPD, fotos S3 regionais no `next/image`.
- Assistente web com Generative UI (sem dump Markdown).
- Bot Chatwoot: debounce 4s, anexos de foto, preço de tabela antes do handoff, busca fuzzy, handoff na mesma conversa, anti-loop.
- CI/CD do monorepo por submodule (SoR → AI → clientes).
- CRUD de usuários internos + troca de senha.
- Kotlin **fora** do monorepo; `personal-finance` fora do painel.

### 8.2 Legado presente no código (não é o caminho feliz)

| Item | Estado |
|------|--------|
| `GET/POST /webhook` Meta no bot | Transição; Chatwoot é a inbox |
| Evolution inbound/outbound | Silenciado se Chatwoot configurado |
| `app/models/vehicles.py` no bot | Código morto (Kotlin direto) |
| `SELLER_*_PHONE` no `almotos-ai` | Não referenciadas nas tools atuais |
| `ProtectedRoute` no admin | Não usado |
| Métodos `api.sales.lucroTotal` / `vendasPorMarca` / `veiculosDoCliente` | Client órfão; SoR FastAPI não expõe |
| Env `KOTLIN_BASE_URL` / arquivo `kotlin-client.ts` | Nome histórico; aponta ao FastAPI |
| README raiz / README do front | Parcialmente defasados (Kotlin, `/webhook` Meta, “Clientes”, TODOs já feitos) |

### 8.3 Parcial / débito técnico relevante

- **Edição de venda/compra/troca na UI:** API tem `PUT`; telas só cancelam.
- **Delete de veículo/contato na UI:** API existe; painel não expõe.
- **Trocas** sem busca textual.
- **Tags:** sem CRUD isolado.
- **`transaction_history`:** só escrita.
- **`/financial/movements`:** carrega o conjunto em memória antes de paginar (risco com volume alto).
- **Schema baseline** pré-001 não está versionado no Alembic; `001` sem downgrade.
- **Auth do admin** só no cliente (JWT no `localStorage`); middleware Next não enforce.
- **RBAC** limitado: só `/users` exige ADMIN; resto do ERP é “qualquer autenticado”.
- **Exportação** PDF/Excel de relatórios: não implementada.
- **Testes automatizados** no front/catálogo/bot: praticamente só SoR tem pytest; bot tem compileall + import smoke; AI tem `tsc`; fronts têm lint+build.
- **`personal-finance/`** local: changelog diz gitignore; a pasta pode aparecer untracked — não faz parte do produto.
- **`index.html`** de teste do bot pode carregar widget Chatwoot de produção — não usar como página pública.
- Pacing/presence Evolution (“digitando”) foi **removido** em 2026-09-08 de propósito (Meta via Chatwoot).

### 8.4 O que não está no escopo atual

- Locação/aluguel de motos.
- Pagamentos online, boleto, PIX, gateway.
- Cálculo de parcela/financiamento (copy 48x/18x + handoff humano).
- Oficina, revisão, estoque de peças.
- Segundo writer no Postgres ou Redis de inventário.
- Kotlin como API viva no mesmo banco.

### 8.5 Como operar localmente (ordem)

1. `almotos-backend`: `docker compose up -d` → `.env` → `uv sync` → `alembic upgrade head` → uvicorn `:8081`.
2. `almotos-ai`: `KOTLIN_BASE_URL=http://localhost:8081` + `OPENAI_API_KEY` → `:3100`.
3. Admin: `NEXT_PUBLIC_API_URL=http://localhost:8081` → `:3000`.
4. Catálogo: `ALMOTOS_AI_URL=http://localhost:3100` → `:3001`.
5. Bot: `ALMOTOS_AI_URL` + Chatwoot → `:8000`.

Clone: `git clone --recurse-submodules` (ou `git submodule update --init --recursive`). Commit do dia a dia **dentro** do submodule; o pai só atualiza o SHA.

### 8.6 Fontes canônicas vs. este arquivo

| Pergunta | Onde olhar |
|----------|------------|
| O que um agente **pode** fazer | `docs/ai/CLAUDE.md` |
| O que mudou ontem | `docs/ai/CHANGELOG.md` |
| Contrato HTTP vivo | `almotos-backend` + `/docs` |
| Prompt do bot | `almotos-ai/src/chat/system-prompt.ts` |
| Estado consolidado | **este arquivo** |

Após mudança de contrato, ADR ou tool MCP, atualizar `docs/ai/CHANGELOG.md` (ADR-005) e rever as seções 4–8 daqui.
