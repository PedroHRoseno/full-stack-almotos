# Campanha Black November AL Motos — Guia de Gravação e Edição

> Módulo complementar do [`ALMOTOS_DESIGN_SYSTEM.md`](ALMOTOS_DESIGN_SYSTEM.md). **Tudo o que está no guia principal continua valendo** (tokens, fontes, margens de segurança, tom de voz, regras comerciais). Este arquivo só diz o que muda durante a campanha.
> Vigência sugerida: até **30/11/2026**. Ao acabar, volte ao kit padrão: nada de selo Black em dezembro.
> Arquivos prontos: [`docs/brand/kit/black-november/`](brand/kit/black-november/).

---

## 0. Regras comerciais na Black (leia antes de gravar)

As regras do guia principal ficam **mais rígidas** na Black November, porque o Procon e o público ficam de olho em "Black Fraude".

- **Nunca** divulgue valor de parcela, entrada ou juros, nem "aprovação garantida". Continua: "Financiamento em até 48x • Cartão em até 21x • *Sujeito a análise de crédito".
- **Desconto só se for real.** Se falar em "preço Black" ou "R$ X off", o preço anterior tem que estar no catálogo há pelo menos 30 dias e ser comprovável. Na dúvida, fale em **"condição especial"** e mande para a simulação, nunca em "desconto".
- **Troca:** diga "sua usada entra na troca", "avaliação na hora". **Nunca** diga "pagamos acima da FIPE" ou "sua usada vale mais", a menos que exista uma regra real e escrita.
- **Prazo:** toda peça com oferta mostra o prazo ("até 30/11" ou "enquanto durar o estoque"). Nada de "últimas horas" se não forem as últimas horas.
- Sem oficina, sem aluguel, sem "revisada": vale do mesmo jeito.

---

## 1. Adaptação visual (sem perder a cara da marca)

### Paleta da campanha

A base é a mesma. Entra **um** acento (o dourado) e **uma** textura (o carbono), e os dois só aparecem em elementos da campanha.

| Token | Hex | Função na Black | Limite |
| --- | --- | --- | --- |
| `canvas` | `#09090b` | Fundo dominante: a Black é mais escura que o normal | ≥ 80% da tela |
| `surface` / `surface-raised` | `#121215` / `#18181b` | Cards e textura carbono | — |
| `brand` | `#eb0b0b` | Faixa da oferta, barras de velocidade, palavra de destaque | ≤ 12% |
| `ink` | `#f6f6f8` | Textos | — |
| **`bn-gold`** | `#d4a24c` | Texto "BLACK NOVEMBER", contorno de selos e tarjas | **Só nos selos e tarjas da campanha**, ≤ 3% |
| **`bn-gold-light`** → **`bn-gold-deep`** | `#f0c46a` → `#d4a24c` → `#b8862f` | Degradê metálico vertical **só dentro das letras** "BLACK NOVEMBER" | Nunca em fundo, botão ou legenda |
| **`bn-carbon`** | listras 45° `#121215` / `#0d0d10`, 6px cada | Textura de fundo de selos e da tela final | Nunca atrás de texto pequeno |
| `whatsapp` | `#25d366` | Continua só no CTA de WhatsApp | — |

Contraste: dourado `#d4a24c` sobre `#09090b` dá 8,6:1. Pode ser usado em texto de qualquer tamanho, mas **reserve para a marca da campanha**.

**Regras visuais:**
- **Alto contraste:** grave com o fundo mais escuro (fim de tarde ou noite) e deixe a moto como o ponto mais claro da tela.
- **Proibido:** amarelo-ouro chapado em fundo grande, confete, fogos, glitter, preto puro `#000`, etiqueta "%" gigante, vermelho e dourado lado a lado em áreas iguais (vira "carnaval"), fonte nova. As famílias continuam Anton, Syne e DM Sans.
- **Feed:** no máximo **1 a cada 3 posts** com a capa Black. Os outros são posts normais com o **selo horizontal** no canto, para a grade do perfil não virar um bloco amarelo.
- A **logo** continua nas versões oficiais. Nunca deixe a logo dourada.

### Identidade gráfica da campanha (kit pronto)

| Arquivo | O que é | Onde usar |
| --- | --- | --- |
| `bn-selo-circular.png` (620px) | Selo redondo: fundo carbono, aro dourado duplo, "BLACK NOVEMBER" em Anton com degradê dourado, logo branca e as duas barras de velocidade em vermelho | Canto da capa do Reel, slide 1 do carrossel, Stories. Use com 260 a 340px de largura em 1080 |
| `bn-selo-horizontal.png` | Pílula: logo branca \| BLACK NOVEMBER | Marca d'água da campanha (substitui a marca d'água padrão): x 64 / y 260, 360px de largura |
| `bn-tarja-oferta-relampago.png` | Tarja: topo preto com BLACK NOVEMBER dourado + faixa vermelha "Oferta relâmpago no pátio" + rodapé "Condição especial de entrada · simule no WhatsApp" | Formato 1 |
| `bn-tarja-vitrine-black.png` | Mesma estrutura: "Vitrine Black do pátio" + URL do catálogo | Formato 2 |
| `bn-tarja-sua-usada-na-troca.png` | Mesma estrutura: "Sua usada entra na troca" + "Avaliação na hora" | Formato 3 |
| `bn-tarja-base-vazia.png` | Tarja sem texto | Escreva o nome da moto na faixa vermelha (Syne ExtraBold, 56–64px) |
| `bn-capa-1080x1920.png` | Capa transparente: logo + 2026, "BLACK" dourado / "NOVEMBER" branco em Anton 210px, barras vermelhas, "Condições especiais até 30/11" | Primeiro frame e thumbnail dos Reels, sobre um frame escuro da moto |
| `bn-tela-final-1080x1920.png` | Tela final Black: carbono, pílula dourada, logo, catálogo, WhatsApp, aviso legal com prazo | Últimos 3s de **todos** os Reels da campanha |

**Posição das tarjas:** dentro de x 64–920 e y 1150–1450, entrando da esquerda em 0,3s e saindo depois de 3s. Nunca use duas tarjas juntas na tela. Os selos e tarjas padrão (48x, 21x, troca) continuam valendo **em cima do fundo Black**.

---

## 2. Props físicos e ambientação rápida no pátio

Orçamento total estimado: R$ 250 a 450, reaproveitável no ano que vem.

| Prop | Especificação | Como usar em cena | Custo aprox. |
| --- | --- | --- | --- |
| **2 bastões LED** (vermelho + branco) | Tubo LED RGB 60–120cm, com bateria | Atrás e ao lado da moto, inclinados a 45°, um vermelho e outro branco frio. Fazem linhas de reflexo no tanque e na carenagem | R$ 120–250 |
| **Fita LED vermelha** | 5m, 12V ou USB, com adesivo | No rodapé da parede de logos ou embaixo do balcão: dá o brilho vermelho do fundo | R$ 30–50 |
| **Placa cenográfica Black** | PVC 3mm, 200×170mm: fundo preto fosco, "BLACK NOVEMBER" em dourado (adesivo vinil metalizado) e logo branca | Troca a placa cenográfica padrão durante a campanha. **Só para gravar dentro da loja** | R$ 25–40 |
| **Tag de guidão / retrovisor** | Cartão PVC preto 9×15cm, furo + cordão vermelho, borda em vinil dourado, escrito "BLACK NOVEMBER AL MOTOS · Condição especial" | Pendurada no retrovisor esquerdo, virada para a câmera. Aparece em todo plano 3/4 | R$ 5 cada (10 unidades) |
| **Faixa de chão** | Fita adesiva vermelha de 5cm, em duas linhas paralelas (não use a fita zebrada preta e amarela) | Duas linhas no piso na frente da moto herói (as "barras de velocidade" da logo) | R$ 15 |
| **Tapete preto fosco** | O do kit padrão | Base escura limpa: destaca a moto e esconde o piso | — |
| **Capa de moto preta** | Capa comum de cetim ou lona preta | Revelação no gancho: vendedor puxa a capa | R$ 40–60 |
| **Camisa preta da equipe** | Polo preta com logo | Todos de preto durante a campanha | — |

### Ambientação em 10 minutos

1. **Horário:** do fim da tarde até a noite (a partir das 17h30) ou loja com a porta fechada. Desligue as lâmpadas amarelas e deixe só o LED branco principal + os bastões.
2. **Moto herói** no tapete, em 3/4 frontal, com a faixa vermelha no chão à frente, a tag no retrovisor e a placa Black.
3. **Fundo:** a parede de logos com a fita LED vermelha embaixo, **desfocada** (modo retrato ou 2x afastado da parede, pelo menos 2m).
4. **Bastão vermelho** atrás da moto, no lado oposto à câmera. **Bastão branco** do lado da câmera, a 45° e na altura do tanque.
5. **Teste:** tire uma foto. Se o vermelho do LED "pintar" uma moto vermelha inteira, afaste o bastão ou troque por branco. A cor real da moto precisa aparecer.

O espectador percebe que é Black em 1 segundo pelo **escuro + linhas de luz + tag dourada**, sem precisar de nenhum texto.

---

## 3. Formatos de Reels de alta conversão

Comum aos três formatos: 1080×1920 a 30fps · marca d'água = `bn-selo-horizontal` · legendas no estilo padrão (DM Sans 700, caixa escura, destaque vermelho) · tela final Black nos últimos 3s · aviso "*Sujeito a análise de crédito" sempre que aparecer 48x ou 21x.

### Formato 1 — "Oportunidade Relâmpago" (15s)

Uma moto de giro rápido (CG 160, Biz 125, Bros 160). Objetivo: **conversa no WhatsApp**.

| Tempo | Visual (câmera) | Texto em tela | Áudio / fala | Edição |
| --- | --- | --- | --- | --- |
| 0–2s | Escuro total → vendedor puxa a capa preta; os bastões acendem (ou o farol liga) | `bn-capa` reduzida: "BLACK NOVEMBER" + nome da moto em Anton: "CG 160 TITAN" | Ronco da partida no frame 1; batida grave da trilha | Corte seco na batida; sem fade de abertura |
| 2–5s | Arco de 3/4 frontal com o gimbal, lento | `bn-tarja-base-vazia` com "Honda CG 160 Titan 2023" | "Chegou CG Titan 2023 na Black da AL Motos." | Tarja entra em 0,3s |
| 5–9s | 3 takes de 1,3s: painel ligado (km) → tag dourada no retrovisor → pneu/roda | `SeloAnoModelo` (ano + km), depois a legenda | "18 mil km, documento em dia, pronta pra rodar." | Cortes na batida; 1 speed ramp no take da roda |
| 9–12s | Vendedor de frente, tag em primeiro plano | `bn-tarja-oferta-relampago` + badge 48x + aviso legal | "Condição especial de entrada nesta semana. Simula comigo no WhatsApp." | Badge entra 0,4s depois da tarja |
| 12–15s | `bn-tela-final` | (na própria tela) | "Chama no Zap: é só essa unidade." *(só se for verdade)* | Trilha termina na batida |

**Legenda escrita:** "🏍️ CG 160 Titan 2023 · 18 mil km na Black November AL Motos. Condição especial de entrada até 30/11, simulação personalizada no WhatsApp 📲 (81) 99426-8997. Financiamento em até 48x • Cartão em até 21x • *Sujeito a análise de crédito."

### Formato 2 — "Vitrine Black / Top 3 do Pátio" (25s)

Uma moto econômica, uma street e uma trail. Objetivo: **tráfego para o catálogo**.

| Tempo | Visual (câmera) | Texto em tela | Áudio / fala | Edição |
| --- | --- | --- | --- | --- |
| 0–3s | Plano aberto do pátio escuro, a câmera avança devagar entre as motos alinhadas; os LEDs fazem linhas | `bn-capa`: "BLACK NOVEMBER" + "TOP 3 DO PÁTIO" | Batida + "Separei 3 motos pra você ver na Black." | Primeiro frame já em movimento |
| 3–9s | **Econômica** (ex.: Biz 125): 3/4 → painel → banco/baú | `bn-tarja-base-vazia`: "1 · Econômica — Biz 125 2022" | "Pra economizar no dia a dia: Biz 125." | 3 cortes de 2s; tarja só no 1º take |
| 9–15s | **Street** (ex.: Fazer 250): 3/4 → motor → farol | "2 · Street — Fazer 250 2021" | "Pra quem roda muito: Fazer 250." | Transição: whip pan feito na câmera |
| 15–21s | **Trail** (ex.: Bros 160): rasante na roda → 3/4 → lateral | "3 · Trail — Bros 160 2023" | "E pra encarar estrada de barro: Bros 160." | Match cut roda → roda |
| 21–25s | `bn-tela-final` | `bn-tarja-vitrine-black` some, entra a tela final | "Tem muito mais no catálogo, link na bio." | Trilha sobe e fecha |

Regra: **não compare** "qual é a melhor". Diga "pra quem…". Use um ano, km e cor reais em cada uma (a ficha precisa bater com o catálogo).

**Legenda escrita:** "Top 3 da Vitrine Black AL Motos 🏍️ Biz 125 • Fazer 250 • Bros 160, e o estoque completo em tempo real no catálogo: catalogo.almotoscaruaru.com.br (link na bio). Condições especiais até 30/11. *Sujeito a análise de crédito."

### Formato 3 — "Sua Usada Entra na Troca" (20s)

Para quem já tem moto e quer subir de categoria. Objetivo: **trazer o cliente com a moto dele** (WhatsApp ou visita).

| Tempo | Visual (câmera) | Texto em tela | Áudio / fala | Edição |
| --- | --- | --- | --- | --- |
| 0–3s | Moto "antiga" (ex.: Pop 110i de um cliente ou do estoque) parada; o vendedor aponta para ela | Anton: "TÁ COM ESSA?" | "Tá com uma moto dessas e quer subir de nível?" | Corte seco; som do pisca |
| 3–6s | Match cut: a câmera vira para a moto nova (ex.: CG 160 Fan ou XRE 190) com os LEDs acesos | Anton: "PODE SAIR COM ESSA." | Ronco da nova; batida forte | Speed ramp curto na virada (o único do vídeo) |
| 6–12s | Vendedor de frente segura a chave da moto do cliente e a tag Black | `bn-tarja-sua-usada-na-troca` | "Na Black November sua usada entra na troca: a gente avalia na hora, aqui na loja." | Legenda com destaque vermelho em "troca" |
| 12–16s | Detalhes rápidos da nova: painel → tanque → tag | Badges "Aceitamos sua usada na troca" + 48x + aviso legal | "O resto você financia em até 48x ou passa no cartão em até 21x." | Badges entram um por vez |
| 16–20s | `bn-tela-final` | — | "Traz sua moto e o documento. Rua Visconde de Inhaúma, 725." | Fecha na batida |

**Quebra de objeção** (escolha 1 para a legenda ou para o comentário fixado):
- "Não sei quanto vale a minha" → "Traz que a gente avalia na hora, sem compromisso."
- "Minha moto ainda tá financiada" → "Chama no WhatsApp que a gente vê o seu caso." *(nunca prometa quitar)*
- "Não tenho entrada" → "Sua usada pode ser a entrada. Simula com a gente."

**Legenda escrita:** "Sua usada entra na troca na Black November AL Motos 🏍️ Avaliação na hora aqui na loja e o restante em até 48x no financiamento ou 21x no cartão. Até 30/11. 📍 Rua Visconde de Inhaúma, 725 · Maurício de Nassau · 📲 (81) 99426-8997. *Sujeito a análise de crédito."

---

## 4. Checklist: gravar e editar em menos de 20 minutos

### Antes (uma vez só, ~30 min)
- [ ] Importar no CapCut (Sobreposição → favoritos) todos os PNGs de `docs/brand/kit/black-november/` e `docs/brand/kit/`.
- [ ] Instalar as fontes Anton, Syne e DM Sans no celular (CapCut → Texto → Fontes → Importar).
- [ ] Salvar no CapCut um **modelo de projeto** por formato (1, 2 e 3), com os PNGs já posicionados nos tempos das tabelas, a tela final no fim e o estilo de legenda "AL Motos Legenda".
- [ ] Imprimir as tags de guidão e a placa Black.

### Gravação (~8 min por vídeo)
- [ ] **1 min:** limpar a moto (microfibra, painel, pneu), pôr a placa Black, a tag no retrovisor e o tapete.
- [ ] **1 min:** apagar as luzes amarelas; bastão vermelho atrás e bastão branco do lado; fita LED ligada.
- [ ] **Celular:** limpar a lente · vertical · 1080p 30fps (o 60fps fica só para a roda) · travar exposição e foco (segurar na tela) · baixar a exposição em 0,3–0,7 · lente 1x · modo avião.
- [ ] **5 min:** gravar os takes **na ordem da tabela** do formato, cada take com 4–5s (sobra para cortar). Duas versões de cada fala.
- [ ] **1 min:** conferir no rolo que o km do painel está legível e que a placa real não aparece.

### Edição no CapCut (~10 min)
1. **(1 min)** Abrir o modelo do formato → "Substituir" os clipes na ordem.
2. **(2 min)** Áudio → Extrair batidas → alinhar os cortes às marcações. Takes de 1,3–2s; fala até 4s.
3. **(1 min)** Ajuste geral: contraste +10, realce −15, sombra −10, temperatura −5 (puxa para o frio). Nunca filtro pronto.
4. **(2 min)** Texto → Legendas automáticas → revisar modelo, ano, km e "48x" → aplicar o estilo salvo → 1 destaque vermelho por frase.
5. **(1 min)** Conferir se tarjas e badges estão nos tempos certos, com o aviso legal junto de 48x/21x.
6. **(1 min)** Ligar `guia-safe-zone` → conferir as margens → **desligar o guia**.
7. **(1 min)** Volume: voz em 100%, trilha em 15–20% durante a fala e 60% sem fala. Se for impulsionar, use só música livre de direitos.
8. **(1 min)** Exportar em 1080p · 30fps · taxa de bits "Recomendada/Alta". Capa: um frame da moto + `bn-capa`.

### Antes de postar (~1 min)
- [ ] Sem valor de parcela, sem "aprovação garantida", sem "desconto" que não dê para provar.
- [ ] O prazo "até 30/11" aparece na tela final e na legenda.
- [ ] A legenda escrita tem: modelo + ano na 1ª linha, condições, aviso legal, **um** CTA e 5–8 hashtags (`#blacknovember #almotoscaruaru #motoscaruaru #caruaru` + modelo).
- [ ] Comentário fixado com a resposta padrão para "quanto fica a parcela?": "Depende da sua entrada e do seu perfil. Chama no WhatsApp (81) 99426-8997 que a gente simula agora, sem compromisso. 😉"
