class_name Enemy
extends CharacterBody2D

signal atacou(alvo: Player, dano: int)
signal morreu(tipo: String)

var vida_maxima = 3
var vida_atual = vida_maxima
var dano = 1
var tipo = "normal"
var cor_base = Color(1, 0.65, 0.45)
var escala_base = 0.35
var alvo: Player

@onready var visual: Sprite2D = $Sprite2D
@onready var texto_vida: Label = $Vida
@onready var tempo_ataque: Timer = $TempoAtaque

func configurar(nova_vida: int, novo_dano: int, novo_tipo: String = "normal"):
	vida_maxima = nova_vida
	vida_atual = nova_vida
	dano = novo_dano
	tipo = novo_tipo
	if tipo == "mini":
		cor_base = Color(0.75, 0.5, 1)
		escala_base = 0.45
	elif tipo == "boss":
		cor_base = Color(1, 0.85, 0.25)
		escala_base = 0.55

func _ready():
	visual.modulate = cor_base
	visual.scale = Vector2(escala_base, escala_base)
	_atualizar_vida()

func receber_dano(valor: int):
	if vida_atual == 0:
		return
	vida_atual = maxi(vida_atual - valor, 0)
	_atualizar_vida()
	visual.modulate = Color(1, 0.25, 0.25)
	create_tween().tween_property(visual, "modulate", cor_base, 0.3)
	if vida_atual == 0:
		morreu.emit(tipo)
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
		visual.scale = Vector2(escala_base + 0.07, escala_base + 0.07)
		create_tween().tween_property(visual, "scale", Vector2(escala_base, escala_base), 0.2)

func _atualizar_vida():
	var nome = "MINI BOSS " if tipo == "mini" else ("BOSS " if tipo == "boss" else "")
	texto_vida.text = "%sHP %d/%d" % [nome, vida_atual, vida_maxima]
