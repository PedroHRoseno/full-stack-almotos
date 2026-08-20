# AL Motos — Guia de Estudos de System Design

**Audiência:** entrevista técnica de Forward-Deployed AI Engineer (FDE)  
**Fonte de verdade:** código e ADRs do monorepo `full-stack-almotos` (agosto/2026)  
**Como usar:** memorize os one-liners no início de cada seção; use o restante para defender trade-offs.

---

## Como falar isso em 60 segundos

> A AL Motos é o sistema operacional de uma concessionária em Caruaru. O `almotos-backend` (FastAPI) é o **System of Record**: único writer do PostgreSQL, invariantes de estoque e JWT do painel (cutover 2026-08-20; o Kotlin ficou em standby). A IA **não** conversa com o banco. Catálogo e WhatsApp são thin clients de um orquestrador Node (`almotos-ai`) que expõe tools Zod + MCP, projeta um DTO público sem placa/CPF/preço, e força **handoff humano** para negociação. O admin **não** passa pelo LLM. Eu separei gestão interna de vitrine pública de propósito: o operador precisa de PII e custo; o cliente e o modelo, não.

Se o entrevistador pedir um diagrama mental:

```
Cliente (site / WA)          Operador (painel)
        │                            │
        ▼                            ▼
  catalog  ou  bot              almotos-front
        │                      (BFF /api/proxy + JWT)
        ▼                            │
   almotos-ai                        │
   ACL + MCP + /v1/chat              │
        │                            │
        └────────────┬───────────────┘
                     ▼
          almotos-backend (SoR) → PostgreSQL
```

---

## 1. Visão geral do sistema e contexto de negócio

### O que o sistema faz

A AL Motos opera uma concessionária de motos usadas em Caruaru/PE. O produto digital cobre **dois públicos que não podem ver o mesmo recorte de dados**:

| Público | Necessidade | Superfície |
|---|---|---|
| Operador da loja | Cadastrar motos, comprar/vender/trocar, custos, caixa, publicar no site | `almotos-front` → Kotlin (JWT) |
| Cliente final | Ver estoque real, filtrar, falar com assistente, pedir fotos, negociar preço com humano | `almotos-catalog` e WhatsApp → `almotos-ai` → Kotlin público |

O backend Kotlin persiste Partner, Vehicle, Purchase, Sale, Exchange, VehicleCost, StoreTransaction e User. Regras de estoque são transacionais: compra → `DISPONIVEL`; venda → `VENDIDO`; troca move a moto de saída para vendido e cadastra a de entrada. Só motos `DISPONIVEL` **e** `published=true` entram no catálogo público.

### Valor de negócio

1. **Operação interna confiável.** A loja não pode ter duas verdades de estoque. Uma moto vendida no painel some da vitrine e do assistente sem job paralelo.
2. **Pré-venda 24/7 sem vazar margem.** O assistente (web + WhatsApp) qualifica intenção com estoque real. Preço, financiamento e desconto **não** são gerados pelo modelo — o prompt e as tools bloqueiam isso. Negociação = vendedor humano (`wa.me`).
3. **Separação intencional de superfícies.** Painel e catálogo são deploys distintos (Vercel × Vercel), stacks próximas mas contratos diferentes. O browser do catálogo **nunca** chama o Kotlin. `OPENAI_API_KEY` vive **somente** no `almotos-ai`.
4. **Canal WhatsApp sem duplicar o cérebro.** O bot Python é adapter da Meta Cloud API. Se a loja pedir Instagram depois, o orquestrador já é o ponto único de prompts e tools.

### Por que isso importa numa entrevista FDE

FDE não é “colocar um chatbot na frente do ERP”. É desenhar a fronteira entre o modelo e o sistema que o cliente já usa para operar o negócio. Aqui a fronteira é explícita: o LLM é um **cliente privilegiado de uma API pública projetada**, não um usuário do banco.

---

## 2. Detalhamento da arquitetura

O repositório pai é **composição + governança**. Cada produto é Git submodule com remote próprio. Commit do dia a dia acontece **dentro** do submodule; o pai versiona o ponteiro SHA. CI/CD no pai filtra por path e publica na ordem de dependência de runtime: FastAPI SoR → `almotos-ai` → front / catálogo / bot.

| Pasta | Papel | Stack | Porta | Deploy |
|---|---|---|---|---|
| `almotos-backend` | SoR — REST, JWT, catálogo público | FastAPI, Python 3.12, PostgreSQL 15 | 8081 | Railway |
| `almotos-front` | Painel admin | Next.js 15, React 19 | 3000 | Vercel |
| `almotos-catalog` | Vitrine + assistente (Generative UI) | Next.js 14, React 18 | 3001 | Vercel |
| `almotos-ai` | MCP Server + agent runtime `POST /v1/chat` | Node 20, Express, Zod, Vercel AI SDK | 3100 | Railway |
| `almotos-ai-bot` | Adapter WhatsApp (Meta Cloud API) | FastAPI, Python 3.12 | 8000 | Railway |

### 2.1 `almotos-backend` — System of Record

Único writer do PostgreSQL (FastAPI). Mapeia o schema que o Hibernate criou; **não** roda Alembic/`create_all`. Identidade interna do veículo é a **placa**. Domínio de produção: `api.almotoscaruaru.com.br`. O Kotlin (`vehicle-sales-manager-v2-kotlin`) é standby pós-cutover 2026-08-20.

**Contrato interno (JWT):** `/vehicles`, `/partners`, `/sales`, `/purchases`, `/exchanges`, `/financial/movements`, `/store-transactions`, `/reports/*`, `/api/auth/login`.

**Contrato público (sem JWT):** `GET /api/public/vehicles` com filtros aditivos `brand`, `maxKm`, `yearMin`. `Cache-Control: public, max-age=30`. O DTO público **omite** placa, CPF, custo, preço e status interno. Query: `status = DISPONIVEL AND published = true`.

**Invariante de publicação:** ao marcar vendido, `published` é forçado para `false`. A vitrine não depende de um cron para “despublicar”.

### 2.2 `almotos-front` — painel do operador

UI de gestão. **Não passa pelo MCP** (ADR implícito no README: “Admin não passa pelo MCP”). O browser chama `/api/proxy/*`; a Route Handler no servidor Next encaminha para o SoR, anexando `Authorization` uma única vez e filtrando headers da Vercel. Isso é BFF clássico: esconde o host Railway, evita CORS e `DNS_HOSTNAME_RESOLVED_PRIVATE`.

O operador autentica, vê PII, registra compra/venda/troca e publica a moto (`published` + fotos S3 + descrição). Essa é a única escrita de catálogo.

### 2.3 `almotos-catalog` — vitrine + Generative UI

Listagem ISR (`revalidate = 60`) via BFF `GET /api/catalog/vehicles` → `almotos-ai` `GET /v1/inventory`. Página `/motos/[slug]` com JSON-LD. Chat: `useChat` do Vercel AI SDK contra `/api/chat`, que faz proxy de **stream** para `POST /v1/chat` com `channel: "web"`.

Renderização de tools no cliente (`tool-renderers.tsx`):

- `searchInventory` → grid de cards com link para `/motos/{slug}`
- `getVehiclePhotos` → faixa de imagens
- `handoffToSeller` → botões `wa.me`

O browser **não** tem `OPENAI_API_KEY` nem URL do Kotlin em produção. `ALMOTOS_AI_URL` é obrigatória em prod (ADR-003). Fallback `KOTLIN_BASE_URL` existe só em dev.

### 2.4 `almotos-ai` — Anti-Corruption Layer + MCP + agent runtime

Três superfícies no mesmo processo:

| Superfície | Uso |
|---|---|
| `GET /v1/inventory` e `GET /v1/inventory/:slug` | Projeção pública para o catálogo (cache in-process ~60s; **não** cacheia falha do Kotlin) |
| `POST /v1/chat` | Agent runtime (`channel: web` stream; `channel: whatsapp` JSON + memória de thread) |
| `POST /mcp` (Streamable HTTP) e `npm run mcp:stdio` | Mesmas tools para Cursor / Inspector |

Tools públicas (Zod, read-only): `searchInventory`, `getVehiclePhotos`, `handoffToSeller`. O cliente HTTP (`kotlin-client.ts`) chama **somente** `GET /api/public/vehicles`, valida com `kotlinVehicleSchema`, deriva `slug` / `colorLabel` / `catalogUrl` e **descarta** campos que o SoR não deveria ter enviado.

Redis (`REDIS_URL`) é **memória de thread WhatsApp** (TTL 24h, últimas 20 turns), não espelho de estoque (ADR-001). Sem Redis, cai para Map in-memory.

### 2.5 `almotos-ai-bot` — thin adapter

FastAPI. `GET /webhook` (challenge da Meta) e `POST /webhook` (HMAC `X-Hub-Signature-256`; em prod, sem `WHATSAPP_APP_SECRET` → 403). Responde 200 imediatamente e processa em `BackgroundTasks` — contrato de webhook at-least-once.

`AlmotosAiClient.complete` envia `{ channel: "whatsapp", threadId: phone, text, stream: false }`. O bot **não** tem `OPENAI_API_KEY` nem URL do Kotlin. Fallback de texto se o orquestrador falhar.

### 2.6 Governança (não é “documentação morta”)

`docs/ai/CLAUDE.md` é normativo (RFC 2119). ADRs que você deve citar:

- **ADR-001** — só o `almotos-backend` fala com Postgres; Redis não espelha estoque
- **ADR-002** — tools públicas read-only, sem PII/financeiro
- **ADR-003** — prompts e tools só no `almotos-ai`; catálogo/bot são thin clients
- **ADR-004** — Zod em todo input de tool
- **ADR-005** — changelog em `docs/ai/CHANGELOG.md` após mudança de contrato

CI/CD (`.github/workflows/ci-cd.yml`): path-filter por submodule; CD não publica catálogo/bot antes do `almotos-ai`; não publica AI antes do Kotlin se ambos mudaram. Secrets de plataforma no GitHub; runtime (`OPENAI_API_KEY`, etc.) nos painéis Railway/Vercel.

---

## 3. Mapeamento formal de System Design

Esta seção traduz o código para o vocabulário que o entrevistador espera. Fale o conceito, depois o artefato.

### 3.1 Microsserviços e governança de monorepo

**Conceito.** Microsserviços = processos com ciclo de vida, stack e falha independentes, comunicando-se por contratos. Monorepo ≠ monólito: o pai orquestra, os filhos são deploys.

**Como apliquei.** Cinco serviços, cinco stacks, três plataformas (Railway JVM/Node/Python + Vercel ×2). Fronteiras alinhadas a **capacidade de negócio**, não a “uma pasta por linguagem”:

- SoR (integridade)
- ACL/IA (modelo + projeção)
- Admin (operação autenticada)
- Catálogo (leitura pública + UI gerada)
- Adapter de canal (WhatsApp)

**Governança.** Submodules evitam um único Git gigante e permitem permissão/remoto por produto. O custo é o ponteiro SHA: o pai precisa de CI que faça checkout `submodules: recursive`. Path-filter trata alteração de gitlink como mudança da pasta. Ordem de CD é o grafo de dependência, não “deploy everything”.

**Trade-off que eu defendo.** Não é um mesh com 15 serviços. É um **modular monolith distribuído o suficiente** para isolar o LLM do banco e o admin da vitrine. Mais serviços (API Gateway dedicado, identity service, inventory read-replica) seria over-engineering para o volume de uma concessionária.

**Pergunta esperada:** “Por que não um monólito Next + Kotlin só?”  
**Resposta:** o painel e o catálogo têm threat models opostos. Colocar o LLM no mesmo processo do JPA quebraria ADR-001 no primeiro hotfix. O bot Python precisa de processo longo (webhook Meta); Vercel não serve. A separação paga o custo operacional.

### 3.2 System of Record (SoR) e integridade de dados

**Conceito.** SoR é o sistema cuja escrita é canônica. Outros sistemas **projetam** visões; não competem como verdade.

**Como apliquei.**

- Identidade interna: placa. Identidade pública: slug **derivado na ACL** (ver §5 — isso é o gap).
- Transações JPA nas escritas de compra/venda/troca; efeitos de estoque no mesmo aggregate.
- Publicação é flag no aggregate `Vehicle`, não uma tabela “site_inventory”.
- API pública é **aditiva**: filtros opcionais não mudam o JSON antigo.
- Projeção `PublicVehicleDTO` / `toPublicDTO()` é allowlist, não “omit no serializer e rezar”.

**O que o SoR recusa fazer.** Não conhece OpenAI, MCP, WhatsApp nem slugs de marketing (hoje). Ele conhece placa, CPF, dinheiro e status. Essa ignorância é uma feature.

**Cache.** 30s no HTTP público do Kotlin + 60s no `almotos-ai` + 60s ISR no catálogo. Estoque de concessionária tolera dezenas de segundos. Cache de **erro** é proibido: Kotlin fora do ar não deve servir lista vazia como verdade.

### 3.3 Anti-Corruption Layer (ACL) e Security by Design

**Conceito.** ACL (DDD) traduz um modelo externo para o modelo do seu bounded context, para o legado/o vendor não vazar para dentro. Aqui o “legado externo” é o **LLM + o canal público**. O bounded context protegido é o SoR.

**Como apliquei em `almotos-ai`:**

1. **Tradução de modelo.** Kotlin fala `modelName`, placa, hex de cor, enum `HONDA`. O mundo público fala `model`, `slug`, `colorLabel` (“Vermelho”), `catalogUrl`. `kotlinVehicleSchema.safeParse` **dropa** itens inválidos em vez de quebrar o chat.
2. **Redução de privilégio.** O orquestrador **não tem** credencial JWT de admin. Só consome `/api/public/**`. Mesmo que o prompt seja injetado, a tool não consegue `GET /partners/{cpf}` nem `POST /sales`.
3. **Capability scoping (ADR-002).** Três tools. Nenhuma escreve estoque. Nenhuma devolve preço. `handoffToSeller` devolve links, não uma cotação.
4. **Segredo concentrado.** `OPENAI_API_KEY` só neste serviço. Catálogo na Vercel não pode vazar a chave no bundle.
5. **Prompt como política.** System prompt: “NUNCA informe preços”; “NÃO invente motos que não vieram de `searchInventory`”; canal WhatsApp vs web com formatos diferentes. Política no prompt **e** no schema — defesa em profundidade.

**Security by Design (ameaças concretas):**

| Ameaça | Controle |
|---|---|
| Prompt injection pedindo placa/custo | Tool só vê DTO público; SoR não envia esses campos |
| LLM “vender” uma moto | Não existe tool de escrita de estoque |
| Chave OpenAI no frontend | BFF `/api/chat`; key no Railway do AI |
| Webhook WhatsApp forjado | HMAC SHA-256; 403 sem secret em prod |
| Admin usar o modelo como atalho para o banco | Admin nem entra no MCP |
| Espelho de estoque no Redis | ADR-001; Redis só thread |

**Frase para a entrevista:** “O modelo é untrusted input. Tools são a sandbox. O SoR é o kernel.”

### 3.4 Backend for Frontend (BFF)

**Conceito.** BFF é uma API moldada para **uma** experiência de cliente, não um CRUD genérico. Evita chatty calls e esconde backends.

Há **dois** BFFs, de propósito:

**BFF Admin (`almotos-front` `/api/proxy/[...path]`).** Pass-through autenticado. Problema que resolve: browser na Vercel → Railway (CORS, hostname privado, gzip duplo, header `Authorization` duplicado). Não agrega, não traduz. O painel já fala o idioma do SoR.

**BFF Catálogo (`almotos-catalog` `/api/catalog/vehicles` e `/api/chat`).** Não é pass-through do Kotlin. Agrega a **visão pública já projetada** pelo ACL. Chat faz streaming proxy (`text/event-stream`) e injeta `channel: "web"`. O cliente React só conhece origem mesma do site.

**Por que o catálogo não chama o Kotlin direto em produção.** ADR-003: um único lugar gera slug/colorLabel. Se o Next falasse com o SoR, a projeção duplicaria (hoje o fallback local ainda duplica — cheiro que o §5 também endereça).

**Não é API Gateway.** Não há auth central, rate limit global nem roteamento de 40 serviços. Chamar de Gateway seria inflar o currículo.

### 3.5 Generative UI e Tool Use / MCP

**Tool Use (function calling).** O runtime (`ai` SDK) recebe `publicAiTools`. `maxSteps: 4`. O modelo decide chamar `searchInventory({ brand: "Honda", maxKilometers: 20000 })`; o servidor executa; o resultado volta como `toolInvocations` no stream. A UI **não** parseia o texto da resposta para montar cards — renderiza o resultado estruturado da tool. Isso é Generative UI: o modelo escolhe *qual* componente, o código escolhe *como* desenhar.

**MCP (Model Context Protocol).** As **mesmas** funções (`searchInventory`, `getVehiclePhotos`, `handoffToSeller`) são registradas num `McpServer` + resource `inventory://available`. Cursor e o Inspector falam MCP; o site fala `/v1/chat`; o WhatsApp fala `/v1/chat` sem stream. Um contrato de tools, três transportes.

**Por que MCP e `/v1/chat` coexistirem.** MCP é o protocolo para *host* de agentes (Cursor, futuros canais). `/v1/chat` é o runtime de produto (OpenAI + memória + stream). Extrair um “MCP-only” e fazer o Next ser MCP client seria mais uma hop e pior latência no chat do site. Pragmatismo: MCP para ferramentas de desenvolvimento e extensão; HTTP chat para UX.

**Structured outputs.** Zod nos parâmetros (ADR-004). Sem isso, o modelo inventa `maxKm: "vinte mil"` e o Kotlin 400.

**Handoff como tool, não como texto.** Se o modelo só “sugerisse WhatsApp”, a UI não teria botão confiável e o WhatsApp não teria mídia. Tool = contrato.

---

## 4. O ciclo de vida da requisição de IA

Dois caminhos de entrada, um cérebro. Desenhe os dois no quadro.

### 4.1 WhatsApp (canal síncrono para o usuário, assíncrono no webhook)

```
Meta Cloud API
    │  POST /webhook  (assinatura HMAC)
    ▼
almotos-ai-bot  (FastAPI)
    │  200 OK imediato + BackgroundTasks
    │  mark as read
    ▼
POST almotos-ai /v1/chat
    { channel: "whatsapp", threadId: "<phone>", text, stream: false }
    │
    ▼
almotos-ai runtime
    1. Carrega histórico Redis/memória (threadId = telefone, 20 turns, 24h)
    2. system prompt (regras de preço + formato WA)
    3. generateText(gpt-4o-mini, tools, maxSteps 4, maxTokens 600)
    4. Se o modelo chama tool → execute → Kotlin GET /api/public/vehicles
    5. LLM gera texto final
    6. Persiste turns; extrai até 3 URLs de getVehiclePhotos
    │
    ▼
JSON { text, images[] }
    │
    ▼
bot envia texto + imagens na Cloud API
```

**Detalhes que demonstram maturidade:**

- Webhook **sempre** 200 após parse, mesmo payload estranho — senão a Meta retenta em loop.
- `threadId` = telefone. Memória é por conversa, não global (evita vazar contexto entre clientes).
- Fotos não vão no markdown: o runtime colhe `toolResults` de `getVehiclePhotos` e o adapter manda mídia nativa.
- Timeout HTTP 60s no client Python; fallback humano se o AI cair.

### 4.2 Catálogo web (stream + Generative UI)

```
Browser  useChat({ api: "/api/chat" })
    │
    ▼
Next.js Route Handler  (BFF)
    injeta channel: "web", stream: true
    │
    ▼
POST almotos-ai /v1/chat
    streamText → pipeDataStreamToResponse
    │
    ├─ tool searchInventory
    │     fetchInventory(brand, maxKm, yearMin)  →  Kotlin
    │     filtro residual (model, color) na ACL
    │     devolve até 8 cards sem preço
    │
    ├─ tool getVehiclePhotos  →  até 3 URLs
    ├─ tool handoffToSeller   →  wa.me pré-preenchido
    │
    ▼
SSE para o browser
    AssistantWidget renderiza texto + ToolBlocks
```

**Listagem da vitrine (sem LLM):** `page.tsx` → `getCatalogVehicles()` → `GET /v1/inventory` → cache ACL → Kotlin. O chat **não** é o path da home.

### 4.3 O que acontece dentro de uma tool contra o SoR

`searchInventory` é o exemplo canônico de ACL:

1. Input Zod (`brand?`, `model?`, `color?`, `maxKilometers?`, `yearMin?`).
2. Params que o Kotlin entende (`brand`, `maxKm`, `yearMin`) vão na query — filtrar no banco, não trazer o estoque inteiro sempre.
3. `model` e `color` ainda filtram na ACL (`matchesSearch`), porque o SoR não tem `colorLabel` nem busca por trecho de modelo no endpoint público.
4. Map para o contrato da UI: `slug`, `colorLabel`, `imageUrl`, `catalogUrl`. Sem placa.

`handoffToSeller` **não** chama o Kotlin. Gera links. Hoje a intenção morre ali — o ponto da proposta do §5.

### 4.4 Caminho que a IA **não** percorre

Operador loga no painel → JWT → `/api/proxy/sales` → Kotlin → Postgres. Zero tokens de modelo, zero MCP. Cite isso. Mostra que você não “AI-washed” o CRUD.

---

## 5. Foco da entrevista — alteração de escopo menor

**Nome da proposta:** persistir o lead de handoff no SoR (write-scoped), sem CRM e sem dar ao LLM poder de estoque.

### 5.1 O problema (evidência no código, não opinião)

O funil de IA hoje:

1. Cliente pede preço ou humano.
2. O modelo chama `handoffToSeller`.
3. A tool devolve `{ message, links[] }` com `wa.me`.
4. No site, um card; no WhatsApp, o próprio canal já é o vendedor.

**O SoR não fica sabendo.** Redis guarda texto da conversa WA por 24h e some. O painel (`almotos-front`) não tem fila “clientes que pediram preço nesta Honda”. Se o vendedor não olhar o WhatsApp, a qualificação que a IA fez **não vira operação**.

Isso é o gap clássico de FDE: o agente gera valor na conversa e o sistema de record não absorve o artefato.

### 5.2 Por que esta mudança (e não outra)

Critério: **alto impacto de negócio × pouca superfície × alinhada aos ADRs**.

| Alternativa que eu recusei | Por que é over-engineering / errada |
|---|---|
| Tool `createSale` / `setPrice` | Quebra ADR-002 e o invariante financeiro. O modelo não fecha negócio. |
| CRM completo (pipeline, scoring, dono, SLA) | Sem evidência de volume. Começa com uma tabela e uma tela. |
| Kafka + outbox “LeadCreated” | Um POST interno basta. Uma loja, um writer. |
| Espelhar conversas no Postgres | PII de chat no SoR sem retenção definida. Lead ≠ transcrição. |
| Fazer o bot Python gravar o lead | Duplicaria a regra; o handoff já vive no ACL (ADR-003). |
| Novo microsserviço de leads | Mais deploy, mais falha. Leads são um aggregate pequeno do SoR. |

**Por que não só “melhorar o prompt”?** Prompt não cria registro auditável nem aparece no painel do operador.

### 5.3 Desenho (o mínimo que fecha o loop)

```
handoffToSeller (já existe)
        │
        ├─ (igual) gera links wa.me  →  UI / WhatsApp
        │
        └─ NOVO, side-effect, best-effort
              POST Kotlin /api/internal/leads
              Header: X-AI-Internal-Token
              Body: { channel, threadId?, vehicleSlug?, model?, reason }
                    │
                    ▼
              CatalogLead (SoR)
                    │
                    ▼
              Painel GET /leads  (JWT, já autenticado)
```

**Side-effect, não tool nova.** Se `recordLead` for tool, o modelo esquece de chamar. Handoff **é** o momento de intenção. A persistência é política do sistema, não decisão do LLM. Isso é Security/Product by Design.

**Best-effort.** Se o Kotlin estiver down, o cliente **ainda** recebe o `wa.me`. Pré-venda não pode 500 porque a fila de leads falhou. Log + métrica; não transação distribuída.

### 5.4 Contrato e segurança

Entidade `CatalogLead` (Kotlin):

- `id` (UUID)
- `createdAt`
- `channel`: `WEB` \| `WHATSAPP`
- `threadId`: telefone (WA) ou nulo (web anônimo)
- `vehicleSlug` / `model` (opcionais; **nunca** placa)
- `reason` (string curta da tool)
- `status`: `NEW` \| `CONTACTED` (o operador marca no painel)

**Não** vai para `/api/public/**` — endpoint público de escrita seria spam. Novo matcher: `/api/internal/**` autenticado por **service token** compartilhado só com `almotos-ai` (`AI_INTERNAL_TOKEN`). O token de admin JWT **não** é reutilizado pelo orquestrador — o AI continua sem poder listar parceiros.

Idempotência barata: unique `(channel, threadId, vehicleSlug, data UTC)` ou hash do payload com TTL de 1h. Evita duplicar lead se o modelo chamar a tool duas vezes no mesmo `maxSteps`. Sem Redis extra: unique constraint no Postgres.

Rate limit: no Kotlin, por `threadId` (ex.: 5 leads/hora). Defesa se alguém martelar o chat.

### 5.5 Superfície de código (estimativa: horas, não sprints)

| Módulo | Mudança |
|---|---|
| Kotlin | Entity + repository + `POST /api/internal/leads` + `GET /leads` (JWT) + security matcher |
| `almotos-ai` | `postLead()` no `kotlin-client`; chamar no fim de `handoff-to-seller.ts`; env `AI_INTERNAL_TOKEN`; log se 5xx |
| `almotos-front` | Página `/leads`: tabela data, canal, modelo, slug, WhatsApp, marcar CONTACTED |
| Catálogo / bot | **Zero.** Já passam por `/v1/chat`. |

Contrato da tool **para a UI não muda**. Generative UI continua igual. Change additive.

### 5.6 Como eu explico o impacto

- **Operação:** o dono abre o painel de manhã e vê quem pediu preço ontem, mesmo se o WhatsApp foi silenciado.
- **IA:** o handoff deixa de ser um beco sem saída. Qualificação vira dado.
- **Arquitetura:** primeiro write do ACL, **capability-scoped**. Demonstra que “ACL read-only” era o default certo, e que escrita se abre com allowlist, token próprio e campos sem PII financeira.
- **O que eu mensuraria depois (sem construir agora):** contagem de leads/dia, % CONTACTED em 24h, motos mais pedidas. Se isso for zero, o problema é o prompt/handoff, não a tabela.

### 5.7 Se o entrevistador aprofundar: o segundo gap (ainda menor)

Slug público hoje é **derivado** em `almotos-ai` (`uniqueSlug(brand-model-year)`). `PublicVehicleDTO` não tem slug. Duas CG 2023 iguais recebem sufixo `-2` **na ordem da lista**. Se a ordem mudar, URL e SEO quebram. O fallback local do catálogo ainda re-slugifica.

**Fix aditivo, se sobrar tempo na conversa:** coluna `catalogSlug` unique no `Vehicle`, gerada na primeira publicação, imutável; incluir no DTO público; `GET /api/public/vehicles/{slug}`. Identidade pública volta para o SoR. A ACL para de inventar ID.

Eu **não** misturaria slug + leads no mesmo PR. Um problema de identidade, um de funil. Entrevistador FDE quer ver recorte.

### 5.8 Roteiro oral (2–3 minutos)

1. “Hoje o agente já detecta intenção de compra via `handoffToSeller`. O artefato some no `wa.me`.”
2. “Eu persistiria um `CatalogLead` no Kotlin, como side-effect best-effort da tool existente.”
3. “Token interno, sem placa/preço, sem tool nova, sem CRM, catálogo e bot intocados.”
4. “UI: uma lista no painel que o operador já usa. Se o POST falhar, o cliente ainda fala com o vendedor.”
5. “Isso é o menor write que fecha o loop IA → operação. O próximo write só existe com evidência de uso.”

---

## 6. Perguntas que você deve saber defender

**Por que gpt-4o-mini e não um modelo maior?**  
Latência e custo no WhatsApp. Tools fazem o trabalho factual. Temperatura 0.4. Se a qualidade de roteamento de tools cair, aí se sobe o modelo — não o contrário.

**Por que Kotlin e não Node no SoR?**  
O núcleo nasceu como domínio transacional (estoque, dinheiro, JPA). Trocar de linguagem não aumenta integridade. Node entrou onde o ecossistema de agentes (AI SDK, MCP, Zod) é nativo.

**E se o Kotlin cair?**  
Catálogo: 502 no BFF, ISR pode servir snapshot de 60s. Chat: 502/503. Bot: fallback de texto. Admin: proxy 502. Não há replica de leitura. Aceitável para o porte; o próximo passo seria health + timeout no `kotlin-client`, não um segundo banco.

**Por que cache em três camadas?**  
Cada uma serve um cliente diferente (HTTP público, processo AI, CDN/ISR). TTL curto. Concessionária não é HFT. O risco é cache de miss/erro, e isso já está evitado no client AI.

**MCP não é overkill?**  
O produto usa `/v1/chat`. MCP é o mesmo contrato de tools para o próprio desenvolvedor (Cursor) e para o programa de aceleração — você demonstra protocolo, não um wrapper interno intransferível. O custo é um `create-server.ts` fino.

**Como você evita alucinação de estoque?**  
Obrigar tool; prompt “não invente”; Zod; SoR filtra `published + DISPONIVEL`; UI renderiza o JSON da tool, não um parágrafo solto.

**Onde está o rate limit do chat?**  
Hoje: não há no orquestrador. Admita. Mitigações atuais: webhook HMAC, tools read-only, maxSteps 4, maxTokens 600 no WA. Um FDE honesto propõe rate limit por IP/thread **depois** do lead, ou junto se o custo OpenAI já doer.

**Por que submodules em vez de monorepo de packages?**  
Histórico: cada app já tinha remote. O pai ganhou composição e CI. Desvantagem: SHA drift. Compensa enquanto os deploys são independentes.

---

## 7. Cheat sheet — frases por conceito

| Conceito | Frase |
|---|---|
| SoR | “FastAPI (`almotos-backend`) é o único writer do Postgres; o resto projeta. Kotlin em standby.” |
| ACL | “O LLM fala um idioma; o estoque fala outro. `almotos-ai` traduz e reduz privilégio.” |
| BFF | “Dois BFFs: proxy JWT no admin, agregação pública no catálogo.” |
| Generative UI | “A tool devolve dados; o React escolhe o componente. O modelo não desenha HTML.” |
| MCP | “Um schema de tools, vários transportes: stdio, Streamable HTTP, e o runtime HTTP do produto.” |
| Handoff | “Preço é humano. A IA qualifica e transfere.” |
| Segurança | “Prompt injection esbarra na tool sandbox, não no JPA.” |
| Escopo menor | “Persistir o lead do handoff. Side-effect, best-effort, token interno, uma tela.” |

---

## 8. Mapa mental de arquivos (para revisar na véspera)

| Arquivo | Por que abrir |
|---|---|
| `README.md` | Diagrama e tabela de papéis |
| `docs/ai/CLAUDE.md` | ADRs 001–005 |
| `almotos-ai/src/chat/runtime.ts` | Stream web vs generate WA |
| `almotos-ai/src/tools/ai-tools.ts` | Contratos Zod das tools |
| `almotos-ai/src/inventory/kotlin-client.ts` | Cache, projeção, query ao SoR |
| `almotos-ai/src/mcp/create-server.ts` | MCP = mesmas tools |
| `almotos-ai/src/chat/system-prompt.ts` | Política de preço e canais |
| `almotos-catalog/src/app/api/chat/route.ts` | BFF stream |
| `almotos-catalog/src/components/assistant/tool-renderers.tsx` | Generative UI |
| `almotos-ai-bot/app/routes/webhook.py` | HMAC + 200 + background |
| `almotos-front/src/app/api/proxy/[...path]/route.ts` | BFF admin |
| `PublicVehicleController.kt` + `PublicVehicleDTO.kt` | Superfície pública do SoR |
| `SecurityConfig.kt` | permitAll público vs JWT |
| `VehicleService.kt` | `published` forçado para false na venda |
| `.github/workflows/ci-cd.yml` | Ordem Kotlin → AI → clientes |

---

*Documento gerado a partir do workspace em 2026-08-16. Se o código divergir, o código vence; atualize este guia e o `CHANGELOG.md` (ADR-005) juntos.*
