# Build V3 — Realismo Visual e Físico da Oficina do Foguete

## Diagnóstico

A versão atual validou a montagem por manipulação direta, mas ainda é um *graybox* técnico:

- os objetos são reconhecidos pela função, não pelo material;
- a garrafa não parece PET;
- as aletas não parecem papelão/plástico artesanal;
- o mecanismo de energia ainda é abstrato;
- o lançamento é uma animação, não uma consequência contínua da montagem;
- a trajetória não comunica massa, instabilidade, arrasto, giro ou vento.

A próxima versão não deve acrescentar mais sistemas de interface. Deve elevar dois eixos em paralelo:

1. **realismo visual dos objetos**;
2. **realismo perceptivo do lançamento**.

## Meta de produto

Ao ver a bancada sem qualquer texto, uma pessoa deve reconhecer imediatamente:

- uma garrafa PET reutilizada;
- cone e aletas artesanais;
- elásticos, fita e peças de oficina;
- uma base de teste segura e estilizada;
- um foguete montável que reage à qualidade da montagem.

Ao lançar, o jogador deve perceber visualmente por que o foguete voou bem ou mal, sem depender de porcentagens ou mensagens explicativas.

## Nível de realismo desejado

Não buscamos uma calculadora de engenharia nem uma reprodução operacional de um foguete real. Buscamos **realismo perceptivo**:

- materiais convincentes;
- massa e inércia perceptíveis;
- trajetória contínua;
- instabilidade visível;
- causalidade entre montagem e voo;
- feedback sonoro e visual coerente.

## Eixo 1 — Assets visuais

Produzir ou adquirir os seguintes assets em `.glb`:

- garrafa PET transparente com silhueta reconhecível;
- cone de papel/plástico fino;
- aleta de papelão com espessura e bordas imperfeitas;
- fita adesiva e pequenas tiras aplicadas;
- elástico relaxado e tensionado;
- base de teste estilizada;
- bancada de madeira usada;
- pequenos objetos de cenário: lápis, régua, caderno, recortes.

### Materiais mínimos

- PET transparente com reflexos e pequenas deformações;
- papelão fosco e fibroso;
- papel levemente amassado;
- borracha/elástico com deformação visível;
- madeira com desgaste;
- metal/plástico da base com acabamento simples.

## Eixo 2 — Simulação de voo

Substituir trajetórias pré-definidas por um modelo contínuo simplificado, calculado em tempo real.

### Fases

1. montagem;
2. preparação na base;
3. liberação;
4. impulso curto;
5. subida por inércia;
6. ápice;
7. queda;
8. impacto e retorno à bancada.

### Variáveis derivadas da montagem

- alinhamento do cone;
- simetria e ângulo das aletas;
- distribuição visual de massa;
- energia virtual selecionada;
- estabilidade da fixação;
- desalinhamento do conjunto.

### Forças perceptivas

- gravidade;
- impulso aplicado ao eixo local do foguete;
- arrasto proporcional à velocidade;
- torque de estabilização derivado das aletas;
- torque de erro provocado por assimetria;
- vento/gusts leves e configuráveis;
- redução gradual da energia durante a fase de impulso.

Usar coeficientes normalizados, sem apresentar valores reais de pressão, dimensões operacionais ou instruções para construção física.

## Feedback do lançamento

O lançamento deve comunicar o resultado por meio de:

- som de preparação e liberação;
- deformação ou vibração sutil antes da saída;
- partículas estilizadas de ar/água;
- câmera acompanhando a subida;
- sombra no solo;
- trilha visual discreta;
- giro e oscilação compatíveis com a montagem;
- marcador de ápice e ponto de queda apenas no modo de desenvolvedor.

## Interface

A interface do jogador deve ser mínima.

- esconder percentuais e notas;
- esconder painel de telemetria por padrão;
- abrir painel de desenvolvedor com `F2`;
- mostrar dicas somente após inatividade;
- permitir reiniciar e retornar à bancada.

## Métricas para o desenvolvedor

Registrar:

- altura máxima virtual;
- duração do voo;
- deslocamento lateral;
- oscilação angular média e máxima;
- número de rotações;
- qualidade da montagem por componente;
- alterações feitas entre testes;
- evolução entre lançamentos.

## Estratégia de produção

### Trilha A — Código

- criar modelo de voo contínuo;
- separar parâmetros de montagem e física;
- adicionar câmera e feedback;
- permitir troca de assets sem alterar a lógica.

### Trilha B — Arte

- produzir assets no Blender ou contratar artista 3D;
- exportar cada objeto separadamente;
- integrar gradualmente, começando pela garrafa e aleta;
- preservar pivôs, escalas e zonas de encaixe.

## Critério de aceite da V3

A build será aceita quando:

1. a garrafa for reconhecida imediatamente como PET;
2. pelo menos garrafa, cone e aletas usarem modelos e materiais próprios;
3. o jogador manipular os objetos diretamente;
4. a trajetória for calculada continuamente;
5. montagens diferentes produzirem diferenças visíveis de giro, altura e direção;
6. o jogador entender o resultado observando o voo;
7. a telemetria registrar o voo sem dominar a tela;
8. o ciclo montar → lançar → observar → ajustar for prazeroso.

## Segurança

Este projeto é uma simulação digital educativa. Não incluir números reais de pressão, medidas operacionais, componentes funcionais ou instruções detalhadas para construir e lançar um foguete pressurizado no mundo físico.
