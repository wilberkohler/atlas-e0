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
- Lançamento com simulação contínua simplificada, usando energia, alinhamento, aletas, vento e arrasto internos.
- Telemetria oculta por padrão, aberta com `F2`.
- Diretórios preparados para assets `.glb` em `assets_3d/source` e `assets_3d/export`.

## Testes de desenvolvimento

```powershell
godot_console --headless --path "C:\Users\NTB-ENG\Documents\Atlas E0\app\godot\rocket_workshop" --script res://scripts/dev/asset_import_smoke_test.gd
godot_console --headless --path "C:\Users\NTB-ENG\Documents\Atlas E0\app\godot\rocket_workshop" --script res://scripts/dev/flight_smoke_tests.gd
godot_console --headless --path "C:\Users\NTB-ENG\Documents\Atlas E0\app\godot\rocket_workshop" --script res://scripts/dev/launch_scene_smoke_test.gd
```

## Pipeline Blender -> Godot

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe" --background --python "C:\Users\NTB-ENG\Documents\Atlas E0\tools\blender\generate_rocket_workshop_v3.py"
godot_console --headless --path "C:\Users\NTB-ENG\Documents\Atlas E0\app\godot\rocket_workshop" --import --quit
```

Os `.glb` importados ficam em `assets_3d/export/v3` dentro do projeto. As pecas carregam esses modelos automaticamente e voltam para placeholders se algum asset ainda nao existir.
