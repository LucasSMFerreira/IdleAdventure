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
    stage_manager.configure(EstadoJogo.andar_escolhido, EstadoJogo.fase_escolhida)
    _aplicar_status()
    _on_player_vida_mudou(player.vida_atual, player.vida_maxima)
    _atualizar_xp()
    _atualizar_gold()
    _estilizar_barra(barra_vida, Color(0.22, 0.79, 0.48))
    _estilizar_barra(barra_xp, Color(0.42, 0.72, 1.0))
    _criar_onda()

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
    var item: Dictionary = Itens.gerar_drop(andar_atual, fase_atual, tipo)
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
    if get_node_or_null("PainelBau"):
        return
    var painel: CanvasLayer = preload("res://scenes/inventario.tscn").instantiate() as CanvasLayer
    painel.name = "PainelBau"
    add_child(painel)
    camera.chest_open = true
    painel.tree_exiting.connect(func() -> void: camera.chest_open = false)
    painel.connect("equipamento_mudou", _aplicar_status)
    painel.connect("craft_concluido", _atualizar_gold)
