# Plano de teste — Vertical Slice da Oficina do Foguete PET v1

## Objetivo

Validar integridade dos assets, manipulação direta, causalidade do voo, retry, comparação, telemetria invisível e preservação da build anterior.

## Pré-requisitos

- Godot `4.7.stable`.
- Projeto: `app/godot/rocket_workshop/project.godot`.
- Cena sob teste: `res://scenes/vertical_slice_v1/vertical_slice_main.tscn`.
- Renderer configurado: `gl_compatibility`.

## Suite automatizada

Executar na raiz do repositório:

```powershell
$project = "C:\Users\NTB-ENG\Documents\Atlas E0\app\godot\rocket_workshop"
godot_console --headless --path $project --script res://scripts/dev/vertical_slice_v1_asset_import_test.gd
godot_console --headless --path $project --script res://scripts/dev/vertical_slice_v1_validation.gd
godot_console --headless --path $project --script res://scripts/dev/vertical_slice_v1_scene_smoke_test.gd
godot_console --headless --path $project --quit-after 120 res://scenes/vertical_slice_v1/vertical_slice_main.tscn
```

Regressão:

```powershell
godot_console --headless --path $project --script res://scripts/dev/asset_import_smoke_test.gd
godot_console --headless --path $project --script res://scripts/dev/flight_smoke_tests.gd
godot_console --headless --path $project --script res://scripts/dev/launch_scene_smoke_test.gd
godot_console --headless --path $project --quit-after 120 res://scenes/main_3d.tscn
```

Resultados esperados:

- seis mensagens `ASSET_OK`;
- `Vertical slice v1 causality and telemetry validation passed.`;
- `Vertical slice v1 integrated scene smoke test passed.`;
- zero `ERROR`, `Parse Error`, NaN ou timeout;
- build anterior continua passando.

## Casos causais

| Caso | Variação | Resultado esperado |
| --- | --- | --- |
| Stable | três aletas simétricas e fixadas | menor giro e caminho limpo |
| Spin | uma aleta inclinada | torque e rotação maiores |
| Lateral | aletas/alturas assimétricas | desvio lateral maior |
| Short | energia abstrata menor | ápice mais baixo e voo mais curto |
| Determinístico | mesma configuração e seed | mesma altura e deslocamento |
| Colisão inesperada | impacto externo durante voo | transição segura para impacto/revisão |

## Teste manual da oficina

1. Abra a cena e confirme que o mundo 3D ocupa a tela, sem painel lateral.
2. Aguarde a frase inicial desaparecer.
3. Passe o cursor sobre uma aleta; verifique hover e cursor.
4. Pegue a aleta; observe lift, sombra e movimento amortecido.
5. Gire com roda e `Q`/`E`; incline com mouse direito.
6. Solte perto da garrafa; confirme snap suave e pequeno erro preservado.
7. Remova e reposicione a mesma aleta.
8. Repita com uma segunda aleta, deixando uma delas visivelmente inclinada.
9. Pegue a fita e faça um arco ao redor de cada junção; confirme faixa progressiva.
10. Pegue a jarra, aproxime o bico da abertura e incline; confirme nível de água visível.
11. Confirme que a base responde por luz/som, sem texto de checklist.
12. Leve o foguete montado até a base.

Falhas:

- objeto teleporta ou vibra;
- peça atravessa a bancada;
- snap corrige toda imperfeição;
- fita funciona como simples botão;
- água aparece como número;
- helpers técnicos ficam visíveis.

## Teste manual do campo

1. Confirme transição curta e preservação visual da montagem.
2. Arraste a alavanca abstrata algumas vezes.
3. Confirme vibração/luz/som crescentes sem pressão ou unidade real.
4. Clique o botão integrado à base.
5. Verifique a pausa de antecipação antes da saída.
6. Durante `THRUST`, verifique gotas e volume do jato.
7. Observe subida, desaceleração, ápice, descida e impacto.
8. Verifique que a câmera mantém horizonte e permite perceber giro.
9. Confirme trajetória, ápice e impacto na revisão.
10. Cronometre o retorno; deve ser solicitado em menos de três segundos após a revisão.

## Retry e comparação

1. Após o primeiro voo, ajuste apenas uma aleta.
2. Confirme que cone, água, demais aletas e fita permanecem.
3. Faça o segundo lançamento sob a mesma seed padrão.
4. Confirme duas linhas de trajetória com cores discretas.
5. Pergunte ao participante o que mudou e o que tentaria em seguida, sem explicar a causa.

## Painel F2

1. Confirme que está oculto ao iniciar.
2. Pressione `F2` e verifique configuração, métricas, forças, torque, estado, seed e histórico.
3. Execute Stable, Spin, Lateral e Short.
4. Confirme que os presets não aparecem fora do painel.
5. Desative/ative seed fixa e confirme o estado interno.

## Telemetria

1. Complete duas tentativas.
2. Verifique `user://atlas_e0/vertical_slice_pet_v1/attempt_history.json`.
3. Confirme JSON válido e valores físicos normalizados/fictícios.
4. Verifique primeira peça, ordem, geometria das aletas, fixação, água, energia, fases, trajetória, ápice, impacto e retry.
5. Corrompa uma cópia isolada do arquivo, nunca o dado original; confirme recuperação por `.bak`.
6. Confirme que nenhuma telemetria aparece na interface normal ou nas screenshots.

## Capturas visuais

Regenerar somente quando necessário:

```powershell
godot_console --path $project --script res://scripts/dev/vertical_slice_v1_capture.gd
```

Esperado: cinco PNGs reais em `docs/builds/screenshots/`.

## Playtest humano

Sessão recomendada: 5–8 minutos, sem instrução detalhada.

Perguntas após duas tentativas:

- “O que você acha que mudou o voo?”
- “O que você mudaria agora?”
- “Você gostaria de tentar mais uma vez?”

A experiência só é aprovada se a pessoa identificar uma hipótese plausível e demonstrar vontade espontânea de ajustar e relançar.
