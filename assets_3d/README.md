# Assets 3D - Oficina do Foguete

Este pacote e gerado por script Blender para substituir os placeholders da build Godot sem quebrar a interacao.

## Gerar ou reexportar

Execute a partir da raiz do repositorio:

```powershell
& "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe" --background --python "tools/blender/generate_rocket_workshop_v3.py"
```

O script e idempotente: ele limpa apenas as colecoes com prefixo `RW3_`, recria os assets, salva o `.blend` e exporta os `.glb`.

## Saidas

Fonte editavel:

```text
assets_3d/source/oficina_foguete_v3.blend
```

Exports principais:

```text
assets_3d/export/v3/pet_bottle_main.glb
assets_3d/export/v3/pet_bottle_impact.glb
assets_3d/export/v3/bottle_cap.glb
assets_3d/export/v3/nose_cone_a.glb
assets_3d/export/v3/nose_cone_b.glb
assets_3d/export/v3/cardboard_fin_straight.glb
assets_3d/export/v3/cardboard_fin_warped.glb
assets_3d/export/v3/tape_set.glb
assets_3d/export/v3/elastic_set.glb
assets_3d/export/v3/launch_stand.glb
assets_3d/export/v3/workbench.glb
assets_3d/export/v3/workshop_props.glb
```

Os mesmos `.glb` sao espelhados em:

```text
app/godot/rocket_workshop/assets_3d/export/v3/
```

Esse espelho e necessario porque o Godot importa assets pelo namespace `res://`.
O `.blend` fica fora do projeto Godot para evitar que o editor tente importa-lo como asset.

## Escala e pivots

- Unidade Blender: metro.
- Garrafa PET: origem no centro da garrafa, eixo longitudinal em X.
- Cone: origem na base, eixo longitudinal em X, ponta para +X.
- Aleta: origem na linha de contato com a garrafa.
- Elastico: origem no centro visual do conjunto.
- Bancada e base: origem no centro do asset.

## Integracao no Godot

As cenas existentes continuam sendo:

```text
app/godot/rocket_workshop/scenes/parts/pet_bottle.tscn
app/godot/rocket_workshop/scenes/parts/nose_cone.tscn
app/godot/rocket_workshop/scenes/parts/fin.tscn
app/godot/rocket_workshop/scenes/parts/elastic_unit.tscn
```

O script `DraggablePart3D` tenta carregar automaticamente:

```text
res://assets_3d/export/v3/pet_bottle_main.glb
res://assets_3d/export/v3/nose_cone_a.glb
res://assets_3d/export/v3/cardboard_fin_straight.glb
res://assets_3d/export/v3/elastic_set.glb
```

Se o `.glb` nao existir ou ainda nao tiver sido importado, os placeholders procedurais continuam funcionando.

## Pontos para revisao artistica

- Textura e microimperfeicoes do PET.
- UVs finais.
- Material da fita.
- Deformacao do elastico.
- Desgaste da bancada.
- Acabamento dos props.

## Seguranca

Os assets sao apenas visuais e ludicos. Eles nao incluem medidas, conexoes reais, instrumentos funcionais ou detalhes que sirvam como orientacao pratica para construir um foguete pressurizado real.
