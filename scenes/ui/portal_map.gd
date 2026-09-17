extends Control

const DIFFICULTIES: Array[String] = ["Normal", "Pesadelo", "Inferno", "Tormento"]
const ICONS: Array[String] = ["icon_bone_skull", "icon_cyan_skull", "icon_red_skull", "icon_horned_skull"]
const DETAILS: Array[String] = [
	"Inimigos no nível base",
	"Inimigos ×2,5 · drop +50%",
	"Inimigos ×5 · raro garantido",
	"Inimigos ×10 · drops únicos"
]

var shown_floor: int = 1
var selected_stage: int = 1
var map_panel: NinePatchRect
var floor_label: Label
var progress_label: Label
var difficulty_label: Label
var stage_details: Label
var enter_button: Button
var previous_floor_button: Button
var next_floor_button: Button
var nodes: Array[Button] = []
var transition: ColorRect

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	UIFactory.backdrop(self)
	map_panel = UIFactory.frame(self, Vector2(12, 8), Vector2(616, 302), false, true)
	_build_header()
	_build_summary()
	_build_route()
	UIFactory.navigation(self, _open_module)
	_build_transition()
	shown_floor = clampi(EstadoJogo.andar_escolhido, 1, _last_floor())
	selected_stage = clampi(EstadoJogo.fase_escolhida, 1, _last_unlocked_stage(shown_floor))
	refresh()

func _build_header() -> void:
	UIFactory.text(map_panel, "PORTAL DA TORRE", Vector2(24, 10), Vector2(195, 27), 17, DarkTheme.GOLD)
	previous_floor_button = UIFactory.action(map_panel, "◀", Vector2(224, 11), Vector2(29, 27), _change_floor.bind(-1))
	floor_label = UIFactory.text(map_panel, "", Vector2(258, 11), Vector2(117, 27), 13, DarkTheme.GOLD)
	floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_floor_button = UIFactory.action(map_panel, "▶", Vector2(380, 11), Vector2(29, 27), _change_floor.bind(1))
	var difficulty := OptionButton.new()
	difficulty.position = Vector2(426, 10)
	difficulty.size = Vector2(166, 29)
	DarkTheme.button(difficulty, DarkTheme.CRIMSON)
	for index: int in range(DIFFICULTIES.size()):
		difficulty.add_icon_item(load("res://assets/ui/%s.svg" % ICONS[index]), DIFFICULTIES[index])
	difficulty.select(EstadoJogo.difficulty_selected)
	difficulty.item_selected.connect(_difficulty_changed)
	map_panel.add_child(difficulty)

func _build_summary() -> void:
	_card(Vector2(20, 49), Vector2(175, 239))
	UIFactory.text(map_panel, "PROGRESSO", Vector2(33, 62), Vector2(148, 22), 12, DarkTheme.GOLD)
	progress_label = UIFactory.text(map_panel, "", Vector2(33, 86), Vector2(148, 42), 10, DarkTheme.TEXT)
	progress_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_divider(33, 134, 148)
	UIFactory.text(map_panel, "DIFICULDADE", Vector2(33, 144), Vector2(148, 20), 10, DarkTheme.GOLD)
	difficulty_label = UIFactory.text(map_panel, "", Vector2(33, 166), Vector2(148, 40), 10, DarkTheme.TEXT)
	difficulty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_divider(33, 207, 148)
	stage_details = UIFactory.text(map_panel, "", Vector2(33, 214), Vector2(148, 30), 11, DarkTheme.GOLD)
	stage_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enter_button = UIFactory.action(map_panel, "ENTRAR", Vector2(31, 251), Vector2(153, 28), _start_selected, DarkTheme.GOLD)

func _build_route() -> void:
	var route_card := _card(Vector2(203, 49), Vector2(393, 239))
	route_card.clip_contents = true
	var map_art := TextureRect.new()
	map_art.texture = load("res://assets/ui/portal_map_bg.svg")
	map_art.position = Vector2(6, 6)
	map_art.size = Vector2(381, 226)
	map_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_art.modulate = Color(1, 1, 1, 0.24)
	map_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route_card.add_child(map_art)
	UIFactory.text(map_panel, "CAMINHO DO ANDAR", Vector2(220, 62), Vector2(260, 22), 12, DarkTheme.GOLD)
	UIFactory.text(map_panel, "Chefe", Vector2(224, 253), Vector2(62, 18), 9, Color("fca5a5"))
	_draw_route()
	for stage: int in range(1, Progressao.FASES_POR_ANDAR + 1):
		var button := Button.new()
		button.position = _stage_position(stage)
		button.size = Vector2(45, 45)
		button.text = "☠" if stage == 10 else "%02d" % stage
		DarkTheme.button(button)
		button.add_theme_font_size_override("font_size", 15)
		button.pressed.connect(_select_stage.bind(stage))
		map_panel.add_child(button)
		nodes.append(button)

func _card(at: Vector2, dimensions: Vector2) -> Panel:
	var card := Panel.new()
	card.position = at
	card.size = dimensions
	card.add_theme_stylebox_override("panel", DarkTheme.panel(Color("1a1614"), Color("6b4f36"), 2))
	map_panel.add_child(card)
	return card

func _divider(x: float, y: float, width: float) -> void:
	var line := ColorRect.new()
	line.color = Color("6b4f36")
	line.position = Vector2(x, y)
	line.size = Vector2(width, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(line)

func _stage_position(stage: int) -> Vector2:
	var column: int = stage - 1 if stage <= 5 else 10 - stage
	return Vector2(220 + column * 76, 103 if stage <= 5 else 198)

func _draw_route() -> void:
	for stage: int in range(1, Progressao.FASES_POR_ANDAR):
		var start := _stage_position(stage) + Vector2(22, 22)
		var finish := _stage_position(stage + 1) + Vector2(22, 22)
		for dash: int in range(1, 6):
			var mark := ColorRect.new()
			mark.color = Color("9a6725")
			mark.position = start.lerp(finish, float(dash) / 6.0)
			mark.size = Vector2(5, 3)
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			map_panel.add_child(mark)

func _build_transition() -> void:
	transition = ColorRect.new()
	transition.color = Color.WHITE
	var transition_material := ShaderMaterial.new()
	transition_material.shader = load("res://assets/shaders/rune_wipe.gdshader")
	transition_material.set_shader_parameter("progress", 0.0)
	transition.material = transition_material
	transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition.z_index = 100
	add_child(transition)

func _last_floor() -> int:
	return mini(Progressao.TOTAL_ANDARES, int((EstadoJogo.maior_fase_liberada - 1) / Progressao.FASES_POR_ANDAR) + 1)

func _last_unlocked_stage(floor_number: int) -> int:
	return clampi(EstadoJogo.maior_fase_liberada - (floor_number - 1) * Progressao.FASES_POR_ANDAR, 1, Progressao.FASES_POR_ANDAR)

func refresh() -> void:
	floor_label.text = "ANDAR %d" % shown_floor
	previous_floor_button.disabled = shown_floor == 1
	next_floor_button.disabled = shown_floor == _last_floor()
	selected_stage = clampi(selected_stage, 1, _last_unlocked_stage(shown_floor))
	for index: int in range(nodes.size()):
		var stage := index + 1
		var button := nodes[index]
		var unlocked := stage <= _last_unlocked_stage(shown_floor)
		var selected := stage == selected_stage
		button.disabled = not unlocked
		var border := DarkTheme.GOLD if selected else (DarkTheme.CRIMSON if stage == 10 else Color("8b7355"))
		button.add_theme_stylebox_override("normal", DarkTheme.panel(Color("49351e") if selected else Color("241d19"), border, 3 if selected else 2))
		button.add_theme_stylebox_override("disabled", DarkTheme.panel(Color("161311"), Color("4e433b"), 1))
		button.add_theme_color_override("font_color", DarkTheme.GOLD if selected or stage == 10 else DarkTheme.TEXT)
		button.add_theme_color_override("font_disabled_color", Color("776b60"))
		button.tooltip_text = ("Fase %d-%d · %s" % [shown_floor, stage, "Rei Orc" if stage == 10 else "Mini boss"]) if unlocked else "Conclua a fase anterior para liberar"
	var unlocked_floor := _last_floor()
	var unlocked_stage := _last_unlocked_stage(unlocked_floor)
	progress_label.text = "Liberado até %d-%d\nHerói Lv. %d  ·  %d Gold" % [unlocked_floor, unlocked_stage, EstadoJogo.nivel, EstadoJogo.gold]
	difficulty_label.text = "%s\n%s" % [DIFFICULTIES[EstadoJogo.difficulty_selected], DETAILS[EstadoJogo.difficulty_selected]]
	stage_details.text = "FASE %d-%d\n%s" % [shown_floor, selected_stage, "Rei Orc" if selected_stage == 10 else "Mini boss"]
	enter_button.tooltip_text = "Iniciar a fase %d-%d" % [shown_floor, selected_stage]

func _select_stage(stage: int) -> void:
	selected_stage = stage
	refresh()

func _change_floor(direction: int) -> void:
	shown_floor = clampi(shown_floor + direction, 1, _last_floor())
	selected_stage = 1 if direction > 0 else _last_unlocked_stage(shown_floor)
	refresh()

func _difficulty_changed(index: int) -> void:
	EstadoJogo.set_difficulty(index)
	refresh()

func _start_selected() -> void:
	if not EstadoJogo.selecionar_fase(shown_floor, selected_stage):
		return
	enter_button.disabled = true
	var tween := create_tween()
	var transition_material := transition.material as ShaderMaterial
	tween.tween_property(transition_material, "shader_parameter/progress", 1.0, 0.35)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/world/wildlands_road.tscn")

func _open_module(module: String) -> void:
	UIFactory.open_module(self, module)
