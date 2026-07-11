# Prompt Codex 011 — Loop de Repetição e Game Feel

Integre somente depois que as cenas `FinInteractionLab.tscn` e `FlightLab.tscn` estiverem aprovadas isoladamente.

## Objetivo

Criar uma vertical slice de 30 a 60 segundos que provoque espontaneamente a vontade de ajustar a montagem e tentar novamente.

## Ciclo

```text
montar uma aleta
→ definir energia/água de forma visual
→ ajustar ângulo da base
→ lançar
→ observar trajetória
→ retornar rapidamente
→ alterar uma variável
→ lançar de novo
```

## Regra central

Não mostrar nota, porcentagem ou tela de resultado durante o ciclo principal.

O jogador deve compreender o resultado por:

- trajetória;
- giro;
- estabilidade;
- altura;
- deslocamento pelo vento;
- impacto;
- comparação com o voo anterior.

## Preparação visual

Implementar:

- garrafa presa à base;
- mecanismo visual de energia sem valores reais;
- indicador físico de vento, como fita ou biruta;
- aro ou faixa de objetivo no cenário;
- alavanca física de lançamento;
- câmera próxima do foguete.

## Anticipação

Antes do lançamento:

- pausa curta de 0,3 a 0,8 segundos;
- tensão visual na base;
- pequeno tremor do foguete;
- som crescente de preparação;
- câmera aproximando discretamente;
- partículas ou condensação abstrata.

## Lançamento

No momento da liberação:

- resposta imediata da base;
- som de soltura;
- partículas de água/ar estilizadas;
- microtremor de câmera curto;
- rastro inicial forte e depois reduzido;
- transição da câmera para acompanhamento.

## Durante o voo

- escala visual clara por cenário;
- rastro temporário;
- giro e inclinação legíveis;
- vento visível no ambiente;
- câmera amortecida;
- ápice claramente perceptível;
- som de vento crescente e decrescente.

## Após o voo

- impacto físico e som coerente;
- câmera segura por breve momento;
- trajetória anterior permanece como linha fantasma;
- marcador discreto no ponto mais alto e no impacto;
- retorno à bancada em no máximo três segundos;
- montagem preservada;
- próxima ação sugerida pelo próprio mundo, não por texto longo.

## Comparação

Após o segundo voo:

- manter as duas trajetórias com cores ou intensidades diferentes;
- destacar visualmente onde houve maior estabilidade;
- não explicar tudo por texto;
- permitir ao jogador inferir a causa.

## Objetivo de teste

Criar uma configuração inicial propositalmente imperfeita, mas não frustrante:

- uma aleta levemente inclinada;
- energia mediana;
- vento lateral leve.

O primeiro voo deve apresentar giro ou desvio suficiente para provocar ajuste.

Após o jogador corrigir a aleta, o segundo voo deve melhorar perceptivelmente.

## Métricas

Registrar:

- tempo até o primeiro lançamento;
- quantidade de alterações após cada voo;
- variável alterada primeiro;
- número de lançamentos;
- tempo entre pouso e nova interação;
- abandono após primeiro voo;
- repetição espontânea;
- melhora entre trajetórias.

## Critérios de aceite

1. O primeiro ciclo completo leva menos de um minuto.
2. O primeiro voo imperfeito é compreensível e não parece aleatório.
3. A correção de uma aleta melhora o voo de forma visível.
4. O retorno à bancada leva menos de três segundos.
5. O jogador consegue alterar uma variável sem abrir painel.
6. Ao menos uma pessoa de teste tenta uma segunda vez sem ser instruída.
7. A segunda trajetória permite comparação imediata.
8. A experiência continua funcionando sem HUD técnico.

## Segurança

Manter todos os parâmetros abstratos. Não incluir instruções, medidas ou valores reais para montagem ou pressurização física de garrafas.
