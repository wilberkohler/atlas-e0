# Prompt Codex 002 — Build Interativo Sensorial

Evolua o projeto Flutter existente em `app/flutter` para transformar a Experiência Zero em uma bancada de testes de Design de Experiências.

## Objetivo da Build 002

Substituir a experiência de perguntas independentes por uma experiência interativa curta, baseada em exploração sensorial e decisões implícitas.

O jogador deve sentir que está explorando um pequeno ambiente, não respondendo a um questionário.

## Princípio de design

> Não queremos que o jogador responda perguntas. Queremos que ele tenha vontade de fazer perguntas ao mundo.

## Conceito da experiência

Criar uma cena simples chamada `Sala Zero`.

A sala deve conter alguns elementos interativos visuais, por exemplo:

- um objeto desconhecido no centro;
- uma porta fechada;
- uma janela com algo distante;
- uma mesa com uma gaveta;
- um painel ou dispositivo apagado.

A interface pode ser simples e minimalista. Não precisa de arte final. Pode usar cards, ícones, formas geométricas e animações simples.

## Regras

- Reduzir textos longos.
- Evitar perguntas diretas do tipo quiz.
- O jogador deve interagir tocando em elementos da cena.
- Cada interação deve gerar uma pequena reação visual ou textual curta.
- A experiência deve durar entre 2 e 5 minutos.
- Ao final, exibir uma tela de observações sobre como o jogador explorou.

## Eventos a registrar

Para cada interação, registrar:

- tipo do elemento tocado;
- ordem da interação;
- horário;
- tempo desde o início da sessão;
- tempo desde a última interação;
- número de vezes que o mesmo elemento foi tocado;
- se o jogador explorou elementos opcionais;
- se o jogador tentou sair antes de explorar a sala.

## Estados de experiência inferidos de forma simples

Criar regras simples, sem IA generativa:

### Curiosidade

Sinais possíveis:

- tocou em vários elementos diferentes;
- explorou elementos opcionais;
- voltou a elementos já vistos.

### Hesitação

Sinais possíveis:

- demorou muito entre interações;
- tocou repetidamente no mesmo elemento sem avançar.

### Engajamento

Sinais possíveis:

- completou a experiência;
- explorou mais do que o mínimo;
- permaneceu ativo até a tela final.

## Tela final

A tela final deve se chamar `O que observamos`.

Não usar arquétipos.
Não usar frases como `você é`.
Não classificar personalidade.

Usar frases como:

- `Você explorou a sala antes de tentar concluir a experiência.`
- `Você voltou a elementos já vistos, o que indica tentativa de confirmar pistas.`
- `Você interagiu rapidamente com os primeiros elementos e desacelerou quando encontrou algo inesperado.`

## Estrutura sugerida

Criar ou adaptar:

```text
lib/models/
  interactive_element.dart
  interaction_event.dart
  experience_state_summary.dart

lib/screens/
  zero_room_screen.dart
  observation_screen.dart

lib/services/
  interaction_observer.dart
  experience_state_inferer.dart

lib/widgets/
  interactive_element_card.dart
  zero_room_layout.dart
```

## Critério de aceite

A build deve permitir:

1. abrir a experiência;
2. explorar a Sala Zero;
3. registrar interações;
4. gerar observações simples com base no comportamento;
5. concluir a experiência sem erros.

Priorize simplicidade, clareza e modularidade. Não tente fazer arte sofisticada agora.
