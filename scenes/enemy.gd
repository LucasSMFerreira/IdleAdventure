class_name Enemy
extends CharacterBody2D

signal atacou(alvo: Player, dano: int)

var vida_maxima = 3
var vida_atual = vida_maxima
var dano = 1
var alvo: Player

@onready var visual: Sprite2D = $Sprite2D
@onready var texto_vida: Label = $Vida
@onready var tempo_ataque: Timer = $TempoAtaque

func configurar(nova_vida: int, novo_dano: int):
	vida_maxima = nova_vida
	vida_atual = nova_vida
	dano = novo_dano

func _ready():
	_atualizar_vida()

func receber_dano(dano: int):
	if vida_atual == 0:
		return
	vida_atual = maxi(vida_atual - dano, 0)
	_atualizar_vida()
	visual.modulate = Color(1, 0.25, 0.25)
	create_tween().tween_property(visual, "modulate", Color(1, 0.65, 0.45), 0.3)
	if vida_atual == 0:
		tempo_ataque.stop()
		var saida = create_tween()
		saida.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.35)
		saida.tween_callback(queue_free)

func _on_area_ataque_body_entered(body):
	if body is Player and not body.derrotado:
		alvo = body
		_atacar()
		tempo_ataque.start()

func _on_area_ataque_body_exited(body):
	if body == alvo:
		tempo_ataque.stop()
		alvo = null

func _atacar():
	if vida_atual > 0 and is_instance_valid(alvo) and not alvo.derrotado:
		atacou.emit(alvo, dano)
		visual.scale = Vector2(0.42, 0.42)
		create_tween().tween_property(visual, "scale", Vector2(0.35, 0.35), 0.2)

func _atualizar_vida():
	texto_vida.text = "HP %d/%d" % [vida_atual, vida_maxima]
