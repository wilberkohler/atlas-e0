# Preflight — Vertical Slice da Oficina do Foguete PET v1

Data da auditoria: 2026-07-11 (America/Sao_Paulo)

## Resultado da porta de qualidade

**Aprovado para iniciar a integração dos assets v2.** Os seis GLBs obrigatórios existem, são estruturalmente válidos, não dependem de arquivos externos e contêm meshes reconhecíveis. A importação real pelo Godot ainda é um gate da Fase 1; se qualquer asset falhar, a implementação visual deve parar sem fallback para primitivas.

## Estado inicial do repositório

- Repositório: `wilberkohler/atlas-e0`
- Branch: `main`
- HEAD auditado: `7ea1267d6018df4f8151e473e960b484f3e18427`
- Upstream: `origin/main` em `fb6cd8e`
- Estado: `main` dois commits à frente de `origin/main`
- Build anterior preservada pela tag: `v0.3-graybox-3d` (`45f7dd5`)
- Cena principal existente: `res://scenes/main_3d.tscn`
- Godot: `4.7.stable.official.5b4e0cb0f`
- Renderer: `gl_compatibility`
- Autoloads: nenhum

O working tree já estava sujo antes deste slice: oito arquivos Godot rastreados modificados e 24 entradas não rastreadas. Essas mudanças preexistentes não serão revertidas, sobrescritas nem incluídas indiscriminadamente nos commits desta tarefa.

## Projeto Godot localizado

Único projeto encontrado:

`app/godot/rocket_workshop/project.godot`

Cenas anteriores encontradas e preservadas:

- `scenes/main.tscn`
- `scenes/main_3d.tscn`
- `scenes/environment/workbench.tscn`
- `scenes/parts/elastic_unit.tscn`
- `scenes/parts/fin.tscn`
- `scenes/parts/nose_cone.tscn`
- `scenes/parts/pet_bottle.tscn`
- `scenes/props/launch_stand.tscn`
- `scenes/reference/dashboard_main.tscn`

Scripts anteriores encontrados: 24, distribuídos entre `assembly`, `dev`, `environment`, `flight`, `interaction`, `launch`, `props`, `reference`, `telemetry`, `ui` e a raiz de `scripts`. Nenhum deles será removido ou renomeado pelo vertical slice v1.

## Assets Blender auditados

Fontes preservadas:

- `assets_3d/source/v1/rocket_workshop_hero_v1.blend`
- `assets_3d/source/v2/rocket_workshop_hero_v2.blend`

Os renders e arquivos Blender v1, v2 e v3 permanecerão intocados.

### GLBs v2 obrigatórios

| Asset | Tamanho | Integridade | Marcadores relevantes |
| --- | ---: | --- | --- |
| `pet_bottle.glb` | 138.092 bytes | glTF 2 válido | `GRAB_PIVOT`, `SNAP_NOSE`, `SNAP_FIN_1..3` |
| `paper_nose_cone.glb` | 52.776 bytes | glTF 2 válido | `CONE_BASE_PIVOT` |
| `cardboard_fin.glb` | 33.176 bytes | glTF 2 válido | `FIN_GRAB_PIVOT`, `SNAP_CONTACT` |
| `launch_stand.glb` | 98.448 bytes | glTF 2 válido | `ROCKET_PLACEMENT_POINT` |
| `workbench.glb` | 149.128 bytes | glTF 2 válido | raiz única |
| `tape_roll.glb` | 105.816 bytes | glTF 2 válido | raiz única |

Dimensões principais auditadas no Blender 5.1.2:

- garrafa: aproximadamente `0,82 × 0,81 × 2,66`;
- cone: aproximadamente `0,67 × 0,67 × 0,77`;
- aleta: aproximadamente `0,73 × 0,04 × 0,74`;
- bancada: tampo aproximadamente `5,90 × 3,25 × 0,18`;
- base: aproximadamente `1,34 × 0,82 × 0,62`;
- fita: rolo aproximadamente `0,69 × 0,69 × 0,12`.

O gerador v2 usa sistema métrico, transformação aplicada e exportação Y-up. A orientação e os materiais serão validados novamente após a importação Godot.

## Riscos encontrados

1. Os v2 estavam fora da raiz `res://` e ainda não tinham sidecars `.import`.
2. O código atual referencia v3 e usa fallback visual para primitivas; o novo slice não reutilizará esse fallback.
3. A física existente no working tree integra um `Node3D`; ela não atende à exigência de `RigidBody3D`.
4. A telemetria existente fica somente em memória e não salva JSON.
5. Não há asset v2 específico para o recipiente de água; ele precisará de uma malha autoral simples, não de um cilindro genérico visível.
6. `scenes/main.tscn` e `scenes/reference/dashboard_main.tscn` compartilham um UID anterior; este slice não alterará essas cenas.
7. A aprovação perceptiva e o critério humano exigem avaliação presencial e não podem ser inferidos por compilação.

## Estratégia de preservação

- Criar apenas novos arquivos em namespaces `vertical_slice_v1` e novos wrappers de objetos.
- Espelhar os GLBs v2 dentro do projeto sem alterar os originais.
- Não alterar `project.godot` nem a cena principal anterior durante o desenvolvimento.
- Executar a nova cena explicitamente.
- Manter a telemetria anterior e criar um serviço persistente separado para o slice.
- Não criar fallback visível por primitivas para os seis objetos principais.
- Limitar commits, se seguros, apenas aos caminhos novos desta tarefa.

## Gate seguinte

Copiar os seis GLBs v2 para `app/godot/rocket_workshop/assets_3d/export/v2/`, executar importação headless, carregar cada um como `PackedScene`, instanciar e confirmar a presença de `MeshInstance3D`. Somente depois disso a montagem visual deve avançar.
