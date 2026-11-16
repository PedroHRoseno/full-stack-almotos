# AL Motos — Design System & Guia de Conteúdo

> Fonte única da verdade para criar Reels, Stories, carrosséis e posts do `@almotoscaruaru` com consistência visual e verbal. Anexe ou cole este arquivo inteiro em qualquer IA (ChatGPT, Claude, geradores de arte/roteiro) antes de pedir conteúdo.
> AL Motos · ROSENO E SILVA COMERCIO DE VEICULOS LTDA · Rua Visconde de Inhaúma, 725 — Maurício de Nassau, Caruaru/PE.

## Sumário

1. Identidade visual & tokens
2. Direção de arte para Reels
3. Props físicos e digitais (+ especificação do kit)
4. Tom de voz, copy e compliance
5. Templates de prompts

---

## 1. Identidade visual & tokens

AL Motos é uma revenda de motos seminovas e novas em Caruaru/PE (Rua Visconde de Inhaúma, 725 — Maurício de Nassau). Compramos, vendemos, trocamos e consignamos. **Não temos oficina e não alugamos motos.** O visual é **Clean Automotive em Dark Mode**: fundo escuro profundo, um vermelho forte e o verde só para WhatsApp. O que queremos passar: procedência, transparência, troca e financiamento sem enrolação, confiança. Nada de "startup futurista" e nada de "feira bagunçada".

Este guia é a fonte única da verdade para qualquer pessoa ou IA que produza Reels, Stories, carrosséis e posts para o `@almotoscaruaru`. As seções seguintes cobrem Reels, props, tom de voz e prompts prontos.

### Ecossistema e destino dos CTAs

| Canal | Endereço | Uso no conteúdo |
| --- | --- | --- |
| Catálogo (estoque em tempo real + assistente de IA) | `catalogo.almotoscaruaru.com.br` | CTA principal: "Veja o estoque completo no catálogo — link na bio" |
| Site | `almotoscaruaru.com.br` | Institucional, endereço, horários |
| Instagram | `@almotoscaruaru` | Canal de aquisição: Reels → catálogo / Direct / WhatsApp |
| WhatsApp | (81) 99426-8997 | Simulação de financiamento, cartão e avaliação da usada |

### Cores

Use só estes tokens. O primeiro tema (`dark`) é o padrão de todo conteúdo social.

| Token | Hex | RGB | Função |
| --- | --- | --- | --- |
| `canvas` | `#09090b` | 9, 9, 11 | Fundo de toda peça |
| `surface` | `#121215` | 18, 18, 21 | Cards e painéis |
| `surface-raised` | `#18181b` | 24, 24, 27 | Card dentro de card, chips neutros |
| `line` | `#27272a` | 39, 39, 42 | Bordas sutis 1–2px |
| `ink` | `#f6f6f8` | 246, 246, 248 | Títulos, preços, legendas |
| `ink-muted` | `#a2a2ad` | 162, 162, 173 | Ficha técnica, subtítulos, avisos |
| `ink-subtle` | `#6f6f7a` | 111, 111, 122 | Só texto ≥24px |
| `brand` | `#eb0b0b` | 235, 11, 11 | Vermelho institucional: tarjas, badges, destaque |
| `brand-hover` | `#c90a0a` | 201, 10, 10 | Segunda faixa, sombra de tarja |
| `on-brand` | `#ffffff` | 255, 255, 255 | Texto/logo sobre vermelho |
| `logo-red` | `#ff0000` | 255, 0, 0 | Só a arte da logo |
| `whatsapp` | `#25d366` | 37, 211, 102 | Exclusivo CTA WhatsApp |
| `on-whatsapp` | `#09090b` | 9, 9, 11 | Texto sobre o verde |
| `scrim` | `rgba(9,9,11,.72)` | — | Caixa atrás de legenda sobre vídeo |

Regras:

- Proporção de cor em qualquer peça: **70% `canvas`/`surface`, 20% `ink`, até 10% `brand`**. O vermelho é tempero, não fundo — exceção: a tela final e capas de campanha podem ter uma faixa `brand` de até 1/3 da área.
- `whatsapp` aparece **só** em CTA de WhatsApp. Nunca como cor de destaque, preço ou "sucesso".
- Texto pequeno sempre `ink` ou `ink-muted`. `brand` como texto só a partir de 24px (sobre `canvas` dá 4,3:1).
- Sobre o verde, texto `on-whatsapp` (escuro). Branco sobre `#25d366` dá 2:1 e não lê.
- Sem degradês coloridos, sem neon, sem roxo/azul "tech". O único efeito permitido é um brilho vermelho suave (radial de `brand` a ~18% de opacidade) atrás da moto em capas, como no topo do catálogo.
- Os posts antigos usam parede quadriculada de logos e amarelo nas legendas. **Daqui em diante:** legenda em `ink` sobre `scrim`; destaque em caixa `brand`. A parede de logos da loja pode aparecer como cenário real, não como fundo gráfico.

### Tipografia para social media

Mesmas famílias do catálogo, todas gratuitas no Google Fonts e disponíveis no **Canva**. No **CapCut**, importe os `.ttf` (Texto → Fontes → Importar) uma vez em cada celular da equipe.

| Família | Papel | Onde baixar | Se faltar |
| --- | --- | --- | --- |
| **Syne** ExtraBold 800 | `display`: nome da moto, títulos, número da condição | fonts.google.com/specimen/Syne | Montserrat ExtraBold |
| **DM Sans** 400/600/700 | `sans`: legendas, fichas, texto corrido, avisos | fonts.google.com/specimen/DM+Sans | Poppins |
| **Anton** 400 | `impact`: gancho dos 0–3s e capa (é a condensada pesada que já aparece em "ESTÁ PENSANDO" e "BLACK NOVEMBER") | fonts.google.com/specimen/Anton | Bebas Neue |

Hierarquia (tamanhos para tela de 1080px de largura — no Canva, exatamente estes; no CapCut, ajuste pela régua até bater a altura relativa):

| Estilo | Família | Tamanho / entrelinha | Uso |
| --- | --- | --- | --- |
| `hook` | Anton | 128 / 0,92, MAIÚSCULAS | Gancho e capa. Máx. 3 linhas |
| `title-xl` | Syne 800 | 96 / 0,95 | Nome da moto |
| `title-lg` | Syne 800 | 72 / 1,0 | Título de slide e tela final |
| `condition` | Syne 800 | 56 / 1,05 | "48x", "21x" dentro do badge |
| `caption` | DM Sans 700 | 52 / 1,15 | Legenda dinâmica falada |
| `subtitle` | DM Sans 600 | 40 / 1,2 | Ficha: ano · km · cor |
| `body` | DM Sans 400 | 32 / 1,4 | Texto de carrossel |
| `legal` | DM Sans 500 | 24 / 1,35 | "*Sujeito a análise de crédito" |

Regras: no máximo **2 famílias por peça** (Anton + DM Sans no Reels; Syne + DM Sans no carrossel). Nomes de modelo sempre como a montadora escreve: "Honda CG 160 Titan", "Yamaha NMAX 160", "XRE 300 Sahara". Números com separador brasileiro: "18.400 km", "2023/2024".

### Logo

Arquivos em `docs/brand/logos/` (e no grupo **Logos** do Design System). A logo é uma arte de uma cor só; nunca redesenhe, distorça, contorne, aplique sombra ou mude a cor fora destas versões.

| Versão | Arquivo | Quando usar |
| --- | --- | --- |
| Principal vermelha | `almotos-logo-vermelha.png` | Sobre `canvas`, `surface` ou fundos claros. Padrão. |
| Branca (vazada) | `almotos-logo-branca.png` | Sobre `brand`, sobre vídeo e como **marca d'água** |
| Preta | `almotos-logo-preta.png` | Só em impressos/fundos claros quando o vermelho não puder (ex.: carimbo, PB) |
| Avatar circular | `almotos-avatar-circular.png` | Foto de perfil, ícone de destaques, selo de canto |
| Negativo quadrado | `almotos-logo-negativo-quadrado.png` | Capa de destaque, slide de abertura |

- **Proporção** da logo horizontal: ≈ 2,33 : 1 (1024×440). Trave a proporção sempre.
- **Área de proteção** (`logo-clearspace`): 25% da altura da logo livre em todos os lados — nenhum texto, borda ou badge entra.
- **Tamanho mínimo**: 240px de largura em 1080px (Reels/feed); 120px como marca d'água.
- **Marca d'água em vídeo**: logo branca, 160–200px de largura, opacidade 60–70%, canto **superior esquerdo** logo abaixo de `safe-top` (y ≈ 260px, x = 64px). Nunca no rodapé (cai sob a legenda do Instagram) nem à direita (coluna de botões).
- Não coloque a logo vermelha sobre o vermelho da moto ou sobre a faixa `brand`: use a branca.

### Estilo fotográfico e enquadramento

- **Estoque (catálogo/site):** proporção `aspect-estoque` 4:3, horizontal, mínimo 1600×1200. Moto em **3/4 frontal** (≈45°), guidão virado para a câmera, no descanso lateral, câmera na altura do tanque (~80cm). Sequência padrão: 3/4 frontal → lateral → traseira 3/4 → painel ligado (km visível) → motor → pneus → detalhe de conservação → chave/manual (se houver).
- **Vídeo:** `aspect-reels` 9:16, 1080×1920, 30fps (60fps para slow motion de detalhes), modo vertical nativo do celular, lente 1x (nunca ultra-wide colado na moto: deforma o tanque).
- **Feed/carrossel:** `aspect-feed` 4:5, 1080×1350.
- **Luz:** luz difusa e de lado. Grave de manhã cedo ou fim de tarde no pátio, ou dentro da loja com LED 5600K. Nada de sol do meio-dia direto (estoura o cromado) e nada de luz amarela misturada com branca.
- **Limpeza:** moto lavada e seca, pneu com brilho fosco, fundo sem cones, baldes, mangueira, outras motos cortadas pela metade, gente passando ou placa real à mostra. Preferir fundo da loja com a parede de logos ou fundo escuro.
- **Placa:** sempre coberta pela placa cenográfica AL Motos (ver Props) ou desfocada na edição.
- **Tratamento:** contraste +10, sombras −10, saturação neutra; vermelho da moto fiel (não "estourar" o vermelho). Nunca filtros do Instagram.

---

## 2. Direção de arte para Reels

Todo Reel de moto segue a mesma arquitetura de 15–30s. Formato `aspect-reels` 1080×1920, 30fps, exportado em 1080p no CapCut (taxa de bits "Alta").

### Arquitetura (versão de 30s)

| Bloco | Tempo | O que mostra | Texto em tela | Áudio |
| --- | --- | --- | --- | --- |
| **1. Gancho** | 0–3s | Plano mais forte da moto: farol acendendo, partida com ronco, roda girando, ou o vendedor puxando a capa | `hook` em Anton, 2–3 linhas: "CG 160 TITAN 2023 CHEGOU" / "ESTÁ PENSANDO EM TROCAR?" | Batida da trilha entra no 1º frame; ronco do motor por cima |
| **2. Apresentação** | 3–15s | 5–7 takes de 1,5–2s: 3/4 frontal em movimento (câmera andando em arco), lateral, painel ligado com km, motor, pneus, banco, detalhe de conservação | Tarja da moto (`TarjaMoto`) entra no 1º take e sai em 3s; depois só legendas dinâmicas | Voz do vendedor ou locução; trilha a −20 dB |
| **3. Condições & procedência** | 15–22s | Documento (CRLV com dados borrados), chave/manual se houver, vendedor falando para a câmera | Badges `BadgeCondicao` entrando um a um (48x, 21x, troca) + `legal` | Voz em primeiro plano |
| **4. CTA** | 22–30s | `TelaFinal`: logo, catálogo, WhatsApp, endereço | "Link do catálogo na bio" / "Chama no WhatsApp" | Trilha volta ao volume cheio e termina na batida |

**Versão de 15s:** gancho 0–2s → apresentação 2–9s (4 takes) → 1 badge + `legal` 9–12s → tela final 12–15s.

### Ritmo e cortes

- Corte seco é o padrão. Cada take dura 1,5–2,5s; nenhum take parado passa de 3s (exceto fala do vendedor, até 5s).
- Corte **na batida** da trilha. No CapCut: Áudio → Batidas → Auto, e alinhe os cortes às marcações.
- Transições permitidas (no máximo 2 por vídeo): **match cut** (roda → roda, farol → farol), **whip pan feito na câmera**, **speed ramp** curto (1 por vídeo, 0,3x → 1x em detalhes).
- Proibido: transições 3D, cubo, estrela, glitch pesado, flash branco repetido, zoom tremido automático, figurinhas/emojis animados, fontes "divertidas", textos girando, mais de 3 efeitos no mesmo vídeo.
- Primeiro frame já com conteúdo (nada de tela preta ou logo de abertura): o gancho é a moto.
- Capa do Reel (thumbnail): frame 3/4 frontal + `hook` em 2 linhas, dentro da área segura central 1080×1440 (o feed corta em 4:5).

### Trilha sonora

- Orgânico: áudio em alta do Instagram, com energia média-alta (90–130 BPM), sem letra explícita.
- Anúncio impulsionado: só música da biblioteca livre da Meta (Sound Collection) ou do CapCut "uso comercial" — áudio em alta pode ser bloqueado em anúncio.
- Com voz: trilha a −18 a −22 dB; sem voz: trilha a −8 dB e ronco do motor a −12 dB.
- Sempre um som real da moto (partida, ronco, pisca) nos primeiros 3s.

### Legendas e overlays

- Legenda dinâmica obrigatória em todo vídeo com fala (metade do público assiste sem som). CapCut: Texto → Legendas automáticas → revise erro a erro.
- Estilo `caption`: DM Sans 700, 52px, `ink`, sobre caixa `scrim` com `radius-md`, padding `space-2` × `space-3`. **3–5 palavras por linha, máx. 2 linhas.**
- Destaque: 1 palavra por frase (o modelo, "troca", "48x") em caixa `brand` com texto `on-brand`. Nunca amarelo, nunca contorno colorido.
- Posição: centralizada, entre y = 1100 e y = 1450 (acima do rodapé do Instagram, abaixo do rosto do vendedor).
- Animação de entrada: "pop" sutil ou "digitar" de 0,2s. Sem balanço, sem rotação.

### Margens de segurança (1080×1920)

Ver o componente `GuiaSafeZone` e importe o guia como camada de referência no CapCut (oculte antes de exportar).

| Zona | Medida | Token | O que fica de fora |
| --- | --- | --- | --- |
| Topo | 0–250px | `safe-top` | Barra "Reels", câmera, status |
| Rodapé | últimos 420px | `safe-bottom-reels` | @, legenda, áudio, botão seguir |
| Direita | últimos 160px | `safe-right-reels` | Curtir, comentar, compartilhar, áudio |
| Esquerda | 0–64px | `safe-side` | Bordas do aparelho |

Área livre para texto e badges: **x 64–920, y 250–1500**. Rostos e a moto podem ocupar a tela toda; texto, logo e badges nunca saem dessa área.

---

## 3. Props físicos e digitais

Objetos reais para o pátio e a loja da Rua Visconde de Inhaúma, e um kit gráfico que se cria **uma única vez** e se reutiliza em todos os vídeos.

### Props físicos (cenário)

| Item | Especificação | Para quê |
| --- | --- | --- |
| **Placa cenográfica** (2 unidades) | PVC expandido 3mm ou acrílico 3mm, 200×170mm (tamanho da placa Mercosul de moto), fundo `canvas`, logo branca centralizada, faixa `brand` de 20mm no topo, furos nas posições da placa original | Cobrir a placa real em fotos e vídeos. **Só para gravação dentro da loja/pátio** — nunca rodar em via pública com ela. |
| **Tag de chave AL Motos** | Chaveiro de acrílico vermelho `brand` ou couro preto com logo gravada, 1 por moto em destaque | Plano de entrega da chave, fecho de Reel ("a chave é sua") |
| **Tag de preço/ficha no guidão** | Cartão 10×15cm em PVC preto com área para modelo, ano e km (escrito à mão em caneta branca ou adesivo) | Planos gerais do pátio sem precisar de texto na edição. **Sem parcelas.** |
| **Bastão LED** (1–2) | Tubo LED RGB/branco 5600K, 60–120cm, bateria | Luz de recorte lateral no tanque e farol à noite; reflexo "linha" na carenagem |
| **Painel LED com difusor** | 30–50W, 5600K, softbox ou difusor | Luz principal dentro da loja |
| **Rebatedor 5 em 1** | 80cm, face branca/prata | Abrir sombras no pátio de dia |
| **Tapete de borracha preto** | 2×1m | Base limpa sob a moto (esconde mancha de óleo do piso) |
| **Cavalete central/pedestal** | Para motos sem descanso central | Plano de roda girando em ponto morto |
| **Kit de limpeza** | Microfibra, limpa-vidro para painel, pretinho fosco para pneu, flanela para cromados | Passar antes de cada gravação (30s por moto) |
| **Estabilizador + lapela** | Gimbal de celular e microfone de lapela sem fio | Arcos suaves em volta da moto; voz limpa do vendedor |
| **Camisa da equipe** | Camisa preta ou vermelha com logo (a polo vermelha já usada nos vídeos) | Vendedor sempre identificado em cena |

#### Posicionamento no pátio

- **Moto herói** isolada, 1,5m de qualquer outra, no tapete, em 3/4 frontal para a câmera, guidão virado para a câmera, descanso lateral.
- **Fundo**: parede de logos da loja ou porta de vidro com motos desfocadas atrás (abertura máxima / modo retrato). Nunca a rua, o portão ou o estacionamento de clientes.
- **Linha de estoque** (plano de abertura): motos alinhadas em diagonal, todas no mesmo ângulo, guidões para o mesmo lado, da mais baixa (Pop/Biz) à mais alta (XRE/Lander).
- **Câmera**: altura do tanque para a moto herói; altura do peito para fala do vendedor; rasante (20cm do chão) para roda e farol.

### Props digitais (kit CapCut / Canva)

O kit já está pronto em PNG transparente, em escala de 1080px: `docs/brand/kit/` (e no grupo **Kit** do Design System). No CapCut, importe cada PNG como sobreposição e salve como favorito; no Canva, envie para "Uploads" ou para o Kit de Marca. As peças de 1080×1920 (tela final, marca d'água, guia, capas) entram em tela cheia sem ajuste; as outras são recortadas e se posicionam dentro da área segura. Para campos variáveis use a versão `-base-vazia` e digite o texto por cima com as fontes do guia.

| Arquivo | Item |
| --- | --- |
| `badge-48x-financiamento.png` · `badge-21x-cartao.png` | Badges de condição |
| `tag-aceitamos-sua-usada-na-troca.png` · `selo-consignacao.png` | Tags neutras |
| `aviso-legal.png` | Aviso de crédito (obrigatório com 48x/21x) |
| `selo-ano-km-exemplo.png` · `selo-ano-km-base-vazia.png` | Selo ano/modelo + km |
| `tarja-moto-exemplo.png` · `tarja-moto-base-vazia.png` | Tarja da moto |
| `legenda-estilo-exemplo.png` | Referência do estilo de legenda |
| `tela-final-1080x1920.png` | Tela final (opaca) |
| `marca-dagua-1080x1920.png` | Marca d'água já posicionada |
| `guia-safe-zone-1080x1920.png` | Guia de margens (ocultar antes de exportar) |
| `capa-categoria-economicas/street/trail/scooters.png` | Capas de categoria |

Especificação de cada item:

| # | Item | Componente | Conteúdo fixo | Campos variáveis |
| --- | --- | --- | --- | --- |
| 1 | Badge de financiamento | `BadgeCondicao` | "Até **48x** no financiamento" | — |
| 2 | Badge de cartão | `BadgeCondicao` | "Até **21x** no cartão" | — |
| 3 | Tag de troca | `BadgeCondicao` | "Aceitamos sua usada na troca" | — |
| 4 | Aviso legal | `BadgeCondicao` (rodapé) | "*Sujeito a análise de crédito. Simule com nossa equipe." | — |
| 5 | Selo ano/modelo | `SeloAnoModelo` | — | Ano/modelo, km |
| 6 | Tarja da moto | `TarjaMoto` | Faixa `brand`, logo branca pequena | Marca + modelo, versão, ficha |
| 7 | Estilo de legenda | `Legenda` | Caixa `scrim` + destaque `brand` | Texto |
| 8 | Tela final | `TelaFinal` | Logo, `catalogo.almotoscaruaru.com.br`, botão WhatsApp, endereço | — |
| 9 | Marca d'água | logo branca | 180px, 65% opacidade, x 64 / y 260 | — |
| 10 | Guia de margens | `GuiaSafeZone` | Camada de referência — ocultar antes de exportar | — |
| 11 | Capa de categoria | — | `hook` + nome da categoria: "ECONÔMICAS", "STREET", "TRAIL", "SCOOTERS" | — |
| 12 | Selo "Consignação" | `BadgeCondicao` | "Venda sua moto com a gente — consignação" | — |

Categorias do estoque para capas e carrosséis:

- **Econômicas / urbano**: Honda Pop 110i, Biz 110i/125, Yamaha Crypton.
- **Street / trabalho**: Honda CG 160 (Start, Fan, Titan), Yamaha Factor 150, Fazer 150/250, Honda CB 300F Twister.
- **Trail / crossover**: Honda NXR 160 Bros, XRE 190, XRE 300 / Sahara 300, Yamaha Crosser 150, Lander 250.
- **Scooters / automáticas**: Honda PCX 160, Elite 125, Yamaha NMAX 160, Fluo 125.

### Especificação do kit digital

#### `BadgeCondicao` — Badge de condição

Pílula que anuncia uma condição comercial (48x, 21x, troca, consignação) em Reels, Stories e carrosséis.

**Variantes**
- **Vermelha** (`brand` + `on-brand`): condições de pagamento — "Até **48x** no financiamento", "Até **21x** no cartão". O número em Syne 800 (`condition`), o resto em DM Sans 700.
- **Neutra** (`surface-raised`, borda `line`, texto `ink`): "Aceitamos sua usada na troca", "Venda a sua com a gente · consignação".

**Medidas em 1080px:** altura 96px, padding 16 × 36px, raio `radius-pill`, número 56px, texto 40px. Exporte cada badge como PNG transparente.

**Uso**
- Entram uma por vez, 0,4s entre elas, no bloco 15–22s do Reel; no máx. 3 na tela.
- Sempre que aparecer 48x ou 21x, o aviso `legal` fica na mesma tela.
- Posição: centro-esquerda, dentro de x 64–920 / y 250–1500.

**Nunca**: valor de parcela, "sem juros", "aprovado", verde do WhatsApp no badge.

#### `SeloAnoModelo` — Selo de ano/modelo

Selo de duas partes com ano/modelo (bloco `brand`) e quilometragem (bloco `surface`), para ficar colado na moto em fotos e vídeos.

**Campos:** ano/modelo ("2023/2024" ou "2022"), km com ponto de milhar ("18.400 km"), cor opcional em `ink-muted`.

**Medidas em 1080px:** altura 72px, raio `radius-sm`, ano em Syne 800 48px, km em DM Sans 600 40px, borda 1px `line`.

**Uso**
- Canto superior direito da foto de estoque (respeitando 80px de margem) ou ao lado da `TarjaMoto` no Reel.
- O km é o que está no painel no dia da gravação — mostre o painel no vídeo para comprovar.
- Moto nova (0 km): escreva "0 km" só se for de fato nova, nunca para seminova.

#### `TarjaMoto` — Tarja da moto

Tarja de identificação da moto (lower third) que entra no primeiro take da apresentação e sai após 3s.

**Estrutura:** faixa `brand` com logo branca pequena + divisória + nome da moto em Syne 800 (`title-xl` reduzido para caber em uma linha) · fio `brand-hover` de 8px (eco das duas linhas de velocidade da logo) · faixa `scrim` com ficha em DM Sans 600 (`subtitle`): ano · km · cor.

**Medidas em 1080px:** largura máx. 856px (x 64–920), nome 60–72px, ficha 36–40px, raio `radius-sm` só nos cantos externos.

**Posição:** y ≈ 1180–1400 (acima do rodapé do Instagram). Nunca no topo (conflita com a marca d'água) e nunca sobre o rosto do vendedor.

**Animação:** desliza da esquerda em 0,3s (ease-out), sai para a esquerda em 0,2s. Sem rebote.

**O consumidor fornece:** marca + modelo + versão como a montadora escreve, ano/modelo, km do painel, cor.

#### `Legenda` — Legenda dinâmica

Estilo único de legenda dinâmica para todo vídeo com fala: texto `ink` em caixa `scrim`, com uma palavra de destaque em caixa `brand`.

**Regras**
- Fonte `caption`: DM Sans 700, 52px em 1080px, entrelinha 1,15, centralizada.
- Caixa `scrim` (preto 72%), raio `radius-md`, padding 16 × 24px.
- 3–5 palavras por linha, máx. 2 linhas por vez.
- 1 destaque por frase: o modelo, o número ("48x", "18 mil km") ou a palavra-chave ("troca"). Caixa `brand`, texto `on-brand`.
- Posição: centro, y 1100–1450.

**No CapCut:** gere legendas automáticas → selecione todas → aplique o estilo salvo "AL Motos Legenda" → corrija erros de modelo/números à mão.

**Nunca:** amarelo, contorno colorido, sombra forte, emoji, mais de uma cor de destaque.

#### `TelaFinal` — Tela final

Tela de encerramento padrão de todo Reel e Story (3–5s): logo, catálogo, WhatsApp e endereço, sempre igual.

**Estrutura (1080×1920)**
- Fundo `canvas` com brilho radial suave de `brand` a 18% atrás da logo.
- Logo vermelha principal, 560px de largura, y ≈ 290.
- Título `title-lg` em Syne 800: "Escolha a sua no nosso catálogo".
- Card `surface` (borda `line`, `radius-card`) com rótulo "Estoque em tempo real · link na bio" em `ink-muted` e `catalogo.almotoscaruaru.com.br` em `ink`.
- Botão `whatsapp` em `radius-pill` com ícone e número em `on-whatsapp` (texto escuro).
- Endereço em `ink-muted`, `subtitle`.
- Faixa `brand` nos 420px do rodapé (área que o Instagram cobre), cortada por duas linhas `canvas` — eco das linhas de velocidade da logo. Nenhum texto nessa faixa.

**Uso:** é a mesma tela em todos os vídeos; não troque cores nem texto por campanha. Para campanhas (Black November, 13º), troque só o título.

#### `GuiaSafeZone` — Guia de margens

Guia de margens de segurança do Instagram Reels/Stories em 1080×1920, para usar como camada de referência na edição.

**Zonas proibidas para texto, logo e badges**
- Topo 0–250px (`safe-top`): barra "Reels", câmera.
- Rodapé últimos 420px no Reels (`safe-bottom-reels`), 280px no Story (`safe-bottom-story`).
- Direita últimos 160px no Reels (`safe-right-reels`): curtir, comentar, compartilhar.
- Esquerda 0–64px (`safe-side`).

**Área segura:** x 64–920, y 250–1500. Legendas em y 1100–1450; marca d'água em x 64 / y 260.

**No CapCut:** importe o PNG do guia como sobreposição na 1ª faixa, opacidade 40%, trave a camada e **desative antes de exportar**. No Canva, use-o como elemento bloqueado e apague antes de baixar.

Feed/carrossel 4:5 (1080×1350): margem interna `safe-feed` 80px em todos os lados; a grade do perfil corta para 3:4 no centro, então o título fica no meio vertical.

---

## 4. Tom de voz, copy e compliance

Falamos como o vendedor de confiança do bairro: **direto, acolhedor, seguro**. Próximo de quem é de Caruaru e região, sem gíria forçada, sem exagero de vendedor de feira.

### Princípios

- **Direto:** o modelo e o ano na primeira frase. "Chegou CG 160 Titan 2023, vermelha, 18 mil km."
- **Transparente:** fala o que a moto tem, inclusive o detalhe. "Tem um risquinho no protetor, olha aqui." Mostrar defeito pequeno gera confiança.
- **Acolhedor:** trata por "você". Pode usar "a gente", "bora", "visse" com moderação (1 por vídeo). Nada de "mano", "tá ligado", "brabo", "monstra".
- **Agilidade sem promessa:** "a gente simula na hora", "avalia sua usada no mesmo dia" — nunca "aprova na hora".
- Emojis em legenda escrita: no máximo 3, funcionais (📍 endereço, 📲 WhatsApp, 🏍️ modelo). Nunca no vídeo.
- Hashtags: 5–8 no fim da legenda: `#almotoscaruaru #motoscaruaru #caruaru #motoseminova` + modelo (`#cg160`, `#nmax160`).

### Ganchos falados (0–3s) que funcionam

- "Essa aqui é pra quem trabalha de moto todo dia."
- "Tá pensando em trocar a sua? Olha o que chegou."
- "CG Titan 2023 com 18 mil km. Bora ver de perto?"
- "Sua moto usada pode virar entrada dessa aqui."
- "Scooter pra fugir do trânsito de Caruaru: NMAX 160."

### Diga / Evite

| Diga | Evite |
| --- | --- |
| "Financiamento em até 48x, simula com a gente no WhatsApp" | "Parcelas de R$ 299", "a partir de R$ X por mês" |
| "Cartão em até 21x" | "21x sem juros" (a menos que seja verdade e esteja escrito na simulação) |
| "Sujeito a análise de crédito" | "Aprovação garantida", "aprova na hora", "sem consulta", "nome sujo aprova" |
| "Avaliamos sua usada na troca" | "Pagamos a tabela FIPE na sua usada" |
| "Documentação conferida, pronta pra transferência" | "Revisada na nossa oficina" (**não temos oficina**) |
| "Pode vir ver e testar aqui na loja" | "Aluga", "locação", "diária" (**não alugamos**) |
| "Moto com 18.400 km no painel" | "Zero bala", "nova" para seminova, "única dona" sem comprovar |
| "Uma das opções mais econômicas pra rodar todo dia" | "A mais barata de Caruaru", "o menor preço do Nordeste" |
| "Seminova" / "nova" conforme o caso | "Moto de leilão" nunca (se não for) — e se for, informar |

### O que NUNCA dizer ou mostrar

1. Valor fixo de parcela, entrada ou juros — em fala, texto, legenda ou capa.
2. Promessa de aprovação de crédito de qualquer tipo.
3. Oficina, revisão, manutenção ou garantia mecânica própria.
4. Aluguel, locação ou moto por aplicativo "pra alugar".
5. Superlativos que não dá para provar ("a melhor", "a mais barata").
6. Placa real, dados do documento (nome, CPF, Renavam) ou rosto de cliente sem autorização.
7. Comparação depreciativa com outras lojas.

Sempre que aparecer **48x** ou **21x**, coloque o `legal` "*Sujeito a análise de crédito. Simule com nossa equipe." na mesma tela ou na legenda escrita.

### Condução do CTA

Escolha **um** CTA principal por peça, nesta ordem de prioridade:

1. **Catálogo** (descoberta de estoque): "Tem muito mais moto no nosso catálogo — link na bio." / na legenda: "📲 Estoque completo: catalogo.almotoscaruaru.com.br".
2. **WhatsApp** (moto específica, simulação, troca): "Chama no WhatsApp que a gente simula sua parcela." / "📲 (81) 99426-8997".
3. **Direct com palavra-chave** (para medir alcance): "Comenta EU QUERO que te mando as condições no direct."
4. **Visita** (prova social, loja): "📍 Rua Visconde de Inhaúma, 725 — Maurício de Nassau, Caruaru."

O CTA falado e o CTA escrito dizem a mesma coisa. A tela final (`TelaFinal`) sempre aparece, mesmo quando o CTA principal é Direct.

---

## 5. Templates de prompts

Três prompts prontos para colar no ChatGPT, Claude ou outro gerador. Troque só o que está entre `[COLCHETES]`. Para resultados ainda melhores, anexe este guia inteiro junto.

### Bloco de contexto fixo (já incluído nos 3 prompts)

```text
CONTEXTO AL MOTOS (não altere):
- Revenda de motos seminovas e novas em Caruaru/PE, Rua Visconde de Inhaúma, 725 – Maurício de Nassau. Instagram @almotoscaruaru.
- Fazemos SÓ compra, venda, troca e consignação. NÃO temos oficina. NÃO alugamos motos.
- Condições: financiamento em até 48x, cartão de crédito em até 21x, avaliação da usada na troca.
- PROIBIDO: valor de parcela/entrada/juros, promessa de aprovação, "sem consulta", oficina/revisão própria, aluguel, superlativos não comprováveis ("a mais barata"). Sempre que citar 48x ou 21x, incluir "*Sujeito a análise de crédito. Simule com nossa equipe."
- CTAs: catálogo catalogo.almotoscaruaru.com.br (link na bio), WhatsApp (81) 99426-8997, Direct com palavra-chave, visita à loja.
- Tom: direto, acolhedor, confiável, próximo de Caruaru sem gíria exagerada; trata por "você"; modelo e ano na primeira frase; transparente sobre detalhes da moto.
- Visual: Clean Automotive dark. Fundo #09090b, cards #121215/#18181b, bordas #27272a, texto #f6f6f8 e #a2a2ad, vermelho #eb0b0b (máx. 10% da peça), verde #25d366 só no botão de WhatsApp (texto escuro sobre ele). Fontes: Anton (ganchos, maiúsculas), Syne ExtraBold (títulos), DM Sans (legendas e texto). Sem degradê, neon, emoji em tela, amarelo ou estética "startup".
- Reels 1080x1920: texto só entre x 64–920 e y 250–1500 (fora do topo 250px, rodapé 420px e direita 160px).
```

### 1. Roteiro de Reel de apresentação de moto

```text
Você é roteirista e diretor de Reels da AL Motos. Use o CONTEXTO AL MOTOS abaixo à risca.

[COLE AQUI O BLOCO DE CONTEXTO FIXO]

MOTO: [Marca Modelo Versão] — Ano/modelo [AAAA/AAAA] — [XX.XXX] km — Cor [cor] — Categoria [Econômica | Street | Trail | Scooter]
DESTAQUES REAIS: [ex.: pneus novos, manual e chave reserva, único detalhe: risco no protetor]
QUEM APRESENTA: [nome do vendedor ou "sem fala, só locução/legenda"]
DURAÇÃO: [15s | 30s]
CTA PRINCIPAL: [Catálogo | WhatsApp | Direct "EU QUERO"]

Entregue em tabela com colunas: Tempo | Plano/ação de câmera | Fala (o que o vendedor diz) | Texto em tela (overlay) | Áudio/trilha.
Siga a arquitetura: 0–3s gancho (som real da moto + texto Anton em até 3 linhas) → 3–15s apresentação em 5–7 takes de 1,5–2s (3/4 frontal em arco, lateral, painel com km, motor, pneus, detalhe) → 15–22s condições (badges "Até 48x", "Até 21x no cartão", "Aceitamos sua usada na troca" + aviso legal) e procedência (documento com dados borrados, chave/manual SE houver) → 22–30s tela final padrão.
Regras: cortes secos na batida, máx. 2 transições (match cut, whip pan na câmera ou 1 speed ramp), legendas 3–5 palavras por linha. Depois da tabela, dê: 3 opções de gancho alternativo, 1 sugestão de capa (frame + texto de 2 linhas) e a lista de takes para gravar em ordem no pátio.
Não invente itens que não estão em DESTAQUES REAIS.
```

### 2. Post / carrossel de estoque ou comparativo

```text
Você é diretor de arte e redator da AL Motos. Use o CONTEXTO AL MOTOS abaixo à risca.

[COLE AQUI O BLOCO DE CONTEXTO FIXO]

TIPO: [Estoque da semana | Comparativo | Categoria]
MOTOS (uma por linha: Modelo – ano/modelo – km – cor – destaque real):
[...]
PÚBLICO DESTE POST: [ex.: quem trabalha com entrega | primeira moto | quem quer scooter para a cidade]
Nº DE SLIDES: [5–8], formato 1080x1350 (4:5).

Entregue slide a slide: Slide N | Imagem (qual foto, enquadramento 3/4 frontal/lateral/painel) | Título (Syne ExtraBold, até 6 palavras) | Texto de apoio (DM Sans, até 3 linhas) | Elementos (badge, selo de ano, tarja) | Observação de layout (margem interna 80px, card #121215 raio 24px).
Slide 1 = capa com gancho em Anton (até 3 linhas) e brilho vermelho suave atrás da moto. Último slide = CTA para o catálogo + WhatsApp + aviso legal.
Em comparativo: compare só dados verificáveis (cilindrada, tipo de uso, câmbio, consumo declarado pela montadora — indique a fonte), em tabela com linhas alternadas #121215/#18181b; nunca diga que uma é "melhor", diga "para quem…".
Não use valor de parcela. Preço à vista só se eu informar e for igual ao do catálogo.
```

### 3. Legenda + CTA de conversão

```text
Você é redator de conversão da AL Motos. Use o CONTEXTO AL MOTOS abaixo à risca.

[COLE AQUI O BLOCO DE CONTEXTO FIXO]

PEÇA: [Reel | Carrossel | Story] sobre [moto ou tema]
OBJETIVO: [Levar ao catálogo | Gerar conversa no WhatsApp | Comentários "EU QUERO" | Visita à loja | Captar motos para consignação]
DETALHES REAIS: [ano, km, cor, destaques]

Escreva 3 versões de legenda (curta: até 2 linhas; média: até 5 linhas; longa: até 9 linhas), cada uma com:
1. Primeira linha-gancho com modelo e ano (aparece antes do "mais").
2. Corpo com 2–3 benefícios reais e o tom AL Motos (você, a gente, sem gíria exagerada).
3. Condições em uma linha: "Financiamento em até 48x • Cartão em até 21x • Avaliamos sua usada na troca" + "*Sujeito a análise de crédito."
4. Um único CTA principal conforme OBJETIVO, com 📲 ou 📍.
5. 5–8 hashtags (#almotoscaruaru #motoscaruaru #caruaru + modelo).
No fim, entregue: 1 frase de CTA falado para os últimos 3s do vídeo (mesma mensagem da legenda) e 1 resposta-padrão para quem comentar "quanto fica a parcela?" (acolhedora, sem valor, levando para simulação no WhatsApp).
Máximo 3 emojis por legenda.
```
