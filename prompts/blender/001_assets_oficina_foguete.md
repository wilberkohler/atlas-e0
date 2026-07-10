# Prompt Blender 001 — Assets da Oficina do Foguete

Use este documento como especificação para criar, por meio de Blender e eventualmente um script Python `bpy`, o primeiro pacote de assets 3D da Oficina do Foguete.

## Objetivo

Criar objetos estilizados, reconhecíveis e leves para uma experiência Godot em formato de diorama 3D.

A aparência deve comunicar materiais cotidianos de uma oficina infantil de invenção:

- garrafa PET;
- papelão;
- papel;
- fita adesiva;
- elástico;
- madeira;
- plástico simples.

Não buscar fotorrealismo. Buscar leitura visual clara, personalidade e boa resposta à iluminação.

## Assets obrigatórios

### 1. Garrafa PET

- Corpo transparente.
- Formato reconhecível de garrafa reutilizada.
- Leves deformações para não parecer cilindro perfeito.
- Objeto separado da tampa ou bocal.
- Origem central adequada para manipulação.
- Dimensões coerentes entre os demais assets, sem usar medidas operacionais de construção real.

### 2. Cone

- Cone simples de papel ou plástico fino.
- Material levemente fosco.
- Borda visível.
- Origem no centro da base para facilitar o snap no topo da garrafa.

### 3. Aleta

- Uma peça de papelão.
- Espessura visível.
- Bordas um pouco irregulares.
- Produzir uma única aleta reutilizável três vezes no Godot.
- Origem no ponto de contato com a garrafa.

### 4. Elástico virtual

- Faixa elástica grossa e estilizada.
- Deve poder ser deformada no Godot ou ter duas versões: relaxada e esticada.
- Material fosco com pequena variação de superfície.
- Não representar um mecanismo real de lançamento em detalhe.

### 5. Base de lançamento

- Estrutura simples de madeira e plástico/metal.
- Visual de brinquedo experimental.
- Uma área clara para posicionar a garrafa.
- Um pequeno indicador luminoso ou encaixe para alavanca.
- Sem detalhes operacionais reais de pressão.

### 6. Bancada

- Mesa de madeira marcada pelo uso.
- Pequenas manchas, riscos e recortes.
- Escala suficiente para acomodar todos os objetos.
- Bordas arredondadas.

### 7. Fita adesiva

- Rolo separado.
- Material semitransparente ou brilhante.
- Pode ser inicialmente decorativo, mas deve permitir interação futura.

## Estilo

- Low-poly refinado.
- Formas arredondadas e amigáveis.
- Materiais simples com aparência PBR leve.
- Paleta natural: transparência do PET, marrom do papelão, madeira, borracha, pequenas cores de destaque.
- Evitar aparência de ícones, botões ou componentes de dashboard.

## Requisitos técnicos

- Blender em unidades métricas.
- Aplicar transforms antes da exportação.
- Normais consistentes.
- Malhas limpas e leves.
- Cada asset em coleção própria ou claramente nomeado.
- Origens/pivôs posicionados para arraste, giro e encaixe.
- Sem modificadores não aplicados, exceto quando necessários para versões editáveis.
- Exportar cada asset como `.glb` separado.

## Convenção de nomes

```text
PET_Bottle
Nose_Cone
Cardboard_Fin
Elastic_Relaxed
Elastic_Stretched
Launch_Stand
Workbench
Tape_Roll
```

## Materiais sugeridos

```text
MAT_PET_Clear
MAT_Paper_OffWhite
MAT_Cardboard
MAT_Rubber
MAT_Wood_Workbench
MAT_Plastic_Base
MAT_Tape_Clear
```

## Estrutura de saída

```text
assets_3d/source/oficina_foguete.blend
assets_3d/export/pet_bottle.glb
assets_3d/export/nose_cone.glb
assets_3d/export/cardboard_fin.glb
assets_3d/export/elastic_relaxed.glb
assets_3d/export/elastic_stretched.glb
assets_3d/export/launch_stand.glb
assets_3d/export/workbench.glb
assets_3d/export/tape_roll.glb
```

## Se for gerar via Python `bpy`

Crie um script reproduzível que:

1. limpe a cena;
2. crie coleções;
3. gere as malhas base;
4. aplique bevels discretos;
5. crie materiais;
6. defina pivôs;
7. salve o `.blend`;
8. exporte os `.glb` individualmente.

O script deve ser idempotente: executá-lo novamente não deve duplicar objetos indefinidamente.

## Critério de aceite visual

Ao abrir a cena sem textos, uma pessoa deve reconhecer imediatamente:

- uma bancada de trabalho;
- uma garrafa PET;
- peças de papelão;
- elásticos;
- uma base para testar o foguete.

## Observação de segurança

Os assets e a cena são para uma simulação digital. Não incluir escala, instrumentos, conexões ou detalhes que funcionem como instruções reais de construção e lançamento de um foguete pressurizado.
