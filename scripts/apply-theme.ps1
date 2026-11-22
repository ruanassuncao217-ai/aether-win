# AETHER-WIN - aplica tema escuro + cor de destaque + ajustes de barra de tarefas e wallpaper.
# Depende de common.ps1 (dot-sourced pelo install.ps1).

$Accents = @{
    Cyan    = @(0, 229, 255)
    Magenta = @(255, 0, 200)
    Violet  = @(139, 92, 246)
    Green   = @(0, 255, 156)
}

function Set-AetherTheme {
    param([string]$Accent = 'Cyan', [switch]$AccentSurfaces)

    $rgb = $Accents[$Accent]
    $abgr = ConvertTo-AbgrInt -R $rgb[0] -G $rgb[1] -B $rgb[2]

    $personalize = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    $dwm         = 'HKCU:\Software\Microsoft\Windows\DWM'
    $accentKey   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'
    $advanced    = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'

    Write-Step "Tema escuro + transparencia + destaque $Accent"
    Set-Reg $personalize 'AppsUseLightTheme'    0
    Set-Reg $personalize 'SystemUsesLightTheme' 0
    Set-Reg $personalize 'EnableTransparency'   1
    # Por padrao o destaque NAO pinta barra de tarefas/titulos (fica tudo preto). -AccentSurfaces liga isso.
    $prev = 0; if ($AccentSurfaces) { $prev = 1 }
    Set-Reg $personalize 'ColorPrevalence' $prev
    Set-Reg $dwm 'ColorPrevalence' $prev
    Set-Reg $dwm 'AccentColor'     $abgr
    Set-Reg $accentKey 'AccentColorMenu' $abgr
    Set-Reg $accentKey 'StartColorMenu'  $abgr
    Write-Ok "Tema aplicado"

    Write-Step "Ajustes da barra de tarefas (Windows 11)"
    Set-Reg $advanced 'TaskbarAl'         1   # centralizada
    Set-Reg $advanced 'ShowTaskViewButton' 0
    Set-Reg $advanced 'TaskbarDa'         0   # widgets (pode ser protegido em builds recentes)
    Set-Reg $advanced 'ShowCopilotButton' 0
    Write-Ok "Barra de tarefas ajustada"
}

function Set-AetherWallpaper {
    param([string]$Source)

    if (-not (Test-Path $Source)) { Write-Warn2 "Wallpaper nao encontrado: $Source"; return }
    $destDir = Join-Path $env:USERPROFILE 'Pictures\Aether'
    $dest = Join-Path $destDir (Split-Path $Source -Leaf)

    Write-Step "Wallpaper"
    $desktop = 'HKCU:\Control Panel\Desktop'
    $key = "$desktop|WallPaper"
    if (-not $script:Backup.ContainsKey($key)) {
        $old = (Get-ItemProperty -Path $desktop -Name WallPaper -ErrorAction SilentlyContinue).WallPaper
        $script:Backup[$key] = @{ existed = $true; value = $old; type = 'String' }
    }
    if ($DryRun) { Write-Host "  (dry-run) definir wallpaper $dest"; return }

    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Copy-Item $Source $dest -Force

    Add-Type -Namespace Aether -Name Native -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Auto)]
public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
'@
    # 20 = SPI_SETDESKWALLPAPER ; 3 = UPDATEINIFILE | SENDCHANGE
    [void][Aether.Native]::SystemParametersInfo(20, 0, $dest, 3)
    Write-Ok "Wallpaper definido: $dest"
}

# Escuro em tudo: Office preto e (opcional) navegadores com modo escuro forcado.
function Set-AetherDarkEverywhere {
    param([switch]$ForceDarkBrowsers)

    Write-Step "Escuro em tudo (Office, navegadores)"
    # Office: 0=Colorido 3=Cinza escuro 4=Preto (verifique no Office: Arquivo > Opcoes > Geral)
    foreach ($v in '16.0') { Set-Reg "HKCU:\Software\Microsoft\Office\$v\Common" 'UI Theme' 4 }

    if ($ForceDarkBrowsers) {
        # Politicas de usuario: funcionam, mas Edge/Chrome mostram "gerenciado pela organizacao".
        Set-Reg 'HKCU:\Software\Policies\Microsoft\Edge'  'ForceDarkModeEnabled' 1
        Set-Reg 'HKCU:\Software\Policies\Google\Chrome'   'ForceDarkModeEnabled' 1
        Write-Ok "Edge e Chrome com modo escuro forcado em todos os sites"
    } else {
        Write-Warn2 "Navegadores: use -ForceDarkBrowsers para forcar escuro em todos os sites (ou a extensao Dark Reader)."
    }
}
