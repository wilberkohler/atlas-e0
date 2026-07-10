# Direção Visual — Oficina do Foguete v2

## Conceito

A nova Oficina do Foguete deve parecer uma pequena bancada real de invenção, não um dashboard.

A referência emocional é uma criança explorando materiais simples e descobrindo relações de causa e efeito com as próprias mãos.

## Formato visual recomendado

### Diorama 3D com câmera ortográfica

- Visão superior inclinada, semelhante a uma maquete.
- Bancada ocupando quase toda a tela.
- Objetos com escala consistente e sombras suaves.
- Pouca interface sobreposta.
- Materiais estilizados, mas reconhecíveis.

Esse formato permite sensação física sem exigir um mundo 3D amplo ou controles complexos de primeira pessoa.

## Composição da bancada

### Centro

- Garrafa PET transparente deitada ou apoiada em um suporte de montagem.
- Espaço livre ao redor para arrastar e girar peças.

### Lado esquerdo

- Cone de papel.
- Três aletas de papelão.
- Rolo de fita.
- Elásticos.

### Lado direito

- Base de lançamento.
- Ferramenta simples de ajuste.
- Alavanca ou acionador virtual.

### Fundo

- Pequeno quadro com desenhos e pistas visuais, sem instrução textual longa.
- Prateleira com protótipos anteriores ou peças descartadas.

## Materiais

- PET: transparente, levemente amassado, com reflexos suaves.
- Papelão: bordas visíveis e textura fibrosa.
- Elástico: material fosco e deformável.
- Fita: semitransparente com brilho discreto.
- Madeira: bancada com marcas de uso.
- Metal/plástico da base: simples, robusto e reconhecível.

## Vocabulário de interação

### Selecionar

O objeto recebe contorno luminoso sutil e levanta alguns milímetros.

### Arrastar

O objeto acompanha o cursor sobre um plano de trabalho.

### Girar

- Roda do mouse, teclas Q/E ou manipulador circular curto.
- No toque, gesto de rotação com dois dedos em versão futura.

### Encaixar

- Zona válida aparece discretamente quando a peça se aproxima.
- Um som curto e uma pequena animação confirmam o encaixe.

### Encaixe ruim

- A peça não é bloqueada arbitrariamente.
- Ela pode ser colocada, mas fica torta, frouxa ou com feedback visual de instabilidade.

### Remover

O jogador pode puxar a peça de volta e tentar outra posição.

### Testar

O lançamento é consequência da montagem visível, não de sliders abstratos.

## Causalidade visível

- Aletas assimétricas fazem o foguete girar.
- Cone torto altera a trajetória.
- Energia insuficiente produz voo curto.
- Energia excessiva na simulação gera instabilidade, sem usar valores reais.
- Montagem equilibrada produz voo estável.

## Interface

### Visível ao jogador

- Botão discreto de teste apenas quando a montagem mínima estiver pronta.
- Botão de desfazer/reiniciar.
- Uma frase curta de contexto.

### Oculta por padrão

- Linha do tempo de eventos.
- Métricas.
- Score técnico.
- Dados de sessão.

O painel de desenvolvimento deve abrir apenas por atalho, por exemplo `F2`.

## Objetivo da próxima build

O jogador deve compreender, em poucos segundos, que pode pegar as peças e montar algo.

A experiência deve produzir este ciclo:

> tocar → arrastar → encaixar → testar → observar → ajustar → melhorar
