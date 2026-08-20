# Guia de Navegação de Código — AL Motos

**Para quê:** code review na entrevista (Node.js, TypeScript, Next.js), com o mapa mental de quem já pensa em Kotlin e Python.  
**Como usar:** leia a visão de 60 segundos, depois o mapa de cada pasta. Na véspera, abra só os arquivos da seção 4.

---

## Visão de 60 segundos

Cinco pastas, cinco processos. Cada uma faz um trabalho só:

| Pasta | Em uma frase | Se fosse o seu stack antigo |
|---|---|---|
| `almotos-backend` | O dono do banco e das regras de estoque | O Spring Boot que você já conhece, agora em FastAPI |
| `almotos-ai` | O cérebro da IA: prompts, tools e chat | Um FastAPI que **não** tem banco, só chama o SoR |
| `almotos-front` | Painel interno do operador | Um front autenticado falando com o SoR via JWT |
| `almotos-catalog` | Site público + chat que desenha cards | Uma vitrine Next que **nunca** vê placa nem preço |
| `almotos-ai-bot` | Adaptador WhatsApp | FastAPI fino: recebe webhook da Meta e encaminha |

Regra de ouro: **só o `almotos-backend` fala com o Postgres**. A IA não tem JDBC. O catálogo e o WhatsApp não têm chave da OpenAI. O painel **não** passa pelo chat.

Fluxo da IA:

```
Cliente (site ou WhatsApp)
        │
        ▼
  catálogo  ou  bot Python
        │
        ▼
  almotos-ai  (Express + tools Zod + OpenAI)
        │
        ▼
  GET /api/public/vehicles  (SoR FastAPI, sem JWT)
        │
        ▼
  PostgreSQL
```

Fluxo do operador (zero IA):

```
Painel Next  →  /api/proxy  →  FastAPI JWT  →  Postgres
```

---

## Dicionário rápido (Node/TS ↔ Kotlin/Python)

Guarde estas analogias. Elas são o jeito mais honesto de falar “eu não decorei a sintaxe, mas sei o papel de cada peça”.

| No projeto | O que é | Kotlin (Spring) | Python (FastAPI) |
|---|---|---|---|
| **Express** (`almotos-ai/src/index.ts`) | Servidor HTTP: declara rotas, CORS, JSON | `Spring Boot` + `@RestController` | `FastAPI` / `uvicorn` |
| **Next.js App Router** (`src/app/`) | Pastas = URLs. `page.tsx` desenha a tela; `route.ts` é API no mesmo app | Um controller + uma view, mas o arquivo *é* a rota | Um `APIRouter` cujo path é o nome da pasta |
| **Route Handler** (`route.ts`) | Função `GET`/`POST` no servidor Next | Método `@GetMapping` / `@PostMapping` | `@app.get` / `@app.post` |
| **`"use client"`** | Este arquivo roda no **browser** (hooks, clique, estado) | Não existe no Spring: o HTML já veio pronto do servidor | Como um script JS no template, não o `def` do FastAPI |
| **BFF / proxy** | Next no servidor encaminha o pedido para outro backend | Um `RestTemplate`/`WebClient` escondendo o host | Um `httpx` no próprio FastAPI, sem o browser falar com o Spring |
| **Zod** | Schema que valida JSON em runtime | Bean Validation (`@Valid`) + DTO Kotlin | **Pydantic** (`BaseModel`) |
| **`z.infer<typeof schema>`** | TypeScript gera o tipo a partir do schema | O `data class` do DTO | `TypeAdapter` / o próprio tipo do `BaseModel` |
| **Vercel AI SDK (`ai`)** | Loop “modelo ↔ tools”: o GPT pede uma função, o Node executa, o resultado volta | Não tem equivalente nativo; seria um client OpenAI + dispatcher de funções | `openai` SDK + `tools=` no `chat.completions` |
| **`tool({ parameters, execute })`** | Declara o que o modelo pode chamar | Um `@Service` method com contrato fechado | Uma função Python + JSON Schema (Pydantic) |
| **MCP** | Mesmas tools, protocolo padrão (Cursor, Inspector) | Expor os *mesmos* services por gRPC *e* REST | Mesmo service, dois transports (`stdio` e HTTP) |
| **`streamText` vs `generateText`** | Stream (site) vs JSON fechado (WhatsApp) | `Flux` vs `Mono` / resposta bloqueante | `StreamingResponse` vs `return dict` |
| **ioredis / Map** | Memória de conversa WhatsApp (não é estoque) | Spring Data Redis | `redis-py` |
| **middleware.ts** | Roda *antes* da página (edge) | `OncePerRequestFilter` / Spring Security filter | Middleware FastAPI |
| **React Context** (`AuthContext`) | Estado global no browser (token, usuário) | Session no servidor (aqui o token vive no `localStorage`) | Estado de um SPA (não existe no FastAPI puro) |
| **shadcn/ui + Radix** | Botão, dialog, input prontos | Nada a ver com negócio: é “look and feel” | Equivalente a um kit de componentes (Chakra, etc.) |

**TypeScript em uma frase:** é Java/Kotlin com tipos que existem na hora de *escrever* o código. Em runtime vira JavaScript. Por isso o Zod existe: o compilador some, o schema fica. No Kotlin o tipo sobrevive no bytecode; no Python o Pydantic faz o mesmo papel do Zod.

**Node em uma frase:** um processo que escuta HTTP, igual ao `bootRun` do Spring ou ao `uvicorn`. Não é “frontend”. O `almotos-ai` é um backend.

---

## 1. SoR legado (Kotlin) — fora do monorepo

O Spring Boot não está mais neste repositório pai. Código: `https://github.com/PedroHRoseno/vehicle-sales-manager-v2-kotlin`. O dono da verdade **hoje** é `almotos-backend` (as mesmas rotas HTTP).

Na entrevista: “o SoR não conhece OpenAI nem WhatsApp. Essa ignorância é de propósito.”

---

## 2. `almotos-ai` — o cérebro (Node + TypeScript)

Pense neste serviço como **um FastAPI escrito em TypeScript**, ou como um Spring *sem* `@Repository`. Ele só consome `GET /api/public/vehicles`.

O **Express** aqui faz o mesmo papel do **Spring**: sobe o processo, registra rotas, parseia JSON. A biblioteca `ai` (Vercel AI SDK) faz o loop do agente — o equivalente a “chamar o LLM com function calling”.

### Mapa de pastas (`src/`)

- **`index.ts`** — “o `main`”. Cria o Express, liga `/health`, `/v1/inventory`, `/v1/chat`, `/mcp`.
- **`config.ts`** — lê env (`KOTLIN_BASE_URL`, `OPENAI_API_KEY`, telefones). Equivale a `application.yml` ou ao `pydantic-settings` do bot.
- **`chat/`** — runtime do agente (prompt, memória, stream vs JSON).
- **`tools/`** — as três funções que o modelo pode chamar.
- **`inventory/`** — cliente HTTP do Kotlin + tradução de campos (`modelName` → `model`, hex → “Vermelho”, slug).
- **`contracts/`** — schemas Zod. **Isto é o Pydantic deste serviço.**
- **`mcp/`** — as *mesmas* tools, em protocolo MCP (Cursor).
- **`stdio.ts`** — entrada alternativa: MCP pelo terminal (`npm run mcp:stdio`), não pela porta 3100.

### 2–3 arquivos vitais

1. **`src/index.ts`** — o `SpringApplication.run` / o `app = FastAPI()`. Sem este arquivo não existe processo.
2. **`src/chat/runtime.ts`** — decide stream (web) vs JSON (WhatsApp), injeta tools, `maxSteps: 4`.
3. **`src/tools/ai-tools.ts`** — o menu de funções do modelo, com Zod na porta.

Detalhe de entrevista: Redis (`memory.ts`) guarda **últimas 20 falas do WhatsApp por telefone, 24h**. Não é cache de estoque. Sem Redis, cai para um `Map` em memória (como um `ConcurrentHashMap` local).

---

## 3. `almotos-catalog` — vitrine + chat (Next.js 14)

Next.js aqui é **dois apps no mesmo deploy**: páginas HTML *e* APIs no servidor.

Analogia: cada pasta em `src/app/` é um `@RequestMapping`.  
- `page.tsx` = a tela (o “GET que devolve HTML”).  
- `route.ts` = o `@RestController` (o “GET/POST que devolve JSON/stream”).

O browser **não** chama o Kotlin. Em produção só conhece o próprio site; o servidor Next chama o `almotos-ai`.

### Pastas principais

- **`src/app/page.tsx`** — home da vitrine. Roda no servidor, busca estoque, manda para o React.
- **`src/app/motos/[slug]/`** — `[slug]` é path variável. Em Spring seria `@GetMapping("/motos/{slug}")`. Em FastAPI: `@app.get("/motos/{slug}")`.
- **`src/app/api/chat/route.ts`** — BFF do chat: injeta `channel: "web"` e faz proxy do stream.
- **`src/app/api/catalog/vehicles/route.ts`** — BFF da listagem (JSON para o cliente).
- **`src/components/assistant/`** — o widget e o desenho das tools (cards, fotos, botão WhatsApp).
- **`src/lib/catalog.ts`** — `fetch` para `GET /v1/inventory` no `almotos-ai`.

### 2–3 arquivos vitais

1. **`src/app/api/chat/route.ts`** — é aqui que o chat “sai da web” rumo ao backend de IA.
2. **`src/components/assistant/assistant-widget.tsx`** — `useChat({ api: "/api/chat" })`. Equivale a um client HTTP que já entende o protocolo de stream da Vercel.
3. **`src/components/assistant/tool-renderers.tsx`** — se a tool foi `searchInventory`, desenha grid; se `getVehiclePhotos`, faixa de imagens; se `handoffToSeller`, botões `wa.me`. O modelo **não** gera HTML.

`revalidate = 60` na home: o Next guarda a listagem ~1 minuto (ISR). Pense num `@Cacheable(ttl = 60s)` na borda, não no Postgres.

---

## 4. `almotos-front` — painel (Next.js 15)

Mesma ideia de pastas = URLs, mas o público é o **operador**. Aqui tem placa, CPF, custo, JWT. **Não tem LLM.**

### Pastas principais

- **`src/app/`** — uma pasta por tela: `login`, `motos`, `vendas`, `compras`, `trocas`, `clientes`, `fluxo-caixa`, `relatorios`.
- **`src/app/api/proxy/[...path]/`** — `[...path]` = “pega o resto da URL”. Em Spring: um controller coringa que reencaminha. O browser chama `/api/proxy/vehicles`; o servidor Next chama o Railway do Kotlin.
- **`src/lib/api.ts`** — o “Feign Client” / `httpx` do painel: toda chamada HTTP autenticada passa daqui.
- **`src/contexts/AuthContext.tsx`** — login grava JWT no `localStorage`; logout limpa. Equivale a guardar o token depois do `/api/auth/login`.
- **`src/components/forms/`** — formulários de moto, venda, compra, troca, parceiro (regra de negócio de UI).
- **`src/components/ui/`** — botão, tabela, dialog… **kit visual**, não domínio.
- **`src/lib/validations/schemas.ts`** — Zod nos formulários (Pydantic no browser, antes de POST).

### 2–3 arquivos vitais

1. **`src/app/api/proxy/[...path]/route.ts`** — o BFF do admin. Copia o `Authorization` uma vez só, tira headers da Vercel, evita CORS e gzip duplo.
2. **`src/lib/api.ts`** — de onde saem `api.vehicles`, `api.sales`, etc. Sempre prefixo `/api/proxy`.
3. **`src/contexts/AuthContext.tsx`** — `POST /api/proxy/api/auth/login` → token. O `AuthGuard` redireciona para `/login` se não houver sessão.

`middleware.ts` existe, mas **não bloqueia de verdade** (não lê `localStorage` no servidor). A trava real é o `AuthGuard` no cliente + o Spring Security no Kotlin. Se perguntarem, seja honesto: defesa em profundidade está no backend.

---

## 5. `almotos-ai-bot` — WhatsApp (FastAPI, o seu terreno)

Thin client. Sem `OPENAI_API_KEY`. Sem URL do Kotlin.

### Pastas principais

- **`app/main.py`** — o `FastAPI()`. Equivale ao `index.ts` do Node.
- **`app/routes/webhook.py`** — `GET` (challenge da Meta) e `POST` (mensagem).
- **`app/services/almotos_ai_client.py`** — `httpx` para `POST /v1/chat` com `channel: "whatsapp"`, `stream: false`.
- **`app/services/chat_service.py`** — marca como lida, pede texto+fotos ao AI, manda na Cloud API; se quebrar, texto de fallback.
- **`app/services/whatsapp_service.py`** — parse do JSON da Meta + envio (texto/imagem). Normaliza 9º dígito BR.
- **`app/models/whatsapp.py`** — Pydantic do payload (o Zod do Python).
- **`app/config.py`** — `pydantic-settings`. No Node isso é `config.ts`.

### 2–3 arquivos vitais

1. **`app/routes/webhook.py`** — HMAC `X-Hub-Signature-256`; em prod, sem secret → 403. Sempre responde **200** depois do parse (senão a Meta retenta em loop). Processa em `BackgroundTasks`.
2. **`app/services/almotos_ai_client.py`** — o único `httpx` rumo ao cérebro.
3. **`app/services/chat_service.py`** — cola webhook → AI → Meta.

---

## O foco do Code Review (Node / TypeScript / Next)

Um entrevistador sênior de IA quase certamente vai pedir para abrir **estes** arquivos. Decore o *fluxo*, não a linha.

### 1. `almotos-ai/src/tools/ai-tools.ts` — “quais poderes o modelo tem?”

Aqui o Vercel AI SDK registra três tools. Cada uma tem:

- uma **descrição** (o modelo lê isso para decidir se chama);
- um **schema Zod** (igual ao Pydantic: se o GPT mandar `maxKm: "vinte mil"`, a tool nem roda);
- um **`execute`** (a função Node de verdade).

As três:

- `searchInventory` — busca estoque (até 8 cards, sem preço).
- `getVehiclePhotos` — até 3 URLs.
- `handoffToSeller` — links `wa.me`, **não** cotação.

Frase: “O modelo é input não confiável. As tools são a sandbox. Não existe tool de venda nem de preço.”

Arquivos irmãos (se pedirem para “entrar” na tool):

- **`search-inventory.ts`** — chama o Kotlin com `brand`/`maxKm`/`yearMin` na query; filtra modelo/cor ainda no Node; devolve slug + `colorLabel` + foto.
- **`handoff-to-seller.ts`** — **não** chama o Kotlin. Monta `wa.me?text=...`.

### 2. `almotos-ai/src/chat/runtime.ts` — “como o chat funciona de verdade?”

Este é o `service` do agente. Em Python seria o `ChatService` *com* a chamada OpenAI (no bot Python essa parte **não existe** — ela foi puxada para cá).

O que acontece:

1. Lê `channel`: `web` ou `whatsapp`.
2. Monta o histórico de mensagens. No WhatsApp, busca memória por `threadId` (telefone).
3. Se for **web + stream**: `streamText(...)` e joga SSE na response Express (`pipeDataStreamToResponse`). É o `Flux` / `StreamingResponse`.
4. Se for **WhatsApp**: `generateText(...)` bloqueante, `maxTokens: 600`, devolve `{ text, images }`. Colhe URLs da tool `getVehiclePhotos` para o bot mandar mídia nativa.
5. Tools injetadas: `publicAiTools`. `maxSteps: 4` = no máximo 4 idas e voltas modelo↔função. `temperature: 0.4`.

Se perguntarem “por que mini e não um modelo maior”: latência/custo no WhatsApp; fato vem da tool, não do parágrafo do GPT.

### 3. `almotos-ai/src/inventory/kotlin-client.ts` — “a IA fala com o banco?”

Não. Este arquivo é um **WebClient / httpx**.

- `fetch` em `GET {KOTLIN_BASE_URL}/api/public/vehicles`.
- Valida cada item com **`kotlinVehicleSchema.safeParse`** (Pydantic `model_validate`; item inválido é **descartado**, não derruba o chat).
- Traduz: `modelName` → `model`, gera `slug`, `colorLabel`, `catalogUrl`.
- Cache in-process ~60s **só de sucesso**. Falha do Kotlin não vira “lista vazia verdadeira”.
- Busca filtrada (`brand` na query) **não** usa esse cache — pergunta de novo ao SoR.

Contrato irmão: **`src/contracts/public-vehicle.ts`**. Abra se pedirem “onde está o schema”. Zod aqui = Pydantic no bot / `data class` no Kotlin.

### 4. `almotos-catalog/src/app/api/chat/route.ts` — “como o chat viaja da web ao backend?”

Cadeia completa para falar na lousa:

```
Browser
  useChat({ api: "/api/chat" })          ← assistant-widget.tsx
        │
        ▼
Next Route Handler (servidor, não o browser)
  POST /api/chat
  injeta channel: "web", stream: true    ← route.ts
        │
        ▼
almotos-ai  POST /v1/chat
  streamText + tools                     ← runtime.ts
        │
        ▼
SSE de volta → widget desenha
  searchInventory → VehicleMiniGrid
  getVehiclePhotos → PhotoStrip
  handoffToSeller → HandoffCard          ← tool-renderers.tsx
```

O `route.ts` é pequeno de propósito: **thin client**. Não tem prompt, não tem OpenAI. Só encaminha o corpo e o stream (`text/event-stream`). Em Spring seria um controller que faz `webClient.post().body().retrieve().bodyToFlux`.

### 5. `almotos-catalog/src/components/assistant/tool-renderers.tsx` (+ widget)

Generative UI em linguagem de café: o modelo escolhe **qual** bloco mostrar (estoque, fotos, humano); o React escolhe **como** desenhar. Ninguém parseia “1. Honda CG…” de um parágrafo.

O widget (`assistant-widget.tsx`) ainda esconde texto markdown se a UI da tool já apareceu — defesa contra o modelo “listar de novo” o que o card já mostrou.

**Quinto arquivo se quiserem o painel, não o chat:**

- **`almotos-front/src/app/api/proxy/[...path]/route.ts`** — prova que o admin não passa pelo MCP. “Dois BFFs: um agrega visão pública (catálogo), outro só reencaminha JWT (admin).”

**Bônus MCP (se o programa for agentico):**

- **`almotos-ai/src/mcp/create-server.ts`** — registra as *mesmas* três funções + resource `inventory://available`. HTTP em `mcp/http.ts`; Cursor em `stdio.ts`. Um contrato, três transportes.

**Bônus política:**

- **`almotos-ai/src/chat/system-prompt.ts`** — “NUNCA informe preços”; “não invente moto que não veio de `searchInventory`”; regras diferentes para WhatsApp (texto curto + emojis) vs site (1–2 frases, a UI desenha o resto). Prompt **e** schema: defesa em profundidade.

---

## Roteiro oral de 90 segundos (se pedirem para “abrir o chat”)

1. “O clique está no **`assistant-widget.tsx`**: `useChat` aponta para `/api/chat`.”
2. “O Next, no servidor, é só um cano: **`api/chat/route.ts`** marca `channel: web` e faz stream para o Node.”
3. “O Express em **`index.ts`** manda para **`runtime.ts`**, que chama `gpt-4o-mini` com as tools de **`ai-tools.ts`**.”
4. “Se o modelo busca estoque, **`search-inventory.ts`** usa o **`kotlin-client.ts`**, que só acerta `GET /api/public/vehicles`.”
5. “O JSON da tool volta no stream; **`tool-renderers.tsx`** vira card. Preço? **`handoff-to-seller.ts`** devolve `wa.me`.”

---

## Onde relaxar (seja transparente)

Diga com calma: você desenhou a fronteira e o contrato; a IA gerou boilerplate de framework. Isso é maturidade, não desculpa.

### 1. `almotos-front/src/components/ui/` e `almotos-catalog/src/components/ui/`

Botão, input, dialog, badge, skeleton, `cn()` do Tailwind. É **shadcn/ui + Radix**: o “Material UI” deste stack. Não contém regra de estoque, JWT nem prompt. Frase: “É o kit visual padrão. Eu não reimplementei `Button` na mão.”

O mesmo vale para `globals.css`, fontes no `layout.tsx`, ícones `lucide-react`, animações do `framer-motion` no widget.

### 2. Configuração de framework e deploy

`package.json`, `next.config`, `tailwind.config`, `Dockerfile`, `railway.json`, `tsconfig`. Equivale ao `build.gradle.kts` / `requirements.txt` que o Spring Initializr ou o `fastapi-cli` já cospem. Você sabe **para que serve** (TypeScript liga, Next builda, Railway sobe o processo). Não precisa recitar cada flag.

### 3. Formulários longos e máscaras do painel (parcial)

`form-veiculo.tsx`, `form-venda.tsx`, `masks.ts`, `viacep.ts`, pipeline de crop de foto: muito volume de JSX/CSS. A **intenção** é sua (placa, Zod, `published`, upload). A repetição de `FormField` / `react-hook-form` é o “JPA mapping verboso” do front — você pode dizer que a IA preencheu a sintaxe depois que o schema em **`schemas.ts`** e o contrato do Kotlin estavam claros.

**Não jogue nesta cesta:** `ai-tools.ts`, `runtime.ts`, `kotlin-client.ts`, `api/chat/route.ts`, `proxy/[...path]/route.ts`, `webhook.py`, `PublicVehicleDTO`. Aí o entrevistador quer *você*.

---

## Truques de Next.js que costumam aparecer (sem pânico)

- **Server vs Client.** Sem `"use client"` = servidor (pode `fetch` com secret, como um controller Spring). Com `"use client"` = browser (hooks). O widget **precisa** ser client porque tem input e estado. O `route.ts` **não** tem `"use client"`: é o backend dentro do Next.
- **`[slug]` vs `[...path]`.** Um segmento vs “o resto do path”. Em FastAPI: `{slug}` vs path catch-all.
- **`NEXT_PUBLIC_*`.** Variável que **vaza para o bundle**. Por isso a chave OpenAI **não** tem esse prefixo e **não** vive no catálogo. Igual a não colocar `openai.api-key` no `application-frontend.yml`.
- **ISR `revalidate`.** Cache de página, não verdade de estoque. O Kotlin ainda é o SoR.

---

## Mini mapa “se me pedirem para clicar agora”

| Eles dizem | Você abre |
|---|---|
| “Cadê as tools?” | `almotos-ai/src/tools/ai-tools.ts` |
| “Cadê o loop do agente?” | `almotos-ai/src/chat/runtime.ts` |
| “Como chega no Kotlin?” | `almotos-ai/src/inventory/kotlin-client.ts` |
| “Como o site conversa com a IA?” | `almotos-catalog/src/app/api/chat/route.ts` |
| “Como vira card?” | `almotos-catalog/src/components/assistant/tool-renderers.tsx` |
| “O admin usa o LLM?” | `almotos-front/src/app/api/proxy/[...path]/route.ts` — e diz **não** |
| “WhatsApp?” | `almotos-ai-bot/app/routes/webhook.py` + `almotos_ai_client.py` |
| “O que o público pode ver?” | `PublicVehicleDTO.kt` |

---

*Espelho do código em agosto/2026. Se divergir, o código vence. Pare de arquitetês; fale o arquivo e o que ele impede o modelo de fazer.*
