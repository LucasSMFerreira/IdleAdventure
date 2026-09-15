class_name Enemy
extends CharacterBody2D

signal atacou(alvo: Player)

var vida_maxima = 3
var vida_atual = vida_maxima
var alvo: Player

@onready var texto_vida: Label = $Vida
@onready var tempo_ataque: Timer = $TempoAtaque

func _ready():
	_atualizar_vida()

func receber_dano(dano: int):
	if vida_atual == 0:
		return
	vida_atual = maxi(vida_atual - dano, 0)
	_atualizar_vida()
	if vida_atual == 0:
		tempo_ataque.stop()
		queue_free()

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
		atacou.emit(alvo)

func _atualizar_vida():
	texto_vida.text = "HP %d/%d" % [vida_atual, vida_maxima]
