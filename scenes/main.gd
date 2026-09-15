extends Node2D

@export var cena_inimigo: PackedScene

@onready var player: Player = $Player
@onready var background: ColorRect = $Background
@onready var ground: ColorRect = $Ground
@onready var texto_fase: Label = $Interface/Fase
@onready var texto_player: Label = $Interface/VidaPlayer
@onready var reinicio: Timer = $Reinicio

var fase_atual = 0
var ciclo = 1
var trocando_fase = false
var em_derrota = false

const ONDAS = [
	[450, 650, 850],
	[350, 500, 650, 800],
	[300, 425, 550, 675, 800],
]

func _ready():
	_on_player_vida_mudou(player.vida_atual, player.vida_maxima)
	_criar_onda()

func _physics_process(_delta):
	if em_derrota:
		return
	if player.position.x >= 900.0 and get_tree().get_nodes_in_group("enemy").is_empty() and not trocando_fase:
		trocando_fase = true
		_proxima_fase.call_deferred()

func _proxima_fase():
	fase_atual = (fase_atual + 1) % ONDAS.size()
	if fase_atual == 0:
		ciclo += 1
	player.position = Vector2(100, 210)
	player.curar(4)
	_criar_onda()
	trocando_fase = false

func _criar_onda():
	texto_fase.text = "FASE %d  |  CICLO %d" % [fase_atual + 1, ciclo]
	ground.color = [Color(0.3, 0.55, 0.35), Color(0.65, 0.5, 0.3), Color(0.45, 0.35, 0.65)][fase_atual]
	background.color = [Color(0.1, 0.2, 0.15), Color(0.25, 0.18, 0.1), Color(0.15, 0.1, 0.25)][fase_atual]
	for x in ONDAS[fase_atual]:
		var inimigo: Enemy = cena_inimigo.instantiate()
		add_child(inimigo)
		inimigo.position = Vector2(x, 210)
		inimigo.atacou.connect(_on_inimigo_atacou)

func _on_player_atacou(alvo: Enemy):
	if is_instance_valid(alvo):
		alvo.receber_dano(1)

func _on_inimigo_atacou(alvo: Player):
	if alvo == player and not em_derrota:
		player.receber_dano(1)

func _on_player_vida_mudou(atual: int, maxima: int):
	texto_player.text = "PLAYER HP %d/%d" % [atual, maxima]

func _on_player_morreu():
	em_derrota = true
	texto_fase.text = "DERROTA  |  REINICIANDO..."
	reinicio.start()

func _on_reinicio_timeout():
	get_tree().reload_current_scene()
