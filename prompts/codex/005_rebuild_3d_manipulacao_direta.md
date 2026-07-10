# Prompt Codex 005 — Reconstrução 3D com Manipulação Direta

Reconstrua a Oficina do Foguete como uma experiência 3D de manipulação direta em Godot 4.x.

## Decisão de produto

A build atual funciona tecnicamente, mas ainda é um dashboard: botões e sliders no painel esquerdo controlam uma animação passiva no centro.

A nova build deve inverter essa lógica:

> o foguete e os objetos da bancada são a interface.

Não faça apenas um redesign dos painéis. Crie uma nova cena principal 3D, preservando apenas os serviços úteis de telemetria e histórico.

## Objetivo

Criar um diorama 3D de bancada, visto por câmera ortográfica, no qual o jogador possa:

- selecionar objetos reais ou estilizados;
- arrastar objetos sobre a bancada;
- girar peças;
- encaixar e remover peças;
- montar um foguete virtual inspirado em uma garrafa PET;
- testar o lançamento;
- observar o resultado;
- voltar à bancada, ajustar e testar novamente.

## Escopo da build

Criar apenas:

- 1 bancada;
- 1 corpo de garrafa PET;
- 1 cone;
- 3 aletas independentes;
- 1 conjunto de elásticos ou mecanismo visual de energia;
- 1 base de lançamento;
- 1 botão/alavanca de teste;
- 1 animação simples de voo;
- telemetria oculta por padrão.

Não criar mundo amplo, personagens, loja, login, progressão, física avançada ou arte final.

## Segurança

Esta é uma simulação digital educativa.

Não incluir valores reais de pressão, instruções operacionais, medidas de construção ou procedimentos para lançamento físico.

## Estrutura da cena

Sugestão:

```text
Main.tscn
  Node3D
    WorldEnvironment
    DirectionalLight3D
    Workbench
    AssemblyArea
    LooseParts
    LaunchStand
    CameraRig
      Camera3D (orthographic)
    InteractionController
    LaunchController
    CanvasLayer
      MinimalHUD
      DebugOverlay (hidden)
```

## Câmera

- Camera3D ortográfica.
- Ângulo superior inclinado, estilo diorama.
- Bancada visível quase inteira.
- Permitir zoom limitado com roda do mouse.
- Não exigir movimentação livre de câmera na primeira build.

## Sistema reutilizável de peças

Criar uma classe base, por exemplo `DraggablePart3D`, com:

- id;
- tipo da peça;
- estado atual;
- referência de mesh;
- área de clique;
- posição inicial;
- possibilidade de arrastar;
- possibilidade de girar;
- possibilidade de encaixar;
- evento de interação para telemetria.

Estados sugeridos:

- idle;
- hovered;
- selected;
- dragging;
- near_snap_zone;
- snapped;
- revisited;

## Interação por mouse

### Seleção

- Raycast a partir da câmera.
- Ao passar o mouse, aplicar contorno ou emissão suave.
- Ao clicar, selecionar a peça e elevá-la levemente.

### Arrastar

- Projetar o mouse sobre um plano horizontal da bancada.
- A peça acompanha o cursor de forma suave.
- Não usar RigidBody durante o arraste; priorizar controle e previsibilidade.

### Girar

- Roda do mouse ou teclas `Q` e `E` giram a peça selecionada.
- Passos pequenos e suaves.

### Soltar

- Se estiver próxima a uma `SnapZone3D` compatível, encaixar.
- Caso contrário, deixar sobre a bancada.

### Remover

- Uma peça encaixada pode ser selecionada e puxada novamente.

## Sistema de encaixes

Criar `SnapZone3D` reutilizável, com:

- tipo de peça aceito;
- transform de encaixe;
- tolerância de distância;
- tolerância angular;
- sinal visual quando uma peça compatível se aproxima;
- callback de encaixe e remoção.

### Aletas

- Três zonas ao redor da parte inferior da garrafa.
- Permitir encaixe com alinhamento imperfeito dentro de limites.
- Registrar posição e rotação final de cada aleta.

### Cone

- Zona no topo da garrafa.
- Registrar desalinhamento angular.

### Mecanismo de energia

- Usar representação visual abstrata e segura.
- O jogador deve puxar/ajustar um elástico virtual ou acionar uma pequena alavanca.
- Não usar valores reais de força ou pressão.

## Ausência de sliders

Remover da experiência principal:

- sliders de combustível;
- sliders de aletas;
- sliders de bocal;
- botões que apenas representam peças.

Os parâmetros devem surgir da posição, rotação e montagem dos próprios objetos.

## Avaliação simples do voo

Calcular três variáveis internas:

- `symmetry_score`: baseado no espaçamento e alinhamento das aletas;
- `nose_alignment_score`: baseado no alinhamento do cone;
- `energy_score`: baseado no ajuste virtual do mecanismo de energia.

Usar esses valores apenas para escolher uma de três trajetórias:

1. voo curto/instável;
2. voo razoável com giro;
3. voo estável.

Não mostrar porcentagem numérica ao jogador na experiência principal.

## Lançamento

- Quando corpo, cone, ao menos duas aletas e mecanismo de energia estiverem presentes, liberar visualmente o teste.
- A liberação deve ser comunicada pelo mundo: luz na base, alavanca ativa ou som curto.
- Ao lançar, animar o foguete com `AnimationPlayer` ou Tween.
- A câmera pode acompanhar parcialmente.
- Depois, oferecer retorno à bancada com a montagem preservada.

## Interface mínima

Mostrar apenas:

- uma frase curta no início: `Monte, teste e descubra.`
- botão discreto de reiniciar;
- indicação visual de que a base está pronta;
- instrução contextual de uma linha apenas quando o jogador não interagir por alguns segundos.

Não mostrar painel lateral permanente.

## Telemetria

Preservar e ampliar os serviços existentes.

Registrar:

- primeira peça tocada;
- ordem das peças exploradas;
- tempo até a primeira ação;
- duração de cada arraste;
- quantidade de reposicionamentos;
- rotações feitas;
- tentativas de encaixe;
- encaixes corretos e imperfeitos;
- tempo até o primeiro lançamento;
- número de testes;
- mudanças entre testes;
- melhor trajetória alcançada.

## Painel do desenvolvedor

- Oculto por padrão.
- Abrir/fechar com `F2`.
- Pode reutilizar a tela de métricas atual.
- Não ocupar espaço da experiência principal.

## Assets

Preparar o projeto para importar arquivos `.glb` de Blender.

Usar placeholders 3D simples enquanto os modelos finais não existirem, mas manter cada peça como cena separada:

```text
scenes/parts/pet_bottle.tscn
scenes/parts/nose_cone.tscn
scenes/parts/fin.tscn
scenes/parts/elastic_unit.tscn
scenes/props/launch_stand.tscn
scenes/environment/workbench.tscn
```

## Estrutura de código sugerida

```text
scripts/interaction/
  interaction_controller.gd
  draggable_part_3d.gd
  snap_zone_3d.gd

scripts/assembly/
  rocket_assembly.gd
  assembly_evaluator.gd

scripts/launch/
  launch_controller.gd
  trajectory_profile.gd

scripts/telemetry/
  telemetry_service.gd
  session_recorder.gd

scripts/ui/
  debug_overlay.gd
```

## Critérios de aceite

A build será aceita quando:

1. não houver painel lateral como interação principal;
2. o jogador puder pegar uma peça na bancada;
3. puder arrastar e girar a peça;
4. puder encaixar cone e aletas no corpo;
5. os encaixes alterarem visualmente o foguete;
6. a base comunicar quando o teste estiver disponível;
7. o lançamento responder à montagem;
8. o jogador puder retornar, ajustar e testar novamente;
9. a telemetria continuar funcionando em painel oculto;
10. o projeto rodar sem erros no Godot.

Priorize sensação tátil, clareza e causalidade visível. Não priorize quantidade de recursos.
