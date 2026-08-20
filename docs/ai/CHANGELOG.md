# AI Changelog — AL Motos

Memória contínua do agente (ADR-005). Entradas em ordem inversa (mais recente primeiro).

## 2026-08-20 — Admin: identidade do catálogo + edição de veículo (placa)

- **Arquivos modificados:** `almotos-front/src/app/**`; `almotos-front/src/components/ui/**`; `almotos-front/src/components/forms/form-veiculo.tsx`; `almotos-front/src/components/layout/**`; `almotos-front/tailwind.config.ts`; `almotos-front/src/lib/validations/schemas.ts`
- **Por que:** o SoR já aceita `PUT /vehicles/{placaAtual}` com placa nova no body (UUID interno). O painel passou a expor essa edição e adotou os tokens do catálogo (canvas/brand, DM Sans + Syne só no H1), sem copiar o layout de vitrine — input `rounded-xl`, botão pílula, laranja só em CTA e nav ativo.

## 2026-08-20 — CI: credencial no `git submodule update`

- **Arquivos modificados:** `.github/workflows/ci-cd.yml`
- **Por que:** o clone do submodule não usa o extraheader local do `actions/checkout`. Sem token, o Git pede usuário no runner (`could not read Username for 'https://github.com'`). O step passa a autenticar com `GH_PAT` via `url.*.insteadOf` e limpa o config depois.

## 2026-08-20 — PK UUID em `vehicles`; placa vira UNIQUE

- **Arquivos modificados:** `almotos-backend/alembic/**`; `almotos-backend/src/almotos_backend/models/{vehicle,commerce,finance,base}.py`; `services/{vehicles,purchases,sales,exchanges,costs,vehicle_history,movements}.py`; `routers/vehicles.py`; `tests/**`; `Dockerfile`; `railway.json`; `almotos-front/src/lib/api.ts`; `docs/ai/CLAUDE.md` (ADR-001)
- **Por que:** a placa como PK espalhava FKs varchar e impedia correção de placa. `vehicles.id` UUID passa a ser a PK; filhas apontam para esse id. Lookup HTTP continua por placa (`GET/PUT /vehicles/{placa}`). Alembic aplica o DDL no release; o app **MUST NOT** rodar upgrade/`create_all` no startup.

## 2026-08-20 — CI: checkout de um submodule por job

- **Arquivos modificados:** `.github/workflows/ci-cd.yml`
- **Por que:** `submodules: recursive` clonava todos os filhos. Fine-grained `GH_PAT` sem `almotos-backend` na allowlist devolve 403 (`Write access to repository not granted`) e derruba também o CI do bot/front. Cada job agora faz `git submodule update --init` só da pasta que usa.

## 2026-08-20 — Bot: webhook Chatwoot (caixa omnichannel)

- **Arquivos modificados:** `almotos-ai-bot/app/models/chatwoot.py`; `app/routes/chatwoot.py`; `app/services/chatwoot_client.py`; `app/services/chatwoot_chat_service.py`; `app/config.py`; `app/main.py`; `docs/ai/CLAUDE.md`
- **Por que:** o Chatwoot passou a ser a inbox; o bot deixa de falar direto com a Cloud API da Meta no caminho novo. Webhook `POST /webhook/chatwoot` ignora `outgoing` e eventos ≠ `message_created` (anti-loop). Resposta sai via API Chatwoot; a IA continua só no `almotos-ai` (ADR-003).

## 2026-08-20 — Tutoriais e notas temporárias em `docs/scratch`

- **Arquivos modificados:** `.gitignore`; `.cursor/rules/docs-scratch.mdc`; `README.md`; `docs/ai/` (só `CLAUDE.md` e `CHANGELOG.md` permanecem)
- **Por que:** tutoriais, planos e dumps de design não entram no git. Pasta local `docs/scratch/` (ignorada). Agentes seguem a regra Cursor `docs-scratch`.

## 2026-08-20 — Tutorial de submódulos: só no pai + recuperação

- **Arquivos modificados:** `docs/ai/TUTORIAL_SUBMODULOS.md`
- **Por que:** `git submodule add` dentro de `almotos-front` aninha o SoR no painel. O tutorial agora manda conferir o cwd, atualizar ponteiro após amend, e limpar config + cache em `.git/modules/...` se o add rodou no filho.

## 2026-08-20 — Kotlin sai do monorepo; CI/CD e submodule do SoR FastAPI

- **Arquivos modificados:** `.github/workflows/ci-cd.yml`; `.gitmodules`; `README.md`; `docs/ai/TUTORIAL_SUBMODULOS.md`; `docs/ai/CLAUDE.md`; `almotos-backend/docker-compose.yml`
- **Por que:** o SoR em produção já é o FastAPI. O pai deixa de clonar/buildar o Kotlin; `almotos-backend` vira submodule como os outros produtos. Compose de Postgres local muda para a pasta do FastAPI. Tutorial em `docs/ai/TUTORIAL_SUBMODULOS.md`.

## 2026-08-20 — Fase 10: cutover SoR Kotlin → FastAPI (produção)

- **Arquivos modificados:** `docs/ai/CLAUDE.md` (ADR-001); `docs/ai/PLANO_MIGRACAO_KOTLIN_FASTAPI.md`; `README.md`; `docs/ai/GUIA_NAVEGACAO_CODIGO.md`; `docs/ai/SYSTEM_DESIGN_FDE.md`
- **Por que:** o FastAPI (`almotos-backend`) assumiu o Postgres e o domínio `api.almotoscaruaru.com.br`. O Kotlin fica em standby para rollback. `almotos-ai` continua sem JDBC; o contrato HTTP (JWT, catálogo público, painel) não muda. Schema intocado (zero DDL).

## 2026-08-20 — Fases 3–9: API FastAPI completa (sem cutover)

- **Arquivos modificados:** `almotos-backend/**`; `tests/test_domain.py`; `tests/test_http_contract.py`; `.github/workflows/ci-cd.yml`; `docs/ai/PLANO_MIGRACAO_KOTLIN_FASTAPI.md`
- **Por que:** portar o contrato HTTP do SoR Kotlin (veículos, catálogo público, S3, parceiros, compra/venda/troca, custos, caixa, relatórios) para FastAPI sem DDL. Produção continua no Kotlin (ADR-001) até a Fase 10.

## 2026-08-20 — Fase 2: ORM (schema existente) + login JWT

- **Arquivos modificados:** `almotos-backend/src/almotos_backend/models/**`; `security/**`; `routers/auth.py`; `services/auth.py`; `schemas/auth.py`; `tests/test_auth.py`; `tests/test_jwt.py`; `docs/ai/PLANO_MIGRACAO_KOTLIN_FASTAPI.md`
- **Por que:** mapear as tabelas do Postgres sem DDL; autenticar com o mesmo JWT do Kotlin (HS256 + SHA-256 do secret) e BCrypt `$2a$`, para dual-run sem deslogar. O Kotlin permanece o writer até o cutover (ADR-001).

## 2026-08-20 — Fase 1: esqueleto FastAPI do SoR (`almotos-backend`)

- **Arquivos modificados:** `almotos-backend/**`; `docs/ai/PLANO_MIGRACAO_KOTLIN_FASTAPI.md`; `.gitignore`
- **Por que:** iniciar a migração Kotlin → FastAPI com app, Settings, engine async (`SELECT 1`), CORS, `/health` e exception handlers, **sem** `create_all`/Alembic. O Kotlin permanece o único writer do Postgres (ADR-001) até o cutover.

## 2026-08-17 — Chat web: texto curto + Generative UI (sem dump Markdown)

- **Arquivos modificados:** `almotos-ai/src/chat/system-prompt.ts`; `almotos-catalog/src/components/assistant/assistant-widget.tsx`
- **Por que:** O modelo reescrevia o estoque em Markdown (`![foto]`, listas, `catalogUrl`) e o widget pintava a string crua, colapsando quebras. O canal site agora proíbe esse dump; a UI esconde o parágrafo se a tool já renderizou cards/fotos/handoff. Contrato das tools não muda (ADR-003).

## 2026-08-15 — Pipeline CI/CD no repositório pai (GitHub Actions)

- **Arquivos modificados:** `.github/workflows/ci-cd.yml`
- **Por que:** O monorepo passou a orquestrar CI/CD condicional por submodule (paths-filter), com CD na ordem Kotlin → `almotos-ai` → front/catálogo/bot, para não publicar clientes MCP antes do SoR/ACL. Secrets de Vercel/Railway ficam no GitHub; variáveis de runtime (`OPENAI_API_KEY`, `ALMOTOS_AI_URL`, etc.) continuam nos painéis de deploy, não na pipeline.

## 2026-08-15 — README do monorepo alinhado ao MCP e aos 5 submódulos

- **Arquivos modificados:** `README.md`
- **Por que:** O README precisava descrever o fluxo real (catálogo/bot → `almotos-ai` → Kotlin; admin fora do MCP), portas, env corretas (`ALMOTOS_AI_URL`, sem `NEXT_PUBLIC_API_BASE_URL`) e o GET público aditivo, para onboarding e operação sem reler o changelog.

## 2026-08-15 — Checklist de variáveis pós-MCP (catálogo 502)

- **Arquivos modificados:** `docs/ai/ENV_CHECKLIST.md`, `DEPLOY_PROD.local.md`
- **Por que:** O catálogo em produção devolve 502 `fetch failed` porque o BFF passou a ler `ALMOTOS_AI_URL` / `KOTLIN_BASE_URL`, enquanto a Vercel ainda tem `NEXT_PUBLIC_API_BASE_URL` (nome antigo, não lido). O Kotlin responde 200; o gap é normalização de env entre os 5 serviços. O checklist lista, por painel, o que manter, adicionar, apagar e como validar com curl.

## 2026-08-15 — Adequação dos submódulos ao MCP (API aditiva, thin clients)

- **Arquivos modificados:** `vehicle-sales-manager-v2-kotlin` (`PublicVehicleController`, `VehicleService`, `VehicleRepository`); `almotos-ai` (`kotlin-client.ts`, `search-inventory.ts`, `railway.json`); `almotos-catalog` (`src/lib/catalog.ts`); `almotos-front` (`src/lib/api.ts`); `almotos-ai-bot` (thin client `/v1/chat`, remoção de `openai_service`/`vehicles_api`); `.gitignore`
- **Por que:** O GET público do SoR passou a aceitar filtros opcionais (`brand`, `maxKm`, `yearMin`) e `Cache-Control`, sem mudar o JSON. O MCP encaminha esses params e não cacheia falha do Kotlin. Catálogo exige `ALMOTOS_AI_URL` em produção (ADR-003). Admin passou a usar `GET /vehicles/{placa}` já existente. Bot deixou de chamar OpenAI/Kotlin. Estratégia de go-live ficou em `DEPLOY_PROD.local.md` (fora do git).

## 2026-08-15 — README do monorepo alinhado aos 5 submódulos

- **Arquivos modificados:** `README.md`
- **Por que:** O README ainda descrevia só Kotlin + `almotos-front` e apontava para guias removidos (`SUBMODULES_GUIDE.md`, `VERCEL_RAILWAY_ATUALIZADO.md`). Passou a documentar catálogo, orquestrador MCP, bot WhatsApp, o fluxo de dados obrigatório e o clone com `--recurse-submodules`.

## 2026-08-15 — Isolamento do orquestrador AI (MCP) e governança RFC 2119

- **Arquivos modificados:** `CLAUDE.md`, `docs/ai/CHANGELOG.md`
- **Por que:** A inteligência do produto foi isolada em `almotos-ai` (MCP Server em Node.js/TypeScript) como Anti-Corruption Layer, para que catálogo e WhatsApp sejam thin clients e o Kotlin permaneça o único System of Record. O `CLAUDE.md` passou a ser o documento canônico de guardrails, com palavras-chave RFC 2119, para impedir que agentes violem persistência, PII ou lógica de LLM fora do orquestrador.
