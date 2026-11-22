# AETHER-WIN - instala os aplicativos via winget.
# Os IDs ficam em config/apps.json. Se algum ID mudar no repositorio do winget,
# o script avisa e segue em frente (verifique com: winget search <nome>).

function Install-AetherApps {
    param([string]$ConfigPath, [switch]$IncludeOptional)

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warn2 "winget nao encontrado. Instale o 'Instalador de Aplicativo' pela Microsoft Store e rode de novo."
        return
    }

    $apps = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    foreach ($app in $apps) {
        if ($app.optional -and -not $IncludeOptional) {
            Write-Host "  (opcional, pulando) $($app.name)  -> use -IncludeOptional para instalar"
            continue
        }
        Write-Step "Instalando $($app.name)"
        if ($DryRun) { Write-Host "  (dry-run) winget install --id $($app.id)"; continue }

        winget list --id $app.id --exact --accept-source-agreements 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Ok "$($app.name) ja instalado"; continue }

        winget install --id $app.id --exact --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) { Write-Ok "$($app.name) instalado" }
        else { Write-Warn2 "Falhou: $($app.name) ($($app.id)). Verifique o ID com 'winget search'." }
    }
}
