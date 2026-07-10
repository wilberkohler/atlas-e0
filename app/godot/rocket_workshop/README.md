# Oficina do Foguete

Protótipo Godot criado para `app/godot/rocket_workshop/`.

A cena principal agora é a build 3D de manipulação direta:

```text
scenes/main_3d.tscn
```

A build anterior, em formato dashboard, foi preservada como referência:

```text
scenes/reference/dashboard_main.tscn
scripts/reference/workshop_dashboard.gd
```

## Abrir pelo PowerShell

```powershell
godot --path "C:\Users\NTB-ENG\Documents\Atlas E0\app\godot\rocket_workshop"
```

Se o terminal atual ainda não reconhecer o alias recém-instalado pelo `winget`, use o executável direto:

```powershell
& "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64.exe" --path "C:\Users\NTB-ENG\Documents\Atlas E0\app\godot\rocket_workshop"
```

## O que existe no MVP

- Diorama 3D com câmera ortográfica.
- Bancada, garrafa PET, cone, três aletas, elástico virtual e base de lançamento.
- Peças arrastáveis por mouse, com rotação por roda/Q/E.
- Zonas de encaixe para cone, aletas e mecanismo de energia.
- Teste liberado visualmente quando a montagem mínima está pronta.
- Lançamento animado com três trajetórias internas.
- Telemetria oculta por padrão, aberta com `F2`.
- Diretórios preparados para assets `.glb` em `assets_3d/source` e `assets_3d/export`.
