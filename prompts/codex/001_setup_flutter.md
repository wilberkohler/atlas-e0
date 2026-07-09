# Prompt Codex 001 — Setup Flutter

Crie um projeto Flutter minimalista para o repositório `atlas-e0`.

## Objetivo

Construir a primeira versão da Experiência Zero: uma experiência curta de tomada de decisão e observação comportamental.

## Conceito

Frase de abertura:

> Toda decisão revela alguma coisa.

O sistema não deve classificar o jogador. Ele deve observar a sessão e devolver percepções sobre como as decisões foram tomadas.

## Requisitos do MVP

- Criar projeto Flutter dentro da pasta `app/flutter`.
- Implementar tela inicial com a frase: `Toda decisão revela alguma coisa.`
- Botão `Começar`.
- Criar cinco telas de decisão, exibidas uma por vez.
- Cada decisão deve registrar:
  - índice da decisão;
  - horário de entrada na tela;
  - horário da escolha;
  - tempo gasto para decidir;
  - opção escolhida.
- Armazenar os dados da sessão em memória por enquanto.
- Ao final, exibir tela `Observações` com três observações simples baseadas nos dados registrados.

## Restrições

- Não criar login.
- Não criar banco externo.
- Não adicionar IA generativa.
- Não criar ranking.
- Não usar arquétipos.
- Não usar linguagem de teste de personalidade.
- Não adicionar dependências desnecessárias.

## Estrutura sugerida

```text
app/flutter/lib/
  main.dart
  app.dart
  models/
    decision_option.dart
    decision_step.dart
    session_event.dart
    session_summary.dart
  screens/
    opening_screen.dart
    decision_screen.dart
    observations_screen.dart
  services/
    session_observer.dart
    observation_generator.dart
  widgets/
    primary_button.dart
    decision_option_card.dart
```

## Critério de aceite

O app deve rodar localmente e permitir completar uma sessão inteira:

Abertura → 5 decisões → Observações.

A prioridade é clareza, modularidade e facilidade de evolução.
