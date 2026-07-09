# Prompt Codex 003 — Histórico e Painel do Desenvolvedor

Evolua a Experiência Zero para que ela deixe de gerar apenas uma devolutiva individual ao jogador e passe a funcionar como uma bancada de observação comportamental para o desenvolvedor.

## Objetivo da Build 003

Criar persistência local de sessões e um painel simples para análise das interações.

A prioridade é permitir que o desenvolvedor observe padrões de comportamento ao longo de várias sessões.

## Contexto do aprendizado da Build 002

- A experiência ficou menos chata, mas ainda cansou quando a lógica não ficou clara.
- A lógica de liberação da saída precisa ser mais compreensível ou visualmente sugerida.
- Botões ainda parecem interface, não objetos de um mundo.
- A devolutiva comportamental é mais valiosa como banco de dados para o desenvolvedor do que como resposta final ao jogador neste estágio.
- A análise deve considerar múltiplas sessões, não apenas uma sessão isolada.

## Requisitos principais

### 1. Persistência local

Persistir localmente cada sessão finalizada em JSON.

Cada sessão deve conter:

- sessionId;
- data/hora de início;
- data/hora de fim;
- duração total;
- lista de eventos de interação;
- quantidade total de interações;
- elementos únicos explorados;
- elemento mais tocado;
- tempo médio entre interações;
- se a experiência foi concluída;
- se o usuário repetiu a experiência.

Pode usar armazenamento local simples. Se já houver alguma biblioteca adequada no projeto, aproveite. Caso contrário, usar uma solução simples e bem documentada.

### 2. Painel do desenvolvedor

Criar uma tela acessível discretamente, por exemplo por botão pequeno no canto da tela inicial chamado `Dev` ou por uma ação simples.

O painel deve mostrar:

- número de sessões registradas;
- duração média das sessões;
- taxa de conclusão;
- elemento mais explorado;
- quantidade média de elementos únicos por sessão;
- lista das últimas sessões;
- detalhe de uma sessão com linha do tempo dos eventos.

### 3. Exportação

Adicionar botão para copiar ou exportar o JSON das sessões para facilitar análise futura.

Se exportação de arquivo for trabalhosa, pelo menos exibir o JSON em uma tela copiável.

### 4. Melhorar clareza da saída da sala

A lógica para liberar a saída da sala deve ser compreensível.

Sugestão:

- A porta começa apagada ou bloqueada.
- Cada elemento explorado acende um pequeno indicador visual.
- Quando uma condição mínima é atingida, a porta muda visualmente.
- A porta não deve depender de lógica escondida sem feedback.

Evitar que o jogador precise adivinhar uma regra invisível.

### 5. Elementos mais parecidos com objetos

Reduzir aparência de botão tradicional.

Cada elemento deve ter:

- nome curto;
- ícone ou representação visual simples;
- estado visual: não explorado, explorado, revisitado;
- reação curta ao toque.

Não precisa de arte final.

## Regras de design

- Curiosidade sem clareza vira frustração.
- O jogador deve perceber que suas interações alteram o ambiente.
- A experiência deve gerar dados úteis para o desenvolvedor.
- A devolutiva final para o jogador pode ser simples; o foco desta build é o painel de observação.

## Estrutura sugerida

Adicionar ou adaptar:

```text
lib/models/
  experience_session.dart
  interaction_event.dart
  session_metrics.dart

lib/services/
  session_storage.dart
  session_metrics_service.dart

lib/screens/
  developer_dashboard_screen.dart
  session_detail_screen.dart

lib/widgets/
  metric_card.dart
  interaction_timeline.dart
```

## Critério de aceite

A build deve permitir:

1. jogar uma sessão;
2. concluir a sessão;
3. salvar os eventos localmente;
4. jogar novamente e manter histórico;
5. abrir painel do desenvolvedor;
6. visualizar métricas agregadas;
7. abrir detalhe de sessão;
8. visualizar ou copiar/exportar JSON.

Priorize clareza, simplicidade e dados úteis. Não sofisticar visualmente além do necessário.
