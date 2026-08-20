# Plano de Migração — SoR Kotlin → FastAPI (AL Motos)

**Status:** Fase 10 concluída (2026-08-20). SoR em produção: `almotos-backend` (FastAPI) em `api.almotoscaruaru.com.br`. Kotlin em standby.  
**Data:** 2026-08-20  
**Escopo:** substituir `vehicle-sales-manager-v2-kotlin` como System of Record, **sem alterar o PostgreSQL de produção**.  
**Fora de escopo nesta migração:** `almotos-ai`, `almotos-catalog`, `almotos-front`, `almotos-ai-bot` (só consomem o contrato HTTP; mudam no cutover se o host/env mudar).

---

## 1. Análise de contexto (o que o Kotlin realmente faz)

O backend Spring Boot 3.2 / Kotlin é o **único writer do Postgres**. Painel (`almotos-front`) fala JWT; catálogo e WhatsApp **nunca** falam com o banco — passam por `almotos-ai` → `GET /api/public/vehicles`.

### 1.1 Domínio e invariantes (não negociáveis)

| Evento | Efeito de estoque | Efeito de vitrine | Financeiro |
|---|---|---|---|
| Compra criada | veículo → `DISPONIVEL` | — | entra em totais se `status=ACTIVE` e `deleted=false` |
| Compra cancelada | veículo → `INACTIVE` | `published` forçado `false` se deixar de estar `DISPONIVEL` | some dos relatórios |
| Venda criada | veículo → `VENDIDO` | `published=false` | crédito |
| Venda cancelada / DELETE | veículo → `DISPONIVEL` | — | some dos relatórios |
| Troca criada | saída → `VENDIDO`; entrada → `DISPONIVEL` | saída despublicada | `diferencaValor` (sinal define ENTRY/EXIT) |
| Troca cancelada | só a **saída** volta a `DISPONIVEL` | — | some dos relatórios |
| Custo de veículo | — | — | débito (soft delete) |
| Transação da loja | — | — | ENTRY/EXIT + categoria |

Regra transversal em `VehicleService.updateVehicleStatus` / `updateCatalog` / `updateVehicle`:

> Se `status != DISPONIVEL` e `published == true`, **forçar** `published = false`. A vitrine some sem cron.

Parceiro: PK é `document` (CPF 11 ou CNPJ 14 dígitos, sanitizado). Compra/venda exigem parceiro **já cadastrado**. Troca tenta o documento do body; se vazio, usa o parceiro da última venda do veículo de entrada.

Histórico (`transaction_history`) é append-only: `CREATED` / `EDITED` / `CANCELLED` para `PURCHASE`, `SALE`, `EXCHANGE`, `STORE_TRANSACTION`.

### 1.2 Superfície HTTP que precisa ser binária-compatível

O painel e o `almotos-ai` já estão em produção. O FastAPI **MUST** preservar path, método, query, status code e JSON **camelCase**.

**Público (sem JWT)**

| Método | Path | Notas |
|---|---|---|
| POST | `/api/auth/login` | `{ token, username, role }` |
| GET | `/api/public/vehicles` | `brand`, `maxKm`, `yearMin`; só `DISPONIVEL` + `published=true`; **sem placa/preço/CPF**; `Cache-Control: public, max-age=30` |
| OPTIONS | `/**` | CORS preflight |

**Autenticado (Bearer JWT)**

| Método | Path |
|---|---|
| GET/POST/PUT | `/vehicles` |
| GET | `/vehicles/available`, `/vehicles/{placa}`, `/vehicles/{placa}/history` |
| PATCH | `/vehicles/{placa}/catalog` |
| POST | `/api/vehicles/images/upload` (multipart `file` → `{ url }`) |
| GET/POST | `/vehicles/{placa}/costs` |
| DELETE | `/vehicles/{placa}/costs/{id}` |
| GET/POST | `/partners` |
| GET/PUT | `/partners/{document}` |
| GET/POST | `/sales`, `/purchases`, `/exchanges`, `/store-transactions` |
| PUT / POST cancel / DELETE | `/{recurso}/{id}` (+ query `deleteVehicle` / `deleteIncomingVehicle`) |
| GET | `/reports/dashboard`, `/reports/financial` |
| GET | `/financial/movements` |

Paginação Spring Data (o front já espera isto):

```json
{ "content": [], "totalElements": 0, "totalPages": 0, "size": 20, "number": 0, "first": true, "last": true }
```

Query: `page`, `size`, `sort=campo,desc` (0-based).

Jackson atual: `NON_NULL` + `fail-on-unknown-properties: false`. Datas `java.util.Date` saem em ISO-8601 (Spring Boot desliga timestamps). O FastAPI **MUST** omitir nulos e aceitar campos extras no input.

### 1.3 O que NÃO traduzir 1:1 (sotaque JVM)

- `StockEffectStrategy` / `SaleStockEffect` / `PurchaseStockEffect` → funções no service (`_marcar_vendido`, `_marcar_disponivel`).
- Repositórios Spring Data como interfaces → queries SQLAlchemy no próprio service (ou funções `select` no módulo do domínio). Sem camada Repository vazia.
- `try/catch` em cada controller → `HTTPException` + exception handlers globais.
- `@Lazy` / fábricas / `ABC` extras.
- `FinancialMovementService` hoje carrega **tudo** em memória e pagina depois. Na Fase 8 podemos manter o comportamento; otimizar SQL é opcional e posterior, sem mudar o JSON.

### 1.4 Lacunas do cliente (não implementar “porque o front declara”)

O `almotos-front` chama rotas que **não existem** no Kotlin atual (`DELETE /vehicles/{placa}`, `DELETE /partners/{document}`, `GET /sales/search`, `/sales/vehicles`, `/sales/salesPerBrand`, `/sales/profit`). A migração replica o **SoR real**, não o client morto.

---

## 2. Decisões de stack (alvo)

| Tema | Escolha | Por quê |
|---|---|---|
| Web | FastAPI async + Uvicorn | Pedido; footprint menor que JVM no Railway |
| ORM | **SQLAlchemy 2.0** (`ext.asyncio` + `AsyncSession`) | Schema legado com FKs “mentirosas” e `ElementCollection`; SQLModel mistura tabela e JSON e atrapalha camelCase |
| Schemas | Pydantic v2, `alias_generator` camelCase + `populate_by_name` | Contrato do painel/AI |
| Settings | `pydantic-settings` | Igual ao bot; lê as **mesmas** env do Kotlin (`DB_*`, `JWT_*`, `AWS_*`, `CORS_*`) |
| Deps | **`uv` + `pyproject.toml`** | Mais enxuto e reprodutível que Poetry; gera lock. `requirements.txt` só como export se o Railway exigir |
| Auth | PyJWT HS256 + bcrypt (`pwdlib`/`passlib`) | Compatível com hashes Spring e com o truque SHA-256 do `JwtService` |
| Testes | `pytest` + `httpx.AsyncClient` + Postgres de teste (Docker) | SQLite mente demais (identity, enums, timestamps) |
| Migrations | **Nenhuma Alembic de create** | `create_all` desligado; modelos só mapeiam o existente |

JWT **MUST** repetir o Kotlin:

```text
key = SHA-256(JWT_SECRET UTF-8)
alg = HS256
claims = sub=username, role, iat, exp
```

Senha: BCrypt Spring (`$2a$`) é verificável no Python. Não rehashar usuários existentes no cutover.

---

## 3. Nova estrutura de diretórios

Novo serviço no monorepo (irmão do Kotlin, **não** misturar com `almotos-ai-bot`):

```text
almotos-backend/
├── pyproject.toml
├── uv.lock
├── Dockerfile
├── railway.json
├── .env.example
├── README.md
├── src/almotos_backend/
│   ├── main.py                 # FastAPI(), CORS, handlers, routers
│   ├── config.py               # Settings
│   ├── db.py                   # engine async, sessionmaker, get_session
│   ├── deps.py                 # Depends: sessão, usuário JWT
│   ├── exceptions.py           # NotFoundError, ConflictError, ...
│   ├── pagination.py           # Page query + JSON estilo Spring
│   ├── security/
│   │   ├── jwt.py
│   │   └── passwords.py
│   ├── models/                 # SQLAlchemy Mapped — 1:1 com o Postgres
│   │   ├── base.py
│   │   ├── vehicle.py
│   │   ├── partner.py
│   │   ├── commerce.py         # Purchase, Sale, Exchange
│   │   ├── finance.py          # VehicleCost, StoreTransaction, TransactionHistory
│   │   └── user.py
│   ├── schemas/                # Pydantic (JSON camelCase)
│   │   ├── common.py
│   │   ├── auth.py
│   │   ├── vehicle.py
│   │   ├── partner.py
│   │   ├── commerce.py
│   │   └── finance.py
│   ├── routers/
│   │   ├── auth.py
│   │   ├── public_vehicles.py
│   │   ├── vehicles.py
│   │   ├── vehicle_images.py
│   │   ├── partners.py
│   │   ├── purchases.py
│   │   ├── sales.py
│   │   ├── exchanges.py
│   │   ├── store_transactions.py
│   │   ├── reports.py
│   │   └── financial_movements.py
│   ├── services/               # regras de negócio (funções/módulos, sem ABC)
│   │   ├── auth.py
│   │   ├── vehicles.py
│   │   ├── stock.py            # efeitos DISPONIVEL/VENDIDO/INACTIVE + published
│   │   ├── partners.py
│   │   ├── purchases.py
│   │   ├── sales.py
│   │   ├── exchanges.py
│   │   ├── costs.py
│   │   ├── store_transactions.py
│   │   ├── history.py
│   │   ├── reports.py
│   │   └── s3.py
│   └── utils/
│       └── documents.py        # DocumentUtils
└── tests/
    ├── conftest.py
    ├── test_auth.py
    ├── test_public_catalog.py
    ├── test_stock_invariants.py
    └── ...
```

**Por que híbrido (models globais + routers por domínio):** o grafo de FKs é um único aggregate (Partner ↔ Vehicle ↔ Sale/Purchase/Exchange). Separar `src/inventory` e `src/sales` como pacotes isolados duplicaria imports e pioraria o mapeamento. Routers/services por domínio já dão modularidade FastAPI sem fingir bounded contexts.

---

## 4. Mapeamento Kotlin → FastAPI

### 4.1 Camadas

| Kotlin | FastAPI |
|---|---|
| `@SpringBootApplication` + `main` | `src/almotos_backend/main.py` |
| `application-*.yml` | `config.Settings` (`pydantic-settings`) |
| `@RestController` | `APIRouter` + `Depends` |
| `@Service` | módulo em `services/` (funções + classes simples) |
| `JpaRepository` | `select()` / `session.execute()` no service |
| `@Entity` | `MappedAsDataclass` / `DeclarativeBase` com `mapped_column` **explícito** |
| DTO `data class` | Pydantic `BaseModel` (`serialization_alias`) |
| `JwtAuthenticationFilter` | dependência `get_current_user` + middleware só para 401 |
| `SecurityConfig` | rotas públicas registradas sem `Depends`; resto com JWT |
| `CorsConfig` | `CORSMiddleware` |
| `@ControllerAdvice` (ausente; try/catch local) | `exception_handler` global |
| `S3Service` + `S3Config` | `boto3`/`aioboto3` no service de upload |
| `InitialDataLoader` | startup hook: se `users` vazio, cria admin (`ADMIN_USERNAME` / `ADMIN_PASSWORD`) |
| Flyway `V1` | **não portar** — já rodou em produção |
| Hibernate `ddl-auto: validate` | nunca `create_all`; opcional `alembic check` só no CI, sem upgrade |

### 4.2 Tabelas e colunas (contrato de persistência)

Hibernate / Spring Boot 3 usa `CamelCaseToUnderscoresNamingStrategy`. Onde não há `@Column(name=...)`, o nome físico é snake_case. **Antes de cravar os modelos, a Fase 0 confirma no banco real** (`information_schema`). Mapa esperado:

#### `vehicles` — PK `license_plate` (varchar)

| Python attr | Coluna | Tipo esperado |
|---|---|---|
| `license_plate` | `license_plate` | varchar PK |
| `brand` | `brand` | varchar (`HONDA`, `YAMAHA`, …) |
| `model_name` | `model_name` | varchar NOT NULL |
| `manufacture_year` | `manufacture_year` | int |
| `model_year` | `model_year` | int |
| `color` | `color` | varchar |
| `kilometers_driven` | `kilometers_driven` | int |
| `published` | `published` | boolean |
| `description` | `description` | varchar(1000) NULL |
| `status` | `status` | varchar (`DISPONIVEL`/`VENDIDO`/`INACTIVE`) |
| `created_at` | `created_at` | timestamp NOT NULL |

`inStock` **não é coluna** — é `status == DISPONIVEL` no schema de resposta.

#### `vehicle_images` (`@ElementCollection`)

| Coluna | Notas |
|---|---|
| `vehicle_license_plate` | FK lógica para `vehicles.license_plate` |
| `image_url` | varchar(1000) NOT NULL |

Sem `@OrderColumn`: a ordem das fotos **não é garantida** no banco. Mapear como `list[str]` via relationship/`selectinload`, sem inventar coluna `order`.

#### `addresses`

`id` identity; `street_name` **nullable**; `number`, `city`, `state`, `zip_code` NOT NULL; `reference` nullable.

#### `partners` — PK `document`

Coluna foi `cpf` → Flyway `V1` renomeou para `document`. Não reaplicar.  
`phone_number1`, `phone_number2`; `address_id` FK para `addresses`.

**Não** carregar `sales`/`purchases`/`exchanges` em cascade estilo JPA `OneToMany` no Partner — isso é o sotaque Hibernate. Contar com `COUNT` nas queries de detalhe.

#### `purchases` / `sales`

| Coluna JPA | Conteúdo real |
|---|---|
| `id` | identity bigint |
| `vehicle_id` | **placa** (varchar), não um int |
| `partner_id` | **document** (varchar), não um int |
| `purchase_price` / `sale_price` | `float8` (Double Java — **não** `Numeric`) |
| `purchase_date` / `sale_date` | timestamp |
| `deleted` | boolean |
| `status` | `ACTIVE` / `CANCELLED` |

#### `exchanges`

`vehicle_entrada_id`, `vehicle_saida_id` (placas); `partner_id` (document); `diferenca_valor` float8; `exchange_date`; `deleted`; `status`.

#### `vehicle_costs`

`vehicle_license_plate` (placa); `cost` float8; `description`; `cost_date`; `deleted`.

#### `store_transactions`

`description` TEXT; `value` float8; `date`; `type` (`ENTRY`/`EXIT`); `category` (enums de loja); `status`; `deleted`.

#### `transaction_history`

`transaction_type` com CHECK que **precisa** incluir `STORE_TRANSACTION` (já houve incidente; ver `scripts/fix-transaction-history-constraint.sql`). Não dropar/recriar a constraint.

#### `users`

`username` unique; `password` BCrypt; `role` (`ADMIN`/`USER`).

#### Tabelas de infraestrutura (não mapear como domínio)

`flyway_schema_history` — read-only, não tocar.

### 4.3 Enums (valores literais no banco)

Copiar os **nomes** Kotlin, não traduzir:

- `VehicleBrand`: `TOYOTA` … `KTM` (inclui `MERCEDES_BENZ`, `BMW_MOTORRAD`, `HARLEY_DAVIDSON`)
- `VehicleStatus`: `DISPONIVEL`, `VENDIDO`, `INACTIVE`
- `TransactionStatus`: `ACTIVE`, `CANCELLED`
- `TransactionType` (histórico): `PURCHASE`, `SALE`, `EXCHANGE`, `STORE_TRANSACTION`
- `TransactionTypeEnum` (caixa): `ENTRY`, `EXIT`
- `TransactionCategory`: `OPERACIONAL`, `ADMINISTRATIVO`, `MARKETING`, `INFRAESTRUTURA`, `PESSOAL`, `SERVICOS_PRESTADOS`, `OUTROS`
- `ActionType`: `CREATED`, `EDITED`, `CANCELLED`
- `Role`: `ADMIN`, `USER`

No SQLAlchemy: `Enum(..., native_enum=False, length=…)` ou `String` — o Hibernate gravou **varchar**, não `CREATE TYPE`.

### 4.4 JSON (aliases)

Pydantic nos schemas de API, **não** nos models ORM:

```python
model_config = ConfigDict(populate_by_name=True, from_attributes=True)
# licensePlate ← license_plate, modelName ← model_name, etc.
```

DTO público (`PublicVehicleDTO`): `brand`, `model` (não `modelName`), `year` (= `model_year`), `color`, `kilometersDriven`, `imageUrlList`, `description`. Allowlist — nunca vazar placa/custo/preço.

---

## 5. Fases de execução

Cada fase termina com testes verdes e o Kotlin **ainda** no ar. Cutover só na Fase 10.

### Fase 0 — Congelar o schema real (somente leitura)

1. `pg_dump --schema-only` (ou `\d+` em cada tabela) do Postgres de **produção** e do local.
2. Diff contra a tabela da seção 4.2.
3. Anexar o dump em `docs/ai/schema_postgres_snapshot.md` (sem dados, sem secrets).
4. Decisão: se alguma coluna divergir (ex.: `images_order`, `cpf` residual, tipo `numeric`), o ORM segue o **banco**, não o Kotlin.

**Critério de pronto:** snapshot versionado; zero `ALTER`.

### Fase 1 — Esqueleto da aplicação

- `almotos-backend/` com `uv`, FastAPI, `Settings`, engine async (`postgresql+asyncpg`), `get_session`, CORS, health `GET /health`, exception handlers, Dockerfile (Python 3.12 slim), `railway.json`.
- **Não** ligar `create_all`. Smoke: sobe, conecta, `SELECT 1`.

**Critério de pronto:** `pytest` de health + conexão; app sobe no Docker.

### Fase 2 — Modelos ORM + auth

- Mapear **todas** as tabelas da seção 4.2.
- Teste de integração: `SELECT` em cada tabela (não precisa de fixture de negócio).
- JWT (SHA-256 do secret) + login + seed de admin se `users` vazio.
- Contrato: `POST /api/auth/login` idêntico; token gerado no Python deve ser aceito no Python; token gerado no Kotlin **SHOULD** ser aceito no Python (mesmo secret) para cutover sem deslogar.

**Critério de pronto:** login 200; 401 sem token nas rotas protegidas; OPTIONS 200.

### Fase 3 — Veículos, catálogo público, S3

- CRUD efetivo do `VehicleController` + `PATCH .../catalog` + histórico.
- `GET /api/public/vehicles` (filtros aditivos + cache header).
- Upload S3 (`POST /api/vehicles/images/upload`).
- Invariante `published`.

**Critério de pronto:** testes de catálogo (sem placa no JSON); `almotos-ai` apontando para o FastAPI **em local** lista estoque.

**Feito (2026-08-20):** rotas de veículos, catálogo público, upload S3 e histórico implementados. Dual-run local na porta 8081.

### Fase 4 — Parceiros

- Sanitizar documento; upsert; GET detalhe com counts (sem carregar coleções JPA).
- Validação de endereço (cidade/número/UF/CEP obrigatórios se address vier).

**Feito (2026-08-20):** CRUD de parceiros com sanitização de CPF/CNPJ.

### Fase 5 — Compras, vendas, trocas

- Transação SQLAlchemy (`session.begin()`).
- Efeitos de estoque na **mesma** transação que o insert.
- Soft-cancel + DELETE como no Kotlin (`deleteSale` → cancel; `deletePurchase` com `deleteVehicle`).
- `transaction_history` em cada create/edit/cancel.

**Critério de pronto:** testes de invariante (vender moto já vendida → 409/400; cancelar venda devolve `DISPONIVEL`; troca move os dois lados).

**Feito (2026-08-20):** compras, vendas e trocas com efeito de estoque na mesma transação.

### Fase 6 — Custos e fluxo de caixa da loja

- Costs nested em `/vehicles/{placa}/costs`.
- Store transactions + histórico com `STORE_TRANSACTION`.

**Feito (2026-08-20):** custos nested e transações da loja.

### Fase 7 — Relatórios e movimentações

- Dashboard e relatório (fórmulas atuais, inclusive `despesasOperacionais` só EXIT nas categorias OPERACIONAL/ADMINISTRATIVO/MARKETING/INFRAESTRUTURA).
- Movimentações unificadas (mesmo JSON; paginação pode continuar in-memory nesta fase).

**Feito (2026-08-20):** dashboard, relatório financeiro e movimentações.

### Fase 8 — Contrato com os clientes

- Suíte HTTP espelhando `almotos-front/src/lib/api.ts` (rotas que existem).
- Fixture Zod/`kotlinVehicleSchema` do `almotos-ai`.
- Comparar, em staging, um GET paginado Kotlin vs FastAPI (mesmo banco read-only).

**Feito (2026-08-20, local):** suíte HTTP de contrato (página Spring, catálogo sem placa, OpenAPI). Comparação lado a lado Kotlin vs FastAPI fica para o dual-run local do usuário.

### Fase 9 — Observabilidade e empacotamento

- Logs estruturados; `/health` (DB ping); OpenAPI (`/docs`); multipart 10MB.
- CI no workflow pai: path `almotos-backend/**` (espelhar job Kotlin: test → build image).

**Feito (2026-08-20):** job `ci-backend` no workflow pai (`uv run pytest`). Job `cd-backend` preparado; o primeiro serviço é criado no painel (mesmo Postgres, Kotlin permanece).

### Fase 10 — Cutover Railway (só após OK explícito)

1. Deploy FastAPI no **mesmo** Postgres (`ddl-auto`/Alembic off).
2. Smoke produção: login, listar veículos, GET público.
3. Repontar `KOTLIN_BASE_URL` do `almotos-ai` e o proxy do `almotos-front` para o novo host (o **nome** da env pode permanecer na Fase 10 para reduzir risco).
4. Kotlin em standby (não dropar o serviço no dia 0).
5. Atualizar ADR-001: SoR passa a ser o FastAPI; `almotos-ai` continua **sem** Postgres.
6. Entrada em `docs/ai/CHANGELOG.md` (ADR-005).

**Feito (2026-08-20):** FastAPI no mesmo Postgres; domínio `api.almotoscaruaru.com.br` no serviço novo; painel e catálogo público no FastAPI. Kotlin permanece no Railway sem o domínio customizado.

Rollback: DNS/host de volta ao Kotlin; banco intocado.

---

## 6. Riscos do banco existente

| Risco | Impacto | Mitigação |
|---|---|---|
| Colunas reais ≠ naming Hibernate (histórico `ddl-auto: update`) | App não lê/grava; pior: grava na coluna errada | Fase 0 obrigatória; `mapped_column` com nome físico literal |
| `vehicle_id` / `partner_id` guardam **strings** (placa/documento) | Join int quebraria FKs | `ForeignKey` varchar; nunca `Integer` nesses campos |
| `vehicle_images` sem ordem | Fotos “embaralham” no catálogo | Não inventar coluna; documentar bag semantics |
| `Double` Java → `double precision` | Centavos imprecisos (já é o caso hoje) | Mapear `Float`/`Double`; **não** migrar para `Numeric` (isso seria ALTER) |
| CHECK `transaction_history_transaction_type_check` incompleto em algum ambiente | INSERT de caixa 500 | Só **ler** a constraint; se faltar `STORE_TRANSACTION`, reportar — não aplicar SQL sem aprovação (exceção à regra “zero ALTER”, e só se o prod já estiver quebrado) |
| Sequences / `identity` vs `serial` | INSERT sem id falha | Usar `Identity()` alinhado ao `\d` da Fase 0 |
| `partners.cpf` residual se Flyway não rodou num clone | PK errada | Detectar na Fase 0; **não** rodar `V1` de novo se `document` já existe |
| Tipos `timestamp` vs `timestamptz` | Off-by-hours no painel | Espelhar o tipo real; serializar ISO-8601 |
| `flyway_schema_history` | Alembic “baseline” pode conflitar | Não usar Alembic no cutover |
| Dois writers (Kotlin + Python) no mesmo banco | Corrida em estoque | Cutover com **um** processo writer; dual-run só read no Python |
| JWT secret curto + SHA-256 | Tokens inválidos se o Python usar o secret cru | Portar o digest à risca |
| BCrypt rounds / `$2a$` vs `$2b$` | Login 401 | Verificar hash existente; não regravar senhas |
| `NON_NULL` no JSON | Front quebra se enviarmos `null` explícito | `response_model_exclude_none=True` |
| Paginação 0-based vs 1-based | Listas vazias no painel | Emular Spring (`page=0`) |
| `FinancialMovementService` full-scan | Timeout se o volume crescer | Comportamento igual na v1; otimizar depois |
| ADR-001 hoje diz “só o Kotlin fala com Postgres” | Agente futuro ligar Prisma no AI | Atualizar CLAUDE.md **no cutover**, não antes (durante o dual-run o Kotlin ainda é o writer) |

---

## 7. Variáveis de ambiente (reuso)

Manter os nomes do perfil `prod` para o Railway não mudar no dia 1:

- `PORT`, `DB_URL` (JDBC hoje → converter para DSN `postgresql+asyncpg://` **no código**, aceitando `jdbc:postgresql://` na env), `DB_USER`, `DB_PASSWORD`
- `JWT_SECRET`, `JWT_EXPIRATION` (ms)
- `CORS_ALLOWED_ORIGINS`
- `ADMIN_USERNAME`, `ADMIN_PASSWORD`
- `AWS_REGION`, `AWS_BUCKET_NAME`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`

Parser de `DB_URL`: se começar com `jdbc:`, strip do prefixo e montar URL asyncpg. Isso evita editar o painel Railway no cutover.

---

## 8. Governança

- Novo código **MUST NOT** conectar `almotos-ai` / catálogo / bot ao Postgres (ADR-001: só o `almotos-backend` é writer).
- Tools públicas continuam read-only e sem PII (ADR-002).
- Contrato `GET /api/public/vehicles` é aditivo: filtros opcionais, JSON antigo intacto (ADR-005 no cutover).
- Este arquivo é o playbook. Código só depois da aprovação da Fase 1 (a Fase 0 pode ser executada antes, porque é só leitura).

---

## 9. Ordem sugerida no chat, após aprovação

1. Confirmar snapshot (Fase 0) se ainda não houver dump.  
2. Implementar Fase 1 no diretório `almotos-backend/`.  
3. Parar de novo ao fim de cada fase e pedir OK para a seguinte.

**Não faremos nesta migração:** recriar tabelas, Alembic `upgrade head` vazio “para ter migração”, traduzir `StockEffectStrategy`, unificar SoR com o bot WhatsApp, mudar o front ou o MCP.
