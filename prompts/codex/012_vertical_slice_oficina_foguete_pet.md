Você está trabalhando no repositório:

wilberkohler/atlas-e0

REFERÊNCIA DE EXPERIÊNCIA

Considere este vídeo como referência visual e comportamental:

https://www.youtube.com/watch?v=8bQJ1cFgyUk

O vídeo deve ser usado como inspiração para:

- aparência de materiais cotidianos;
- sensação de atividade prática;
- manipulação de uma garrafa PET;
- montagem artesanal;
- transição entre preparação e lançamento;
- expectativa antes do teste;
- movimento perceptivamente convincente;
- vontade de corrigir a montagem e tentar novamente.

Não copie literalmente o tutorial.

Não transforme a aplicação em instrução operacional de construção de um foguete físico.

Caso o ambiente do Codex não consiga acessar o vídeo, use integralmente a especificação abaixo como fonte de verdade.

TÍTULO DA TAREFA

Vertical Slice — Oficina Interativa e Teste de Foguete PET

OBJETIVO PRINCIPAL

Transformar o protótipo atual da Oficina do Foguete em uma experiência interativa curta, visual e sensorial, na qual o jogador:

1. manipula objetos reconhecíveis;
2. monta um foguete virtual inspirado em uma garrafa PET;
3. prepara o teste sem sliders ou formulários;
4. lança o foguete em uma área externa;
5. observa uma trajetória perceptivamente coerente;
6. identifica uma possível causa do resultado;
7. volta à montagem;
8. modifica alguma coisa;
9. lança novamente;
10. compara visualmente as duas tentativas.

A experiência deve provocar espontaneamente a sensação:

“Quero mudar alguma coisa e tentar novamente.”

DECISÃO DE PRODUTO

O produto não deve parecer:

- dashboard;
- software técnico;
- formulário;
- quiz;
- editor CAD;
- tutorial textual;
- animação pré-programada sem causalidade;
- gráfico de resultados;
- demonstração abstrata de física.

O produto deve parecer:

- uma pequena atividade prática;
- um brinquedo digital inteligente;
- uma oficina científica interativa;
- uma experiência de experimentar, observar e ajustar;
- uma simulação visual em que o mundo responde às ações do jogador.

DIREÇÃO VISUAL

A direção visual oficial é:

“realismo lúdico de oficina científica”

Características:

- objetos reconhecíveis;
- materiais cotidianos;
- formas levemente simplificadas;
- boa iluminação;
- ambiente acolhedor;
- pequenas imperfeições;
- cores claras e convidativas;
- PET transparente;
- aletas leves;
- papel e papelão visíveis;
- fita adesiva reconhecível;
- água visível dentro da garrafa;
- ambiente externo para o lançamento;
- ausência de painéis permanentes.

SEGURANÇA

Esta é uma simulação digital educativa.

Não incluir:

- valores reais de pressão;
- unidades reais de pressão;
- dimensões operacionais;
- componentes funcionais de pressurização;
- diagramas técnicos de base de lançamento;
- instruções de fabricação;
- etapas reproduzíveis de lançamento físico;
- especificações de válvulas;
- limites reais de materiais;
- procedimentos de segurança usados como substituto de supervisão profissional.

Todos os parâmetros físicos devem ser:

- normalizados;
- fictícios;
- internos;
- não exibidos como instruções operacionais.

PRESERVAÇÃO

Antes de modificar qualquer arquivo:

1. inspecione o repositório;
2. encontre o projeto Godot atual;
3. identifique todas as cenas e scripts existentes;
4. identifique os assets Blender v1 e v2;
5. execute `git status --short`;
6. registre a branch atual;
7. preserve a build anterior;
8. não sobrescreva cenas anteriores;
9. não remova telemetria existente;
10. não altere ou apague renders e arquivos Blender anteriores.

Se existirem assets em:

assets_3d/export/v2/

use-os.

Verifique especialmente:

- pet_bottle.glb
- paper_nose_cone.glb
- cardboard_fin.glb
- launch_stand.glb
- workbench.glb
- tape_roll.glb

PORTA DE QUALIDADE DE ASSETS

Não prossiga usando cubos, cilindros, cápsulas ou cones genéricos como objetos principais.

Se os assets v2 não existirem ou não puderem ser importados:

1. pare a implementação visual;
2. crie um relatório de pré-verificação;
3. informe exatamente quais assets estão ausentes;
4. não substitua silenciosamente os objetos por primitivas genéricas;
5. não declare a tarefa concluída.

Primitivas podem ser usadas somente para:

- colisões;
- helpers invisíveis;
- áreas de snap;
- protótipos técnicos que não aparecem ao jogador.

ARQUITETURA GERAL

Criar uma nova versão do vertical slice, sem destruir a anterior.

Estrutura sugerida:

app/godot/rocket_workshop/
  scenes/
    vertical_slice_v1/
      vertical_slice_main.tscn
      workshop_scene.tscn
      field_test_scene.tscn
      transition_scene.tscn
      result_comparison_scene.tscn

    objects/
      pet_bottle_interactive.tscn
      fin_interactive.tscn
      nose_cone_interactive.tscn
      tape_roll_interactive.tscn
      water_container_interactive.tscn
      launch_stand_interactive.tscn

  scripts/
    vertical_slice/
      vertical_slice_controller.gd
      experience_state.gd

    interaction/
      object_grabber_3d.gd
      tactile_drag_controller.gd
      rotation_controller.gd
      snap_zone_3d.gd
      tape_gesture_controller.gd
      water_fill_controller.gd

    assembly/
      rocket_configuration.gd
      rocket_assembly_controller.gd
      assembly_metrics.gd

    launch/
      bottle_rocket_body.gd
      bottle_rocket_simulator.gd
      launch_sequence_controller.gd
      launch_camera_controller.gd
      trajectory_recorder.gd
      trajectory_renderer.gd

    telemetry/
      attempt_record.gd
      attempt_history.gd
      experience_telemetry.gd

    ui/
      contextual_hint_controller.gd
      developer_overlay.gd

  resources/
    flight/
      stable_profile.tres
      spin_profile.tres
      lateral_profile.tres
      short_profile.tres

  data/
    sample_attempts/

Salvar também este prompt em:

prompts/codex/012_vertical_slice_oficina_foguete_pet.md

CENA 1 — OFICINA

Criar uma pequena bancada ou mesa de preparação.

A câmera deve usar perspectiva 3/4 próxima dos objetos.

Não usar câmera excessivamente distante.

A cena deve conter:

- garrafa PET;
- três aletas;
- cone;
- fita adesiva;
- recipiente de água;
- base de teste visível ao fundo;
- poucos objetos secundários;
- iluminação clara;
- sombras de contato;
- fundo de oficina simples.

O ambiente deve parecer preparado para uma atividade prática.

A maior parte da tela deve ser ocupada pelo mundo 3D.

Não criar painel lateral.

A única mensagem inicial permitida é:

“Monte. Teste. Observe.”

Essa frase deve desaparecer após poucos segundos ou depois da primeira interação.

INTERAÇÃO CENTRAL

O foguete e os objetos devem ser a interface.

Não criar botões com nomes de peças.

Não usar lista de objetos.

Não usar sliders.

Não usar dropdowns.

Não usar formulário.

O jogador deve manipular diretamente os objetos.

SISTEMA DE SELEÇÃO

Implementar:

- raycast da câmera;
- hover discreto;
- contorno ou emissão suave;
- mudança de cursor;
- pequena elevação visual ao pegar;
- sombra acompanhando o objeto;
- movimento amortecido;
- feedback sonoro quando disponível;
- ausência de teleportes bruscos.

Ao passar o cursor:

- o objeto deve responder visualmente;
- não exibir caixa retangular de botão;
- não exibir texto permanente.

Ao clicar e segurar:

- o objeto deve ser levantado alguns centímetros virtuais;
- deve acompanhar o cursor com suavização;
- deve manter sensação de peso;
- não deve atravessar a bancada;
- não deve vibrar ou oscilar de forma errática.

ROTAÇÃO

Permitir:

- roda do mouse;
- teclas Q e E;
- ou gesto de arraste secundário.

A rotação deve:

- ser suave;
- permitir alinhamento fino;
- ter passos pequenos;
- preservar controle;
- registrar o ângulo final.

ENCAIXE DE ALETAS

Criar três áreas de encaixe ao redor da parte inferior da garrafa.

Cada aleta deve poder:

- ser pega;
- ser girada;
- ser aproximada;
- receber atração magnética suave;
- encaixar corretamente;
- encaixar com pequeno desalinhamento;
- ser removida;
- ser reposicionada.

Não corrigir automaticamente toda imperfeição.

O jogador deve conseguir produzir:

- configuração simétrica;
- configuração assimétrica;
- uma aleta inclinada;
- aletas em alturas ligeiramente diferentes;
- montagem imperfeita, mas testável.

Registrar para cada aleta:

- posição angular ao redor da garrafa;
- inclinação;
- altura;
- orientação;
- número de reposicionamentos;
- qualidade do encaixe;
- presença ou ausência de fixação.

INTERAÇÃO COM FITA

A fita não deve ser apenas um botão “fixar”.

Criar uma interação gestual simplificada.

Fluxo desejado:

1. jogador pega o rolo de fita;
2. aproxima de uma junção entre garrafa e aleta;
3. começa um gesto de aplicação;
4. move o cursor ao redor da região;
5. uma faixa visual aparece progressivamente;
6. ao completar um gesto mínimo, a peça é marcada como fixada.

Não implementar física de fita completa.

A fita pode ser representada por:

- mesh em arco;
- faixa progressiva;
- decal;
- banda ao redor da junção.

O importante é comunicar:

“eu prendi esta peça”.

A qualidade da fixação pode ser interna e normalizada:

- ausente;
- parcial;
- adequada.

Não mostrar percentuais.

CONE

O cone deve:

- ser manipulado diretamente;
- encaixar no topo;
- permitir pequeno desalinhamento;
- poder ser removido;
- alterar visualmente o conjunto.

Registrar:

- desvio angular;
- centralização;
- qualidade da fixação.

ÁGUA

Criar uma interação visual simplificada.

O jogador deve:

1. pegar um recipiente;
2. aproximá-lo da garrafa;
3. inclinar ou manter sobre a abertura;
4. observar o nível de líquido subir.

Não exibir:

- litros;
- mililitros;
- medidas;
- porcentagens operacionais;
- valores reais.

Internamente, usar valor normalizado entre 0 e 1.

Visualmente, o jogador deve perceber apenas:

- pouco;
- intermediário;
- muito.

O líquido deve ser uma malha separada da garrafa.

A superfície deve permanecer visualmente legível.

Não exigir simulação real de fluido.

Usar uma solução controlada:

- mesh interno;
- nível vertical;
- shader simples;
- pequena movimentação visual.

PREPARAÇÃO DO TESTE

Quando a configuração mínima estiver pronta:

- corpo;
- ao menos duas aletas;
- cone opcional;
- alguma água;
- fixação mínima;

o ambiente deve comunicar que o teste está disponível.

Não mostrar mensagem “pronto” em painel.

Usar:

- luz discreta na base;
- pequeno som;
- alteração de postura visual;
- destaque no local de teste.

O jogador deve pegar o foguete montado e colocá-lo na base.

A base deve possuir:

- ponto de encaixe visual;
- indicador fictício;
- pequeno mecanismo abstrato;
- nenhuma representação operacional real.

TRANSIÇÃO PARA O CAMPO

Depois de colocar o foguete na base:

- fazer uma transição curta;
- preservar a configuração;
- trocar para um campo externo;
- manter o foguete montado;
- evitar tela longa de carregamento;
- não mostrar formulário.

O campo deve conter:

- gramado ou terreno;
- céu;
- iluminação natural;
- horizonte;
- poucos elementos de referência;
- base de lançamento;
- espaço livre para acompanhar o voo.

Não construir mundo amplo.

A cena externa deve ser pequena, mas convincente.

PREPARAÇÃO DE ENERGIA

Criar uma interação abstrata de preparação.

Pode ser:

- pequena alavanca;
- manopla;
- mecanismo fictício;
- gesto repetido curto.

Não reproduzir bomba, válvula ou conexão operacional real.

Não exibir pressão.

Internamente, gerar `energy_level` normalizado entre 0 e 1.

Visualmente, comunicar energia por:

- vibração leve;
- som crescente;
- movimento do líquido;
- indicador luminoso abstrato;
- pequena tensão da base.

MOMENTO DE ANTECIPAÇÃO

Antes do lançamento, criar entre 0,4 e 1 segundo de antecipação:

- redução momentânea do som ambiente;
- pequena vibração;
- líquido se movendo;
- base reagindo;
- câmera ajustando o enquadramento;
- indicador mudando.

Não lançar imediatamente no mesmo frame do comando.

LANÇAMENTO

Não usar Tween como sistema principal de trajetória.

O foguete deve usar uma simulação física híbrida.

Usar:

- RigidBody3D;
- gravidade;
- impulso contínuo durante uma fase curta;
- arrasto;
- vento;
- torque;
- inércia;
- estabilização derivada das aletas;
- assimetria derivada da montagem;
- mudança de massa abstrata durante o impulso;
- colisão com o solo.

Todos os coeficientes devem ser fictícios e normalizados.

Não usar valores reais de pressão.

Não documentar equações como instrução de construção.

FASES DO VOO

Implementar estados claros:

1. PREPARED
2. ANTICIPATION
3. THRUST
4. COAST
5. APEX
6. DESCENT
7. IMPACT
8. REVIEW

Cada estado deve emitir sinais e registrar telemetria.

EMPURRO E MASSA

Durante `THRUST`:

- aplicar força na direção longitudinal do foguete;
- reduzir a força por uma curva suave;
- reduzir massa de forma abstrata e controlada;
- produzir jato visual de água;
- gerar partículas e gotas;
- produzir som;
- adicionar pequena vibração de câmera.

A curva não deve representar dados reais.

Usar parâmetros de gameplay normalizados.

ARRASTO

Aplicar arrasto dependente da velocidade.

Limitar valores para preservar estabilidade numérica.

A sensação deve ser:

- aceleração forte no início;
- desaceleração progressiva;
- subida livre;
- ápice legível;
- queda natural.

ESTABILIZAÇÃO

Calcular `stability_score` a partir de:

- simetria das aletas;
- orientação das aletas;
- altura relativa;
- qualidade dos encaixes;
- presença das aletas;
- alinhamento do cone.

Usar esse valor para criar torque estabilizador que tende a alinhar o eixo do foguete com sua velocidade.

Configuração melhor:

- menos oscilação;
- menos giro;
- direção mais limpa.

Configuração pior:

- giro;
- precessão;
- oscilação;
- desvio;
- perda de altura.

ASSIMETRIA

Calcular `asymmetry_vector` a partir da montagem.

Uma aleta inclinada deve produzir:

- torque visível;
- rotação progressiva;
- alteração de trajetória.

A consequência deve ser clara o suficiente para o jogador formular uma hipótese.

VENTO

Criar vento leve com:

- direção constante por tentativa;
- pequena variação temporal;
- semente registrada;
- intensidade limitada.

O vento deve influenciar o voo, mas não pode esconder o efeito da montagem.

Para comparação entre tentativas, permitir:

- manter a mesma semente de vento;
- ou indicar discretamente mudança ambiental.

Por padrão, manter condições semelhantes entre duas tentativas consecutivas para que a comparação seja justa.

JATO DE ÁGUA

Criar efeito visual com:

- partículas;
- gotas;
- spray;
- rastro curto;
- redução progressiva;
- reação no chão ou na base, se simples de implementar.

Não usar apenas uma linha azul.

O jato deve ter:

- volume;
- dispersão;
- duração curta;
- mudança durante o impulso.

CÂMERA

Criar sistema de câmera em fases.

### Preparação

- câmera próxima;
- composição do foguete na base;
- leve movimento de antecipação.

### Lançamento

- afastamento rápido controlado;
- pequena vibração;
- acompanhamento vertical.

### Voo

- câmera segue com atraso suave;
- mantém referência do horizonte;
- não cola excessivamente no foguete;
- permite perceber giro e trajetória.

### Ápice

- reduzir ligeiramente a velocidade da câmera;
- não usar câmera lenta exagerada;
- tornar a mudança de direção legível.

### Queda

- acompanhar parcialmente;
- manter noção de escala;
- mostrar impacto.

### Revisão

- mostrar a trajetória completa;
- marcar ápice e local de impacto;
- retornar à bancada rapidamente.

TRAJETÓRIA VISUAL

Registrar posições durante o voo.

Após o voo:

- desenhar uma linha translúcida;
- marcar ápice;
- marcar impacto;
- manter no máximo as duas últimas trajetórias;
- usar cores diferentes, mas discretas;
- não exibir porcentagens;
- não exibir nota;
- não criar gráfico lateral.

Na segunda tentativa, mostrar:

- trajetória anterior;
- trajetória atual;
- diferença visível.

REPLAY CURTO

Criar replay opcional ou revisão automática muito curta.

Pode mostrar:

- início do giro;
- desvio;
- momento da perda de estabilidade;
- ápice;
- impacto.

Não explicar imediatamente a causa por texto.

O replay deve ajudar o jogador a observar.

RETORNO À OFICINA

Depois do lançamento:

- retornar em no máximo três segundos após a revisão;
- preservar a montagem;
- preservar posições e ângulos;
- permitir remover e alterar peças;
- não exigir remontagem completa;
- manter a tentativa anterior registrada;
- permitir novo lançamento rapidamente.

O ciclo entre impacto e possibilidade de alteração deve ser curto.

GAME FEEL

Adicionar microfeedbacks:

- hover;
- elevação ao pegar;
- sombra;
- movimento amortecido;
- som de plástico;
- som de papelão;
- som de fita;
- pequeno estalo ao encaixar;
- reação visual da garrafa;
- vibração da base;
- som de vento;
- som de impacto;
- partículas;
- camera shake controlado;
- luz natural.

Caso não existam arquivos de áudio licenciados:

- criar arquitetura de eventos de áudio;
- usar sons temporários claramente identificados;
- não baixar arquivos sem licença;
- documentar quais sons precisam ser substituídos.

INTERFACE

A interface principal deve ser quase invisível.

Permitido:

- frase inicial;
- botão discreto para reiniciar;
- botão discreto para retornar;
- dica contextual de uma linha após inatividade;
- indicador visual dentro do mundo.

Não permitido:

- painel lateral;
- sliders;
- números de estabilidade;
- números de energia;
- nota;
- ranking;
- checklist textual permanente;
- lista de peças;
- botões “adicionar aleta”;
- botão “configurar pressão”.

DICAS CONTEXTUAIS

Somente após alguns segundos sem ação.

Exemplos:

- “Experimente pegar uma peça.”
- “Você pode girar o objeto.”
- “Aproxime a peça da garrafa.”
- “Observe o que mudou.”

As dicas devem desaparecer após interação.

Não explicar a solução completa.

TELEMETRIA

Manter invisível para o jogador.

Registrar por tentativa:

- session_id;
- attempt_id;
- data/hora;
- tempo de montagem;
- primeira peça tocada;
- ordem de interação;
- posições das aletas;
- ângulos das aletas;
- altura das aletas;
- qualidade de fixação;
- alinhamento do cone;
- nível abstrato de água;
- energia abstrata;
- tempo até lançar;
- trajetória;
- altura máxima;
- tempo até ápice;
- deslocamento lateral;
- rotação total;
- posição de impacto;
- número de alterações após o voo;
- tempo até a próxima tentativa;
- se o jogador lançou novamente.

Salvar em JSON local.

PAINEL DO DESENVOLVEDOR

Oculto por padrão.

Abrir com F2.

Mostrar:

- configuração atual;
- métricas internas;
- forças;
- torque;
- estado do voo;
- trajetória;
- semente de vento;
- histórico de tentativas.

O painel não deve aparecer em screenshots normais nem ocupar a experiência.

PRESETS DE TESTE

Criar presets apenas para desenvolvimento, acessíveis pelo painel F2:

- Stable
- Spin
- Lateral drift
- Short flight

Eles servem para validar a física sem remontar manualmente.

Não mostrar ao jogador.

MODO DETERMINÍSTICO

Criar opção de semente fixa para:

- vento;
- pequenas variações;
- comparação entre builds;
- testes reproduzíveis.

TESTES AUTOMATIZADOS OU DE VALIDAÇÃO

Criar testes ou scripts de validação para garantir:

1. configuração estável produz menos rotação;
2. aleta inclinada produz mais torque;
3. assimetria produz maior desvio lateral;
4. menor energia produz voo mais curto;
5. foguete alcança ápice e entra em descida;
6. trajetória é registrada;
7. histórico preserva duas tentativas;
8. retorno à oficina mantém configuração;
9. nenhuma força gera NaN ou velocidade infinita;
10. a simulação termina mesmo após colisão inesperada.

Se não houver framework de teste instalado, criar uma cena de teste automatizada ou script headless.

FASES DE IMPLEMENTAÇÃO

Executar na seguinte ordem:

FASE 0 — Auditoria

- localizar projeto;
- localizar assets v2;
- verificar importação;
- registrar estado atual;
- criar relatório de pré-verificação.

FASE 1 — Assets no Godot

- importar assets v2;
- configurar materiais;
- verificar escala;
- verificar pivôs;
- verificar colisões;
- montar oficina sem gameplay novo;
- gerar screenshot técnico.

FASE 2 — Uma interação tátil

- garrafa;
- uma aleta;
- pegar;
- girar;
- encaixar;
- remover.

Não avançar até funcionar com suavidade.

FASE 3 — Montagem mínima

- três aletas;
- cone;
- fita simplificada;
- água visual.

FASE 4 — Campo de teste

- transição;
- base;
- preparação abstrata;
- antecipação.

FASE 5 — Física de voo

- impulso;
- arrasto;
- estabilidade;
- assimetria;
- vento;
- ápice;
- queda;
- impacto.

FASE 6 — Comparação

- trajetória;
- replay;
- retorno;
- nova tentativa;
- comparação visual.

FASE 7 — Telemetria e validação

- JSON;
- painel F2;
- presets;
- testes;
- relatório.

Não pular diretamente para a integração completa.

COMMITS

Se o ambiente permitir commits, criar commits separados por fase:

1. `feat: import hero assets into rocket workshop`
2. `feat: add tactile direct manipulation`
3. `feat: add physical rocket assembly`
4. `feat: add outdoor launch scene`
5. `feat: add hybrid bottle rocket flight`
6. `feat: add retry and trajectory comparison`
7. `test: validate launch causality and telemetry`

Não fazer push forçado.

Não reescrever histórico.

ENTREGÁVEIS

Criar:

docs/builds/vertical_slice_pet_rocket_v1_preflight.md

docs/builds/vertical_slice_pet_rocket_v1_report.md

docs/builds/vertical_slice_pet_rocket_v1_test_plan.md

docs/builds/vertical_slice_pet_rocket_v1_known_issues.md

data/sample_attempts/pet_rocket_attempts_v1.json

Se possível, gerar screenshots:

docs/builds/screenshots/
  workshop_v1.png
  fin_attachment_v1.png
  launch_preparation_v1.png
  launch_v1.png
  trajectory_comparison_v1.png

Não inventar screenshots caso o ambiente não consiga executar o Godot.

CRITÉRIOS DE ACEITE

A tarefa só pode ser considerada concluída quando:

1. os objetos principais são reconhecíveis sem legenda;
2. não há painel lateral;
3. o jogador pega diretamente uma aleta;
4. a aleta pode ser girada;
5. a aleta pode ficar ligeiramente desalinhada;
6. a fita gera uma fixação visual;
7. a água aparece dentro da garrafa;
8. o foguete é colocado fisicamente na base;
9. há antecipação antes do lançamento;
10. há jato visual de água;
11. o voo não é um Tween vertical;
12. há ápice;
13. há descida;
14. há impacto;
15. uma aleta torta produz giro perceptível;
16. montagem assimétrica produz desvio perceptível;
17. o jogador volta à oficina mantendo a montagem;
18. pode corrigir uma peça;
19. pode lançar novamente;
20. duas trajetórias podem ser comparadas;
21. não há números operacionais reais;
22. a telemetria permanece oculta;
23. o projeto roda sem erros críticos;
24. nenhuma versão anterior foi apagada.

CRITÉRIO HUMANO PRINCIPAL

O vertical slice deverá ser avaliado por uma pessoa.

Não declarar sucesso apenas porque o código compilou.

A pergunta central é:

“Depois de um voo imperfeito, a pessoa consegue imaginar o que alterar e sente vontade de testar essa alteração?”

Se a resposta ainda for “não”, registrar a tarefa como tecnicamente concluída, mas não aprovada como experiência.

LIMITES

Não criar:

- loja;
- login;
- multiplayer;
- progressão;
- personagem completo;
- mãos animadas complexas;
- mundo aberto;
- fases adicionais;
- sistema de missões;
- tutorial longo;
- IA generativa;
- placar;
- ranking;
- conquista;
- publicidade;
- física de fluido completa.

RESPOSTA FINAL DO CODEX

Ao terminar, apresentar:

1. resumo do que foi implementado;
2. auditoria inicial;
3. assets encontrados e utilizados;
4. arquivos criados;
5. arquivos modificados;
6. cenas criadas;
7. scripts criados;
8. comandos executados;
9. testes executados;
10. screenshots realmente geradas;
11. limitações;
12. problemas conhecidos;
13. checklist dos critérios de aceite;
14. confirmação de que versões anteriores foram preservadas;
15. instruções exatas para abrir e testar a experiência;
16. controles;
17. caminho dos logs e JSON;
18. avaliação honesta do critério humano principal.

Não iniciar automaticamente uma etapa seguinte.
Pare após entregar o vertical slice e o relatório.
