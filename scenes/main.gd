extends Node2D

@export var cena_inimigo: PackedScene

@onready var player: CharacterBody2D = $Player

var reiniciando = false

func _physics_process(_delta):
	if player.position.x >= 900.0 and get_tree().get_nodes_in_group("enemy").is_empty() and not reiniciando:
		reiniciando = true
		_recomecar_ciclo.call_deferred()

func _recomecar_ciclo():
	player.position = Vector2(100, 210)
	for x in [600, 800]:
		var inimigo = cena_inimigo.instantiate()
		add_child(inimigo)
		inimigo.position = Vector2(x, 210)
	reiniciando = false

func _on_player_atacou(alvo: Node):
	if is_instance_valid(alvo) and alvo.has_method("receber_dano"):
		alvo.call("receber_dano", 1)
