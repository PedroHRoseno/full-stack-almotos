<#
.SYNOPSIS
  Ambiente de QA local da AL Motos: backend + painel com dados de teste, num comando.

.DESCRIPTION
  up      Sobe tudo (cria o banco de QA na primeira vez) e mostra os endereços e logins.
  reset   Para tudo, recria o banco de QA do zero e sobe de novo.
  down    Para backend, painel (e o Postgres de QA, se estiver em uso).
  status  Mostra o que está rodando.
  logs    Mostra as últimas linhas dos logs do backend e do painel.

  Por padrão usa SQLite. Com -Postgres usa um Postgres próprio do QA (Docker, porta 5433)
  e roda as migrações 013-015 de verdade (downgrade + upgrade).

  Segurança: o backend do QA lê só almotos-backend/.env.qa (FORECAST_AMBIENTE=MOCK, sem
  token). A ForeCast é simulada; nenhuma nota sai da máquina.

.EXAMPLE
  ./scripts/qa.ps1 up
  ./scripts/qa.ps1 reset -Postgres
  ./scripts/qa.ps1 down
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("up", "reset", "down", "status", "logs")]
    [string]$Command = "up",
    [switch]$Postgres
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
$Backend = Join-Path $Root "almotos-backend"
$Front = Join-Path $Root "almotos-front"
$StateDir = Join-Path $Root ".qa"
$StateFile = Join-Path $StateDir "state.json"
$BackendPort = 8090
$FrontPort = 3010
$PgUrl = "postgresql://qa:qa@localhost:5433/almotos_qa"
$Compose = Join-Path $Backend "docker-compose.qa.yml"

function Write-Step([string]$Text) { Write-Host "==> $Text" -ForegroundColor Cyan }
function Write-Ok([string]$Text) { Write-Host "    $Text" -ForegroundColor Green }
function Write-Warn([string]$Text) { Write-Host "    $Text" -ForegroundColor Yellow }

function Read-State {
    if (Test-Path $StateFile) { return Get-Content $StateFile -Raw | ConvertFrom-Json }
    return $null
}

function Save-State($State) {
    New-Item -ItemType Directory -Force $StateDir | Out-Null
    $State | ConvertTo-Json | Set-Content -Path $StateFile -Encoding utf8
}

function Test-Port([int]$Port) {
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $async = $client.BeginConnect("127.0.0.1", $Port, $null, $null)
        $ok = $async.AsyncWaitHandle.WaitOne(300) -and $client.Connected
        $client.Close()
        return $ok
    } catch { return $false }
}

function Stop-Tree([int]$ProcessId) {
    if (Get-Process -Id $ProcessId -ErrorAction SilentlyContinue) {
        & taskkill /T /F /PID $ProcessId 2>$null | Out-Null
    }
}

function Wait-Http([string]$Url, [int]$Seconds) {
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -lt 500) { return $true }
        } catch {
            if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -lt 500) { return $true }
        }
        Start-Sleep -Milliseconds 800
    }
    return $false
}

function Set-QaEnv([bool]$UsePostgres) {
    # Variáveis só deste processo (e dos filhos): não mexe no ambiente do usuário.
    $env:ALMOTOS_ENV_FILE = ".env.qa"
    if ($UsePostgres) { $env:DB_URL = $PgUrl } else { Remove-Item Env:DB_URL -ErrorAction SilentlyContinue }
    # Nunca herdar token real de um terminal que tenha FORECAST_* exportado.
    Get-ChildItem Env: | Where-Object { $_.Name -like "FORECAST_*" } | ForEach-Object { Remove-Item "Env:$($_.Name)" }
}

function Invoke-Backend([string[]]$Arguments) {
    Push-Location $Backend
    try {
        & python -m uv run @Arguments
        if ($LASTEXITCODE -ne 0) { throw "Falhou: uv run $($Arguments -join ' ')" }
    } finally { Pop-Location }
}

function Initialize-Database([bool]$UsePostgres, [bool]$Reset) {
    $envQa = Join-Path $Backend ".env.qa"
    if (-not (Test-Path $envQa)) {
        Copy-Item (Join-Path $Backend ".env.qa.example") $envQa
        Write-Ok "Criado almotos-backend/.env.qa (a partir do .env.qa.example)."
    }
    if ($UsePostgres) {
        Write-Step "Postgres de QA (Docker, porta 5433)"
        & docker info *> $null
        if ($LASTEXITCODE -ne 0) { throw "Docker não está rodando. Abra o Docker Desktop ou use o modo padrão (sem -Postgres)." }
        if ($Reset) { & docker compose -f $Compose down -v | Out-Null }
        & docker compose -f $Compose up -d --wait
        if ($LASTEXITCODE -ne 0) { throw "Não subiu o Postgres de QA." }
        if ($Reset) {
            Write-Step "Schema no Postgres + teste das migrações 013-015 (downgrade e upgrade)"
            Invoke-Backend @("python", "-c", "import asyncio; from almotos_backend.qa_seed import _reset_schema; from almotos_backend.db import dispose_engine; asyncio.run(_reset_schema()); asyncio.run(dispose_engine())")
            Invoke-Backend @("alembic", "stamp", "head")
            Invoke-Backend @("alembic", "downgrade", "012_vehicle_optional_plate")
            Invoke-Backend @("alembic", "upgrade", "head")
            Write-Ok "Migrações 013-015 desceram e subiram sem erro."
        }
    }
    Write-Step "Dados de QA"
    $seedArgs = @("python", "-m", "almotos_backend.qa_seed")
    if ($Reset) { $seedArgs += "--reset" }
    Invoke-Backend $seedArgs
}

function Start-Qa([bool]$UsePostgres, [bool]$Reset) {
    $state = Read-State
    if ($state -and $state.backendPid -and (Get-Process -Id $state.backendPid -ErrorAction SilentlyContinue)) {
        if (-not $Reset) {
            Write-Warn "O QA já está rodando. Use 'reset' para recriar ou 'down' para parar."
            Show-Summary $state
            return
        }
    }
    foreach ($port in @($BackendPort, $FrontPort)) {
        if (Test-Port $port) { throw "A porta $port já está em uso por outro programa. Libere-a e tente de novo." }
    }

    Set-QaEnv $UsePostgres
    $sqlite = Join-Path $Backend "qa.sqlite"
    $needsSeed = $Reset -or ($UsePostgres -and -not $state.seeded) -or (-not $UsePostgres -and -not (Test-Path $sqlite))
    if (-not (Test-Path (Join-Path $Front "node_modules"))) {
        Write-Step "Instalando dependências do painel (primeira vez)"
        Push-Location $Front; try { & npm install; if ($LASTEXITCODE -ne 0) { throw "npm install falhou" } } finally { Pop-Location }
    }
    Initialize-Database $UsePostgres $needsSeed

    New-Item -ItemType Directory -Force $StateDir | Out-Null
    $backendLog = Join-Path $StateDir "backend.log"
    $frontLog = Join-Path $StateDir "front.log"

    Write-Step "Subindo backend em http://localhost:$BackendPort"
    $backend = Start-Process -FilePath "python" -WorkingDirectory $Backend -PassThru -WindowStyle Hidden `
        -ArgumentList @("-m", "uv", "run", "uvicorn", "almotos_backend.main:app", "--host", "127.0.0.1", "--port", "$BackendPort") `
        -RedirectStandardOutput $backendLog -RedirectStandardError "$backendLog.err"

    Write-Step "Subindo painel em http://localhost:$FrontPort"
    $env:BACKEND_URL = "http://localhost:$BackendPort"
    $env:NEXT_PUBLIC_API_URL = "http://localhost:$BackendPort"
    $env:NEXT_DIST_DIR = ".next-qa"
    $npx = (Get-Command npx.cmd -ErrorAction SilentlyContinue).Source
    if (-not $npx) { $npx = "npx" }
    # Sem --turbopack: o Turbopack falha em algumas respostas do Google Fonts
    # ("next/font/google queries have exactly one entry"); o webpack é estável.
    $front = Start-Process -FilePath $npx -WorkingDirectory $Front -PassThru -WindowStyle Hidden `
        -ArgumentList @("next", "dev", "-p", "$FrontPort") `
        -RedirectStandardOutput $frontLog -RedirectStandardError "$frontLog.err"

    $state = [pscustomobject]@{
        backendPid = $backend.Id
        frontPid   = $front.Id
        postgres   = $UsePostgres
        seeded     = $true
        startedAt  = (Get-Date).ToString("s")
    }
    Save-State $state

    if (-not (Wait-Http "http://127.0.0.1:$BackendPort/health" 60)) {
        Write-Warn "O backend não respondeu em 60 s. Veja: ./scripts/qa.ps1 logs"
    } else { Write-Ok "Backend no ar." }
    if (-not (Wait-Http "http://127.0.0.1:$FrontPort/login" 120)) {
        Write-Warn "O painel ainda está compilando. Veja: ./scripts/qa.ps1 logs"
    } else { Write-Ok "Painel no ar." }
    Show-Summary $state
}

function Stop-Qa {
    $state = Read-State
    if (-not $state) { Write-Warn "Nada rodando."; return }
    Write-Step "Parando QA"
    if ($state.frontPid) { Stop-Tree $state.frontPid }
    if ($state.backendPid) { Stop-Tree $state.backendPid }
    if ($state.postgres) { & docker compose -f $Compose stop | Out-Null }
    $state.backendPid = $null
    $state.frontPid = $null
    Save-State $state
    Write-Ok "Parado. Os dados ficam; 'reset' recria do zero."
}

function Show-Summary($State) {
    $banco = if ($State.postgres) { "Postgres de QA (localhost:5433/almotos_qa)" } else { "SQLite (almotos-backend/qa.sqlite)" }
    Write-Host ""
    Write-Host "QA local no ar" -ForegroundColor Green
    Write-Host "  Painel:   http://localhost:$FrontPort"
    Write-Host "  API:      http://localhost:$BackendPort/docs"
    Write-Host "  Banco:    $banco"
    Write-Host "  Fiscal:   ForeCast SIMULADA (nada vai à SEFAZ)"
    Write-Host "  Login:    admin / admin123   ·   vendedor / vendedor123"
    Write-Host "  Parar:    ./scripts/qa.ps1 down    ·    Recriar: ./scripts/qa.ps1 reset"
    Write-Host ""
}

function Show-Status {
    $state = Read-State
    $backend = $state -and $state.backendPid -and (Get-Process -Id $state.backendPid -ErrorAction SilentlyContinue)
    $front = $state -and $state.frontPid -and (Get-Process -Id $state.frontPid -ErrorAction SilentlyContinue)
    Write-Host ("Backend ({0}): {1}" -f $BackendPort, $(if ($backend) { "rodando" } else { "parado" }))
    Write-Host ("Painel  ({0}): {1}" -f $FrontPort, $(if ($front) { "rodando" } else { "parado" }))
    if ($state) { Write-Host ("Banco: {0}" -f $(if ($state.postgres) { "Postgres de QA" } else { "SQLite" })) }
}

function Show-Logs {
    foreach ($name in @("backend.log", "backend.log.err", "front.log", "front.log.err")) {
        $path = Join-Path $StateDir $name
        if (Test-Path $path) {
            Write-Host "---- $name" -ForegroundColor Cyan
            Get-Content $path -Tail 25
        }
    }
}

switch ($Command) {
    "up" {
        $state = Read-State
        $usePg = $Postgres.IsPresent -or ($state -and $state.postgres -and -not $PSBoundParameters.ContainsKey("Postgres"))
        Start-Qa $usePg $false
    }
    "reset" {
        $state = Read-State
        $usePg = $Postgres.IsPresent -or ($state -and $state.postgres)
        Stop-Qa
        Start-Qa $usePg $true
    }
    "down" { Stop-Qa }
    "status" { Show-Status }
    "logs" { Show-Logs }
}
