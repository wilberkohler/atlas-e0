# Metodologia MIT e influência na Experience Engine

## Síntese

A inspiração central do MIT para o Atlas não deve ser simplesmente “aulas práticas”. A ideia mais forte é a integração entre teoria, prática, projeto, laboratório e pesquisa.

O MIT resume isso no princípio `mens et manus`: mente e mão. Para a Experience Engine, isso pode ser traduzido assim:

> O jogador aprende melhor quando pensa com a mão: observa, manipula, testa, falha, ajusta e só depois formaliza o aprendizado.

## O que observar na metodologia MIT

### 1. Learning by doing

O MIT explicita que combina rigor acadêmico com uma abordagem de `learning-by-doing`, ou seja, aprender fazendo. Esse ponto não é apenas operacional; ele define a arquitetura da experiência.

Para o Atlas, isso significa que o jogador não deve começar recebendo uma explicação completa. Ele deve começar diante de uma situação manipulável.

### 2. Mens et manus

Na visão do MIT, `mens et manus` coloca teoria e prática em equilíbrio. A teoria nasce da sala de aula, mas a prática nasce do ato de fazer algo funcionar.

Para o Atlas, a consequência é clara: o aprendizado não deve estar apenas no texto final ou na explicação da IA, mas no comportamento do mundo quando o jogador mexe nele.

### 3. Maker education

O MIT destaca makerspaces, oficinas, classes mão-na-massa e programas experienciais. A cultura maker não é só fabricação; é experimentação com materiais, restrições, tentativa e erro.

Para a Experience Engine, isso sugere que a interface precisa se aproximar de uma bancada, oficina ou laboratório, não de uma prova ou questionário.

### 4. Pesquisa com mentoria

O UROP, programa de pesquisa de graduação do MIT, mostra outro ponto importante: o aluno entra cedo em pesquisa real, com mentoria, problema aberto e possibilidade de contribuição concreta.

Para o Atlas, isso sugere um modelo onde o jogador não apenas consome conteúdo. Ele pode se tornar um pesquisador dentro do mundo.

### 5. Projetos interdisciplinares

O NEET do MIT organiza trilhas interdisciplinares em torno de projetos reais e aplicados. Isso reforça que o aprendizado de engenharia não acontece em caixinhas isoladas, mas em sistemas.

Para o Atlas, o mundo deve combinar física, orçamento, risco, reputação, pessoas, recursos, tempo e consequências.

## Tradução para a Experience Engine

### Princípio 1 — Problema antes da explicação

A experiência deve começar com uma situação: algo quebrado, estranho, incompleto ou instável.

O jogador deve pensar:

> O que acontece se eu mexer nisso?

Não:

> Qual alternativa devo escolher?

### Princípio 2 — Objeto antes de botão

Botões comunicam interface.
Objetos comunicam mundo.

A Build 002 mostrou que representar objetos como botões reduz a sensação de exploração. A próxima evolução deve testar objetos com posição, estado, reação e transformação.

### Princípio 3 — Feedback sistêmico

O mundo deve responder de forma visível:

- acender;
- travar;
- vibrar;
- mudar de som;
- mudar de forma;
- revelar uma pista;
- liberar uma nova possibilidade.

Sem feedback, curiosidade vira frustração.

### Princípio 4 — Hipótese por build

A partir da Build 004, cada build deve testar uma única hipótese comportamental.

Exemplo:

> Objetos visuais manipuláveis geram mais exploração do que botões representando objetos.

### Princípio 5 — Dados para o desenvolvedor

A devolutiva comportamental não precisa ser, neste momento, uma resposta ao jogador. O valor maior está em criar uma base de dados para entender padrões.

Métricas importantes:

- tempo até primeira interação;
- elementos únicos explorados;
- revisitas;
- abandono;
- sequência de exploração;
- tempo entre ações;
- resposta a pistas visuais;
- diferença entre sessões do mesmo usuário;
- diferença entre perfis de usuários.

## Proposta para o Atlas

O Atlas deve ser tratado como um laboratório de experiências aplicadas, inspirado em engenharia prática.

A fórmula-base pode ser:

```text
Situação concreta
→ Manipulação
→ Resposta do mundo
→ Registro de comportamento
→ Reflexão
→ Nova hipótese
```

A IA entra depois, não como professora que explica tudo, mas como mentora, observadora ou pesquisadora que ajuda a transformar experiência em aprendizado.

## Decisão recomendada

A Build 004 deve testar a hipótese:

> Objetos despertam mais exploração do que botões.

Não mudar a história, o painel, a lógica de sessão ou a estrutura geral. Mudar apenas a representação visual e interativa dos elementos da sala.

O objetivo é um experimento limpo.
