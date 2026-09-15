extends Node2D

@export var cena_inimigo: PackedScene

@onready var player: CharacterBody2D = $Player
@onready var ground: ColorRect = $Ground
@onready var texto_fase: Label = $Interface/Fase

var fase_atual = 0
var ciclo = 1
var trocando_fase = false

const ONDAS = [
	[450, 650, 850],
	[350, 500, 650, 800],
	[300, 425, 550, 675, 800],
]

func _ready():
	_criar_onda()

func _physics_process(_delta):
	if player.position.x >= 900.0 and get_tree().get_nodes_in_group("enemy").is_empty() and not trocando_fase:
		trocando_fase = true
		_proxima_fase.call_deferred()

func _proxima_fase():
	fase_atual = (fase_atual + 1) % ONDAS.size()
	if fase_atual == 0:
		ciclo += 1
	player.position = Vector2(100, 210)
	_criar_onda()
	trocando_fase = false

func _criar_onda():
	texto_fase.text = "FASE %d  |  CICLO %d" % [fase_atual + 1, ciclo]
	ground.color = [Color(0.3, 0.55, 0.35), Color(0.65, 0.5, 0.3), Color(0.45, 0.35, 0.65)][fase_atual]
	for x in ONDAS[fase_atual]:
		var inimigo = cena_inimigo.instantiate()
		add_child(inimigo)
		inimigo.position = Vector2(x, 210)

func _on_player_atacou(alvo: Node):
	if is_instance_valid(alvo) and alvo.has_method("receber_dano"):
		alvo.call("receber_dano", 1)
