# Prompt Codex 004 — Objetos vs Botões

Evolua a Experiência Zero para testar uma única hipótese comportamental.

## Hipótese da Build 004

> Objetos visuais manipuláveis despertam mais exploração do que botões que apenas representam objetos.

## Objetivo

Transformar os elementos da Sala Zero para que pareçam objetos posicionados em um pequeno mundo interativo, e não botões de interface.

Não alterar a estrutura geral do app.
Não sofisticar o painel do desenvolvedor.
Não criar novas mecânicas complexas.
Não mudar a hipótese da build.

A build deve isolar uma variável: representação visual dos elementos.

## Contexto

Na Build 002/003, os elementos eram funcionalmente interativos, mas ainda pareciam botões. O teste indicou que isso reduziu a sensação de mundo e aumentou o cansaço quando a lógica de saída não ficou clara.

Agora queremos testar se a simples mudança de representação — de botões para objetos manipuláveis — aumenta exploração, revisitas e engajamento.

## O que manter

- Registro de sessões.
- Histórico local.
- Painel do desenvolvedor.
- Métricas existentes.
- Lógica geral de conclusão.
- Exportação/visualização de JSON, se já implementada.

## O que mudar

### 1. Layout da Sala Zero

Substituir a lista ou grade de botões por uma composição visual simples da sala.

Pode ser uma tela 2D simples com áreas posicionadas:

- centro: objeto desconhecido;
- lateral esquerda: mesa/gaveta;
- lateral direita: painel apagado;
- fundo: janela;
- fundo ou canto: porta.

Não precisa de arte final. Pode usar `Container`, `Stack`, `Positioned`, ícones, formas geométricas e pequenas animações.

### 2. Objetos com estado visual

Cada objeto deve ter estados visíveis:

- não explorado;
- explorado;
- revisitado;
- ativo ou alterado.

Exemplos de mudanças:

- o objeto central pulsa após o primeiro toque;
- a gaveta fica entreaberta;
- o painel acende uma luz;
- a janela revela uma silhueta ou sinal distante;
- a porta muda de bloqueada para disponível.

### 3. Feedback de mundo

Cada interação deve parecer uma reação do ambiente, não apenas uma mensagem de interface.

Exemplos:

- luz acende;
- pequeno som textual sugerido, se áudio ainda não existir;
- estado muda;
- microanimação;
- indicador visual aparece.

Evitar textos longos.

### 4. Clareza da porta

A porta deve comunicar visualmente sua condição.

Exemplo:

- bloqueada: porta escura, indicador vermelho/cinza, texto curto `sem energia`;
- parcialmente liberada: indicadores acesos conforme exploração;
- liberada: porta iluminada, texto curto `abrir`.

O jogador não deve precisar adivinhar uma regra invisível.

### 5. Medição específica da hipótese

No painel do desenvolvedor, adicionar ou destacar métricas úteis para comparar esta build com a anterior:

- quantidade média de elementos únicos explorados;
- número de revisitas por sessão;
- tempo até primeira interação;
- tentativas de saída antes da liberação;
- taxa de conclusão;
- duração média.

Se possível, registrar `buildVersion: "004_objetos_vs_botoes"` em cada sessão.

## Critério de aceite

A build deve permitir:

1. abrir a Sala Zero;
2. ver objetos posicionados em uma sala, não botões tradicionais;
3. tocar nos objetos e perceber mudança visual;
4. entender visualmente por que a porta está bloqueada ou liberada;
5. concluir a sessão;
6. registrar a sessão com `buildVersion`;
7. visualizar as métricas no painel do desenvolvedor.

## Regra final

Não tente transformar a experiência em jogo completo ainda.
Esta build é um experimento de percepção e exploração.
