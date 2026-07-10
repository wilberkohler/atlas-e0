# Brief para Freelancer — Artista 3D da Oficina do Foguete

## Projeto

Oficina do Foguete — protótipo interativo em Godot 4.x.

## Objetivo do trabalho

Criar um pacote pequeno de assets 3D semirrealistas e otimizados para jogo, substituindo placeholders por objetos cotidianos reconhecíveis e manipuláveis.

O foco é qualidade de leitura, materialidade e integração técnica, não quantidade de objetos.

## Entregáveis obrigatórios

1. garrafa PET transparente;
2. cone artesanal de papel/plástico fino;
3. aleta modular de papelão, com versão reta e empenada;
4. conjunto de fita adesiva;
5. elástico relaxado e tensionado;
6. base de teste estilizada e não operacional;
7. bancada de madeira;
8. pequeno conjunto de props de oficina.

## Estilo

- semirrealista estilizado;
- aparência de experimento escolar/oficina infantil inteligente;
- materiais reconhecíveis;
- pequenas imperfeições;
- formas amigáveis;
- sem marcas comerciais;
- sem aparência industrial ou militar.

## Requisitos de integração

- Blender como arquivo-fonte;
- exportação `.glb` individual;
- materiais compatíveis com glTF/Godot;
- pivôs adequados para arraste, giro e encaixe;
- escala consistente;
- transforms aplicados;
- UVs e texturas organizadas;
- colisões simples ou indicação clara para criação no Godot;
- nomes conforme especificação do projeto;
- malhas otimizadas para desktop/mobile intermediário.

## Critério principal de qualidade

Ao abrir a cena sem texto, uma pessoa precisa reconhecer imediatamente que está diante de uma garrafa PET, aletas artesanais, cone de papel, fita, elástico e uma bancada de teste.

## Processo recomendado

### Marco 1 — Blockout

- silhuetas;
- escala;
- pivôs;
- teste de importação no Godot.

### Marco 2 — Materiais

- PET;
- papelão;
- papel;
- borracha;
- madeira;
- metal/plástico.

### Marco 3 — Acabamento

- pequenas imperfeições;
- otimização;
- exportações finais;
- organização de arquivos.

Não iniciar acabamento antes da aprovação do blockout e do teste de pivôs no Godot.

## Arquivos finais

```text
oficina_foguete_v3.blend
exports/*.glb
textures/*
README_assets.md
```

O `README_assets.md` deve documentar:

- versões do Blender;
- materiais;
- escalas;
- nomes de objetos;
- pivôs;
- instruções de reexportação;
- licenças de qualquer recurso externo utilizado.

## Propriedade intelectual e licenças

- trabalho original ou uso de recursos devidamente licenciados;
- informar por escrito todos os recursos de terceiros;
- entregar arquivos-fonte;
- cessão dos direitos patrimoniais conforme contrato do projeto;
- não reutilizar elementos exclusivos sem autorização.

## Segurança

O pacote é destinado a uma simulação digital. A base e os mecanismos não devem reproduzir detalhes funcionais, medidas, conexões ou componentes que sirvam como instruções práticas para construir um lançador pressurizado real.
