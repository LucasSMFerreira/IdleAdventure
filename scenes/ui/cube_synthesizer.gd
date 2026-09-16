extends CanvasLayer

const CATEGORIES: Array[String] = ["Síntese", "Alquimia", "Corrosão", "Criação", "Encantamento", "Oferenda"]
var inputs: Array[int] = []
var cells: Array[ItemSlot] = []
var result: ItemSlot
var status: Label
var category: OptionButton
var include_stash: CheckBox

func _ready() -> void:
	layer = 20
	inputs.resize(9)
	inputs.fill(0)
	UIFactory.backdrop(self)
	var panel := UIFactory.frame(self, Vector2(95, 8), Vector2(450, 306), true)
	UIFactory.text(panel, "CUBO DE SÍNTESE", Vector2(18, 7), Vector2(250, 24), 16, DarkTheme.GOLD)
	UIFactory.action(panel, "✕", Vector2(400, 7), Vector2(32, 24), queue_free, DarkTheme.CRIMSON)
	category = OptionButton.new()
	category.position = Vector2(18, 38)
	category.size = Vector2(184, 30)
	DarkTheme.button(category)
	for value: String in CATEGORIES: category.add_item(value)
	category.item_selected.connect(_category_changed)
	panel.add_child(category)
	var level_filter := OptionButton.new()
	level_filter.position = Vector2(248, 38)
	level_filter.size = Vector2(184, 30)
	DarkTheme.button(level_filter)
	for start: int in range(1, 101, 10): level_filter.add_item("Lv.%d–%d" % [start, mini(start + 9, 100)])
	panel.add_child(level_filter)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(84, 80)
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	panel.add_child(grid)
	for index: int in range(9):
		var cell := UIFactory.slot(grid, Vector2.ZERO, "cube", index)
		cell.item_dropped.connect(_drop)
		cell.quick_clicked.connect(_remove)
		cells.append(cell)
	UIFactory.text(panel, "✦  ➜", Vector2(225, 117), Vector2(70, 32), 18, DarkTheme.GOLD)
	result = UIFactory.slot(panel, Vector2(330, 110), "result", 0)
	result.custom_minimum_size = Vector2(48, 48)
	include_stash = CheckBox.new()
	include_stash.text = "Incluir itens do Baú"
	include_stash.position = Vector2(84, 202)
	include_stash.size = Vector2(210, 24)
	include_stash.button_pressed = true
	include_stash.add_theme_color_override("font_color", DarkTheme.TEXT)
	panel.add_child(include_stash)
	status = UIFactory.text(panel, "", Vector2(18, 230), Vector2(414, 24), 10)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.action(panel, "FORJAR", Vector2(150, 261), Vector2(150, 30), _confirm, DarkTheme.GOLD)
	_category_changed(0)

func _category_changed(index: int) -> void:
	status.text = "Combine 9 itens do mesmo grau para criar o grau superior." if index == 0 else "%s: receitas serão liberadas pelos andares." % CATEGORIES[index]

func _drop(item_id: int, _destination: String, index: int) -> void:
	if inputs.has(item_id): return
	if not include_stash.button_pressed and InventoryStore.locate(item_id) != "bag":
		status.text = "Ative ‘Incluir itens do Baú’."
		return
	inputs[index] = item_id
	cells[index].set_item(item_id)
	_validate()

func _remove(item_id: int, _source: String) -> void:
	var index := inputs.find(item_id)
	if index >= 0:
		inputs[index] = 0
		cells[index].set_item(0)
	_validate()

func _validate() -> void:
	var count := 0
	for item_id: int in inputs:
		if item_id > 0: count += 1
	status.text = "%d/9 itens selecionados" % count

func _confirm() -> void:
	if category.selected != 0:
		status.text = "Esta receita exige um diagrama encontrado em boss."
		return
	var crafted := EstadoJogo.synthesize_nine(inputs, include_stash.button_pressed)
	if crafted == 0:
		status.text = "Use 9 itens iguais em parte, andar e raridade, com Gold suficiente."
		return
	result.set_item(crafted)
	inputs.fill(0)
	for cell: ItemSlot in cells: cell.set_item(0)
	status.text = "Síntese concluída! O novo item foi enviado ao Baú."
	result.modulate = DarkTheme.GOLD
	create_tween().tween_property(result, "modulate", Color.WHITE, 0.7)
