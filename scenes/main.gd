extends Node2D

@onready var player: Player = $Player
@onready var stage_manager: StageManager = $StageManager
@onready var camera: CameraFeedback = $Camera
@onready var background: ColorRect = $Background
@onready var ground: ColorRect = $Ground
@onready var cenario: Cenario = $ParallaxBackground/ParallaxLayer/Cenario
@onready var texto_fase: Label = $Interface/Fase
@onready var texto_player: Label = $Interface/VidaPlayer
@onready var objetivo: Label = $Interface/Objetivo
@onready var texto_xp: Label = $Interface/Experiencia
@onready var texto_drop: Label = $Interface/Drop
@onready var texto_gold: Label = $Interface/Gold
@onready var barra_vida: ProgressBar = $Interface/BarraVida
@onready var barra_xp: ProgressBar = $Interface/BarraXP
@onready var aviso_drop: Timer = $AvisoDrop
@onready var reinicio: Timer = $Reinicio

var battle_log: Label
var battle_elapsed: float = 0.0

var andar_atual: int = 1
var fase_atual: int = 1
var ciclo_atual: int = 1
var em_derrota: bool = false
var torre_concluida: bool = false

func _ready() -> void:
    stage_manager.wave_started.connect(_on_wave_started)
    stage_manager.enemy_died.connect(_on_inimigo_morreu)
    stage_manager.stage_cleared.connect(_on_stage_cleared)
    stage_manager.heal_requested.connect(player.curar)
    stage_manager.reposition_requested.connect(func(destination: Vector2) -> void: player.position = destination)
    stage_manager.tower_finished.connect(_on_tower_finished)
    stage_manager.ground_impact.connect(camera.shake_ground)
    player.attack_landed.connect(_on_player_attack_landed)
    player.hurtbox.damaged.connect(_on_player_damaged)
    stage_manager.floor_transition_started.connect(_on_floor_transition)
    stage_manager.configure(EstadoJogo.andar_escolhido, EstadoJogo.fase_escolhida)
    _aplicar_status()
    _on_player_vida_mudou(player.vida_atual, player.vida_maxima)
    _atualizar_xp()
    _atualizar_gold()
    _estilizar_barra(barra_vida, Color(0.22, 0.79, 0.48))
    _estilizar_barra(barra_xp, Color(0.42, 0.72, 1.0))
    _criar_onda()
    _build_idle_hud()

func _process(delta: float) -> void:
    battle_elapsed += delta

func _build_idle_hud() -> void:
    var log_background := ColorRect.new()
    log_background.position = Vector2(0, 252)
    log_background.size = Vector2(640, 22)
    log_background.color = Color(0.04, 0.025, 0.02, 0.76)
    log_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $Interface.add_child(log_background)
    battle_log = Label.new()
    battle_log.position = Vector2(10, 254)
    battle_log.size = Vector2(550, 18)
    battle_log.text = "[00:00] A aventura continua..."
    battle_log.add_theme_font_size_override("font_size", 10)
    battle_log.add_theme_color_override("font_color", Color("f8e7c2"))
    $Interface.add_child(battle_log)
    var toggle := TextureButton.new()
    toggle.name = "HeroModalToggle"
    toggle.position = Vector2(580, 304)
    toggle.size = Vector2(52, 50)
    toggle.texture_normal = load("res://assets/ui/octagon_normal.svg")
    toggle.texture_hover = load("res://assets/ui/octagon_hover.svg")
    toggle.texture_pressed = load("res://assets/ui/octagon_pressed.svg")
    toggle.ignore_texture_size = true
    toggle.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    toggle.tooltip_text = "Abrir ou fechar Herói"
    toggle.pressed.connect(_toggle_hero_modal)
    $Interface.add_child(toggle)
    var icon := TextureRect.new()
    icon.texture = load("res://assets/ui/hero/portrait_barbarian.svg")
    icon.position = Vector2(11, 7)
    icon.size = Vector2(30, 30)
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    toggle.add_child(icon)
    var label := Label.new()
    label.text = "HERO"
    label.position = Vector2(0, 36)
    label.size = Vector2(52, 11)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 7)
    label.add_theme_color_override("font_color", Color("fbbf24"))
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    toggle.add_child(label)

func _estilizar_barra(barra: ProgressBar, cor: Color) -> void:
    var fundo: StyleBoxFlat = StyleBoxFlat.new()
    fundo.bg_color = Color(0.06, 0.11, 0.16)
    fundo.set_corner_radius_all(3)
    barra.add_theme_stylebox_override("background", fundo)
    var preenchimento: StyleBoxFlat = StyleBoxFlat.new()
    preenchimento.bg_color = cor
    preenchimento.set_corner_radius_all(3)
    barra.add_theme_stylebox_override("fill", preenchimento)

func _criar_onda() -> void:
    stage_manager.spawn_wave()

func _avancar() -> void:
    stage_manager.advance()

func _on_wave_started(floor_number: int, stage_number: int, cycle_number: int, encounter: String) -> void:
    andar_atual = floor_number
    fase_atual = stage_number
    ciclo_atual = cycle_number
    texto_fase.text = "ANDAR %d/%d  •  FASE %d/%d  •  CICLO %d/%d" % [floor_number, Progressao.TOTAL_ANDARES, stage_number, Progressao.FASES_POR_ANDAR, cycle_number, Progressao.CICLOS_POR_FASE]
    texto_drop.hide()
    aviso_drop.stop()
    var tint: Color = Color.from_hsv(float((floor_number + 2) % 10) / 10.0, 0.45, 0.18 + stage_number * 0.005)
    background.color = Color(tint.r, tint.g, tint.b, 0.0)
    ground.color = tint.lightened(0.4)
    cenario.configurar(floor_number, stage_number)
    objetivo.text = "Boss do andar" if encounter == "boss" else ("Mini boss da fase" if encounter == "mini" else "Elimine os inimigos para avançar.")

func _on_stage_cleared(floor_number: int, stage_number: int) -> void:
    EstadoJogo.liberar_proxima(floor_number, stage_number)

func _on_tower_finished() -> void:
    torre_concluida = true
    player.velocidade = 0.0
    texto_fase.text = "TORRE CONCLUÍDA!  |  %d ANDARES" % Progressao.TOTAL_ANDARES
    objetivo.text = "Você venceu o último boss."

func _on_inimigo_morreu(tipo: String) -> void:
    if EstadoJogo.ganhar_xp(Progressao.xp_inimigo(andar_atual, tipo)):
        _aplicar_status()
    var gold_drop: int = Progressao.gold_inimigo(andar_atual, tipo)
    EstadoJogo.ganhar_gold(gold_drop)
    _atualizar_gold()
    texto_drop.text = "+%d Gold" % gold_drop
    _write_battle_log("Monstro foi derrotado • +%d Gold" % gold_drop)
    var item: Dictionary = Itens.gerar_drop(andar_atual, fase_atual, tipo, EstadoJogo.difficulty_selected)
    if not item.is_empty():
        EstadoJogo.adicionar_item(item)
        texto_drop.text = "DROP: %s  |  +%d Gold" % [Itens.nome_exibicao(item), gold_drop]
    texto_drop.show()
    aviso_drop.start()
    _atualizar_xp()

func _on_aviso_drop_timeout() -> void:
    texto_drop.hide()

func _atualizar_gold() -> void:
    texto_gold.text = "GOLD %d" % EstadoJogo.gold

func _aplicar_status() -> void:
    player.configurar_status(EstadoJogo.nivel, EstadoJogo.bonus_vida(), EstadoJogo.bonus_ataque())

func _atualizar_xp() -> void:
    if EstadoJogo.nivel == Evolucao.NIVEL_MAXIMO:
        texto_xp.text = "LV 100  •  XP MAX"
        barra_xp.value = 100.0
    else:
        var necessario: int = Evolucao.xp_para_proximo(EstadoJogo.nivel)
        texto_xp.text = "LV %d  •  XP %d/%d" % [EstadoJogo.nivel, EstadoJogo.xp_atual, necessario]
        barra_xp.value = 100.0 * EstadoJogo.xp_atual / necessario

func _on_player_vida_mudou(atual: int, maxima: int) -> void:
    texto_player.text = "HP %d/%d  •  ATK %d" % [atual, maxima, player.dano]
    barra_vida.value = 100.0 * atual / maxi(maxima, 1)

func _on_player_morreu() -> void:
    em_derrota = true
    texto_fase.text = "DERROTA  |  REINICIANDO FASE %d..." % fase_atual
    reinicio.start()

func _on_reinicio_timeout() -> void:
    player.reiniciar()
    await stage_manager.reset_stage()
    em_derrota = false

func _on_menu_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_inventario_pressed() -> void:
    _toggle_hero_modal()

func _toggle_hero_modal() -> void:
    var existing := get_node_or_null("PainelBau")
    if existing != null:
        existing.queue_free()
        return
    var modal: CanvasLayer = (load("res://scenes/ui/hero_inventory_modal.tscn") as PackedScene).instantiate() as CanvasLayer
    modal.name = "PainelBau"
    add_child(modal)
    camera.chest_open = true
    modal.tree_exiting.connect(func() -> void: camera.chest_open = false)
    modal.connect("item_equipped", func(_slot: String, _item: ItemData) -> void: _aplicar_status())

func _write_battle_log(message: String) -> void:
    if battle_log == null:
        return
    var total_seconds := floori(battle_elapsed)
    battle_log.text = "[%02d:%02d] %s" % [total_seconds / 60, total_seconds % 60, message]

func _on_player_attack_landed(target: Hurtbox) -> void:
    _floating_damage(target.get_parent() as Node2D, player.dano, Color("fbbf24"))

func _on_player_damaged(amount: int) -> void:
    _floating_damage(player, amount, Color("ef4444"))
    _write_battle_log("O herói recebeu %d de dano." % amount)

func _floating_damage(target: Node2D, amount: int, color: Color) -> void:
    if target == null:
        return
    var value := Label.new()
    value.text = "-%d" % amount
    value.position = Vector2(-14, -66)
    value.z_index = 20
    value.add_theme_font_size_override("font_size", 14)
    value.add_theme_color_override("font_color", color)
    value.add_theme_color_override("font_outline_color", Color("1a1614"))
    value.add_theme_constant_override("outline_size", 3)
    target.add_child(value)
    var tween := value.create_tween().set_parallel(true)
    tween.tween_property(value, "position:y", -88.0, 0.65)
    tween.tween_property(value, "modulate:a", 0.0, 0.65)
    tween.chain().tween_callback(value.queue_free)

func _open_module(module: String) -> void:
    UIFactory.open_module(self, module)

func _on_floor_transition(_from_floor: int, _to_floor: int) -> void:
    var wipe := ColorRect.new()
    wipe.color = Color.WHITE
    var wipe_material := ShaderMaterial.new()
    wipe_material.shader = load("res://assets/shaders/rune_wipe.gdshader")
    wipe_material.set_shader_parameter("progress", 0.0)
    wipe.material = wipe_material
    wipe.position = Vector2.ZERO
    wipe.size = Vector2(640, 360)
    wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
    wipe.modulate.a = 0.0
    $Interface.add_child(wipe)
    var tween := create_tween()
    wipe.modulate.a = 1.0
    tween.tween_property(wipe_material, "shader_parameter/progress", 1.0, 0.28)
    tween.tween_property(wipe_material, "shader_parameter/progress", 0.0, 0.42)
    tween.finished.connect(wipe.queue_free)
