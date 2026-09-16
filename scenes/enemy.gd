class_name Enemy
extends CharacterBody2D

signal atacou(alvo: Player, dano: int)
signal morreu(tipo: String)
signal health_changed(current: int, maximum: int)
signal died
signal attack_landed(target: Hurtbox)
signal ground_impact

@export var stats: CharacterStats = preload("res://scripts/resources/slime.tres")

var vida_maxima: int = 3
var vida_atual: int = 3
var dano: int = 1
var tipo: String = "normal"
var especie: String = "enemy_slime"
var escala_base: float = 1.0
var ataques: int = 0
var alvo: Player
var especial_atual: bool = false

@onready var visual: AnimatedSprite2D = $Visual
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var hitbox: Hitbox = $WeaponHitbox
@onready var texto_vida: Label = $Vida
@onready var barra_vida: ProgressBar = $BarraVida
@onready var aviso_golpe: Label = $AvisoGolpe
@onready var states: StateMachine = $StateMachine

func configurar(nova_vida: int, novo_dano: int, novo_tipo: String = "normal", nova_especie: String = "enemy_slime") -> void:
    tipo = novo_tipo
    especie = nova_especie
    if tipo == "mini":
        especie = "miniboss_orc"
        escala_base = 1.1
    elif tipo == "boss":
        especie = "boss_orc_king"
        escala_base = 1.25
    var resource_name: String = {
        "enemy_slime": "slime", "enemy_goblin": "goblin", "enemy_skeleton": "skeleton",
        "miniboss_orc": "orc_warrior", "boss_orc_king": "orc_king"
    }.get(especie, "slime")
    stats = load("res://scripts/resources/%s.tres" % resource_name) as CharacterStats
    stats = stats.duplicate() as CharacterStats
    stats.max_health = nova_vida
    stats.attack_damage = novo_dano
    vida_maxima = nova_vida
    vida_atual = nova_vida
    dano = novo_dano

func _ready() -> void:
    if stats == null:
        stats = preload("res://scripts/resources/slime.tres").duplicate() as CharacterStats
    hurtbox.stats = stats
    hurtbox.configure(stats.max_health)
    hurtbox.health_changed.connect(_on_health_changed)
    hurtbox.damaged.connect(_on_damaged)
    hurtbox.died.connect(_on_died)
    hitbox.attack_landed.connect(_on_attack_landed)
    _configure_reach()
    var hurt_shape: CollisionShape2D = hurtbox.get_node("CollisionShape2D") as CollisionShape2D
    hurt_shape.shape = hurt_shape.shape.duplicate() as Shape2D
    (hurt_shape.shape as RectangleShape2D).size *= escala_base
    var actions: Array[String] = ["idle", "attack", "hit", "death"]
    if tipo == "boss":
        actions.append("special")
    visual.sprite_frames = AnimacaoSprites.montar(especie, actions)
    visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    visual.offset = Vector2(0, -26 if especie == "enemy_slime" else (-27 if especie in ["enemy_goblin", "enemy_skeleton"] else -28))
    visual.scale = Vector2.ONE * escala_base
    visual.frame_changed.connect(_on_frame_changed)
    visual.animation_finished.connect(_on_animation_finished)
    states.action_requested.connect(_on_state_action)
    states.state_changed.connect(_on_state_changed)
    states.transition_to(&"Walk")
    states.transition_to(&"Idle")
    var background_style: StyleBoxFlat = StyleBoxFlat.new()
    background_style.bg_color = Color(0.13, 0.14, 0.17)
    barra_vida.add_theme_stylebox_override("background", background_style)
    var fill_style: StyleBoxFlat = StyleBoxFlat.new()
    fill_style.bg_color = Color(0.88, 0.3, 0.27) if tipo == "normal" else Color(0.96, 0.69, 0.3)
    barra_vida.add_theme_stylebox_override("fill", fill_style)
    _atualizar_vida()

func _configure_reach() -> void:
    var reach: float = maxf(stats.attack_range, 20.0)
    var weapon_shape: CollisionShape2D = hitbox.get_node("CollisionShape2D") as CollisionShape2D
    weapon_shape.shape = weapon_shape.shape.duplicate() as Shape2D
    (weapon_shape.shape as RectangleShape2D).size.x = reach
    weapon_shape.position = Vector2(-reach * 0.5, -22.0)
    var detection_shape: CollisionShape2D = $AreaAtaque/CollisionShape2D as CollisionShape2D
    detection_shape.shape = detection_shape.shape.duplicate() as Shape2D
    (detection_shape.shape as RectangleShape2D).size.x = reach
    detection_shape.position = Vector2(-reach * 0.5, -22.0)

func _on_state_action(action: StringName) -> void:
    if action == &"move":
        return
    if action == &"attack" and especial_atual and visual.sprite_frames.has_animation(&"special"):
        visual.play(&"special")
    elif visual.sprite_frames.has_animation(action):
        visual.play(action)

func _on_state_changed(state: StringName) -> void:
    hitbox.active = false
    aviso_golpe.visible = state == &"PreAttack" and especial_atual
    if state == &"PreAttack":
        attacks_setup()
    if state == &"PostAttack":
        var recovery: State = states.get_node("PostAttack") as State
        recovery.duration = maxf(0.25, 1.0 / maxf(stats.attack_speed, 0.1) - 0.65)
    if state == &"Death":
        velocity = Vector2.ZERO
        set_physics_process(false)

func attacks_setup() -> void:
    ataques += 1
    especial_atual = tipo == "boss" and ataques % 3 == 0
    aviso_golpe.visible = especial_atual

func _on_area_ataque_body_entered(body: Node2D) -> void:
    if body is Player and not (body as Player).derrotado and vida_atual > 0:
        alvo = body as Player
        states.transition_to(&"PreAttack")

func _on_area_ataque_body_exited(body: Node2D) -> void:
    if body == alvo:
        alvo = null
        hitbox.active = false
        aviso_golpe.hide()
        if vida_atual > 0 and not states.is_in(&"Hit"):
            states.transition_to(&"Idle")

func _physics_process(_delta: float) -> void:
    if vida_atual <= 0:
        return
    if states.is_in(&"Idle") and is_instance_valid(alvo):
        states.transition_to(&"PreAttack")
    if alvo == null and $AreaAtaque.monitoring:
        for body: Node2D in $AreaAtaque.get_overlapping_bodies():
            if body is Player and not (body as Player).derrotado:
                _on_area_ataque_body_entered(body)
                break
    if alvo == null and (states.is_in(&"Idle") or states.is_in(&"Walk")):
        var player_node: Player = get_tree().get_first_node_in_group("player") as Player
        var distance: float = global_position.x - player_node.global_position.x if player_node != null else INF
        if player_node != null and not player_node.derrotado and distance > stats.attack_range and distance < stats.attack_range + 85.0:
            states.transition_to(&"Walk")
            velocity.x = -stats.move_speed
            move_and_slide()
        else:
            velocity.x = 0.0
            states.transition_to(&"Idle")

func _on_frame_changed() -> void:
    if not states.is_in(&"Attack") or vida_atual <= 0:
        return
    var impact_frame: int = 4 if especial_atual else (3 if tipo != "normal" else 2)
    if visual.frame == impact_frame:
        hitbox.active = true
        hitbox.damage = dano + maxi(1, dano / 2) if especial_atual else dano
        hitbox.strike()
        hitbox.active = false
        aviso_golpe.hide()
        if especial_atual:
            ground_impact.emit()

func _on_animation_finished() -> void:
    if states.is_in(&"Death"):
        queue_free()
    elif states.is_in(&"Attack"):
        states.transition_to(&"PostAttack")
    elif states.is_in(&"Hit"):
        states.transition_to(&"PreAttack" if is_instance_valid(alvo) else &"Idle")

func _on_attack_landed(target: Hurtbox) -> void:
    attack_landed.emit(target)
    if target.get_parent() is Player:
        atacou.emit(target.get_parent() as Player, hitbox.damage)

func _on_health_changed(current: int, maximum: int) -> void:
    vida_atual = current
    vida_maxima = maximum
    _atualizar_vida()
    health_changed.emit(current, maximum)

func _on_damaged(_amount: int) -> void:
    if vida_atual > 0:
        states.transition_to(&"Hit")
        _flash_damage()

func _on_died() -> void:
    states.transition_to(&"Death")
    died.emit()
    morreu.emit(tipo)

func _flash_damage() -> void:
    visual.material = preload("res://assets/shaders/damage_flash.tres").duplicate() as Material
    var shader: ShaderMaterial = visual.material as ShaderMaterial
    shader.set_shader_parameter("flash_amount", 1.0)
    shader.set_shader_parameter("flash_color", Color.WHITE)
    var tween: Tween = create_tween()
    tween.tween_method(func(value: float) -> void: shader.set_shader_parameter("flash_amount", value), 1.0, 0.0, 0.13)

func receber_dano(valor: int) -> void:
    hurtbox.damage(valor)

func _atacar() -> void:
    if vida_atual > 0 and is_instance_valid(alvo):
        states.transition_to(&"PreAttack")

func _atualizar_vida() -> void:
    barra_vida.value = 100.0 * vida_atual / maxi(vida_maxima, 1)
    barra_vida.visible = vida_atual < vida_maxima and vida_atual > 0
    texto_vida.visible = tipo != "normal" and vida_atual > 0
    if tipo != "normal":
        texto_vida.text = "%s %d/%d" % ["BOSS" if tipo == "boss" else "MINI", vida_atual, vida_maxima]
