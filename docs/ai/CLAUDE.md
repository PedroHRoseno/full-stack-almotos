# CLAUDE.md — AL Motos AI Governance & Architecture

**Status:** Normativo  
**Audiência:** Agentes de IA (Cursor, Claude Code) e Engenheiros de Software  
**Objetivo:** Estabelecer Guardrails arquiteturais, AI-ADRs (Architecture Decision Records) e o protocolo de interação (RFC 2119) para o ecossistema AL Motos.

## 1. Terminologia e Rigor de Especificação (RFC 2119)

As palavras-chave **MUST**, **MUST NOT**, **SHOULD**, e **SHOULD NOT** neste documento devem ser interpretadas conforme a RFC 2119.
Agentes autônomos operando neste repositório **MUST** obedecer a estas restrições estritamente para prevenir alucinações arquiteturais e corrupção de dados.

---

## 2. Visão Geral da Arquitetura & Fluxo de Dados

A AL Motos opera em uma arquitetura distribuída, onde a inteligência artificial foi isolada em uma camada de orquestração (MCP) para proteger os dados sensíveis do negócio.

### Papéis dos Submódulos

1. **`almotos-backend` (Backend Core):** É o **System of Record (SoR)**. Única fonte da verdade. Contém regras de negócio, invariantes de estoque e persistência em PostgreSQL. FastAPI/Python; mapeia o schema existente **sem DDL**.
2. **`almotos-ai` (AI Orchestrator & MCP Server):** É a **Anti-Corruption Layer (ACL)**. Escrito em Node.js/TypeScript. Centraliza os prompts e expõe *Tools/Skills* seguras para os clientes via Model Context Protocol (MCP).
3. **`almotos-catalog` (Frontend Next.js):** Vitrine voltada ao cliente. Consome o MCP para oferecer experiências de *Generative UI*.
4. **`almotos-ai-bot` (FastAPI WhatsApp):** Atua apenas como um *Thin Client*. Repassa as intenções do usuário para o `almotos-ai`.
5. **`almotos-front` (Painel admin):** Next.js autenticado; fala com o SoR via `/api/proxy`. **MUST NOT** passar pelo MCP.

O Spring Boot legado (`vehicle-sales-manager-v2-kotlin`) **não** faz mais parte deste monorepo. O código permanece em repositório GitHub próprio, só para rollback no Railway. **MUST NOT** voltar a ser writer enquanto o FastAPI estiver no mesmo Postgres.

### O Fluxo Obrigatório (Guardrail de Acesso a Dados)

Qualquer interação orientada a IA **MUST** seguir o fluxo através do servidor MCP:

`Cliente (Web/WA) → Interface (Next.js/FastAPI) → Orquestrador AI (almotos-ai) → Tools MCP → SoR API (almotos-backend) → PostgreSQL`

---

## 3. Guardrails Arquiteturais (AI-ADRs)

Para manter a integridade e segurança do sistema, as seguintes decisões (ADRs) são vigentes e **MUST NOT** ser violadas pelo agente de IA:

### ADR-001: Isolamento de Persistência (SoR)
- **Decisão:** O `almotos-backend` (FastAPI) é o único writer do PostgreSQL. Cutover 2026-08-20; domínio `api.almotoscaruaru.com.br` aponta para esse serviço.
- **Guardrail:** O serviço `almotos-ai` (Node.js) e as interfaces (Next.js / bot WhatsApp) **MUST NOT** estabelecer um segundo writer nem conexões diretas (ex: Prisma, psycopg2) com o PostgreSQL. Eles **MUST** consumir os dados operacionais através da API REST do SoR. O agente **MUST NOT** criar bancos de dados paralelos (ex: Redis) para espelhar o estoque. O FastAPI **MUST NOT** rodar Alembic/`create_all` no schema de produção.

### ADR-002: Capability Scoping (Segurança de Tools Públicas)
- **Decisão:** Clientes não autenticados (Catálogo e WhatsApp) só podem ler dados públicos e normalizados.
- **Guardrail:** As *Tools* expostas pelo MCP Server para audiência pública (`searchInventory`, `getVehiclePhotos`) **MUST NOT** retornar PII (Placa, CPF do parceiro) ou dados financeiros internos (custo de aquisição). As tools públicas **MUST** ser estritamente *Read-Only*.

### ADR-003: Centralização de Lógica de IA (Thin Clients)
- **Decisão:** A lógica de orquestração, system prompts e definição de tools residem exclusivamente no `almotos-ai`.
- **Guardrail:** Os submódulos `almotos-catalog` e `almotos-ai-bot` **MUST NOT** reimplementar chamadas diretas às APIs de LLM (ex: `openai_service.py` legado) nem duplicar system prompts. Eles **MUST** atuar como clientes consumindo o endpoint `/v1/chat` do orquestrador.

### ADR-004: Validação Estrita (Structured Outputs)
- **Decisão:** A integridade das tools e da Generative UI depende de contratos de dados rígidos.
- **Guardrail:** Todas as *Tools* definidas no MCP Server (`almotos-ai`) **MUST** utilizar `zod` para validar rigorosamente seus `inputSchemas` antes de repassar a requisição para a API do SoR (`almotos-backend`).

### ADR-005: Agentic Memory & Continuous Context (Changelog)
- **Decisão:** O contexto histórico de decisões não pode depender exclusivamente da memória de sessão do LLM.
- **Guardrail:** Após concluir com sucesso qualquer alteração arquitetural, implementação de nova Tool MCP ou mudança em contratos de dados, o agente de IA **MUST** registrar a alteração no arquivo `docs/ai/CHANGELOG.md`.
- Antes de iniciar o planejamento de uma nova feature, o agente **SHOULD** ler este changelog para restaurar seu contexto.
- Cada entrada no log **MUST** conter: Data (YYYY-MM-DD), Arquivos modificados e um breve 'Por que' (A justificativa arquitetural da mudança).

---

## 4. Agentic Workflow (Instruções de Execução)

Ao ser solicitado para criar ou refatorar código neste workspace, o agente de IA **MUST** seguir este protocolo:

1. **Reconhecimento de Fronteiras:** Antes de propor código, identifique em qual pasta a alteração deve ocorrer (`almotos-backend`, `almotos-ai`, `almotos-front`, `almotos-catalog`, `almotos-ai-bot`). Se a feature exigir alteração em múltiplos (ex: criar uma tool no MCP e exibi-la no Next.js), o agente **MUST** descrever a mudança na fronteira (contrato de API) antes de implementar. Tutoriais e notas temporárias **MUST** ir em `docs/scratch/` (gitignored), **MUST NOT** em `docs/ai/` além deste arquivo e do `CHANGELOG.md`.
2. **Uso de Ferramentas (Vercel AI SDK):** Quando atuando no `almotos-catalog` (Next.js), o agente **SHOULD** priorizar o uso do Vercel AI SDK para consumir tools e renderizar *Generative UI*, em vez de respostas em texto puro.
3. **Bloqueio de Alucinação Financeira:** O agente **MUST NOT** gerar código ou prompts que permitam à IA inferir, deduzir ou calcular preços de venda, descontos ou parcelamentos. Essas negociações requerem intervenção humana (Handoff).
