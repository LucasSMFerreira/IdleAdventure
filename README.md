# IdleAdventure

Jogo 2D em Godot 4.7.2. Escolha uma fase liberada no menu, avance por três ciclos de ondas e derrote o mini boss. A fase 10 de cada andar termina com o Rei Orc.

## Estrutura

- scripts/resources/character_stats.gd e os .tres definem os atributos base de Bárbaro, Slime, Goblin, Esqueleto, Orc Guerreiro e Rei Orc.
- scripts/combat/ contém Hurtbox e Hitbox. Layer 2 é a Hurtbox do Bárbaro, Layer 3 é a Hurtbox dos inimigos e Layer 4 contém as Hitboxes.
- scripts/states/ contém StateMachine e estados configurados nas cenas. O golpe tem aviso, quadro ativo e recuperação.
- scripts/world/stage_manager.gd cria ondas e sinaliza avanço, recompensa e impacto do boss. scenes/world/wildlands_road.tscn é a cena jogável.
- scripts/estado_jogo.gd mantém evolução, baú, equipamentos e Gold. O save existente continua no formato anterior.

O baú e o craft não pausam o jogo. No computador, o painel fica abaixo da partida. No telefone, o fundo do painel cobre a partida enquanto o mundo continua rodando.

## Verificação

Com o executável de console do Godot e a pasta do projeto como diretório atual:

godot --headless --editor --path . --quit
godot --headless --path . --script tests/combat_components_test.gd
godot --headless --path . --script tests/stage_loop_test.gd
godot --headless --path . --script tests/boss_special_test.gd
godot --headless --path . --script tests/sprite_alignment_test.gd

Os testes usam arquivos de save temporários separados do progresso do jogador.
