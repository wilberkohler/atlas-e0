# Salto de Qualidade — Vertical Slice da Oficina do Foguete

## Diagnóstico

A build atual provou que o pipeline funciona, mas ainda sofre em três frentes:

1. **Qualidade visual** — os objetos ainda parecem placeholders.
2. **Qualidade mecânica** — o lançamento ainda parece uma animação ou uma simulação pouco convincente.
3. **Qualidade da experiência** — ainda não existe um ciclo forte de tentativa, observação, ajuste e nova tentativa.

O próximo passo não é adicionar mais objetos, telas ou métricas. É construir uma única sequência de aproximadamente 30 a 60 segundos com qualidade suficiente para demonstrar o produto.

## Direção criativa

Adotar o estilo **realismo artesanal de maquete científica**.

A cena deve parecer uma pequena oficina de ciência feita à mão:

- garrafa PET reconhecível;
- papelão com fibras e espessura;
- cone de papel;
- fita adesiva;
- elástico ou mecanismo visual abstrato;
- bancada de madeira marcada;
- iluminação quente;
- proporções levemente estilizadas para facilitar leitura.

O objetivo não é fotorrealismo. É **tangibilidade**: o jogador deve imaginar o material, o peso e o som do objeto.

## Núcleo da experiência

A vertical slice deve provar este ciclo:

> montar → preparar → lançar → observar → comparar → ajustar → lançar novamente

A experiência deve evitar painéis, sliders e percentuais durante o jogo.

## Variáveis iniciais

Limitar a experiência a poucas variáveis compreensíveis:

- alinhamento das aletas;
- inclinação das aletas;
- alinhamento do cone;
- quantidade visual de água/energia virtual;
- ângulo da base;
- vento leve.

Os valores são normalizados e não devem corresponder a instruções reais de pressão ou construção física.

## Quatro portas de qualidade

### Porta 1 — Imagem estática

Antes de trabalhar no jogo completo, produzir uma única cena parada que passe neste teste:

> Em menos de um segundo, uma pessoa reconhece uma garrafa PET artesanal preparada para um teste de foguete.

Critérios:

- silhueta convincente;
- materiais reconhecíveis;
- iluminação coerente;
- escala e composição legíveis;
- ausência de aparência de dashboard.

### Porta 2 — Manipulação tátil

Criar apenas uma interação de alta qualidade: pegar e encaixar uma aleta.

Critérios:

- hover discreto;
- elevação ao selecionar;
- movimento suave;
- rotação controlável;
- atração magnética perto do encaixe;
- som de papelão/fita;
- pequena reação visual ao encaixar;
- possibilidade de remover e reposicionar.

Não avançar até essa única ação ser agradável.

### Porta 3 — Voo convincente

Usar um foguete já montado e trabalhar apenas no lançamento.

Critérios:

- antecipação antes da partida;
- impulso curto e progressivo;
- massa, inércia, gravidade e arrasto perceptíveis;
- estabilização ou instabilidade coerente;
- giro causado por assimetria;
- vento lateral;
- ápice e queda;
- câmera de acompanhamento;
- impacto e retorno rápido.

Duas configurações diferentes devem gerar trajetórias claramente diferentes, mas compreensíveis.

### Porta 4 — Vontade de repetir

Integrar montagem e lançamento.

Critério principal:

> Após o primeiro teste, o jogador decide espontaneamente mudar alguma coisa e tentar novamente.

Recursos mínimos para apoiar isso:

- trilha fantasma do voo anterior;
- comparação visual entre duas trajetórias;
- reinício em poucos segundos;
- nenhuma tela longa de resultado;
- consequências visíveis no próprio foguete e no voo.

## Arquitetura recomendada da simulação

Usar um modelo híbrido:

- `RigidBody3D` para colisão, gravidade e estado físico;
- integração personalizada para empuxo, massa variável abstrata, arrasto, vento e torque aerodinâmico;
- parâmetros normalizados para manter segurança e controle;
- ruído aleatório mínimo e reproduzível por seed;
- resultados explicáveis pela montagem.

Evitar dois extremos:

- trajetória totalmente animada, que parece falsa;
- física completamente solta, que fica caótica e difícil de ensinar.

## Game feel obrigatório

### Antes do lançamento

- pequeno movimento da base;
- tensão visual no mecanismo;
- som curto de preparação;
- pausa de antecipação;
- câmera aproximando discretamente.

### No lançamento

- som de liberação;
- partículas de água/ar abstratas;
- microtremor de câmera;
- resposta imediata da base;
- câmera mudando para acompanhamento.

### Durante o voo

- vento;
- rastro temporário;
- rotação visível;
- leitura clara de estabilidade;
- escala do ambiente para transmitir altura.

### Depois

- impacto;
- câmera retornando;
- trilha fantasma preservada;
- botão físico ou gesto de retorno à bancada;
- montagem mantida para facilitar ajuste.

## Pipeline de arte sem freelancer

1. Definir referências visuais.
2. Gerar modelos-base no Blender por script Python.
3. Ajustar manualmente apenas os três assets heróis: garrafa, aleta e base.
4. Usar materiais PBR e iluminação de ambiente.
5. Importar por `.glb`.
6. Testar no Godot antes de aumentar o pacote.
7. Usar texturas e HDRIs CC0 quando necessário.

## Regra de escopo

Não adicionar novos objetos, personagens, fases, progressão, multiplayer ou monetização até as quatro portas serem aprovadas.

## Métrica de sucesso

A próxima versão não será julgada por quantidade de funcionalidades.

Será julgada por esta reação:

> “Aquela aleta fez o foguete girar. Quero corrigir e lançar de novo.”
