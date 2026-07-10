# Prompt Codex 006 — Simulação Contínua de Lançamento

Evolua a versão 3D atual da Oficina do Foguete em Godot 4.x para substituir o lançamento animado ou baseado em trajetórias pré-definidas por uma simulação contínua simplificada e visualmente convincente.

## Objetivo

O voo deve ser consequência da montagem realizada pelo jogador.

Montagens diferentes precisam produzir diferenças visíveis em:

- altura;
- direção;
- giro;
- oscilação;
- estabilidade;
- duração do voo;
- ponto de queda.

Não mostrar uma porcentagem como resultado principal. O jogador deve compreender o resultado observando o foguete.

## Segurança

Esta é uma simulação digital educativa.

- Não usar ou exibir valores reais de pressão.
- Não incluir medidas operacionais de construção.
- Não reproduzir conexões funcionais de um lançador real.
- Trabalhar com parâmetros internos normalizados entre `0.0` e `1.0`.

## Decisão técnica

Criar um sistema reutilizável de voo, preferencialmente com `RigidBody3D` ou integração de movimento própria em passo de física.

Não usar apenas `Tween` ou `AnimationPlayer` para desenhar uma trajetória fixa.

A animação e os efeitos podem complementar o movimento, mas a posição e rotação principais devem resultar do modelo de forças.

## Arquitetura sugerida

```text
scripts/flight/
  bottle_rocket_body.gd
  flight_model.gd
  flight_parameters.gd
  assembly_to_flight_mapper.gd
  wind_model.gd
  flight_recorder.gd

resources/flight/
  default_flight_parameters.tres
  thrust_curve.tres
```

## Dados de entrada da montagem

Criar uma classe `FlightParameters` ou recurso equivalente com valores normalizados:

```text
energy                 0..1
fin_symmetry           0..1
fin_alignment          0..1
nose_alignment         0..1
attachment_quality     0..1
mass_balance           0..1
body_drag_factor       0..1
wind_strength          0..1
```

Esses valores devem ser produzidos pela montagem física da bancada, não por sliders visíveis.

## Mapeamento da montagem

Criar `AssemblyToFlightMapper` para converter:

- posições das aletas;
- rotações das aletas;
- distância angular entre as aletas;
- alinhamento do cone;
- peças ausentes;
- qualidade dos encaixes;
- nível virtual de energia;

em parâmetros de voo.

O sistema deve ser determinístico quando a montagem e a semente de vento forem iguais.

## Fases do voo

Implementar uma máquina de estados:

```text
ON_STAND
PREPARING
THRUST
COAST
APOGEE
DESCENT
IMPACTED
RESETTING
```

### ON_STAND

- foguete preso à base;
- corpo sem física livre;
- câmera na bancada.

### PREPARING

- pequena vibração;
- feedback visual e sonoro curto;
- duração breve e configurável.

### THRUST

- aplicar impulso ao longo do eixo local do foguete;
- intensidade controlada por uma `Curve` normalizada;
- reduzir gradualmente a massa virtual durante o impulso, sem usar valores físicos reais;
- aplicar pequeno ruído controlado para evitar movimento artificialmente perfeito.

### COAST

- encerrar impulso;
- manter gravidade, arrasto, vento e torques aerodinâmicos simplificados.

### APOGEE

- detectar mudança do componente vertical da velocidade;
- registrar altura máxima;
- permitir pequena pausa visual/câmera lenta opcional, sem interromper a física.

### DESCENT

- continuar gravidade e arrasto;
- permitir rotação e oscilação coerentes;
- não exigir sistema de paraquedas nesta build.

### IMPACTED

- detectar colisão com solo;
- tocar efeito de impacto leve;
- registrar ponto de queda;
- oferecer retorno à bancada.

## Modelo simplificado de forças

Usar coeficientes normalizados e ajustáveis no inspetor.

### Gravidade

Usar a gravidade do projeto Godot.

### Impulso

Aplicar força no eixo longitudinal local do foguete durante a fase `THRUST`.

A força deve vir de:

```text
thrust = base_thrust * energy * thrust_curve.sample(normalized_time)
```

Sem expor unidades reais ao jogador.

### Arrasto

Aplicar força oposta à velocidade, crescendo de forma não linear com a velocidade.

Pode usar uma aproximação do tipo:

```text
drag_force = -velocity.normalized() * drag_coefficient * velocity.length_squared()
```

Limitar valores para estabilidade numérica.

### Estabilidade aerodinâmica simplificada

Criar torque que tende a alinhar o eixo longitudinal do foguete com a direção da velocidade.

A força desse alinhamento deve depender de:

- `fin_symmetry`;
- `fin_alignment`;
- velocidade atual.

### Torque de erro

Desalinhamento de cone, aletas assimétricas e equilíbrio ruim devem gerar torque adicional contínuo.

Evitar simplesmente escolher uma animação de giro. O giro deve surgir do torque calculado.

### Vento

Criar um vetor de vento suave, com ruído de baixa frequência.

- configurável por semente;
- fraco por padrão;
- visível opcionalmente no painel de desenvolvedor;
- sem alterar violentamente o voo.

## Sensação visual

Adicionar:

- partículas estilizadas na liberação;
- trilha curta de partículas durante o impulso;
- sombra do foguete no solo;
- câmera de acompanhamento com suavização;
- leve *screen shake* na saída, configurável e discreto;
- som de tensão, liberação, impulso, vento e impacto;
- rotação visual coerente com a rotação física.

Não usar efeitos exagerados de foguete químico. A aparência deve lembrar um experimento artesanal virtual.

## Câmera

Criar `LaunchCameraRig` com três modos:

1. bancada;
2. acompanhamento do lançamento;
3. visão do resultado/queda.

A câmera deve:

- acompanhar o foguete suavemente;
- manter horizonte legível;
- ampliar o enquadramento conforme a altura;
- evitar perder o foguete;
- retornar à bancada sem corte brusco.

## Resultado sem nota explícita

Na tela do jogador, comunicar apenas por:

- trajetória;
- giro;
- altura percebida;
- distância lateral;
- estado final do foguete;
- breve frase observacional opcional.

Exemplos de frases curtas:

- `As aletas não estabilizaram o giro.`
- `O conjunto subiu alinhado por mais tempo.`
- `Um pequeno desalinhamento desviou a trajetória.`

Não mostrar `95%`, estrelas ou nota geral na interface principal.

## Telemetria de voo

Registrar em `FlightRecorder`:

```text
launch_id
session_id
flight_seed
parameters_snapshot
launch_time
flight_duration
max_height
horizontal_displacement
max_angular_velocity
mean_angular_velocity
rotation_count
impact_position
state_timestamps
```

Adicionar ao painel `F2`:

- gráfico simples de altura por tempo;
- gráfico de velocidade por tempo;
- parâmetros derivados da montagem;
- comparação entre os últimos lançamentos.

## Integração com assets

O sistema de voo deve funcionar com meshes provisórias e com `.glb` finais.

Separar o corpo físico do modelo visual:

```text
BottleRocketBody (RigidBody3D)
  CollisionShape3D
  VisualRoot
    ImportedBottleModel
    ConeVisual
    FinVisuals
  ParticleEffects
  Audio
```

Não acoplar a física a nomes específicos de mesh importada.

## Testes automatizados e de desenvolvimento

Criar pelo menos:

1. teste de voo estável com parâmetros altos;
2. teste com uma aleta desalinhada;
3. teste com baixa energia;
4. teste com cone desalinhado;
5. teste determinístico com mesma semente.

Adicionar modo de desenvolvimento para lançar configurações prontas sem passar pela bancada.

## Critérios de aceite

A build será aceita quando:

1. o foguete usar movimento contínuo, não trajetória fixa;
2. alterar a montagem mudar o voo de forma perceptível;
3. aletas assimétricas produzirem giro ou desvio;
4. baixa energia produzir voo mais curto;
5. o foguete atingir ápice e cair naturalmente;
6. a câmera acompanhar sem perder o objeto;
7. o painel `F2` registrar métricas completas;
8. o ciclo lançar → observar → ajustar funcionar sem erros;
9. nenhuma informação operacional de foguete real for exibida.

Priorize causalidade visível, estabilidade numérica e facilidade de calibração no inspetor.
