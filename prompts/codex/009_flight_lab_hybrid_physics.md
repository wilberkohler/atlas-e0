# Prompt Codex 009 — Flight Lab com Física Híbrida

Crie uma cena isolada chamada `FlightLab.tscn` para reconstruir o lançamento da Oficina do Foguete sem depender da interface de montagem.

## Objetivo

Produzir um voo perceptivamente convincente e controlável, capaz de mostrar diferenças claras entre montagens.

Não trabalhar em arte final nesta etapa. Usar o melhor modelo disponível, mas concentrar-se na mecânica do voo.

## Princípio

Evitar:

- Tween ou AnimationPlayer como trajetória principal;
- impulso instantâneo seguido apenas de gravidade;
- física completamente solta e caótica.

Usar um modelo híbrido:

- `RigidBody3D`;
- integração de forças por `_integrate_forces` ou aplicação contínua de forças;
- empuxo com curva curta no tempo;
- massa abstrata variável durante o impulso;
- arrasto aerodinâmico;
- vento lateral;
- torque estabilizador;
- torque de assimetria;
- gravidade e colisão do Godot.

## Parâmetros normalizados

Criar um resource `RocketBuildProfile` com valores entre 0 e 1 ou intervalos abstratos:

```text
water_fraction
energy_level
fin_symmetry
fin_alignment
fin_cant
nose_alignment
launch_angle
wind_strength
random_seed
```

Não usar valores reais de pressão nem instruções físicas de construção.

## Modelo de forças

### Empuxo

Usar uma curva temporal, não um impulso único.

Exemplo conceitual:

- subida rápida;
- pico curto;
- queda progressiva;
- encerramento suave.

A intensidade depende de `energy_level` e de uma função de eficiência de `water_fraction`.

### Massa abstrata

Durante a fase de empuxo, reduzir gradualmente uma parcela abstrata de massa para produzir alteração perceptível de aceleração.

### Arrasto

Aplicar força oposta à velocidade, proporcional à velocidade ao quadrado, com limites para evitar instabilidade numérica.

### Estabilidade

Calcular o ângulo entre o eixo longitudinal do foguete e a direção da velocidade.

Aplicar torque restaurador baseado em:

- `fin_symmetry`;
- `fin_alignment`;
- velocidade atual.

### Assimetria e giro

Aplicar torque de viés baseado em:

- baixa simetria;
- `fin_cant`;
- desalinhamento do cone.

A diferença precisa ser visualmente clara, mas não caricata.

### Vento

Aplicar vento lateral estável por sessão, com pequena variação suave. Usar seed reproduzível.

## Fases do voo

Criar estado explícito:

```text
READY
ANTICIPATION
THRUST
COAST
APEX
DESCENT
IMPACT
COMPLETE
```

Registrar transições para telemetria e câmera.

## Perfis de teste obrigatórios

Criar presets para comparação:

### Perfil A — Estável

- aletas simétricas;
- cone alinhado;
- energia média/alta;
- pouco vento.

### Perfil B — Giro

- aletas com inclinação assimétrica;
- energia semelhante ao Perfil A.

### Perfil C — Desvio

- baixa simetria;
- vento moderado;
- cone levemente desalinhado.

### Perfil D — Voo curto

- energia baixa ou relação de água/energia pouco eficiente.

A cena deve permitir alternar presets por teclas `1`, `2`, `3`, `4` e lançar com `Space`.

## Câmera

Implementar câmera de acompanhamento em fases:

- enquadramento baixo antes da partida;
- pequena aproximação na antecipação;
- acompanhamento amortecido durante subida;
- abertura do enquadramento perto do ápice;
- acompanhamento parcial na descida;
- corte ou retorno suave após impacto.

Evitar câmera rigidamente presa ao foguete.

## Feedback visual mínimo

- pequena vibração na antecipação;
- partículas abstratas de água/ar no lançamento;
- rastro temporário;
- indicador de vento no cenário, não como HUD;
- trilha fantasma da trajetória anterior;
- marcador do ápice;
- sombra legível no solo.

## Feedback sonoro mínimo

Usar placeholders organizados para:

- preparação;
- liberação;
- jato;
- vento;
- impacto.

O código deve funcionar mesmo sem os arquivos finais, usando fallback silencioso.

## Debug

Criar painel oculto por padrão, alternado com `F2`, mostrando:

- estado atual;
- velocidade;
- altura abstrata;
- ângulo de ataque;
- torque aplicado;
- vento;
- preset atual.

## Critérios de aceite

1. O foguete não segue uma trajetória animada fixa.
2. A aceleração varia durante o empuxo.
3. O foguete alcança ápice e desce.
4. Os quatro presets produzem resultados claramente diferentes.
5. O jogador consegue olhar o voo e identificar qual montagem parece mais estável.
6. A câmera mantém o foguete legível sem parecer presa a ele.
7. O teste pode ser reiniciado em menos de três segundos.
8. A mesma seed reproduz o mesmo voo dentro de tolerância.
9. O projeto roda sem erros.

Não integrar novamente com a oficina até esta cena isolada ser agradável por si só.
