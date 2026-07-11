# Relatório — Vertical Slice da Oficina do Foguete PET v1

Data: 2026-07-11

## Resultado

O vertical slice foi implementado como uma build aditiva do projeto Godot. Ele oferece o ciclo oficina → preparação abstrata → lançamento físico híbrido → revisão → retorno → ajuste → nova tentativa, sem substituir a cena principal anterior.

Status honesto:

- **Implementação técnica:** concluída e validada.
- **Porta de assets v2:** aprovada no Godot.
- **Regressão da build anterior:** aprovada.
- **Critério humano principal:** ainda não aprovado; depende de playtest com uma pessoa.

## Auditoria inicial

- Branch inicial: `main`.
- HEAD inicial: `7ea1267d6018df4f8151e473e960b484f3e18427`.
- Build anterior preservada pela tag `v0.3-graybox-3d` (`45f7dd5`).
- Cena principal existente e preservada: `res://scenes/main_3d.tscn`.
- O working tree já continha oito arquivos rastreados modificados e diversos arquivos não rastreados antes desta tarefa.
- O vertical slice não altera nenhum desses oito arquivos rastreados preexistentes.
- Godot disponível: `4.7.stable.official.5b4e0cb0f`.
- O aviso preexistente de UID duplicado entre `scenes/main.tscn` e `scenes/reference/dashboard_main.tscn` permanece registrado.

Detalhes completos: `docs/builds/vertical_slice_pet_rocket_v1_preflight.md`.

## Referência de experiência

O vídeo de referência pôde ser identificado no navegador como uma atividade prática de foguete PET em ambiente de oficina. A composição inicial — bancada, garrafa reutilizada, papel, aletas e expectativa de teste — orientou o enquadramento e a materialidade. A especificação anexada permaneceu como fonte de verdade; nenhum procedimento operacional do vídeo foi transposto para a aplicação.

## Assets encontrados e utilizados

Todos os seis GLBs v2 obrigatórios foram espelhados para `res://assets_3d/export/v2/`, importados como `PackedScene`, instanciados e validados:

| Asset | Meshes no Godot | Uso |
| --- | ---: | --- |
| `pet_bottle.glb` | 10 | corpo interativo e foguete de voo |
| `paper_nose_cone.glb` | 6 | cone removível/desalinhável |
| `cardboard_fin.glb` | 8 | três aletas manipuláveis |
| `launch_stand.glb` | 10 | base da oficina e do campo |
| `workbench.glb` | 16 | bancada principal |
| `tape_roll.glb` | 4 | rolo de fita gestual |

O recipiente de água não possuía asset v2. Foi criada uma malha autoral de jarra facetada com bico e alça curva; não há fallback visível para cilindro/cubo genérico como recipiente.

## Implementação

### Oficina

- Câmera perspectiva 3/4 próxima.
- Bancada v2, garrafa, três aletas, cone, fita, jarra e base v2.
- Raycast de câmera e hitboxes `Area3D`.
- Hover emissivo, cursor, elevação, sombra e arraste amortecido.
- Rotação por roda, `Q`/`E` e arraste secundário.
- Três zonas de aleta com atração magnética e erro de posição/ângulo preservado.
- Remoção e reposicionamento de peças.
- Fita por caminho e arco ao redor da junção, com faixa progressiva e qualidade ausente/parcial/adequada interna.
- Água normalizada, vertida ao inclinar a jarra, com mesh separada dentro da garrafa.
- Base iluminada somente quando corpo, duas aletas fixadas e água atendem ao mínimo.
- Colocação direta do foguete montado na base.

### Campo e voo

- Campo pequeno com solo, céu, horizonte, luz natural e base v2.
- Alavanca abstrata por gesto de mouse e botão integrado à base.
- Energia fictícia normalizada; nenhum valor de pressão aparece.
- Antecipação entre 0,4 e 0,95 segundo.
- `VS1BottleRocketBody` deriva de `RigidBody3D` e usa integrador customizado ligado ao modelo determinístico.
- Impulso contínuo, gravidade, arrasto, vento por seed, massa abstrata variável, torque estabilizador e torque de assimetria.
- Estados: `PREPARED`, `ANTICIPATION`, `THRUST`, `COAST`, `APEX`, `DESCENT`, `IMPACT`, `REVIEW`.
- Jato com partículas, gotas e volume de spray.
- Câmera por fases, horizonte estável, atraso suave e shake controlado.
- Fail-safe contra NaN, velocidade extrema, timeout, saída de limites e colisão inesperada.

### Revisão, retorno e comparação

- Trajetória registrada em amostras.
- Linha translúcida, marcador de ápice e marcador de impacto.
- Retenção visual das duas últimas tentativas.
- Seed de vento preservada por padrão entre tentativas consecutivas.
- Revisão automática curta e retorno solicitado em menos de três segundos.
- Configuração da oficina preservada no retorno.
- Presets F2: Stable, Spin, Lateral e Short.

### Telemetria

- Oculta por padrão.
- Registra sessão, tentativa, timestamps, ordem de interação, primeira peça, geometria/fixação de aletas, cone, água, energia, fases, trajetória, ápice, deslocamento, rotação, impacto, alterações e retry.
- JSON seguro e normalizado.
- Escrita atômica com `.tmp`, rotação `.bak` e recuperação de backup.
- Caminho: `user://atlas_e0/vertical_slice_pet_v1/attempt_history.json`.
- Painel F2 mostra configuração, métricas, forças, torque, estado, seed e histórico.

## Cenas criadas

Em `app/godot/rocket_workshop/scenes/vertical_slice_v1/`:

- `vertical_slice_main.tscn`
- `workshop_scene.tscn`
- `field_test_scene.tscn`
- `transition_scene.tscn`
- `result_comparison_scene.tscn`

Em `app/godot/rocket_workshop/scenes/objects/`:

- `pet_bottle_interactive.tscn`
- `fin_interactive.tscn`
- `nose_cone_interactive.tscn`
- `tape_roll_interactive.tscn`
- `water_container_interactive.tscn`
- `launch_stand_interactive.tscn`

## Scripts criados

- Estado/montagem: `rocket_configuration.gd`, `assembly_metrics.gd`, `rocket_assembly_controller.gd`, `experience_state.gd`.
- Interação: `object_grabber_3d.gd`, `tactile_drag_controller.gd`, `rotation_controller.gd`, `vs1_snap_zone_3d.gd`, `tape_gesture_controller.gd`, `water_fill_controller.gd`.
- Voo: `bottle_rocket_body.gd`, `bottle_rocket_simulator.gd`, `launch_sequence_controller.gd`, `launch_camera_controller.gd`, `trajectory_recorder.gd`, `trajectory_renderer.gd`, `flight_profile.gd`.
- Telemetria: `attempt_record.gd`, `attempt_history.gd`, `experience_telemetry.gd`.
- UI/áudio: `contextual_hint_controller.gd`, `developer_overlay.gd`, `experience_audio.gd`.
- Composição: `vertical_slice_controller.gd`, `field_test_scene.gd`, `transition_controller.gd`.
- Validação: `vertical_slice_v1_asset_import_test.gd`, `vertical_slice_v1_validation.gd`, `vertical_slice_v1_scene_smoke_test.gd`, `vertical_slice_v1_capture.gd`.

O snap novo usa o nome `vs1_snap_zone_3d.gd` porque `snap_zone_3d.gd` já pertencia à build anterior e foi restaurado sem diff.

## Resources e dados

- `resources/flight/stable_profile.tres`
- `resources/flight/spin_profile.tres`
- `resources/flight/lateral_profile.tres`
- `resources/flight/short_profile.tres`
- `data/sample_attempts/pet_rocket_attempts_v1.json`
- `prompts/codex/012_vertical_slice_oficina_foguete_pet.md` — conteúdo normalizado idêntico ao anexo, 23.833 caracteres.

## Comandos principais executados

```powershell
git status --short
git branch --show-current
git log -n 12 --date=iso-strict
godot --version
godot_console --headless --path ".../rocket_workshop" --import --quit
godot_console --headless --path ".../rocket_workshop" --editor --quit
godot_console --headless --path ".../rocket_workshop" --script res://scripts/dev/vertical_slice_v1_asset_import_test.gd
godot_console --headless --path ".../rocket_workshop" --script res://scripts/dev/vertical_slice_v1_validation.gd
godot_console --headless --path ".../rocket_workshop" --script res://scripts/dev/vertical_slice_v1_scene_smoke_test.gd
godot_console --headless --path ".../rocket_workshop" --script res://scripts/dev/asset_import_smoke_test.gd
godot_console --headless --path ".../rocket_workshop" --script res://scripts/dev/flight_smoke_tests.gd
godot_console --headless --path ".../rocket_workshop" --script res://scripts/dev/launch_scene_smoke_test.gd
godot_console --headless --path ".../rocket_workshop" --quit-after 120 res://scenes/main_3d.tscn
godot_console --headless --path ".../rocket_workshop" --quit-after 120 res://scenes/vertical_slice_v1/vertical_slice_main.tscn
godot_console --path ".../rocket_workshop" --script res://scripts/dev/vertical_slice_v1_capture.gd
```

O Blender 5.1.2 também foi usado em modo somente leitura para auditar dimensões, pivôs e hierarquia interna dos seis GLBs v2.

## Testes executados

| Teste | Resultado |
| --- | --- |
| Importação dos seis v2 e marcadores | aprovado |
| Parser/editor Godot 4.7 | aprovado |
| Estável gira menos | `0,040 < 0,308` |
| Aleta inclinada aumenta giro | aprovado |
| Assimetria aumenta desvio | `0,879 > 0,042` |
| Energia menor encurta voo | `0,989 < 4,726` |
| Ápice e descida | aprovados |
| Trajetória registrada | aprovado |
| Histórico visual de duas tentativas | aprovado |
| Configuração preservada | aprovado |
| NaN/infinito | nenhum detectado |
| Colisão inesperada termina | aprovado |
| Cena integrada | aprovado |
| Três testes da build anterior | aprovados |
| Cena principal anterior | abre sem erro crítico |
| JSON de amostra | válido, duas tentativas |

Os valores acima são unidades abstratas internas de teste, não medidas operacionais.

## Screenshots realmente geradas

- `docs/builds/screenshots/workshop_v1.png`
- `docs/builds/screenshots/fin_attachment_v1.png`
- `docs/builds/screenshots/launch_preparation_v1.png`
- `docs/builds/screenshots/launch_v1.png`
- `docs/builds/screenshots/trajectory_comparison_v1.png`

As cinco imagens foram capturadas pelo renderer OpenGL do Godot em 1280×720. Um artefato de sombra encontrado na primeira revisão foi corrigido e as imagens foram regeneradas.

## Checklist dos critérios de aceite

| # | Critério | Estado |
| ---: | --- | --- |
| 1 | Objetos reconhecíveis sem legenda | técnico aprovado por assets/capturas; confirmação humana pendente |
| 2 | Sem painel lateral | aprovado |
| 3 | Pegar diretamente uma aleta | aprovado |
| 4 | Girar a aleta | aprovado |
| 5 | Manter pequeno desalinhamento | aprovado |
| 6 | Fita cria fixação visual | aprovado |
| 7 | Água aparece na garrafa | aprovado |
| 8 | Foguete colocado fisicamente na base | aprovado |
| 9 | Antecipação antes do lançamento | aprovado |
| 10 | Jato visual de água | aprovado |
| 11 | Voo não é Tween vertical | aprovado; `RigidBody3D` + forças híbridas |
| 12 | Ápice | aprovado |
| 13 | Descida | aprovado |
| 14 | Impacto | aprovado |
| 15 | Aleta torta aumenta giro | aprovado por teste causal |
| 16 | Assimetria aumenta desvio | aprovado por teste causal |
| 17 | Retorno preserva montagem | aprovado |
| 18 | Corrigir uma peça | aprovado |
| 19 | Lançar novamente | aprovado |
| 20 | Comparar duas trajetórias | aprovado |
| 21 | Sem números operacionais reais | aprovado |
| 22 | Telemetria oculta | aprovado |
| 23 | Sem erros críticos | aprovado nos testes executados |
| 24 | Versões anteriores preservadas | aprovado |

## Preservação confirmada

- `project.godot` não foi alterado.
- `scenes/main_3d.tscn` não foi alterada.
- `scripts/interaction/snap_zone_3d.gd` foi restaurado e não possui diff.
- Os mesmos oito arquivos rastreados que já estavam modificados no preflight continuam sendo os únicos arquivos rastreados modificados fora do slice.
- Nenhum Blender, render ou GLB raiz anterior foi apagado ou alterado.
- A cena anterior e seus três smoke tests continuam passando.

## Como abrir e testar

Pelo terminal:

```powershell
godot --path "C:\Users\NTB-ENG\Documents\Atlas E0\app\godot\rocket_workshop" --editor res://scenes/vertical_slice_v1/vertical_slice_main.tscn
```

No editor, abra `scenes/vertical_slice_v1/vertical_slice_main.tscn` e pressione **F6** para executar somente essa cena.

Execução direta:

```powershell
godot --path "C:\Users\NTB-ENG\Documents\Atlas E0\app\godot\rocket_workshop" res://scenes/vertical_slice_v1/vertical_slice_main.tscn
```

A build anterior continua disponível em `res://scenes/main_3d.tscn`.

## Controles

- Mouse esquerdo: pegar, arrastar e soltar objetos.
- Roda do mouse ou `Q`/`E`: girar objeto durante o arraste.
- Mouse direito + arraste: inclinação fina.
- Fita: arrastar o rolo ao redor de uma junção aleta/garrafa.
- Água: pegar a jarra, aproximar o bico da abertura e inclinar.
- Base da oficina: levar o foguete montado até o ponto iluminado.
- Campo: arrastar repetidamente a alavanca abstrata; clicar o botão redondo quando o indicador responder.
- `F2`: painel do desenvolvedor e presets.
- `Voltar`/`Reiniciar`: ações discretas permitidas.

## Logs e JSON

- Runtime: saída padrão do Godot.
- Histórico persistente: `user://atlas_e0/vertical_slice_pet_v1/attempt_history.json`.
- Backup: `user://atlas_e0/vertical_slice_pet_v1/attempt_history.json.bak`.
- No Windows, use `ProjectSettings.globalize_path(...)` ou o painel F2 para confirmar o diretório efetivo do projeto.
- Fixture versionada: `data/sample_attempts/pet_rocket_attempts_v1.json`.

## Avaliação do critério humano principal

A implementação cria causalidade observável: o teste automático confirma diferenças grandes de giro e desvio, a montagem é preservada e a próxima tentativa fica disponível rapidamente. Isso sustenta tecnicamente a hipótese “quero mudar algo e tentar novamente”.

Ainda assim, não houve pessoa jogando nesta execução. Portanto, o vertical slice está **tecnicamente concluído, mas não aprovado como experiência humana**. O próximo passo é um playtest curto usando a pergunta central da especificação; ele não foi iniciado automaticamente.
