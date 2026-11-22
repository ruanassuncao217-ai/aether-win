# AETHER-WIN

> Transforme o Windows 10/11 em um desktop futurista com **um comando**: tema escuro neon, HUD de sistema em tempo real, wallpaper 4K gerado por código, terminal estilizado e **tudo reversível**.

## O que está incluído

| Camada | O que faz | Como |
|---|---|---|
| **Tema do Windows** | Modo escuro total: barra de tarefas, Iniciar e janelas pretas; neon só nos detalhes (Cyan / Magenta / Violet / Green) | Registro (HKCU), sem admin |
| **Escuro em tudo** | Office em tema Preto; `-ForceDarkBrowsers` força escuro no Edge/Chrome | Registro (HKCU) |
| **Barra de tarefas** | Centralizada, sem botão de Visão de Tarefas / Widgets / Copilot | Registro (HKCU) |
| **Wallpaper 4K** | Grade em perspectiva, anel HUD, partículas | `wallpaper/generate_wallpaper.py` (Pillow + NumPy) |
| **Rainmeter** | Skin **Clock** (relógio com barra de segundos) e **HUD** (CPU, RAM, disco, rede em anéis neon) | `rainmeter/Aether` |
| **Terminal** | Esquema de cores *Aether Neon* + prompt Oh My Posh em estilo powerline | `terminal/` |
| **Apps** (via winget) | Rainmeter, TranslucentTB, Windows Terminal, Oh My Posh, PowerToys (+ opcionais: Windhawk, Flow Launcher, Files, YASB) | `config/apps.json` |
| **Reversão** | Backup dos valores originais do registro + `uninstall.ps1` | `%LOCALAPPDATA%\AetherWin\backup.json` |

## Instalação rápida

Requisitos: Windows 10 22H2 ou Windows 11, PowerShell 5.1+, winget (já vem no Windows 11).

```powershell
git clone https://github.com/ruanassuncao217-ai/aether-win.git
cd aether-win

# 0) Gere o wallpaper 4K (precisa de Python): pip install pillow numpy ; python wallpaper/generate_wallpaper.py
#    Depois mova o PNG gerado para a pasta wallpaper/ (o instalador procura wallpaper/aether-wallpaper-4k.png)

# 1) Simulação: mostra tudo que seria alterado, sem alterar nada
.\install.ps1 -DryRun

# 2) Instalação real (acento ciano)
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1

# Variações
.\install.ps1 -Accent Magenta -IncludeOptional
.\install.ps1 -SkipApps -SkipTerminal
```

> Rode o PowerShell **como administrador** se quiser que o instalador crie um ponto de restauração automaticamente
> (o Windows limita a um a cada 24h por padrão). Sem admin, tudo funciona, só pula essa etapa.

### Parâmetros do `install.ps1`

| Parâmetro | Efeito |
|---|---|
| `-Accent Cyan\|Magenta\|Violet\|Green` | Cor de destaque (tema, skins) |
| `-AccentSurfaces` | Pinta barra de tarefas/títulos com a cor de destaque (padrão: tudo preto) |
| `-ForceDarkBrowsers` | Força modo escuro no Edge/Chrome (aparece "gerenciado pela organização") |
| `-DryRun` | Só mostra as ações |
| `-IncludeOptional` | Instala também Windhawk, Flow Launcher, Files e YASB |
| `-SkipApps` `-SkipTheme` `-SkipWallpaper` `-SkipRainmeter` `-SkipTerminal` | Pula etapas |
| `-NoRestorePoint` | Não tenta criar ponto de restauração |

## Como desfazer

```powershell
.\uninstall.ps1              # restaura registro, wallpaper, skins, fragmento do Terminal e perfil do PowerShell
.\uninstall.ps1 -RemoveApps  # idem + desinstala os apps listados em config/apps.json
```

## Estrutura do repositório

```
aether-win/
├── install.ps1              # orquestrador
├── uninstall.ps1            # reversão via backup
├── config/apps.json         # lista de apps (IDs do winget)
├── scripts/
│   ├── common.ps1           # Set-Reg com backup, helpers
│   ├── apply-theme.ps1      # tema, barra de tarefas, wallpaper
│   └── install-apps.ps1     # winget
├── rainmeter/Aether/        # skins Clock + HUD + variáveis de cor
├── terminal/                # esquema de cores + tema Oh My Posh
├── wallpaper/               # gerador Python que cria o PNG 4K
└── docs/CUSTOMIZATION.md    # Windhawk, FancyZones, roadmap
```

## Segurança e transparência

- **Nada de binários de terceiros no repositório.** Os apps vêm do winget (fonte oficial da Microsoft).
- Só toca em `HKCU` (usuário atual); não altera o sistema nem serviços.
- Cada valor de registro alterado tem o original salvo antes; o `uninstall.ps1` restaura (ou remove, se não existia).
- Leia os scripts antes de rodar. São curtos e comentados.

## Limitações conhecidas

- Algumas chaves (por exemplo `TaskbarDa`) são protegidas em builds recentes do Windows 11; o script avisa e segue em frente.
- Estilizar Iniciar/Barra de tarefas além do tema (vidro, bordas, ícones) exige Windhawk/TranslucentTB — veja `docs/CUSTOMIZATION.md`. São mods de terceiros e podem precisar de ajuste após atualizações do Windows.
- Os IDs do winget em `config/apps.json` podem mudar; se um falhar, o script avisa e continua (`winget search <nome>`).
- Testado apenas por revisão de código e geração do wallpaper; **teste primeiro com `-DryRun`** e, se possível, em uma VM.

## Contribuindo

Issues e PRs são bem-vindos: novas skins Rainmeter, paletas de cor, temas de terminal, melhorias no instalador.
Veja o roadmap em `docs/CUSTOMIZATION.md`.

## Licença

MIT — veja [LICENSE](LICENSE).
