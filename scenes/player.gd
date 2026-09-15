class_name Player
extends CharacterBody2D

signal atacou(alvo: Enemy)
signal vida_mudou(atual: int, maxima: int)
signal morreu

enum State { WALK, IDLE, ATTACK, HIT, DEATH }

var current_state = State.WALK
var velocidade = 100.0
var dano = 1
var vida_maxima = 20
var vida_atual = vida_maxima
var derrotado = false
var inimigo_perto = false
var alvo: Enemy
var golpe_pendente = false

@onready var visual: AnimatedSprite2D = $Visual
@onready var aviso_ataque: Label = $AvisoAtaque
@onready var tempo_ataque: Timer = $TempoAtaque
@onready var tempo_aviso: Timer = $TempoAviso

func _ready():
	visual.sprite_frames = AnimacaoSprites.montar("barbarian", ["idle", "walk", "attack", "hit", "death"])
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.animation_finished.connect(_on_animation_finished)
	visual.frame_changed.connect(_on_frame_changed)
	_tocar_estado(State.WALK)

func _physics_process(_delta):
	velocity.x = 0.0 if inimigo_perto or derrotado else velocidade
	move_and_slide()
	if derrotado or current_state == State.HIT or current_state == State.ATTACK:
		return
	if velocity.x != 0.0 and current_state != State.WALK:
		_tocar_estado(State.WALK)
	elif velocity.x == 0.0 and current_state == State.WALK:
		_tocar_estado(State.IDLE)

func _tocar_estado(novo_estado: State):
	current_state = novo_estado
	match current_state:
		State.WALK:
			visual.play("walk")
		State.IDLE:
			visual.play("idle")
		State.ATTACK:
			visual.play("attack")
		State.HIT:
			visual.play("hit")
		State.DEATH:
			visual.play("death")
			set_physics_process(false)

func _on_detection_body_entered(body):
	if body is Enemy and not inimigo_perto and not derrotado and body.vida_atual > 0:
		alvo = body
		alvo.tree_exiting.connect(_on_alvo_saiu)
		inimigo_perto = true
		_atacar()
		tempo_ataque.start()

func _atacar():
	if derrotado or not is_instance_valid(alvo) or alvo.vida_atual == 0:
		return
	golpe_pendente = true
	_tocar_estado(State.ATTACK)

func receber_dano(valor: int):
	if derrotado:
		return
	vida_atual = maxi(vida_atual - valor, 0)
	vida_mudou.emit(vida_atual, vida_maxima)
	if vida_atual == 0:
		derrotado = true
		golpe_pendente = false
		tempo_ataque.stop()
		tempo_aviso.stop()
		aviso_ataque.hide()
		_tocar_estado(State.DEATH)
		morreu.emit()
	else:
		_tocar_estado(State.HIT)

func curar(valor: int):
	if derrotado:
		return
	vida_atual = mini(vida_atual + valor, vida_maxima)
	vida_mudou.emit(vida_atual, vida_maxima)

func _on_frame_changed():
	if current_state == State.ATTACK and visual.frame == 3 and golpe_pendente:
		golpe_pendente = false
		if is_instance_valid(alvo) and alvo.vida_atual > 0 and not derrotado:
			atacou.emit(alvo)

func _on_animation_finished():
	match current_state:
		State.ATTACK, State.HIT:
			_tocar_estado(State.IDLE if inimigo_perto else State.WALK)

func _on_tempo_aviso_timeout():
	aviso_ataque.hide()

func _on_alvo_saiu():
	tempo_ataque.stop()
	tempo_aviso.stop()
	aviso_ataque.hide()
	golpe_pendente = false
	alvo = null
	inimigo_perto = false
	if not derrotado and current_state != State.HIT:
		_tocar_estado(State.WALK)

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
	golpe_pendente = false
	alvo = null
	inimigo_perto = false
	derrotado = false
	golpe_pendente = false
	vida_atual = vida_maxima
	set_physics_process(true)
	visual.modulate = Color.WHITE
	visual.scale = Vector2.ONE
	_tocar_estado(State.WALK)
	vida_mudou.emit(vida_atual, vida_maxima)
