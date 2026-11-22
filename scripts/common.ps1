# AETHER-WIN - funcoes comuns (ASCII only de proposito: PowerShell 5.1 le arquivos sem BOM como ANSI)

$script:BackupPath = Join-Path $env:LOCALAPPDATA 'AetherWin\backup.json'
$script:Backup = @{}

function Write-Step { param([string]$Msg) Write-Host ""; Write-Host "[AETHER] $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "  [OK] $Msg" -ForegroundColor Green }
function Write-Warn2 { param([string]$Msg) Write-Host "  [!]  $Msg" -ForegroundColor Yellow }

function Initialize-Backup {
    $dir = Split-Path $script:BackupPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    if (Test-Path $script:BackupPath) {
        $raw = Get-Content $script:BackupPath -Raw | ConvertFrom-Json
        foreach ($p in $raw.PSObject.Properties) { $script:Backup[$p.Name] = $p.Value }
    }
}

function Save-Backup {
    if ($DryRun) { return }
    $script:Backup | ConvertTo-Json -Depth 6 | Set-Content -Path $script:BackupPath -Encoding UTF8
}

# Grava um valor de registro guardando o valor original (apenas na 1a vez) para o uninstall.
function Set-Reg {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [string]$Type = 'DWord'
    )
    $key = "$Path|$Name"
    if (-not $script:Backup.ContainsKey($key)) {
        $existed = $false; $old = $null
        try { $old = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name; $existed = $true } catch { }
        $script:Backup[$key] = @{ existed = $existed; value = $old; type = $Type }
    }
    if ($DryRun) { Write-Host "  (dry-run) $Path -> $Name = $Value"; return }
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction Stop
    } catch {
        Write-Warn2 "Nao foi possivel gravar $Name (o Windows pode proteger essa chave nesta versao): $($_.Exception.Message)"
    }
}

# Converte A,R,G,B em DWORD ABGR (formato usado pelo DWM) como Int32 com sinal.
function ConvertTo-AbgrInt {
    param([int]$R, [int]$G, [int]$B, [int]$A = 255)
    [uint32]$v = ([uint32]$A -shl 24) -bor ([uint32]$B -shl 16) -bor ([uint32]$G -shl 8) -bor [uint32]$R
    return [BitConverter]::ToInt32([BitConverter]::GetBytes($v), 0)
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    return (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-Explorer {
    if ($DryRun) { Write-Host "  (dry-run) reiniciar explorer.exe"; return }
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
}
