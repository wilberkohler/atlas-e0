# Prompt Blender 002 — Assets Realistas da Oficina do Foguete

Crie um pacote visual de maior qualidade para a Oficina do Foguete, destinado à importação no Godot 4.x.

## Objetivo

Substituir os placeholders geométricos da build atual por objetos imediatamente reconhecíveis, com materiais convincentes e aspecto artesanal.

O resultado deve parecer uma pequena oficina de ciência/engenharia montada por uma criança curiosa ou estudante, sem parecer brinquedo genérico nem equipamento industrial.

## Direção de arte

Estilo:

- semirrealista estilizado;
- materiais cotidianos reconhecíveis;
- pequenas imperfeições;
- boa leitura a média distância;
- escala coerente entre as peças;
- iluminação de bancada quente e acolhedora;
- visual tangível, não aparência de ícone ou dashboard.

Evitar:

- cilindros lisos representando garrafas;
- formas excessivamente perfeitas;
- materiais chapados;
- cores plásticas saturadas demais;
- peças que pareçam botões de interface;
- componentes funcionais detalhados de um lançador real.

## Asset principal — Garrafa PET

Criar uma garrafa PET reutilizada com:

- silhueta reconhecível;
- base com pés/ondulações típicas;
- ombros e gargalo bem definidos;
- parede fina e transparente;
- pequenas deformações e amassados suaves;
- leves riscos e marcas de uso;
- tampa/bocal em objeto separado;
- interior visualmente legível quando iluminado;
- pivô central adequado para rotação e lançamento;
- versão intacta e versão levemente deformada para impacto.

### Material PET

Usar material PBR com:

- transmissão alta;
- IOR aproximado de plástico transparente;
- roughness baixa a moderada;
- normal/bump sutil para microimperfeições;
- espessura suficiente para evitar aparência de vidro maciço;
- reflexos controlados para permanecer legível no Godot.

## Cone

Criar cone artesanal de papel ou plástico fino:

- borda da folha visível;
- pequena sobreposição de colagem;
- deformação discreta;
- material fosco;
- pivô na base;
- duas variações de cor/material.

## Aletas

Criar uma aleta modular de papelão/plástico reciclado:

- espessura perceptível;
- bordas ligeiramente imperfeitas;
- textura fibrosa ou ondulada sutil;
- pequena tira de fita aplicada;
- pivô exatamente na linha de contato com a garrafa;
- versão reta e versão levemente empenada;
- UV simples e reutilizável.

## Fita adesiva

Criar:

- rolo de fita;
- tira curta;
- tira média;
- tira dobrada/irregular.

O material deve ser semitransparente com brilho discreto.

## Elástico

Criar elástico com topologia adequada a deformação:

- versão relaxada;
- versão tensionada;
- shape key ou armature simples para interpolação;
- material de borracha com roughness adequada;
- espessura suficiente para leitura visual.

Não representar em detalhes um mecanismo físico de lançamento real.

## Base de teste

Criar uma base segura e estilizada:

- combinação de madeira, plástico e metal simples;
- aparência de experimento escolar;
- encaixe visual para a garrafa;
- alavanca fictícia ou botão físico de teste;
- luz indicadora;
- sem conexões funcionais, válvulas ou instrumentos realistas;
- pivôs e pontos de montagem nomeados.

## Bancada

Criar bancada de madeira com:

- riscos;
- pequenas manchas;
- marcas de corte;
- cantos arredondados;
- variação de roughness;
- espaço organizado para as peças;
- tamanho adequado ao diorama.

## Props secundários

Criar objetos de ambientação leves:

- lápis;
- régua;
- caderno com desenhos abstratos;
- recortes de papelão;
- tesoura fechada e decorativa;
- adesivos sem marcas comerciais;
- caixa de peças.

Esses objetos não precisam ser interativos nesta build.

## Requisitos técnicos

- Blender em unidades métricas;
- aplicar transforms;
- normais corretas;
- UVs organizadas;
- malhas leves, mas sem sacrificar a silhueta;
- LOD opcional para garrafa e bancada;
- colisões simples em meshes separadas ou nomes claros;
- pivôs preparados para arraste e encaixe;
- cada asset em coleção própria;
- exportação em `.glb` individual;
- materiais compatíveis com glTF/Godot;
- texturas compactadas ou salvas em pasta compartilhada;
- nomes sem espaços.

## Convenção de nomes

```text
PET_Bottle_Main
PET_Bottle_Impact
Bottle_Cap
Paper_Nose_Cone_A
Paper_Nose_Cone_B
Cardboard_Fin_Straight
Cardboard_Fin_Warped
Tape_Roll
Tape_Strip_Short
Tape_Strip_Medium
Elastic_Relaxed
Elastic_Stretched
Launch_Stand
Launch_Lever
Launch_Indicator
Workbench
Prop_Pencil
Prop_Ruler
Prop_Notebook
Prop_CardboardScraps
```

## Estrutura de saída

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

## Se o trabalho for realizado por script Python `bpy`

Gerar um script reproduzível em:

```text
tools/blender/generate_rocket_workshop_v3.py
```

O script deve:

1. limpar somente as coleções que ele próprio gerencia;
2. criar ou atualizar os assets sem duplicar objetos;
3. criar materiais PBR;
4. gerar UVs básicas quando possível;
5. definir pivôs e nomes;
6. salvar o `.blend`;
7. exportar os `.glb`;
8. imprimir relatório de assets gerados.

Observação: um script procedural pode gerar uma boa base, mas o acabamento visual final deve permitir ajustes manuais por artista.

## Critérios de aceite visual

Sem qualquer texto ou legenda, uma pessoa deve reconhecer de imediato:

- uma garrafa PET reutilizada;
- aletas artesanais;
- cone de papel;
- fita adesiva;
- elástico;
- bancada de oficina;
- base de teste experimental.

A garrafa não pode parecer um cilindro transparente genérico. Os materiais devem reagir de forma distinta à luz.

## Segurança

Os modelos existem exclusivamente para uma simulação digital. Não incluir medidas, detalhes internos, instrumentos, conexões ou mecanismos que funcionem como orientação prática para construção de um foguete pressurizado real.
