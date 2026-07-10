# Diagnóstico da Build — Oficina do Foguete

## O que a build comprovou

- O projeto Godot abre e executa corretamente.
- O pipeline GitHub → prompt → Codex → Godot está funcionando.
- Já existe telemetria, histórico de eventos e um lançamento animado.
- A lógica de avaliação básica consegue produzir um resultado numérico.

## Por que a experiência ainda é frustrante

A build atual é essencialmente um painel de controle com uma animação no centro.

### 1. A ação acontece fora do mundo

As decisões reais são tomadas por botões e sliders no painel esquerdo. O foguete no centro é apenas o resultado visual dessas escolhas.

Precisamos inverter essa relação:

> o foguete deve ser o lugar onde a decisão acontece.

### 2. Os objetos ainda são nomes

`Bico`, `Tanque`, `Motor`, `Aletas` e `Sensor` aparecem como botões. O jogador não segura, posiciona, gira, combina ou transforma objetos.

### 3. A cena central é passiva

O centro da tela não funciona como bancada. Não há uma garrafa PET, peças espalhadas, encaixes, materiais, estados visuais ou causalidade física perceptível.

### 4. A telemetria está ocupando o espaço do jogador

O painel de observação é útil para o desenvolvedor, mas quebra a imersão. Ele deve virar uma camada de depuração, acessível por atalho, e não fazer parte da experiência principal.

### 5. Sliders substituem fenômenos físicos

Combustível, aletas e bocal são ajustados por controles abstratos. O objetivo é substituir sliders por manipulação direta:

- mover aletas;
- girar peças;
- esticar um elástico virtual;
- encaixar o corpo na base;
- bombear ou carregar energia em uma simulação segura;
- observar mudanças no próprio objeto.

## Decisão

A próxima build não será um refinamento visual do painel atual. Será uma reconstrução do núcleo da experiência.

## Nova direção

Criar um diorama 3D de bancada, visto por câmera ortográfica, em que o jogador manipula objetos concretos:

- garrafa PET transparente;
- cone de papel ou plástico;
- aletas de papelão;
- elásticos;
- fita adesiva;
- base de lançamento;
- mecanismo de propulsão virtual.

## Regra principal

> Mundo primeiro. Interface depois.

O jogador deve passar a maior parte do tempo tocando o mundo, não operando painéis.

## Escopo da próxima build

- Uma bancada.
- Uma garrafa PET.
- Três aletas.
- Um cone.
- Um elástico ou mecanismo virtual de energia.
- Uma base de lançamento.
- Um teste de voo.
- Painel do desenvolvedor oculto por padrão.

## Segurança

A experiência deve permanecer como simulação digital. Não incluir valores reais de pressão nem instruções operacionais para construir ou lançar foguetes físicos.
