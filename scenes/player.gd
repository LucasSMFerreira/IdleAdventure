class_name Player
extends CharacterBody2D

signal atacou(alvo: Enemy)
signal vida_mudou(atual: int, maxima: int)
signal morreu
signal health_changed(current: int, maximum: int)
signal died
signal attack_landed(target: Hurtbox)

@export var stats: CharacterStats = preload("res://scripts/resources/barbarian.tres")

var velocidade: float = 100.0
var dano: int = 1
var vida_maxima: int = 20
var vida_atual: int = 20
var derrotado: bool = false
var inimigo_perto: bool = false
var alvo: Enemy

@onready var visual: AnimatedSprite2D = $Visual
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var machado_hitbox: Hitbox = $MachadoHitbox
@onready var deteccao: Area2D = $Detection
@onready var aviso_ataque: Label = $AvisoAtaque
@onready var states: StateMachine = $StateMachine

func _ready() -> void:
	stats = stats.duplicate() as CharacterStats
	velocidade = stats.move_speed
	dano = stats.attack_damage
	hurtbox.stats = stats
	hurtbox.configure(stats.max_health)
	hurtbox.health_changed.connect(_on_health_changed)
	hurtbox.damaged.connect(_on_damaged)
	hurtbox.died.connect(_on_died)
	machado_hitbox.attack_landed.connect(_on_attack_landed)
	visual.sprite_frames = AnimacaoSprites.montar("barbarian", ["idle", "walk", "attack", "hit", "death"])
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.frame_changed.connect(_on_frame_changed)
	visual.animation_finished.connect(_on_animation_finished)
	states.action_requested.connect(_on_state_action)
	states.state_changed.connect(_on_state_changed)
	states.transition_to(&"Idle")
	states.transition_to(&"Walk")

func _physics_process(_delta: float) -> void:
	velocity.x = velocidade if states.is_in(&"Walk") and not derrotado and not inimigo_perto else 0.0
	move_and_slide()
	if not inimigo_perto and not derrotado:
		for body: Node2D in deteccao.get_overlapping_bodies():
			if body is Enemy and (body as Enemy).vida_atual > 0:
				_on_detection_body_entered(body)
				break
	if states.is_in(&"Walk") and inimigo_perto:
		states.transition_to(&"PreAttack")

func _configure_reach() -> void:
	var reach: float = maxf(stats.attack_range, 20.0)
	var axe_shape: CollisionShape2D = machado_hitbox.get_node("CollisionShape2D") as CollisionShape2D
	axe_shape.shape = axe_shape.shape.duplicate() as Shape2D
	(axe_shape.shape as RectangleShape2D).size = Vector2(reach, 42.0)
	axe_shape.position = Vector2(reach * 0.5, -22.0)
	var detection_shape: CollisionShape2D = deteccao.get_node("CollisionShape2D") as CollisionShape2D
	detection_shape.shape = detection_shape.shape.duplicate() as Shape2D
	(detection_shape.shape as RectangleShape2D).size.x = reach
	detection_shape.position = Vector2(reach * 0.5, -22.0)

func _on_state_action(action: StringName) -> void:
	if action == &"move":
		return
	if visual.sprite_frames.has_animation(action):
		visual.play(action)

func _on_state_changed(state: StringName) -> void:
	aviso_ataque.visible = state == &"PreAttack"
	machado_hitbox.active = false
	if state == &"PostAttack":
		var recovery: State = states.get_node("PostAttack") as State
		recovery.duration = maxf(0.18, 1.0 / maxf(stats.attack_speed, 0.1) - 0.5)
	if state == &"Death":
		velocity = Vector2.ZERO
		set_physics_process(false)

func _on_detection_body_entered(body: Node2D) -> void:
	if body is Enemy and not inimigo_perto and not derrotado and (body as Enemy).vida_atual > 0:
		alvo = body as Enemy
		alvo.tree_exiting.connect(_on_alvo_saiu, CONNECT_ONE_SHOT)
		inimigo_perto = true
		states.transition_to(&"PreAttack")

func _on_alvo_saiu() -> void:
	alvo = null
	inimigo_perto = false
	machado_hitbox.active = false
	if not derrotado and not states.is_in(&"Hit"):
		states.transition_to(&"Walk")

func _atacar() -> void:
	if not derrotado and is_instance_valid(alvo) and alvo.vida_atual > 0:
		states.transition_to(&"PreAttack")

func _on_frame_changed() -> void:
	if states.is_in(&"Attack") and visual.frame == 3 and not derrotado:
		machado_hitbox.active = true
		machado_hitbox.damage = dano
		machado_hitbox.strike()
		machado_hitbox.active = false

func _on_animation_finished() -> void:
	if states.is_in(&"Attack"):
		states.transition_to(&"PostAttack")
	elif states.is_in(&"Hit"):
		states.transition_to(&"PreAttack" if inimigo_perto else &"Walk")

func _on_attack_landed(target: Hurtbox) -> void:
	attack_landed.emit(target)
	# Combat damage is applied by Hitbox; this legacy signal remains observational.
	if target.get_parent() is Enemy:
		atacou.emit(target.get_parent() as Enemy)

func _on_health_changed(current: int, maximum: int) -> void:
	vida_atual = current
	vida_maxima = maximum
	health_changed.emit(current, maximum)
	vida_mudou.emit(current, maximum)

func _on_damaged(_amount: int) -> void:
	if hurtbox.current_health > 0:
		states.transition_to(&"Hit")
		_flash_damage()

func _on_died() -> void:
	derrotado = true
	states.transition_to(&"Death")
	died.emit()
	morreu.emit()

func _flash_damage() -> void:
	visual.material = preload("res://assets/shaders/damage_flash.tres").duplicate() as Material
	var shader: ShaderMaterial = visual.material as ShaderMaterial
	shader.set_shader_parameter("flash_amount", 1.0)
	shader.set_shader_parameter("flash_color", Color(1.0, 0.26, 0.25))
	var tween: Tween = create_tween()
	tween.tween_method(func(value: float) -> void: shader.set_shader_parameter("flash_amount", value), 1.0, 0.0, 0.16)

func receber_dano(valor: int) -> void:
	hurtbox.damage(valor)

func curar(valor: int) -> void:
	hurtbox.heal(valor)

func configurar_status(novo_nivel: int, bonus_vida: int, bonus_ataque: int) -> void:
	var nova_vida: int = Evolucao.vida_maxima(novo_nivel) + bonus_vida
	var aumento: int = maxi(nova_vida - vida_maxima, 0)
	stats.max_health = nova_vida
	stats.attack_damage = Evolucao.ataque(novo_nivel) + bonus_ataque
	dano = stats.attack_damage
	hurtbox.configure(nova_vida)
	hurtbox.current_health = mini(hurtbox.current_health + aumento, nova_vida)
	_on_health_changed(hurtbox.current_health, nova_vida)

func reiniciar() -> void:
	derrotado = false
	alvo = null
	inimigo_perto = false
	hurtbox.configure(stats.max_health)
	visual.modulate = Color.WHITE
	visual.scale = Vector2.ONE
	set_physics_process(true)
	states.transition_to(&"Walk")
