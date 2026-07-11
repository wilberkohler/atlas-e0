# Problemas conhecidos — Vertical Slice da Oficina do Foguete PET v1

## Bloqueadores

Nenhum bloqueador técnico foi encontrado nos testes automatizados e nas capturas finais.

## Pendências de aprovação

1. **Playtest humano não executado.** A implementação não pode ser declarada aprovada como experiência até uma pessoa completar duas tentativas e responder à pergunta central.
2. **Reconhecimento sem legenda precisa de confirmação humana.** Os assets e capturas são reconhecíveis tecnicamente, mas a leitura imediata deve ser observada com usuários.

## Polimento visual e sensorial

1. Os materiais v2 no renderer `gl_compatibility` ficam mais planos e claros que nos renders Cycles/AgX do Blender.
2. O campo é propositalmente pequeno e usa terreno simples; não há vegetação autoral ou props de escala adicionais.
3. As linhas de trajetória são finas no Compatibility renderer; em alguns ângulos, diferenças laterais pequenas podem ficar sutis.
4. O replay é uma revisão automática curta com trajetória, ápice e impacto; não existe reprodução temporal completa do voo.
5. A superfície de água é controlada e legível, mas não permanece perfeitamente nivelada em rotações extremas da garrafa.
6. O jato possui gotas, partículas e volume; não há reação de spray no terreno além do efeito junto à base.

## Áudio

1. Não há arquivos de áudio licenciados no repositório.
2. Eventos de plástico, papelão, fita, snap, prontidão, antecipação, lançamento e impacto usam síntese temporária original em runtime.
3. Esses sons devem ser substituídos ou refinados por áudio final licenciado antes de uma release pública.

## Interação

1. Tolerâncias de snap, peso amortecido e arco mínimo da fita passaram testes técnicos, mas ainda precisam de ajuste após playtest com mouse/trackpad reais.
2. A preparação abstrata usa alavanca por arraste; acessibilidade por teclado além de rotação `Q`/`E` ainda é limitada.
3. Não foram implementados controles touch específicos.

## Infraestrutura preexistente

1. `scenes/main.tscn` e `scenes/reference/dashboard_main.tscn` compartilham um UID anterior. O Godot emite aviso, mas as cenas testadas executam.
2. O working tree já estava sujo antes da tarefa. Os oito arquivos rastreados preexistentes foram preservados e não pertencem ao vertical slice.
3. `project.godot` continua apontando para a build anterior por decisão de preservação; o slice deve ser aberto explicitamente.
4. Não existe preset de export (`export_presets.cfg`); a validação foi feita no editor/runtime local.

## Segurança

- Não há valores reais de pressão, dimensões operacionais, válvulas, componentes funcionais ou instruções físicas reproduzíveis.
- Coeficientes e dados persistidos são fictícios, normalizados e destinados somente à simulação digital.
