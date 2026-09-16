class_name HeroInventoryModal
extends CanvasLayer

signal class_changed(new_class: String)
signal item_equipped(slot_type: String, item_data: ItemData)
signal hub_tab_opened(tab_id: StringName)
signal closed

const CLASSES: Array[String] = ["Bárbaro", "Arqueira", "Healer", "Mago", "Tank"]
const PORTRAITS: Array[String] = ["portrait_barbarian", "portrait_archer", "portrait_healer", "portrait_mage", "portrait_tank"]
const EQUIPMENT: Array[String] = ["arma", "peito", "pernas", "cabeca", "luvas", "brinco", "anel"]
const EQUIPMENT_LABELS: Dictionary = {"arma":"Arma", "peito":"Armadura", "pernas":"Botas", "cabeca":"Capacete", "luvas":"Luvas", "brinco":"Brinco", "anel":"Anel"}
const EQUIPMENT_POSITIONS: Array[Vector2] = [Vector2(284, 59), Vector2(284, 89), Vector2(284, 119), Vector2(484, 59), Vector2(484, 89), Vector2(484, 119), Vector2(520, 119)]
const HUBS: Array[Array] = [["Baú", "stash", "icon_chest"], ["Skills", "skills", "hero/icon_cross"], ["Talentos", "talents", "icon_talents"], ["Forja", "forge", "icon_cube"], ["Portal", "portal", "hero/icon_portal"]]

var current_class_index: int = 0
var inventory_page: int = 0
var current_source: String = "bag"
var panel: NinePatchRect
var class_label: Label
var portrait: TextureRect
var level_label: Label
var xp_bar: ProgressBar
var equipment_cells: Dictionary = {}
var inventory_grid: GridContainer
var inventory_title: Label
var page_label: Label
var info_panel: PanelContainer
var info_label: Label
var forge_controls: Panel
var skill_tree: Control
var skill_buttons: Array[Button] = []
var skill_description: Label
var forge_selection: int = 0
var forge_mode: bool = false
var forge_description: Label
var utility_panel: Panel
var search_field: LineEdit
var type_filter: OptionButton
var sort_selector: OptionButton
var detail_label: Label
var selected_item_id: int = 0
var recycle_confirmation_id: int = 0
var recycle_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 30
	current_class_index = maxi(0, CLASSES.find(EstadoJogo.active_class))
	_build()
	EstadoJogo.dados_mudaram.connect(refresh)
	InventoryStore.layout_changed.connect(refresh_inventory)
	refresh()

func _build() -> void:
	var shadow := ColorRect.new()
	shadow.color = Color(0.02, 0.015, 0.012, 0.72)
	shadow.position = Vector2(10, 0)
	shadow.size = Vector2(620, 254)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)
	panel = NinePatchRect.new()
	panel.texture = load("res://assets/ui/rune_frame.svg")
	panel.patch_margin_left = 12
	panel.patch_margin_top = 12
	panel.patch_margin_right = 12
	panel.patch_margin_bottom = 12
	panel.position = Vector2(16, 2)
	panel.size = Vector2(800, 328)
	panel.scale = Vector2(0.76, 0.76)
	add_child(panel)
	_build_header()
	_build_hero_section()
	_build_inventory_section()
	_build_footer()
	_build_item_details()

func _build_header() -> void:
	var header := PanelContainer.new()
	header.position = Vector2(14, 10)
	header.size = Vector2(772, 38)
	header.add_theme_stylebox_override("panel", DarkTheme.panel(Color("7f1d1d"), Color("d97706"), 3))
	panel.add_child(header)
	var title := Label.new()
	title.text = "HERO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	DarkTheme.label(title, 20, DarkTheme.GOLD)
	header.add_child(title)
	_icon_button(panel, "hero/icon_banner", Vector2(22, 14), _show_status.bind("Estandarte da formação ativo."))
	_icon_button(panel, "hero/icon_grid", Vector2(58, 14), _show_status.bind("Menu rápido: inventário, formação e forja."))
	_icon_button(panel, "hero/icon_gear", Vector2(700, 14), _show_status.bind("Configurações de interface prontas para áudio e acessibilidade."))
	UIFactory.action(panel, "✕", Vector2(746, 14), Vector2(32, 28), close, DarkTheme.CRIMSON)

func _build_hero_section() -> void:
	var section := PanelContainer.new()
	section.position = Vector2(14, 51)
	section.size = Vector2(772, 102)
	section.add_theme_stylebox_override("panel", DarkTheme.panel(Color("1c1917"), Color("78350f"), 2))
	panel.add_child(section)
	UIFactory.action(panel, "‹", Vector2(326, 52), Vector2(30, 25), _change_class.bind(-1))
	class_label = UIFactory.text(panel, "", Vector2(360, 52), Vector2(118, 25), 14, DarkTheme.GOLD)
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.action(panel, "›", Vector2(482, 52), Vector2(30, 25), _change_class.bind(1))
	portrait = TextureRect.new()
	portrait.position = Vector2(373, 75)
	portrait.size = Vector2(66, 66)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	panel.add_child(portrait)
	level_label = UIFactory.text(panel, "", Vector2(365, 124), Vector2(82, 20), 11, DarkTheme.GOLD)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(368, 143)
	xp_bar.size = Vector2(76, 6)
	xp_bar.show_percentage = false
	xp_bar.add_theme_stylebox_override("background", DarkTheme.panel(Color("100d0c"), Color("3f352e"), 1))
	xp_bar.add_theme_stylebox_override("fill", DarkTheme.panel(Color("d97706"), DarkTheme.GOLD, 0))
	panel.add_child(xp_bar)
	for index: int in range(EQUIPMENT.size()):
		var slot_type := EQUIPMENT[index]
		var cell := UIFactory.slot(panel, EQUIPMENT_POSITIONS[index], "equipment", index, 0, slot_type)
		cell.item_dropped.connect(_on_equipment_drop)
		equipment_cells[slot_type] = cell
		var label := UIFactory.text(panel, str(EQUIPMENT_LABELS[slot_type]), EQUIPMENT_POSITIONS[index] + Vector2(-25 if index < 3 else 34, 8), Vector2(58, 14), 7, Color("d6c5a4"))
		if index < 3: label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_build_formation()

func _build_formation() -> void:
	var start_x := 18.0
	UIFactory.text(panel, "FORMAÇÃO", Vector2(start_x, 61), Vector2(90, 15), 9, DarkTheme.GOLD)
	for index: int in range(5):
		var card := PanelContainer.new()
		card.position = Vector2(start_x + index * 43, 81)
		card.size = Vector2(36, 36)
		card.add_theme_stylebox_override("panel", DarkTheme.panel(Color("171311"), Color("22c55e") if index == 0 else Color("6b4f36"), 2))
		panel.add_child(card)
		var face := TextureRect.new()
		face.texture = load("res://assets/ui/hero/%s.svg" % PORTRAITS[index])
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(face)
	UIFactory.text(panel, "LÍDER", Vector2(start_x, 120), Vector2(38, 13), 7, Color("4ade80"))
	for index: int in range(2):
		var passive := TextureRect.new()
		passive.texture = load("res://assets/ui/octagon_normal.svg")
		passive.position = Vector2(88 + index * 42, 125)
		passive.size = Vector2(36, 30)
		passive.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		panel.add_child(passive)
		var glyph := Label.new()
		glyph.text = "✦" if index == 0 else "◆"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		DarkTheme.label(glyph, 14, DarkTheme.GOLD)
		passive.add_child(glyph)

func _build_inventory_section() -> void:
	var tab_bar := PanelContainer.new()
	tab_bar.position = Vector2(14, 155)
	tab_bar.size = Vector2(772, 27)
	tab_bar.add_theme_stylebox_override("panel", DarkTheme.panel(Color("241d19"), Color("78350f"), 1))
	panel.add_child(tab_bar)
	UIFactory.action(panel, "Inventário", Vector2(25, 156), Vector2(105, 24), _show_inventory, DarkTheme.GOLD)
	UIFactory.action(panel, "Formação", Vector2(134, 156), Vector2(96, 24), _show_formation)
	inventory_title = UIFactory.text(panel, "MOCHILA", Vector2(273, 158), Vector2(180, 20), 10, DarkTheme.GOLD)
	inventory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.action(panel, "‹", Vector2(675, 156), Vector2(26, 23), _change_page.bind(-1))
	page_label = UIFactory.text(panel, "1/1", Vector2(703, 158), Vector2(45, 18), 9)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.action(panel, "›", Vector2(750, 156), Vector2(26, 23), _change_page.bind(1))
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 7
	inventory_grid.position = Vector2(273, 183)
	inventory_grid.add_theme_constant_override("h_separation", 5)
	inventory_grid.add_theme_constant_override("v_separation", 1)
	panel.add_child(inventory_grid)
	utility_panel = Panel.new()
	utility_panel.position = Vector2(18, 184)
	utility_panel.size = Vector2(222, 94)
	utility_panel.add_theme_stylebox_override("panel", DarkTheme.panel(Color("1c1917"), DarkTheme.BRONZE, 1))
	panel.add_child(utility_panel)
	search_field = LineEdit.new()
	search_field.placeholder_text = "Buscar item..."
	search_field.position = Vector2(7, 6)
	search_field.size = Vector2(208, 25)
	search_field.clear_button_enabled = true
	search_field.add_theme_font_size_override("font_size", 11)
	search_field.add_theme_color_override("font_color", DarkTheme.TEXT)
	search_field.add_theme_stylebox_override("normal", DarkTheme.panel(Color("100d0c"), DarkTheme.BRONZE, 1))
	search_field.text_changed.connect(func(_query: String) -> void: _reset_results())
	utility_panel.add_child(search_field)
	type_filter = OptionButton.new()
	type_filter.position = Vector2(7, 35)
	type_filter.size = Vector2(208, 23)
	DarkTheme.button(type_filter)
	for label: String in ["Todos os tipos", "Equipamentos", "Acessórios", "Materiais"]:
		type_filter.add_item(label)
	type_filter.item_selected.connect(func(_index: int) -> void: _reset_results())
	utility_panel.add_child(type_filter)
	sort_selector = OptionButton.new()
	sort_selector.position = Vector2(7, 62)
	sort_selector.size = Vector2(208, 23)
	DarkTheme.button(sort_selector)
	for label: String in ["Ordem dos slots", "Raridade", "Nível", "Nome"]:
		sort_selector.add_item(label)
	sort_selector.item_selected.connect(func(_index: int) -> void: _reset_results())
	utility_panel.add_child(sort_selector)
	info_panel = PanelContainer.new()
	info_panel.position = Vector2(235, 188)
	info_panel.size = Vector2(330, 72)
	info_panel.visible = false
	info_panel.add_theme_stylebox_override("panel", DarkTheme.panel(Color("171311"), DarkTheme.BRONZE, 2))
	panel.add_child(info_panel)
	info_label = Label.new()
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	DarkTheme.label(info_label, 11, DarkTheme.TEXT)
	info_panel.add_child(info_label)
	forge_controls = Panel.new()
	forge_controls.position = Vector2(18, 187)
	forge_controls.size = Vector2(224, 86)
	forge_controls.add_theme_stylebox_override("panel", DarkTheme.panel(Color("1c1917"), DarkTheme.GOLD, 2))
	forge_controls.visible = false
	panel.add_child(forge_controls)
	forge_description = UIFactory.text(forge_controls, "Selecione um item na grade.", Vector2(8, 5), Vector2(208, 34), 9, DarkTheme.TEXT)
	forge_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIFactory.action(forge_controls, "Aprimorar", Vector2(8, 45), Vector2(100, 28), _upgrade_selected, DarkTheme.GOLD)
	recycle_button = UIFactory.action(forge_controls, "Reciclar", Vector2(114, 45), Vector2(100, 28), _recycle_selected, DarkTheme.CRIMSON)
	skill_tree = Control.new()
	skill_tree.position = Vector2(240, 185)
	skill_tree.size = Vector2(335, 90)
	skill_tree.visible = false
	panel.add_child(skill_tree)
	for index: int in range(3):
		if index > 0:
			var connector := ColorRect.new()
			connector.position = Vector2(97 + (index - 1) * 115, 19)
			connector.size = Vector2(15, 2)
			connector.color = DarkTheme.GOLD
			connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
			skill_tree.add_child(connector)
		var button := UIFactory.action(skill_tree, "", Vector2(index * 115, 4), Vector2(98, 30), _select_skill.bind(index), DarkTheme.GOLD)
		skill_buttons.append(button)
	skill_description = UIFactory.text(skill_tree, "", Vector2(0, 45), Vector2(335, 42), 9)
	skill_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_item_details() -> void:
	var detail_panel := Panel.new()
	detail_panel.position = Vector2(612, 52)
	detail_panel.size = Vector2(166, 98)
	detail_panel.add_theme_stylebox_override("panel", DarkTheme.panel(Color("171311"), DarkTheme.BRONZE, 1))
	panel.add_child(detail_panel)
	detail_label = UIFactory.text(detail_panel, "Selecione um item\npara comparar atributos.", Vector2(7, 5), Vector2(152, 88), 9)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.clip_text = true

func _build_footer() -> void:
	for index: int in range(HUBS.size()):
		var data: Array = HUBS[index]
		var button := TextureButton.new()
		button.position = Vector2(185 + index * 88, 283)
		button.size = Vector2(72, 38)
		button.texture_normal = load("res://assets/ui/octagon_normal.svg")
		button.texture_hover = load("res://assets/ui/octagon_hover.svg")
		button.texture_pressed = load("res://assets/ui/octagon_pressed.svg")
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.pressed.connect(_open_hub.bind(str(data[1])))
		button.focus_mode = Control.FOCUS_ALL
		panel.add_child(button)
		var icon := Sprite2D.new()
		icon.texture = load("res://assets/ui/%s.svg" % data[2])
		icon.position = Vector2(36, 12)
		icon.scale = Vector2(0.30, 0.30)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.add_child(icon)
		var label := Label.new()
		label.text = str(data[0])
		label.position = Vector2(0, 24)
		label.size = Vector2(72, 13)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		DarkTheme.label(label, 8, DarkTheme.TEXT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)

func _icon_button(owner: Control, icon_name: String, at: Vector2, callback: Callable) -> void:
	var button := TextureButton.new()
	button.texture_normal = load("res://assets/ui/octagon_normal.svg")
	button.texture_hover = load("res://assets/ui/octagon_hover.svg")
	button.position = at
	button.size = Vector2(30, 28)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.pressed.connect(callback)
	button.focus_mode = Control.FOCUS_ALL
	owner.add_child(button)
	var icon := Sprite2D.new()
	icon.texture = load("res://assets/ui/%s.svg" % icon_name)
	icon.position = Vector2(15, 14)
	icon.scale = Vector2(0.27, 0.27)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_child(icon)

func refresh() -> void:
	if class_label == null: return
	current_class_index = maxi(0, CLASSES.find(EstadoJogo.active_class))
	class_label.text = "<  %s  >" % CLASSES[current_class_index]
	portrait.texture = load("res://assets/ui/hero/%s.svg" % PORTRAITS[current_class_index])
	level_label.text = "Lv. %d" % EstadoJogo.nivel
	xp_bar.value = 100.0 if EstadoJogo.nivel >= Evolucao.NIVEL_MAXIMO else 100.0 * EstadoJogo.xp_atual / maxi(1, Evolucao.xp_para_proximo(EstadoJogo.nivel))
	for slot_type: String in EQUIPMENT:
		var item_id := int(EstadoJogo.equipados.get(slot_type, 0))
		if item_id == 0 and slot_type in ["brinco", "anel"]: item_id = int(EstadoJogo.equipados.get("acessorio", 0)) if slot_type == "brinco" else 0
		(equipment_cells[slot_type] as ItemSlot).set_item(item_id)
	refresh_inventory()
	_refresh_skill_tree()

func refresh_inventory() -> void:
	if inventory_grid == null: return
	for child: Node in inventory_grid.get_children(): child.queue_free()
	var grid: InventoryGrid = InventoryStore.grid_for(current_source)
	if grid == null: return
	var entries: Array[Dictionary] = _visible_entries(grid)
	var pages: int = maxi(1, ceili(float(entries.size()) / 21.0))
	inventory_page = clampi(inventory_page, 0, pages - 1)
	page_label.text = "%d/%d" % [inventory_page + 1, pages]
	inventory_title.text = "MOCHILA" if current_source == "bag" else "BAÚ • ABA %s" % ("I" if current_source == "stash:0" else "II")
	for index: int in range(21):
		var entry_index: int = inventory_page * 21 + index
		var entry: Dictionary = entries[entry_index] if entry_index < entries.size() else {}
		var item_id: int = int(entry.get("id", 0))
		var source_index: int = int(entry.get("index", -1))
		var cell: ItemSlot = UIFactory.slot(inventory_grid, Vector2.ZERO, current_source, source_index, item_id)
		cell.quick_clicked.connect(_quick_equip)
		cell.item_dropped.connect(_inventory_drop)

func _visible_entries(grid: InventoryGrid) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var filtered: bool = not search_field.text.strip_edges().is_empty() or type_filter.selected > 0 or sort_selector.selected > 0
	for index: int in range(grid.capacity()):
		var item_id: int = grid.item_at(index)
		if not filtered:
			result.append({"id": item_id, "index": index})
			continue
		if item_id <= 0: continue
		var record: Dictionary = EstadoJogo.item_por_id(item_id)
		var query: String = search_field.text.strip_edges().to_lower()
		if not query.is_empty() and not str(record.get("nome", "")).to_lower().contains(query): continue
		if not _type_matches(str(record.get("slot", ""))): continue
		result.append({"id": item_id, "index": index, "rarity": int(record.get("qualidade", 0)), "level": int(record.get("nivel", 1)), "name": str(record.get("nome", ""))})
	if sort_selector.selected > 0:
		result.sort_custom(_entry_before)
	return result

func _type_matches(slot: String) -> bool:
	match type_filter.selected:
		1: return slot in ["arma", "arma_secundaria", "cabeca", "peito", "pernas", "luvas", "botas"]
		2: return slot in ["acessorio", "amuleto", "anel", "brinco", "insignia"]
		3: return slot == "material"
	return true

func _entry_before(left: Dictionary, right: Dictionary) -> bool:
	match sort_selector.selected:
		1:
			if int(left["rarity"]) != int(right["rarity"]): return int(left["rarity"]) > int(right["rarity"])
		2:
			if int(left["level"]) != int(right["level"]): return int(left["level"]) > int(right["level"])
		3:
			if str(left["name"]) != str(right["name"]): return str(left["name"]).naturalnocasecmp_to(str(right["name"])) < 0
	return int(left["index"]) < int(right["index"])

func _reset_results() -> void:
	inventory_page = 0
	refresh_inventory()

func _change_class(direction: int) -> void:
	current_class_index = wrapi(current_class_index + direction, 0, CLASSES.size())
	EstadoJogo.active_class = CLASSES[current_class_index]
	EstadoJogo.salvar()
	class_changed.emit(EstadoJogo.active_class)
	EstadoJogo.dados_mudaram.emit()

func _on_equipment_drop(item_id: int, _destination: String, index: int) -> void:
	var slot_type := EQUIPMENT[index]
	var item := ItemData.from_legacy(EstadoJogo.item_por_id(item_id))
	if item.can_equip(CLASSES[current_class_index], EstadoJogo.nivel, slot_type) and EstadoJogo.equipar_no_slot(item_id, slot_type):
		item_equipped.emit(slot_type, item)

func _quick_equip(item_id: int, _source: String) -> void:
	selected_item_id = item_id
	_show_item_details(item_id)
	if forge_mode:
		forge_selection = item_id
		recycle_confirmation_id = 0
		recycle_button.text = "Reciclar"
		_update_forge_description()
		return
	var item := ItemData.from_legacy(EstadoJogo.item_por_id(item_id))
	var target := item.equipment_slot
	if target == "acessorio": target = "brinco" if int(EstadoJogo.equipados.get("brinco", 0)) == 0 else "anel"
	if target not in EQUIPMENT:
		_show_item_details(item_id, "Material ou item sem slot de herói.")
		return
	if not item.can_equip(CLASSES[current_class_index], EstadoJogo.nivel, target):
		var reason: String = "Nível insuficiente." if EstadoJogo.nivel < item.level_req else "Classe incompatível."
		_show_item_details(item_id, reason)
		return
	if EstadoJogo.equipar_no_slot(item_id, target):
		_show_item_details(item_id, "Equipado.")
		item_equipped.emit(target, item)

func _inventory_drop(item_id: int, _destination: String, index: int) -> void:
	InventoryStore.transfer(item_id, current_source, index)
	selected_item_id = item_id
	_show_item_details(item_id)

func _show_item_details(item_id: int, notice: String = "") -> void:
	var record: Dictionary = EstadoJogo.item_por_id(item_id)
	if record.is_empty():
		detail_label.text = "Selecione um item\npara comparar atributos."
		return
	var item: ItemData = ItemData.from_legacy(record)
	var target: String = item.equipment_slot
	if target == "acessorio": target = "brinco"
	var equipped: Dictionary = EstadoJogo.item_equipado(target)
	var health_delta: int = int(record.get("bonus_vida", 0)) - int(equipped.get("bonus_vida", 0))
	var attack_delta: int = int(record.get("bonus_ataque", 0)) - int(equipped.get("bonus_ataque", 0))
	var rarity_name: String = Itens.QUALIDADES[int(item.rarity)]
	var restriction: String = "Nível %d" % item.level_req
	if not item.class_restriction.is_empty(): restriction += " • %s" % item.class_restriction
	detail_label.text = "%s\n%s • Lv.%d • A%d\nΔHP %+d  ΔATK %+d\n%s" % [item.name.left(20), rarity_name, item.level_req, item.floor, health_delta, attack_delta, notice]

func _change_page(direction: int) -> void:
	inventory_page = maxi(0, inventory_page + direction)
	refresh_inventory()

func _show_inventory() -> void:
	forge_mode = false
	forge_controls.visible = false
	skill_tree.visible = false
	utility_panel.visible = true
	current_source = "bag"
	inventory_page = 0
	inventory_grid.visible = true
	info_panel.visible = false
	refresh_inventory()

func _show_formation() -> void:
	forge_mode = false
	forge_controls.visible = false
	skill_tree.visible = false
	utility_panel.visible = false
	inventory_grid.visible = false
	info_panel.visible = true
	info_label.text = "FORMAÇÃO ATIVA\nBárbaro líder • bônus de equipe +5%\nTroque a classe pelas setas no retrato."
	hub_tab_opened.emit(&"formation")

func _open_hub(tab_id: String) -> void:
	hub_tab_opened.emit(StringName(tab_id))
	match tab_id:
		"stash":
			forge_mode = false
			forge_controls.visible = false
			skill_tree.visible = false
			utility_panel.visible = true
			current_source = "stash:0" if current_source == "bag" else ("stash:1" if current_source == "stash:0" else "bag")
			inventory_page = 0
			inventory_grid.visible = true
			info_panel.visible = false
			refresh_inventory()
		"skills":
			forge_mode = false
			forge_controls.visible = false
			utility_panel.visible = false
			inventory_grid.visible = false
			info_panel.visible = false
			skill_tree.visible = true
			_refresh_skill_tree()
		"talents":
			_show_info("TALENTOS PASSIVOS\n◆ Maestria +5%   ✦ Resistência +3%\nPontos adicionais serão liberados por nível.")
		"forge":
			utility_panel.visible = false
			skill_tree.visible = false
			forge_mode = true
			forge_controls.visible = true
			inventory_grid.visible = true
			info_panel.visible = false
			_update_forge_description()
		"portal":
			get_tree().change_scene_to_file("res://scenes/ui/portal_map.tscn")

func _show_info(message: String) -> void:
	forge_mode = false
	forge_controls.visible = false
	skill_tree.visible = false
	utility_panel.visible = false
	inventory_grid.visible = false
	info_panel.visible = true
	info_label.text = message

func _show_status(message: String) -> void:
	_show_info(message)

func _refresh_skill_tree() -> void:
	if skill_tree == null:
		return
	var names: Array[String] = _skill_names()
	for index: int in range(3):
		skill_buttons[index].text = names[index]
		skill_buttons[index].disabled = EstadoJogo.nivel < [1, 15, 50][index]
	_select_skill(0)

func _skill_names() -> Array[String]:
	var by_class: Dictionary = {
		"Bárbaro": ["Golpe", "Fúria", "Machado"],
		"Arqueira": ["Flecha", "Rajada", "Águia"],
		"Healer": ["Cura", "Luz", "Bênção"],
		"Mago": ["Faísca", "Orbe", "Meteorito"],
		"Tank": ["Escudo", "Provocar", "Muralha"],
	}
	var result: Array[String] = []
	result.assign(by_class[CLASSES[current_class_index]])
	return result

func _select_skill(index: int) -> void:
	var unlock_level: int = [1, 15, 50][index]
	var state: String = "Disponível" if EstadoJogo.nivel >= unlock_level else "Desbloqueia no nível %d" % unlock_level
	skill_description.text = "%s • %s\nÁrvore de %s" % [_skill_names()[index], state, CLASSES[current_class_index]]

func _update_forge_description() -> void:
	var record: Dictionary = EstadoJogo.item_por_id(forge_selection)
	if record.is_empty():
		forge_description.text = "Selecione um item na grade."
		return
	var current: int = int(record.get("aprimoramento", 0))
	if current >= 10:
		forge_description.text = "Aprimoramento máximo: +10\nReciclar: +%d Gold" % Itens.valor_reciclagem(record)
		return
	var base_health: int = int(record.get("base_vida", record.get("bonus_vida", 0)))
	var base_attack: int = int(record.get("base_ataque", record.get("bonus_ataque", 0)))
	var next_health: int = base_health + ceili(float(base_health) * (current + 1) * 0.1)
	var next_attack: int = base_attack + ceili(float(base_attack) * (current + 1) * 0.1)
	forge_description.text = "+%d → +%d  •  %d Gold\nHP %d→%d  ATK %d→%d" % [current, current + 1, _forge_cost(record), int(record.get("bonus_vida", 0)), next_health, int(record.get("bonus_ataque", 0)), next_attack]

func _forge_cost(record: Dictionary) -> int:
	var next_rank: int = int(record.get("aprimoramento", 0)) + 1
	return maxi(1, int(record.get("andar", 1))) * 10 * next_rank * (int(record.get("qualidade", 0)) + 1)

func _upgrade_selected() -> void:
	if EstadoJogo.aprimorar_item(forge_selection):
		_update_forge_description()
		_show_item_details(forge_selection, "Aprimoramento concluído.")
		item_equipped.emit("upgrade", ItemData.from_legacy(EstadoJogo.item_por_id(forge_selection)))
	else:
		forge_description.text = "Limite +10 ou Gold insuficiente."

func _recycle_selected() -> void:
	var record: Dictionary = EstadoJogo.item_por_id(forge_selection)
	if record.is_empty():
		forge_description.text = "Selecione um item na grade."
		return
	if int(record.get("qualidade", 0)) >= 1 and recycle_confirmation_id != forge_selection:
		recycle_confirmation_id = forge_selection
		recycle_button.text = "Confirmar"
		forge_description.text = "Reciclar %s?\nClique em Confirmar para concluir." % Itens.QUALIDADES[int(record.get("qualidade", 0))]
		return
	var recycled: int = EstadoJogo.reciclar(forge_selection)
	recycle_confirmation_id = 0
	recycle_button.text = "Reciclar"
	if recycled > 0:
		forge_selection = 0
		selected_item_id = 0
		_show_item_details(0)
		forge_description.text = "Item reciclado • +%d Gold" % recycled
	else:
		forge_description.text = "Remova o item equipado antes de reciclar."

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: InputEventKey = event as InputEventKey
	if key.keycode == KEY_ESCAPE:
		close()
	elif key.ctrl_pressed and key.keycode == KEY_F:
		_show_inventory()
		search_field.grab_focus()
	elif search_field.has_focus():
		return
	elif key.keycode == KEY_PAGEUP:
		_change_page(-1)
	elif key.keycode == KEY_PAGEDOWN:
		_change_page(1)
	elif key.keycode == KEY_LEFT:
		_change_class(-1)
	elif key.keycode == KEY_RIGHT:
		_change_class(1)
	elif key.keycode == KEY_B:
		_open_hub("stash")
	elif key.keycode == KEY_F:
		_open_hub("forge")
	else:
		return
	get_viewport().set_input_as_handled()

func close() -> void:
	closed.emit()
	queue_free()
