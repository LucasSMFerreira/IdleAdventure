class_name Player
extends CharacterBody2D

signal atacou(alvo: Enemy)
signal vida_mudou(atual: int, maxima: int)
signal morreu

var velocidade = 100.0
var vida_maxima = 20
var vida_atual = vida_maxima
var derrotado = false
var inimigo_perto = false
var alvo: Enemy

@onready var aviso_ataque: Label = $AvisoAtaque
@onready var tempo_ataque: Timer = $TempoAtaque
@onready var tempo_aviso: Timer = $TempoAviso

func _physics_process(_delta):
	velocity.x = 0.0 if inimigo_perto or derrotado else velocidade
	move_and_slide()

func _on_detection_body_entered(body):
	if body is Enemy and not inimigo_perto and not derrotado:
		alvo = body
		alvo.tree_exiting.connect(_on_alvo_saiu)
		inimigo_perto = true
		_atacar()
		tempo_ataque.start()

func _atacar():
	if derrotado or not is_instance_valid(alvo):
		return
	atacou.emit(alvo)
	aviso_ataque.show()
	tempo_aviso.start()

func receber_dano(dano: int):
	if derrotado:
		return
	vida_atual = maxi(vida_atual - dano, 0)
	vida_mudou.emit(vida_atual, vida_maxima)
	if vida_atual == 0:
		derrotado = true
		tempo_ataque.stop()
		tempo_aviso.stop()
		aviso_ataque.hide()
		morreu.emit()

func curar(valor: int):
	if derrotado:
		return
	vida_atual = mini(vida_atual + valor, vida_maxima)
	vida_mudou.emit(vida_atual, vida_maxima)

func _on_tempo_aviso_timeout():
	aviso_ataque.hide()

func _on_alvo_saiu():
	tempo_ataque.stop()
	tempo_aviso.stop()
	aviso_ataque.hide()
	alvo = null
	inimigo_perto = false
