extends CharacterBody2D

var vida_maxima = 3
var vida_atual = vida_maxima

@onready var texto_vida: Label = $Vida

func _ready():
	_atualizar_vida()

func receber_dano(dano: int):
	if vida_atual == 0:
		return
	vida_atual = maxi(vida_atual - dano, 0)
	_atualizar_vida()

func _atualizar_vida():
	texto_vida.text = "HP %d/%d" % [vida_atual, vida_maxima]
