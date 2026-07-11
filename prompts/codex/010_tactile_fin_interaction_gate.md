# Prompt Codex 010 — Porta de Qualidade da Interação Tátil

Crie uma cena isolada chamada `FinInteractionLab.tscn`.

## Objetivo

Aprimorar apenas uma ação: pegar uma aleta de papelão e fixá-la em uma garrafa PET.

Não adicionar lançamento, múltiplas peças, pontuação, painel lateral ou novas funcionalidades.

## Cena

- pequena bancada;
- uma garrafa PET apoiada horizontalmente em um suporte;
- uma única aleta de papelão;
- uma área de encaixe na garrafa;
- câmera próxima em três quartos;
- iluminação suficiente para ler materiais e contato.

## Interação

### Hover

- contorno discreto ou realce por stencil;
- elevação visual mínima;
- cursor contextual;
- nenhuma caixa de texto permanente.

### Seleção

- a peça sobe alguns milímetros;
- som curto de papelão;
- movimento com easing rápido e controlado;
- preservar sensação de peso leve.

### Arraste

- movimento amortecido, sem atraso excessivo;
- manter a aleta em plano coerente com a bancada;
- permitir pequena rotação por mouse ou teclas `Q` e `E`;
- sombra acompanha corretamente;
- evitar teletransporte e jitter.

### Aproximação do encaixe

- atração magnética progressiva;
- indicação física discreta na área de contato;
- pequena pré-visualização de orientação;
- resistência visual quando a orientação está muito errada.

### Encaixe

- microanimação de assentamento;
- som de papelão/fita;
- pequena compressão visual ou vibração;
- peça permanece removível;
- garrafa reage sutilmente ao contato.

### Remoção

- selecionar e puxar novamente;
- som curto de desprendimento;
- manter posição e rotação para reposicionamento.

## Assistência invisível

A interação deve ser tolerante:

- zonas de encaixe maiores que a geometria exata;
- correção angular gradual;
- snap apenas quando a intenção estiver clara;
- nunca encaixar instantaneamente a longa distância.

## Telemetria

Registrar:

- tempo até tocar a aleta;
- duração do arraste;
- número de rotações;
- tentativas de encaixe;
- encaixes rejeitados;
- tempo até o primeiro encaixe;
- remoções e reposicionamentos.

## Critérios de aceite

1. Uma pessoa entende sem instrução longa que a aleta pode ser pega.
2. A aleta não parece um botão 3D.
3. O arraste não apresenta jitter perceptível.
4. O encaixe parece consequência do movimento, não de um clique de UI.
5. É agradável remover e encaixar novamente.
6. A ação inteira pode ser concluída em menos de 15 segundos na primeira tentativa.
7. O jogador demonstra vontade de repetir a ação pelo menos uma vez.

Não integrar esta cena com o restante do jogo enquanto os critérios não forem atendidos.
