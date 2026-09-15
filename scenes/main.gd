extends Node2D

@export var cena_inimigo: PackedScene

@onready var player: Player = $Player
@onready var background: ColorRect = $Background
@onready var ground: ColorRect = $Ground
@onready var texto_fase: Label = $Interface/Fase
@onready var texto_player: Label = $Interface/VidaPlayer
@onready var reinicio: Timer = $Reinicio

var andar_atual = 1
var fase_atual = 1
var ciclo_atual = 1
var trocando_ciclo = false
var em_derrota = false
var torre_concluida = false

func _ready():
	_on_player_vida_mudou(player.vida_atual, player.vida_maxima)
	_criar_onda()

func _physics_process(_delta):
	if em_derrota or torre_concluida:
		return
	if player.position.x >= 900.0 and get_tree().get_nodes_in_group("enemy").is_empty() and not trocando_ciclo:
		trocando_ciclo = true
		_avancar.call_deferred()

func _avancar():
	if andar_atual == Progressao.TOTAL_ANDARES and fase_atual == Progressao.FASES_POR_ANDAR and ciclo_atual == Progressao.CICLOS_POR_FASE:
		torre_concluida = true
		player.velocidade = 0.0
		texto_fase.text = "TORRE CONCLUÍDA!  |  %d ANDARES" % Progressao.TOTAL_ANDARES
		return
	if ciclo_atual < Progressao.CICLOS_POR_FASE:
		ciclo_atual += 1
		player.curar(4)
	else:
		ciclo_atual = 1
		if fase_atual < Progressao.FASES_POR_ANDAR:
			fase_atual += 1
		else:
			fase_atual = 1
			andar_atual += 1
		player.curar(player.vida_maxima)
	player.position = Vector2(100, 210)
	_criar_onda()
	trocando_ciclo = false

func _criar_onda():
	texto_fase.text = "ANDAR %d/%d  |  FASE %d/%d  |  CICLO %d/%d" % [andar_atual, Progressao.TOTAL_ANDARES, fase_atual, Progressao.FASES_POR_ANDAR, ciclo_atual, Progressao.CICLOS_POR_FASE]
	var cor = Color.from_hsv(float((andar_atual + 2) % 10) / 10.0, 0.45, 0.18 + fase_atual * 0.005)
	background.color = cor
	ground.color = cor.lightened(0.4)
	var quantidade = Progressao.quantidade_inimigos(andar_atual, fase_atual, ciclo_atual)
	for indice in range(quantidade):
		var inimigo: Enemy = cena_inimigo.instantiate()
		inimigo.configurar(Progressao.vida_inimigo(andar_atual, fase_atual), Progressao.dano_inimigo(andar_atual))
		add_child(inimigo)
		inimigo.position = Vector2(350 + int(500.0 * indice / maxi(quantidade - 1, 1)), 210)
		inimigo.atacou.connect(_on_inimigo_atacou)

func _on_player_atacou(alvo: Enemy):
	if is_instance_valid(alvo):
		alvo.receber_dano(1)

func _on_inimigo_atacou(alvo: Player, dano: int):
	if alvo == player and not em_derrota:
		player.receber_dano(dano)

func _on_player_vida_mudou(atual: int, maxima: int):
	texto_player.text = "PLAYER HP %d/%d" % [atual, maxima]

func _on_player_morreu():
	em_derrota = true
	texto_fase.text = "DERROTA  |  REINICIANDO FASE %d..." % fase_atual
	reinicio.start()

func _on_reinicio_timeout():
	for inimigo in get_tree().get_nodes_in_group("enemy"):
		inimigo.queue_free()
	await get_tree().process_frame
	ciclo_atual = 1
	player.reiniciar()
	player.position = Vector2(100, 210)
	_criar_onda()
	em_derrota = false
