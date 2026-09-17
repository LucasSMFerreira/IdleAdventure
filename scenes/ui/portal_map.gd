extends Control

const DIFFICULTIES: Array[String] = ["Normal", "Pesadelo", "Inferno", "Tormento"]
const ICONS: Array[String] = ["icon_bone_skull", "icon_cyan_skull", "icon_red_skull", "icon_horned_skull"]
const DETAILS: Array[String] = ["Stats ×1.0", "Stats ×2.5 • Drop +50%", "Stats ×5.0 • Raro garantido", "Stats ×10.0 • Drops únicos"]
var shown_floor: int = 1
var selected_stage: int = 1
var map_panel: NinePatchRect
var floor_label: Label
var status: Label
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
	UIFactory.text(map_panel, "PORTAL DA TORRE", Vector2(20, 8), Vector2(230, 24), 17, DarkTheme.GOLD)
	previous_floor_button = UIFactory.action(map_panel, "◀", Vector2(218, 8), Vector2(34, 25), _change_floor.bind(-1))
	floor_label = UIFactory.text(map_panel, "", Vector2(258, 8), Vector2(100, 25), 14, DarkTheme.GOLD)
	floor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_floor_button = UIFactory.action(map_panel, "▶", Vector2(364, 8), Vector2(34, 25), _change_floor.bind(1))
	var map_art := TextureRect.new()
	map_art.texture = load("res://assets/ui/portal_map_bg.svg")
	map_art.position = Vector2(20, 42)
	map_art.size = Vector2(576, 157)
	map_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_art.modulate = Color(1, 1, 1, 0.72)
	map_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_panel.add_child(map_art)
	for path_index: int in range(9):
		var start := Vector2(81 + path_index * 54, 113 + (28 if path_index % 2 == 0 else 0))
		var finish := Vector2(81 + (path_index + 1) * 54, 113 + (28 if (path_index + 1) % 2 == 0 else 0))
		for dash: int in range(5):
			var mark := ColorRect.new()
			mark.color = Color("d97706")
			mark.position = start.lerp(finish, float(dash + 1) / 6.0)
			mark.size = Vector2(4, 2)
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			map_panel.add_child(mark)
	var difficulty := OptionButton.new()
	difficulty.position = Vector2(420, 8)
	difficulty.size = Vector2(175, 28)
	DarkTheme.button(difficulty, DarkTheme.CRIMSON)
	for index: int in range(DIFFICULTIES.size()): difficulty.add_icon_item(load("res://assets/ui/%s.svg" % ICONS[index]), DIFFICULTIES[index])
	difficulty.select(EstadoJogo.difficulty_selected)
	difficulty.item_selected.connect(_difficulty_changed)
	map_panel.add_child(difficulty)
	for stage: int in range(1, 11):
		var position_value := Vector2(42 + (stage - 1) * 54, 94 + (28 if stage % 2 == 0 else 0))
		var button := Button.new()
		button.position = position_value
		button.size = Vector2(39, 39)
		button.text = "☠" if stage == 10 else str(stage)
		button.pressed.connect(_select_stage.bind(stage))
		map_panel.add_child(button)
		nodes.append(button)
	stage_details = UIFactory.text(map_panel, "", Vector2(25, 205), Vector2(565, 22), 12, DarkTheme.GOLD)
	stage_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status = UIFactory.text(map_panel, "", Vector2(25, 229), Vector2(565, 23), 10, DarkTheme.TEXT)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enter_button = UIFactory.action(map_panel, "", Vector2(210, 256), Vector2(195, 30), _start_selected, DarkTheme.GOLD)
	UIFactory.navigation(self, _open_module)
	transition = ColorRect.new()
	transition.color = Color.WHITE
	var transition_material := ShaderMaterial.new()
	transition_material.shader = load("res://assets/shaders/rune_wipe.gdshader")
	transition_material.set_shader_parameter("progress", 0.0)
	transition.material = transition_material
	transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition.modulate.a = 1.0
	transition.z_index = 100
	add_child(transition)
	shown_floor = clampi(EstadoJogo.andar_escolhido, 1, _last_floor())
	selected_stage = clampi(EstadoJogo.fase_escolhida, 1, _last_unlocked_stage(shown_floor))
	refresh()

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
		var unlocked := stage <= _last_unlocked_stage(shown_floor)
		var button := nodes[index]
		button.disabled = not unlocked
		var border := DarkTheme.GOLD if stage == selected_stage else (DarkTheme.CRIMSON if stage == 10 else Color("867665"))
		button.add_theme_stylebox_override("normal", DarkTheme.panel(Color("48331d") if stage == selected_stage else Color("241d19"), border, 3))
		button.add_theme_color_override("font_color", DarkTheme.GOLD if stage == 10 or stage == selected_stage else DarkTheme.TEXT)
		button.tooltip_text = ("Andar %d · Fase %d%s" % [shown_floor, stage, " · Rei Orc" if stage == 10 else " · Mini boss"]) if unlocked else "Conclua a fase anterior para liberar"
	stage_details.text = "[%d-%d] %s  •  %s" % [shown_floor, selected_stage, "Rei Orc" if selected_stage == 10 else "Mini boss ao final", DIFFICULTIES[EstadoJogo.difficulty_selected]]
	status.text = "%s  |  Liberado até [%d-%d]  •  Nível %d  •  %d Gold" % [DETAILS[EstadoJogo.difficulty_selected], _last_floor(), _last_unlocked_stage(_last_floor()), EstadoJogo.nivel, EstadoJogo.gold]
	enter_button.text = "Entrar na fase %d-%d" % [shown_floor, selected_stage]

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

func _start(stage: int) -> void:
	if not EstadoJogo.selecionar_fase(shown_floor, stage):
		return
	enter_button.disabled = true
	var tween := create_tween()
	var transition_material := transition.material as ShaderMaterial
	tween.tween_property(transition_material, "shader_parameter/progress", 1.0, 0.35)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/world/wildlands_road.tscn")

func _start_selected() -> void:
	_start(selected_stage)

func _open_module(module: String) -> void:
	UIFactory.open_module(self, module)

