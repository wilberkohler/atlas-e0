# Prompt Codex 004 — Oficina do Foguete em Godot

Crie um novo protótipo Godot dentro deste repositório em:

```text
app/godot/rocket_workshop/
```

Use Godot 4.x com GDScript, sem C#/.NET.

## Objetivo

Construir uma experiência interativa curta chamada provisoriamente **Oficina do Foguete**.

O jogador deve montar virtualmente um foguete simples inspirado em uma garrafa PET, manipulando objetos em uma bancada. A experiência deve priorizar arrastar, encaixar, girar, inspecionar, testar e observar consequências.

Este protótipo é uma **simulação digital educativa**. Não deve fornecer instruções operacionais para construir ou lançar um foguete real, nem valores reais de pressão, segurança ou montagem física.

## Hipótese de experiência

> O jogador aprende melhor quando manipula objetos, testa hipóteses e observa o mundo responder, em vez de ler instruções ou selecionar respostas.

## Escopo da Build 001

Criar duas cenas principais:

1. `WorkshopScene` — bancada de montagem.
2. `LaunchTestScene` — teste visual simplificado do foguete.

## Elementos da bancada

Criar representações visuais simples, usando formas vetoriais, ícones provisórios ou sprites placeholder:

- corpo do foguete, inspirado em uma garrafa;
- cone frontal;
- três aletas;
- base de lançamento;
- conector de propulsão virtual;
- mangueira ou módulo de energia virtual;
- painel de teste;
- botão/alavanca de lançamento.

Não depender de assets externos para a primeira versão.

## Interações mínimas

### Arrastar e soltar

- Cada peça pode ser arrastada pela bancada.
- Peças compatíveis devem encaixar em zonas de montagem.
- Ao se aproximar de uma zona válida, destacar suavemente o encaixe.
- Ao soltar em zona inválida, a peça retorna à posição anterior com animação curta.

### Rotação

- As aletas devem poder ser rotacionadas em incrementos simples.
- Permitir rotação por botão contextual, roda do mouse ou gesto equivalente.

### Inspeção

- Clique/toque simples seleciona o objeto.
- Duplo clique/toque ou botão de inspeção amplia temporariamente o objeto.
- Exibir apenas informações curtas e visuais, sem textos longos.

### Estados visuais

Cada objeto deve possuir estados claros:

- disponível;
- selecionado;
- sendo arrastado;
- encaixe válido;
- encaixe inválido;
- montado;
- revisitado.

## Lógica de montagem

A montagem mínima válida deve exigir:

- corpo principal;
- cone frontal;
- três aletas;
- conexão com a base de lançamento.

O botão de teste deve ficar desabilitado até a montagem mínima estar completa.

A lógica não pode ser invisível. Exibir progresso visual na própria bancada:

- contornos vazios das partes faltantes;
- pequenos indicadores luminosos;
- mudança visual da base;
- feedback sonoro simples opcional.

Não usar checklist textual longo.

## Qualidade da montagem

Calcular uma qualidade simplificada de 0 a 100 baseada em:

- quantidade correta de peças;
- simetria aproximada das aletas;
- orientação das aletas;
- encaixe correto do cone;
- conexão completa com a base.

Não mostrar necessariamente o número ao jogador durante a montagem.

## Teste de lançamento virtual

Ao acionar o teste:

- transicionar para `LaunchTestScene`;
- exibir animação simples do foguete;
- usar uma trajetória visual baseada na qualidade da montagem;
- criar três resultados iniciais:
  - montagem incompleta ou instável: não decola ou tomba;
  - montagem intermediária: decola baixo ou desvia;
  - montagem boa: voo mais alto e estável.

A física pode ser estilizada e determinística. Não precisa simular aerodinâmica real nesta build.

## Aprendizado por consequência

Evitar mensagens como `certo` ou `errado`.

Preferir:

- animação do foguete reagindo;
- trajetória desenhada;
- comparação visual entre tentativa atual e anterior;
- destaque de uma ou duas partes que mais influenciaram o resultado.

Exemplos de devolutiva curta:

- `As aletas ficaram assimétricas.`
- `A base estava estável.`
- `O cone ficou desalinhado.`

## Repetição

Após o teste, oferecer:

- `Ajustar montagem`;
- `Testar novamente`;
- `Reiniciar bancada`.

Preservar a montagem ao voltar para ajustes.

## Telemetria local

Registrar em memória e salvar localmente em JSON:

- session_id;
- horário de início e fim;
- primeira peça tocada;
- ordem das peças manipuladas;
- quantidade de tentativas de encaixe;
- encaixes inválidos;
- peças removidas após montagem;
- número de testes;
- qualidade de cada tentativa;
- duração até o primeiro lançamento;
- duração total da sessão.

Criar estrutura reutilizável para que esses dados possam futuramente alimentar o painel do desenvolvedor já existente no Atlas.

## Estrutura sugerida

```text
app/godot/rocket_workshop/
  project.godot
  scenes/
    main.tscn
    workshop_scene.tscn
    launch_test_scene.tscn
    components/
      draggable_part.tscn
      snap_zone.tscn
      rocket_assembly.tscn
  scripts/
    main.gd
    workshop_controller.gd
    draggable_part.gd
    snap_zone.gd
    rocket_assembly.gd
    assembly_quality.gd
    launch_simulator.gd
    telemetry_service.gd
  data/
    session_schema.json
  assets/
    placeholders/
  docs/
    README.md
```

## Arquitetura

- Usar composição de cenas.
- Evitar scripts gigantes.
- Separar interação, montagem, qualidade, lançamento e telemetria.
- Usar sinais para comunicar eventos entre componentes.
- Manter os placeholders substituíveis por sprites 2D ou modelos 3D futuros.

## Testes mínimos

Criar testes ou verificações simples para:

- impedir lançamento antes da montagem mínima;
- validar encaixes corretos;
- rejeitar encaixes inválidos;
- calcular qualidade de montagem;
- salvar uma sessão em JSON;
- retornar da cena de lançamento preservando a montagem.

## Critério de aceite

O protótipo deve permitir:

1. abrir a bancada;
2. arrastar e encaixar peças;
3. girar aletas;
4. perceber visualmente o que ainda falta;
5. liberar o teste apenas após montagem mínima;
6. assistir ao lançamento virtual;
7. receber feedback visual curto;
8. voltar, ajustar e testar novamente;
9. registrar a sessão localmente.

Priorize uma experiência fluida e interativa. Não criar menus complexos, login, loja, pontuação, ranking ou arte final nesta etapa.
