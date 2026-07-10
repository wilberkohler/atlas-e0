# Prompt Codex 007 — Gerar Assets da Oficina no Blender

Use a especificação existente em:

```text
prompts/blender/002_assets_realistas_oficina_foguete.md
```

para criar um pipeline reproduzível de geração e exportação dos assets da Oficina do Foguete no Blender.

## Objetivo

Criar um script Python `bpy` que produza uma primeira versão visual significativamente melhor que os placeholders atuais e que possa ser refinada manualmente depois.

## Arquivos a criar

```text
tools/blender/generate_rocket_workshop_v3.py
assets_3d/README.md
```

O script deve gerar e exportar:

```text
assets_3d/source/oficina_foguete_v3.blend
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

## Requisitos do script

- idempotente;
- organizado por funções;
- criar coleções por asset;
- usar nomes estáveis;
- definir pivôs corretos;
- aplicar transforms;
- gerar materiais PBR compatíveis com glTF;
- criar UVs simples quando necessário;
- salvar o `.blend` antes das exportações;
- exportar cada asset individualmente;
- imprimir relatório final de arquivos gerados;
- permitir executar por linha de comando do Blender e pelo editor de scripts.

## Prioridade visual

Priorizar nesta ordem:

1. silhueta convincente da garrafa PET;
2. material transparente legível;
3. aleta com espessura e aparência de papelão;
4. cone com aparência artesanal;
5. bancada de madeira;
6. elástico deformável;
7. base e props.

## Garrafa PET

Não criar um cilindro simples.

A malha deve possuir:

- base com ondulações/pés;
- corpo com leve cintura;
- ombros;
- gargalo;
- pequena assimetria ou deformação;
- Solidify ou geometria equivalente para parede fina;
- material transparente PBR;
- tampa separada.

## Materiais

Criar materiais com nomes definidos na especificação.

Para o PET, usar transmissão, IOR de plástico transparente, roughness moderada e imperfeição sutil. O material deve permanecer legível no Godot.

Para papelão, usar cor, roughness, bump/noise leve e bordas um pouco irregulares.

## Integração Godot

Criar também documentação em `assets_3d/README.md` contendo:

- como executar o script no Blender;
- como reexportar;
- caminhos dos arquivos;
- nomes e pivôs;
- escala adotada;
- como importar os `.glb` no Godot;
- quais cenas existentes devem substituir os placeholders.

Não alterar o código Godot neste prompt.

## Limite esperado

O script procedural deve produzir uma boa base semirrealista, mas não fingir que substitui acabamento artístico manual. Marcar no README os pontos que mais se beneficiam de revisão por artista:

- textura e microimperfeições do PET;
- UVs finais;
- material de fita;
- deformação do elástico;
- desgaste da bancada;
- acabamento dos props.

## Segurança

Não criar mecanismo operacional, conexões reais, dimensões de construção, instrumentos ou detalhes que possam servir como orientação prática para um foguete pressurizado real. O objetivo é exclusivamente visual e lúdico.
