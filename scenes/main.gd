extends Node2D

@export var cena_inimigo: PackedScene

@onready var player: Player = $Player
@onready var background: ColorRect = $Background
@onready var ground: ColorRect = $Ground
@onready var texto_fase: Label = $Interface/Fase
@onready var texto_player: Label = $Interface/VidaPlayer
@onready var objetivo: Label = $Interface/Objetivo
@onready var reinicio: Timer = $Reinicio

var andar_atual = 1
var fase_atual = 1
var ciclo_atual = 1
var trocando_ciclo = false
var em_derrota = false
var torre_concluida = false

func _ready():
	andar_atual = EstadoJogo.andar_escolhido
	fase_atual = EstadoJogo.fase_escolhida
	player.configurar_melhorias(EstadoJogo.maior_fase_liberada)
	_on_player_vida_mudou(player.vida_atual, player.vida_maxima)
	_criar_onda()

func _physics_process(_delta):
	if em_derrota or torre_concluida:
		return
	if player.position.x >= 900.0 and get_tree().get_nodes_in_group("enemy").is_empty() and not trocando_ciclo:
		trocando_ciclo = true
		_avancar.call_deferred()

func _avancar():
	if ciclo_atual < Progressao.CICLOS_POR_FASE:
		ciclo_atual += 1
		player.curar(4)
	else:
		EstadoJogo.liberar_proxima(andar_atual, fase_atual)
		if andar_atual == Progressao.TOTAL_ANDARES and fase_atual == Progressao.FASES_POR_ANDAR:
			torre_concluida = true
			player.velocidade = 0.0
			texto_fase.text = "TORRE CONCLUÍDA!  |  %d ANDARES" % Progressao.TOTAL_ANDARES
			objetivo.text = "Você venceu o último boss."
			return
		ciclo_atual = 1
		if fase_atual < Progressao.FASES_POR_ANDAR:
			fase_atual += 1
		else:
			fase_atual = 1
			andar_atual += 1
		player.configurar_melhorias(EstadoJogo.maior_fase_liberada)
	player.position = Vector2(100, 210)
	_criar_onda()
	trocando_ciclo = false

func _criar_onda():
	texto_fase.text = "ANDAR %d/%d  |  FASE %d/%d  |  CICLO %d/%d" % [andar_atual, Progressao.TOTAL_ANDARES, fase_atual, Progressao.FASES_POR_ANDAR, ciclo_atual, Progressao.CICLOS_POR_FASE]
	var cor = Color.from_hsv(float((andar_atual + 2) % 10) / 10.0, 0.45, 0.18 + fase_atual * 0.005)
	background.color = cor
	ground.color = cor.lightened(0.4)
	if ciclo_atual == Progressao.CICLOS_POR_FASE:
		var guardas = Progressao.guardas_de_chefe(andar_atual, fase_atual)
		for indice in range(guardas):
			var x = 450 if guardas == 1 else 350 + int(350.0 * indice / (guardas - 1))
			_criar_inimigo(x, Progressao.vida_inimigo(andar_atual, fase_atual), Progressao.dano_inimigo(andar_atual), "normal")
		var tipo = "boss" if fase_atual == Progressao.FASES_POR_ANDAR else "mini"
		_criar_inimigo(850, Progressao.vida_chefe(andar_atual, fase_atual), Progressao.dano_chefe(andar_atual, fase_atual), tipo)
		objetivo.text = "Boss do andar" if tipo == "boss" else "Mini boss da fase"
	else:
		var quantidade = Progressao.quantidade_inimigos(andar_atual, fase_atual, ciclo_atual)
		for indice in range(quantidade):
			var x = 350 + int(500.0 * indice / maxi(quantidade - 1, 1))
			_criar_inimigo(x, Progressao.vida_inimigo(andar_atual, fase_atual), Progressao.dano_inimigo(andar_atual), "normal")
		objetivo.text = "Elimine os inimigos para avançar."

func _criar_inimigo(x: int, vida: int, dano: int, tipo: String):
	var inimigo: Enemy = cena_inimigo.instantiate()
	inimigo.configurar(vida, dano, tipo)
	add_child(inimigo)
	inimigo.position = Vector2(x, 210)
	inimigo.atacou.connect(_on_inimigo_atacou)

func _on_player_atacou(alvo: Enemy):
	if is_instance_valid(alvo):
		alvo.receber_dano(player.dano)

func _on_inimigo_atacou(alvo: Player, dano: int):
	if alvo == player and not em_derrota:
		player.receber_dano(dano)

func _on_player_vida_mudou(atual: int, maxima: int):
	texto_player.text = "PLAYER HP %d/%d  |  ATAQUE %d" % [atual, maxima, player.dano]

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

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
