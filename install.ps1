<#
.SYNOPSIS
  AETHER-WIN - transforma o visual do Windows 10/11 em um desktop futurista.

.EXAMPLE
  .\install.ps1 -DryRun                 # so mostra o que seria feito
  .\install.ps1                         # instalacao padrao (acento Cyan)
  .\install.ps1 -Accent Magenta -IncludeOptional
#>
[CmdletBinding()]
param(
    [ValidateSet('Cyan', 'Magenta', 'Violet', 'Green')][string]$Accent = 'Cyan',
    [switch]$SkipApps,
    [switch]$SkipTheme,
    [switch]$SkipWallpaper,
    [switch]$SkipRainmeter,
    [switch]$SkipTerminal,
    [switch]$AccentSurfaces,
    [switch]$ForceDarkBrowsers,
    [switch]$IncludeOptional,
    [switch]$NoRestorePoint,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
. "$Root\scripts\common.ps1"
. "$Root\scripts\apply-theme.ps1"
. "$Root\scripts\install-apps.ps1"

Write-Host ""
Write-Host "  A E T H E R - W I N   //   futuristic desktop for Windows" -ForegroundColor Cyan
Write-Host "  ------------------------------------------------------------" -ForegroundColor DarkCyan
if ($DryRun) { Write-Warn2 "MODO DRY-RUN: nada sera alterado." }

if ([Environment]::OSVersion.Platform -ne 'Win32NT') { throw "Este instalador so funciona no Windows." }
Initialize-Backup

# 1) Ponto de restauracao (precisa de admin; o Windows limita a 1 a cada 24h por padrao)
if (-not $NoRestorePoint -and -not $DryRun) {
    if (Test-Admin) {
        try {
            Write-Step "Criando ponto de restauracao"
            Checkpoint-Computer -Description 'AETHER-WIN antes da instalacao' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
            Write-Ok "Ponto de restauracao criado"
        } catch { Write-Warn2 "Nao foi possivel criar ponto de restauracao: $($_.Exception.Message)" }
    } else {
        Write-Warn2 "Sem privilegios de administrador: pulando ponto de restauracao (o backup do registro do AETHER continua valendo)."
    }
}

# 2) Aplicativos
if (-not $SkipApps) { Install-AetherApps -ConfigPath "$Root\config\apps.json" -IncludeOptional:$IncludeOptional }

# 3) Tema do Windows
if (-not $SkipTheme) {
    Set-AetherTheme -Accent $Accent -AccentSurfaces:$AccentSurfaces
    Set-AetherDarkEverywhere -ForceDarkBrowsers:$ForceDarkBrowsers
}

# 4) Wallpaper
if (-not $SkipWallpaper) { Set-AetherWallpaper -Source "$Root\wallpaper\aether-wallpaper-4k.png" }

# 5) Rainmeter (skins)
if (-not $SkipRainmeter) {
    Write-Step "Skins Rainmeter"
    $skinsDest = Join-Path $env:USERPROFILE 'Documents\Rainmeter\Skins\Aether'
    if ($DryRun) { Write-Host "  (dry-run) copiar skins para $skinsDest" }
    else {
        New-Item -ItemType Directory -Path $skinsDest -Force | Out-Null
        Copy-Item "$Root\rainmeter\Aether\*" $skinsDest -Recurse -Force
        # injeta a cor de destaque escolhida
        $rgb = $Accents[$Accent] -join ','
        $varFile = Join-Path $skinsDest '@Resources\Variables.inc'
        (Get-Content $varFile -Raw) -replace '(?m)^ColorMain=.*$', "ColorMain=$rgb" | Set-Content $varFile -Encoding UTF8
        Write-Ok "Skins copiadas para $skinsDest"

        $rm = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'
        if (Test-Path $rm) {
            Start-Process $rm; Start-Sleep -Seconds 3
            & $rm '!RefreshApp'; Start-Sleep -Seconds 2
            & $rm '!ActivateConfig' 'Aether\Clock' 'Clock.ini'
            & $rm '!ActivateConfig' 'Aether\HUD'   'HUD.ini'
            Write-Ok "Skins Clock e HUD ativadas"
        } else {
            Write-Warn2 "Rainmeter nao encontrado em $rm. Instale e ative as skins manualmente (veja docs/CUSTOMIZATION.md)."
        }
    }
}

# 6) Terminal + Oh My Posh
if (-not $SkipTerminal) {
    Write-Step "Windows Terminal (esquema Aether Neon) + Oh My Posh"
    $fragDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\AetherWin'
    $ompDest = Join-Path $env:LOCALAPPDATA 'AetherWin\aether.omp.json'
    if ($DryRun) { Write-Host "  (dry-run) copiar fragmento do Terminal e tema do Oh My Posh" }
    else {
        New-Item -ItemType Directory -Path $fragDir -Force | Out-Null
        Copy-Item "$Root\terminal\aether-scheme.json" (Join-Path $fragDir 'aether.json') -Force
        New-Item -ItemType Directory -Path (Split-Path $ompDest) -Force | Out-Null
        Copy-Item "$Root\terminal\aether.omp.json" $ompDest -Force

        $begin = '# >>> AETHER-WIN >>>'; $end = '# <<< AETHER-WIN <<<'
        $block = "$begin`r`nif (Get-Command oh-my-posh -ErrorAction SilentlyContinue) { oh-my-posh init pwsh --config `"$ompDest`" | Invoke-Expression }`r`n$end"
        if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
        $current = Get-Content $PROFILE -Raw
        if ($null -eq $current) { $current = '' }
        if ($current -notmatch [regex]::Escape($begin)) { Add-Content -Path $PROFILE -Value "`r`n$block`r`n" }

        if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
            try { oh-my-posh font install Meslo } catch { Write-Warn2 "Instale uma Nerd Font manualmente (ex.: MesloLGM Nerd Font)." }
        }
        Write-Ok "Esquema 'Aether Neon' disponivel no Terminal (Configuracoes > Aparencia). Reabra o terminal."
    }
}

Save-Backup
Write-Step "Reiniciando o Explorer para aplicar o tema"
Restart-Explorer

Write-Host ""
Write-Host "  Pronto. Para desfazer tudo: .\uninstall.ps1" -ForegroundColor Cyan
Write-Host "  Proximos passos opcionais: docs/CUSTOMIZATION.md (Windhawk, TranslucentTB, FancyZones)" -ForegroundColor DarkCyan
