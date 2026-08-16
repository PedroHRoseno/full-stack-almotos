# AI Changelog — AL Motos

Memória contínua do agente (ADR-005). Entradas em ordem inversa (mais recente primeiro).

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
