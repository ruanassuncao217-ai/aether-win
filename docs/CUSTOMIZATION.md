# Personalização avançada

O `install.ps1` entrega a base (tema escuro, destaque neon, wallpaper, HUD, terminal). Esta página cobre as
camadas extras que **não** são automatizadas de propósito, porque mexem em componentes internos do Windows
e podem quebrar após atualizações.

> Os nomes e IDs de apps/mods abaixo refletem o que eu conheço até meados de 2026. Confirme em
> `winget search <nome>` e nos sites oficiais antes de instalar.

## 1. Barra de tarefas translúcida (TranslucentTB)

1. Instale: `winget install CharlesMilette.TranslucentTB` (já está em `config/apps.json`).
2. Clique com o botão direito no ícone da bandeja → **Desktop** → **Clear** (totalmente transparente)
   ou **Acrylic** (vidro fosco com destaque ciano).
3. Marque **Open at boot**.

## 2. Mods de Start e Taskbar (Windhawk)

Instale com `.\install.ps1 -IncludeOptional` ou `winget install RamenSoftware.Windhawk`.
No Windhawk, procure por mods com estes nomes:

- **Windows 11 Taskbar Styler** — temas prontos de barra de tarefas (procure estilos "Glass"/"Neon").
- **Windows 11 Start Menu Styler** — aplica o mesmo estilo ao menu Iniciar.
- **Taskbar clock customization** — formato de relógio/data personalizado.

Windhawk injeta código em processos do Explorer. Se algo falhar após uma atualização do Windows,
desative o mod pelo próprio Windhawk (ele tem modo de recuperação).

## 3. Layout de janelas (PowerToys FancyZones)

1. Abra o PowerToys → **FancyZones** → habilite.
2. Escolha o layout "Priority Grid" ou crie um custom em três colunas (ultrawide) / duas colunas + painel lateral.
3. Segure `Shift` ao arrastar a janela para encaixar na zona.

## 4. Launcher estilo Spotlight (Flow Launcher ou PowerToys Run)

- PowerToys Run: `Alt + Espaço` (já vem com o PowerToys).
- Flow Launcher: `Alt + Espaço` também; em **Settings → Theme** escolha um tema escuro com blur.
  Se usar um, desative o atalho do outro para não conflitar.

## 5. Mudando a cor de destaque

Rode de novo: `.\install.ps1 -Accent Magenta -SkipApps` (opções: `Cyan`, `Magenta`, `Violet`, `Green`).
Para regenerar o wallpaper na mesma cor:

```powershell
cd wallpaper
python generate_wallpaper.py --accent magenta
cd ..
.\install.ps1 -Accent Magenta -SkipApps
```

## 6. Editando as skins do Rainmeter

As skins ficam em `Documentos\Rainmeter\Skins\Aether`. Edite `@Resources\Variables.inc` para trocar cores e fontes;
depois clique com o botão direito na skin → **Refresh skin**.

| Variável      | O que controla                          |
|---------------|-----------------------------------------|
| `ColorMain`   | cor principal (neon)                    |
| `ColorAlt`    | cor secundária (RAM, barra lateral)     |
| `ColorBg`     | fundo translúcido dos painéis (RGBA)    |
| `FontMain`    | fonte dos rótulos                       |
| `FontLight`   | fonte dos números grandes               |

Para monitorar outro disco no HUD, altere `Drive=C:` na medida `[MeasureDisk]` de `HUD\HUD.ini`.

## 7. Terminal

O instalador registra o esquema **Aether Neon** como *fragment extension* do Windows Terminal (sem tocar no seu
`settings.json`). Para usá-lo: Terminal → **Configurações → Aparência → Esquema de cores → Aether Neon**.
Em **Aparência**, ative também *Acrílico* e opacidade ~85% para o efeito de vidro.

O prompt (Oh My Posh) precisa de uma Nerd Font. O instalador tenta `oh-my-posh font install Meslo`;
depois escolha **MesloLGM Nerd Font** na fonte do perfil do Terminal.

## 8. Ideias para evoluir o projeto (roadmap)

- [ ] Skin Rainmeter de clima e agenda
- [ ] Pacote de cursores e ícones (Fluent/neon) com instalação automática
- [ ] Perfil de tema claro "Aether Frost"
- [ ] GitHub Action que gera as variações de wallpaper (todos os acentos) a cada release
- [ ] Integração com YASB (barra superior) com config pronta

## 9. Escuro em tudo: o que o Windows não cobre sozinho

Mesmo com tudo configurado, alguns pontos continuam claros e precisam de ajuste manual:

- **Janelas antigas (Win32)**, como Painel de Controle, algumas caixas de diálogo e o Gerenciador de Dispositivos: o Windows não tem tema escuro nativo para elas. Alternativa: Windhawk, procurando mods de tema escuro para diálogos.
- **Sites**: `-ForceDarkBrowsers` ou a extensão Dark Reader.
- **Apps individuais** (Spotify, Slack, VS Code etc.): ative o tema escuro nas configurações de cada um.
- **Menu Iniciar e barra de tarefas totalmente pretos**: no TranslucentTB use *Acrylic* com opacidade baixa e cor `#000000`.
