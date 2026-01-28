# Guia: Repositório pai + submodules (AlMotos)

Este guia explica como transformar a pasta `full-stack-almotos` em um **repositório Git pai** e os projetos `almotos-front` e `vehicle-sales-manager-v2-kotlin` em **submódulos Git**. Tudo pode ser feito pelo terminal do Cursor (PowerShell no Windows).

---

## Pré-requisitos

1. **Git instalado**  
   No Cursor: **Terminal** → **New Terminal** (ou `` Ctrl+` ``). Verifique:
   ```powershell
   git --version
   ```

2. **Conta em um host remoto** (GitHub, GitLab, etc.)  
   Você vai precisar de **dois repositórios vazios** (ou já existentes):
   - um para o **frontend** (ex.: `almotos-front`)
   - um para o **backend** (ex.: `vehicle-sales-manager-v2-kotlin`)

3. **URLs dos repositórios**  
   Exemplos (substitua pelo seu usuário/organização):
   - Frontend: `https://github.com/SEU_USUARIO/almotos-front.git`
   - Backend: `https://github.com/SEU_USUARIO/vehicle-sales-manager-v2-kotlin.git`

---

## Visão geral do que será feito

| Etapa | O que acontece |
|-------|-----------------|
| 1 | Criar (ou ter) os dois repositórios remotos e ter o código de cada projeto neles |
| 2 | Na pasta **pai** `full-stack-almotos`, remover as pastas atuais dos projetos (ou fazer backup) |
| 3 | Inicializar o Git na pasta pai e adicionar os dois projetos como **submódulos** |
| 4 | Configurar `.gitignore` e commit inicial do repositório pai |

Os submódulos são links para commits específicos de outros repositórios. O repositório pai só guarda o **caminho** e o **commit** de cada submódulo.

---

## Cenário A: Os dois projetos ainda **não** estão em repositórios remotos

Se `almotos-front` e `vehicle-sales-manager-v2-kotlin` ainda não têm histórico Git ou ainda não foram enviados a um remoto, faça primeiro:

### A.1 – Criar os repositórios no GitHub/GitLab

1. Crie **dois** repositórios vazios (sem README, sem .gitignore):
   - `almotos-front`
   - `vehicle-sales-manager-v2-kotlin`

2. Anote as URLs de clone (HTTPS ou SSH), por exemplo:
   - `https://github.com/SEU_USUARIO/almotos-front.git`
   - `https://github.com/SEU_USUARIO/vehicle-sales-manager-v2-kotlin.git`

### A.2 – Enviar cada projeto para o seu repositório

Abra o terminal na **raiz do workspace** (onde está `full-stack-almotos`).

**Frontend:**

```powershell
cd "c:\Users\PICHAU\Desktop\full-stack-almotos\almotos-front"
git init
git add .
git commit -m "chore: initial commit frontend AlMotos"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/almotos-front.git
git push -u origin main
cd ..
```

**Backend:**

```powershell
cd "c:\Users\PICHAU\Desktop\full-stack-almotos\vehicle-sales-manager-v2-kotlin"
git init
git add .
git commit -m "chore: initial commit backend AlMotos"
git branch -M main
git remote add origin https://github.com/SEU_USUARIO/vehicle-sales-manager-v2-kotlin.git
git push -u origin main
cd ..
```

Substitua `SEU_USUARIO` e a URL pelo seu repositório real. Depois disso, siga o **Cenário B** a partir da seção B.2.

---

## Cenário B: Os dois projetos **já** estão em repositórios remotos

Se cada projeto já tem `git init` e `origin` apontando para GitHub/GitLab, use só a parte abaixo.

### B.1 – URLs dos submódulos

Defina as URLs (no PowerShell pode usar variáveis para não errar):

```powershell
$FRONT_URL = "https://github.com/PedroHRoseno/almotos-front.git"
$BACK_URL  = "https://github.com/PedroHRoseno/vehicle-sales-manager-v2-kotlin.git"
```

### B.2 – Backup e remoção das pastas dos projetos

O `git submodule add` **só** funciona em pastas vazias ou inexistentes. Por isso:

1. **Backup (recomendado):** copie a pasta `full-stack-almotos` inteira para outro lugar (ex.: `full-stack-almotos-backup`).

2. **Remover as pastas dos projetos da pasta pai**  
   Na raiz do projeto pai:

   ```powershell
   cd "c:\Users\PICHAU\Desktop\full-stack-almotos"
   Remove-Item -Recurse -Force almotos-front
   Remove-Item -Recurse -Force vehicle-sales-manager-v2-kotlin
   ```

   Se ainda **não** tiver feito o push dos projetos (Cenário A), faça o backup, faça o push (A.2) e **só depois** apague essas pastas e continue abaixo.

### B.3 – Inicializar o repositório pai e adicionar submódulos

Siga **nessa ordem**:

```powershell
cd "c:\Users\PICHAU\Desktop\full-stack-almotos"
git init
git branch -M main
```

Adicionar o **frontend** como submódulo (o Git clona o repo na pasta informada):

```powershell
git submodule add $FRONT_URL almotos-front
```

Adicionar o **backend** como submódulo:

```powershell
git submodule add $BACK_URL vehicle-sales-manager-v2-kotlin
```

(Se não tiver definido `$FRONT_URL` e `$BACK_URL`, use as URLs literais no lugar.)

### B.4 – Arquivos do repositório pai

O Git cria o arquivo `.gitmodules` na raiz. Confira:

```powershell
Get-Content .gitmodules
```

Deve aparecer algo como:

```ini
[submodule "almotos-front"]
	path = almotos-front
	url = https://github.com/SEU_USUARIO/almotos-front.git
[submodule "vehicle-sales-manager-v2-kotlin"]
	path = vehicle-sales-manager-v2-kotlin
	url = https://github.com/SEU_USUARIO/vehicle-sales-manager-v2-kotlin.git
```

Crie ou ajuste o **`.gitignore`** na raiz do pai para não versionar coisas desnecessárias (o conteúdo dos submódulos já é controlado pelos repos deles):

```powershell
@"
# IDEs / OS
.vscode/
.idea/
*.suo
.DS_Store

# Logs / temp
*.log
*.tmp
"@ | Set-Content -Path ".gitignore" -Encoding utf8
```

Quem já tiver um `.gitignore` no pai pode só acrescentar as linhas acima.

### B.5 – Primeiro commit do repositório pai

```powershell
git add .gitmodules .gitignore
git add almotos-front vehicle-sales-manager-v2-kotlin
git status
git commit -m "chore: add almotos-front and vehicle-sales-manager-v2-kotlin as submodules"
```

O `git add` dos nomes das pastas grava o **commit** em que cada submódulo está; os arquivos dentro delas continuam sendo gerenciados pelos próprios repositórios.

### B.6 – Criar e enviar o repositório remoto do pai (opcional)

1. Crie um repositório vazio no GitHub/GitLab para o **monorepo** (ex.: `full-stack-almotos`).

2. Adicione o remote e faça o primeiro push:

   ```powershell
   git remote add origin https://github.com/SEU_USUARIO/full-stack-almotos.git
   git push -u origin main
   ```

---

## Clonar o projeto no futuro (você ou outra pessoa)

Para ter a pasta pai **e** os submódulos preenchidos de uma vez:

```powershell
git clone --recurse-submodules https://github.com/SEU_USUARIO/full-stack-almotos.git
cd full-stack-almotos
```

Se o clone foi feito **sem** `--recurse-submodules`, as pastas dos submódulos ficam vazias. Para preencher depois:

```powershell
cd full-stack-almotos
git submodule update --init --recursive
```

---

## Fluxo de trabalho no dia a dia

### Trabalhar só no frontend

```powershell
cd almotos-front
git checkout main
# ... editar arquivos ...
git add .
git commit -m "feat: sua mensagem"
git push origin main
cd ..
git add almotos-front
git commit -m "chore: atualiza submódulo almotos-front"
git push origin main
```

O último `git add almotos-front` + `commit` + `push` no **pai** atualiza o commit que o pai “fixa” para o frontend.

### Trabalhar só no backend

```powershell
cd vehicle-sales-manager-v2-kotlin
git checkout main
# ... editar arquivos ...
git add .
git commit -m "fix: sua mensagem"
git push origin main
cd ..
git add vehicle-sales-manager-v2-kotlin
git commit -m "chore: atualiza submódulo vehicle-sales-manager-v2-kotlin"
git push origin main
```

### Atualizar os submódulos para o último commit de cada repo

Dentro do repositório pai:

```powershell
git submodule update --remote --merge
git add almotos-front vehicle-sales-manager-v2-kotlin
git status
git commit -m "chore: update submodules to latest"
git push origin main
```

---

## Comandos úteis

| Objetivo | Comando |
|----------|---------|
| Ver status dos submódulos | `git submodule status` |
| Ver em qual commit cada um está | `git submodule status` ou olhar no `git log` do pai |
| Entrar em um submódulo | `cd almotos-front` ou `cd vehicle-sales-manager-v2-kotlin` |
| Sincronizar URLs do `.gitmodules` em clones antigos | `git submodule sync` |
| Atualizar submod para o commit gravado no pai | `git submodule update --init --recursive` |

---

## Resumo rápido (quando os dois repos já existem no remoto)

```powershell
cd "c:\Users\PICHAU\Desktop\full-stack-almotos"
# 1) Backup das pastas almotos-front e vehicle-sales-manager-v2-kotlin, se ainda não tiverem sido enviadas ao remoto.
# 2) Remover as pastas
Remove-Item -Recurse -Force almotos-front
Remove-Item -Recurse -Force vehicle-sales-manager-v2-kotlin
# 3) Init pai e submodules
git init
git branch -M main
git submodule add https://github.com/SEU_USUARIO/almotos-front.git almotos-front
git submodule add https://github.com/SEU_USUARIO/vehicle-sales-manager-v2-kotlin.git vehicle-sales-manager-v2-kotlin
# 4) Commit
git add .
git commit -m "chore: add frontend and backend as submodules"
# 5) (Opcional) Remote do pai
git remote add origin https://github.com/SEU_USUARIO/full-stack-almotos.git
git push -u origin main
```

Substitua `SEU_USUARIO` e as URLs pelos seus repositórios reais.

---

## Onde executar os comandos no Cursor

1. Abra o Cursor na pasta **`full-stack-almotos`** (File → Open Folder).
2. Abra o terminal: **Terminal** → **New Terminal** ou `` Ctrl+` ``.
3. O shell será PowerShell no Windows; os comandos acima são compatíveis.
4. Troque de pasta com `cd "c:\Users\PICHAU\Desktop\full-stack-almotos"` quando estiver em outro diretório.

Se precisar de um único repositório (monorepo) em vez de pai + submódulos, o fluxo é outro: um único `git init` na raiz e tudo versionado junto, sem `git submodule`.
