# Prompt Codex 008 — Hero Assets da Vertical Slice no Blender

Crie um script Python `bpy` reproduzível para gerar apenas os três hero assets da vertical slice da Oficina do Foguete:

1. garrafa PET;
2. aleta de papelão;
3. base artesanal de lançamento.

Não gere o restante da oficina nesta etapa.

## Direção visual

Estilo: **realismo artesanal de maquete científica**.

Os objetos precisam ser reconhecíveis, tangíveis e levemente estilizados. Evitar aparência de cilindros, caixas e primitivas genéricas.

## 1. Garrafa PET

A garrafa deve possuir:

- base ondulada/lobulada reconhecível;
- corpo com variação sutil de diâmetro;
- região de ombro;
- gargalo e anel de tampa;
- parede fina;
- pequenas irregularidades e amassados suaves;
- material transparente com reflexos controlados;
- tampa/bocal como objeto separado;
- pivô adequado para montagem e voo;
- malha limpa e leve.

Criar duas versões:

- `PET_Bottle_Clear`;
- `PET_Bottle_With_Liquid`, com um volume interno simples de líquido colorido separadamente.

Evitar múltiplas camadas transparentes sobrepostas desnecessárias.

## 2. Aleta de papelão

A aleta deve possuir:

- espessura real visível;
- bordas levemente irregulares;
- pequena curvatura ou empeno opcional;
- superfície com variação discreta;
- área de contato clara com a garrafa;
- pivô exatamente no ponto de encaixe;
- material de papelão com roughness elevada e detalhe sutil.

Criar:

- uma versão reta;
- uma versão levemente empenada para testes visuais.

## 3. Base artesanal

A base deve parecer um dispositivo experimental construído em oficina, não equipamento industrial.

Incluir:

- estrutura de madeira e metal/plástico;
- apoio central para a garrafa;
- pequenas peças de fixação;
- alavanca ou trava abstrata;
- indicador visual de pronto;
- marcas de uso;
- pivôs e pontos de encaixe nomeados.

Não representar conexões, medidas ou componentes operacionais reais de pressão.

## Materiais

Criar materiais PBR simples:

- `MAT_PET_Clear`;
- `MAT_Liquid`;
- `MAT_Cardboard`;
- `MAT_Wood_Used`;
- `MAT_Metal_Painted`;
- `MAT_Rubber`.

Adicionar pequenas imperfeições por Noise Texture, Bump e variação de roughness. Não usar texturas externas obrigatórias nesta primeira geração.

## Iluminação de validação

Além dos assets, criar uma cena de validação com:

- bancada simples;
- luz principal ampla e quente;
- luz de preenchimento;
- contraluz suave para evidenciar a transparência da garrafa;
- câmera em ângulo de três quartos;
- fundo neutro.

Renderizar ou deixar pronta uma composição em que os três objetos possam ser julgados antes da exportação.

## Requisitos técnicos

- unidades métricas;
- transforms aplicados;
- normais consistentes;
- bevels discretos;
- smooth shading onde apropriado;
- pivôs corretos;
- coleções separadas;
- nomes estáveis;
- script idempotente;
- salvar `.blend`;
- exportar cada asset em `.glb` separado.

## Saída

```text
tools/blender/generate_vertical_slice_hero_assets.py
assets_3d/source/vertical_slice_hero_assets.blend
assets_3d/export/pet_bottle_clear.glb
assets_3d/export/pet_bottle_with_liquid.glb
assets_3d/export/cardboard_fin_straight.glb
assets_3d/export/cardboard_fin_warped.glb
assets_3d/export/launch_stand_artisanal.glb
```

## Porta de qualidade

Não integrar automaticamente no Godot antes de produzir uma imagem de validação.

A etapa é aprovada apenas se, sem legenda, for possível reconhecer em menos de um segundo:

- uma garrafa PET;
- uma aleta de papelão;
- uma base artesanal de teste.

Se o resultado ainda parecer feito de primitivas, refinar a geometria antes da integração.
