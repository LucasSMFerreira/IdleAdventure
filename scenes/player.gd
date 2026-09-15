class_name Player
extends CharacterBody2D

signal atacou(alvo: Enemy)
signal vida_mudou(atual: int, maxima: int)
signal morreu

var velocidade = 100.0
var dano = 1
var vida_maxima = 20
var vida_atual = vida_maxima
var derrotado = false
var inimigo_perto = false
var alvo: Enemy
var tempo_passos = 0.0
var tween_dano: Tween

@onready var visual: Sprite2D = $Visual
@onready var aviso_ataque: Label = $AvisoAtaque
@onready var tempo_ataque: Timer = $TempoAtaque
@onready var tempo_aviso: Timer = $TempoAviso

func _physics_process(delta):
	velocity.x = 0.0 if inimigo_perto or derrotado else velocidade
	move_and_slide()
	if velocity.x != 0.0:
		tempo_passos += delta
		visual.position.y = sin(tempo_passos * 12.0) * 2.0
	else:
		visual.position.y = 0.0

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
	visual.scale = Vector2(0.42, 0.42)
	create_tween().tween_property(visual, "scale", Vector2(0.35, 0.35), 0.2)
	aviso_ataque.show()
	tempo_aviso.start()

func receber_dano(dano: int):
	if derrotado:
		return
	vida_atual = maxi(vida_atual - dano, 0)
	vida_mudou.emit(vida_atual, vida_maxima)
	if is_instance_valid(tween_dano) and tween_dano.is_running():
		tween_dano.kill()
	visual.modulate = Color(1, 0.25, 0.25)
	tween_dano = create_tween()
	tween_dano.tween_property(visual, "modulate", Color(0.45, 0.7, 1), 0.3)
	if vida_atual == 0:
		derrotado = true
		tween_dano.kill()
		visual.modulate = Color(0.4, 0.4, 0.4)
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

func configurar_status(novo_nivel: int, bonus_vida: int, bonus_ataque: int):
	var nova_vida = Evolucao.vida_maxima(novo_nivel) + bonus_vida
	var aumento_vida = maxi(nova_vida - vida_maxima, 0)
	vida_maxima = nova_vida
	dano = Evolucao.ataque(novo_nivel) + bonus_ataque
	vida_atual = mini(vida_atual + aumento_vida, vida_maxima)
	vida_mudou.emit(vida_atual, vida_maxima)

func reiniciar():
	tempo_ataque.stop()
	tempo_aviso.stop()
	aviso_ataque.hide()
	alvo = null
	inimigo_perto = false
	derrotado = false
	vida_atual = vida_maxima
	visual.modulate = Color(0.45, 0.7, 1)
	visual.scale = Vector2(0.35, 0.35)
	visual.position = Vector2.ZERO
	vida_mudou.emit(vida_atual, vida_maxima)
