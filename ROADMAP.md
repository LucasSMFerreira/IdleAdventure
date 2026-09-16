# Próximas etapas do IdleAdventure

1. Experiência e nível de 1 a 100: inimigos dão XP; mini bosses e bosses dão mais. Mostrar o progresso na tela e salvar a evolução. **Feito; ganho de XP reduzido nesta etapa.**
2. Atributos e equilíbrio: HP e ataque crescem um pouco com o nível. Itens melhores são a principal fonte de força. Ajustar a dificuldade dos 10 andares conforme os testes. **Base feita; equilíbrio pendente.**
3. Recompensas e inventário: recolher drops e Gold dos inimigos e mostrar o que o personagem possui. **Baú com SVGs por parte, andar escrito no item, filtros e caixa manual de craft feitos; outras formas de usar Gold pendentes.**
4. Equipamentos: arma, arma secundária, cabeça, peito, pernas, luvas e acessório. Mostrar cada parte equipada e aplicar seus bônus. Cada andar tem seu conjunto de itens, com qualidades diferentes. **Base feita; lendários com porcentagem de qualidade; efeitos especiais pendentes.**
5. Tipos de personagem: o Bárbaro corpo a corpo é o primeiro personagem jogável. Separar alcance e comportamento dos próximos personagens à distância. **Bárbaro base feito; outras classes pendentes.**
6. Identidade das fases: cenários, sprites animados, inimigos e golpes próprios dos bosses. **Primeiros SVGs aplicados ao Bárbaro, slime, goblin, esqueleto, mini boss, boss e cenário; céu, fundo, chão e objetos SVG refeitos, variação por andar e fundo em movimento feitos; HUD compacto, vida dos inimigos simplificada e impacto do machado sincronizado.**

Os spritesheets iniciais ficam em assets/sprites. O Bárbaro usa quadros de andar, parado, ataque, dano e morte. O boss usa seu golpe especial a cada terceiro ataque, com aviso e dano no momento do impacto.

No computador, abrir o baú mostra o jogo acima e o baú embaixo. No telefone, um fundo do baú cobre a partida; ela continua rodando ao fundo. Na aba Craft, o jogador envia itens do baú para uma caixa. Síntese consome seis peças da mesma parte, andar e categoria com Gold; Refino usa seis lendários para elevar sua qualidade percentual; Reciclagem transforma uma peça livre em Gold.

Fases são liberadas ao vencer bosses. XP evolui o personagem aos poucos; drops melhores e equipamentos são essenciais para vencer fases mais difíceis. O jogador pode revisitar fases liberadas; em caso de derrota, mantém a evolução e tenta a fase novamente.

O machado acompanha a mão nos SVGs parado, andando e atacando. O golpe usa uma área de colisão física e só acerta inimigos dentro dela no quadro do impacto.

## Base técnica da fase Wildlands Road

O combate usa CharacterStats (.tres) por entidade, Hurtbox para vida e Hitbox para golpes. Os componentes emitem health_changed, died e attack_landed; o StageManager distribui ondas e avança as fases por sinais. Estados Idle, Walk, PreAttack, Attack, PostAttack, Hit e Death vivem em nós State independentes. A câmera acompanha o Bárbaro e recebe o sinal de impacto do Special do Rei Orc.

A viewport lógica é 640×360, com filtro Nearest. O baú ocupa a parte de baixo no computador e o jogo continua visível acima. Os sprites têm offset definido pela linha dos pés do frame de repouso, medida nos SVGs. Os testes de combate, ciclo de fase e especial do boss ficam em tests/.
