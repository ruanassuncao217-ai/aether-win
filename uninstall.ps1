<#
.SYNOPSIS
  Reverte as alteracoes do AETHER-WIN usando o backup salvo em %LOCALAPPDATA%\AetherWin\backup.json.
  Nao desinstala os aplicativos (Rainmeter etc.); use -RemoveApps para isso.
#>
[CmdletBinding()]
param([switch]$RemoveApps, [switch]$DryRun)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\scripts\common.ps1"

$backupFile = Join-Path $env:LOCALAPPDATA 'AetherWin\backup.json'
Write-Step "Restaurando configuracoes originais"

if (Test-Path $backupFile) {
    $raw = Get-Content $backupFile -Raw | ConvertFrom-Json
    foreach ($entry in $raw.PSObject.Properties) {
        $path, $name = $entry.Name -split '\|', 2
        $info = $entry.Value
        if ($DryRun) { Write-Host "  (dry-run) restaurar $path -> $name"; continue }
        try {
            if ($name -eq 'WallPaper') {
                Add-Type -Namespace Aether -Name Native -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto)]
public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
'@ -ErrorAction SilentlyContinue
                [void][Aether.Native]::SystemParametersInfo(20, 0, [string]$info.value, 3)
            } elseif ($info.existed) {
                Set-ItemProperty -Path $path -Name $name -Value $info.value -Type $info.type -Force
            } else {
                Remove-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
            }
        } catch { Write-Warn2 "Falha ao restaurar $name : $($_.Exception.Message)" }
    }
    Write-Ok "Registro restaurado"
} else {
    Write-Warn2 "Backup nao encontrado em $backupFile (nada para restaurar no registro)."
}

if (-not $DryRun) {
    # Skins
    $skins = Join-Path $env:USERPROFILE 'Documents\Rainmeter\Skins\Aether'
    $rm = Join-Path $env:ProgramFiles 'Rainmeter\Rainmeter.exe'
    if (Test-Path $rm) { & $rm '!DeactivateConfig' 'Aether\Clock'; & $rm '!DeactivateConfig' 'Aether\HUD' }
    if (Test-Path $skins) { Remove-Item $skins -Recurse -Force; Write-Ok "Skins removidas" }

    # Terminal
    $frag = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\AetherWin'
    if (Test-Path $frag) { Remove-Item $frag -Recurse -Force; Write-Ok "Fragmento do Terminal removido" }

    # Perfil do PowerShell
    if (Test-Path $PROFILE) {
        $txt = Get-Content $PROFILE -Raw
        $clean = [regex]::Replace($txt, '(?s)\r?\n?# >>> AETHER-WIN >>>.*?# <<< AETHER-WIN <<<\r?\n?', "`r`n")
        Set-Content -Path $PROFILE -Value $clean -Encoding UTF8
        Write-Ok "Bloco do Oh My Posh removido do `$PROFILE"
    }
    Remove-Item (Join-Path $env:LOCALAPPDATA 'AetherWin\aether.omp.json') -ErrorAction SilentlyContinue
    Remove-Item $backupFile -ErrorAction SilentlyContinue

    if ($RemoveApps -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        foreach ($app in (Get-Content "$PSScriptRoot\config\apps.json" -Raw | ConvertFrom-Json)) {
            Write-Step "Removendo $($app.name)"
            winget uninstall --id $app.id --exact --silent
        }
    }
}

Restart-Explorer
Write-Host "`n  AETHER-WIN revertido." -ForegroundColor Cyan
