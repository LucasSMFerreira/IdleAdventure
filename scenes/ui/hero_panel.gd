extends CanvasLayer

signal equipment_changed
const CLASSES: Array[String] = ["Bárbaro", "Mago", "Sacerdote"]
const EQUIPMENT: Array[String] = ["arma", "cabeca", "peito", "pernas", "luvas", "arma_secundaria", "amuleto", "anel_1", "anel_2", "insignia"]
const POSITIONS: Array[Vector2] = [Vector2(120, 60), Vector2(75, 98), Vector2(75, 146), Vector2(120, 190), Vector2(352, 60), Vector2(397, 98), Vector2(397, 146), Vector2(352, 190), Vector2(170, 212), Vector2(310, 212)]
var class_index := 0
var cells: Dictionary = {}
var class_label: Label
var stats: Label

func _ready() -> void:
	layer = 20
	class_index = maxi(0, CLASSES.find(EstadoJogo.active_class))
	UIFactory.backdrop(self)
	var panel := UIFactory.frame(self, Vector2(65, 12), Vector2(510, 300), true)
	UIFactory.action(panel, "◀", Vector2(120, 10), Vector2(38, 26), _switch.bind(-1))
	class_label = UIFactory.text(panel, "", Vector2(165, 10), Vector2(180, 26), 16, DarkTheme.GOLD)
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.action(panel, "▶", Vector2(352, 10), Vector2(38, 26), _switch.bind(1))
	UIFactory.action(panel, "✕", Vector2(460, 8), Vector2(32, 24), queue_free, DarkTheme.CRIMSON)
	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/sprites/barbarian_idle_sheet.svg")
	portrait.position = Vector2(185, 52)
	portrait.size = Vector2(140, 140)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.clip_contents = true
	panel.add_child(portrait)
	for index: int in range(EQUIPMENT.size()):
		var slot_name := EQUIPMENT[index]
		var cell := UIFactory.slot(panel, POSITIONS[index], "equipment", index, 0, slot_name)
		cell.item_dropped.connect(_equip)
		UIFactory.text(panel, _short(slot_name), POSITIONS[index] + Vector2(-7, 33), Vector2(47, 12), 7)
		cells[slot_name] = cell
	stats = UIFactory.text(panel, "", Vector2(168, 188), Vector2(176, 48), 11)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var formation := PanelContainer.new()
	formation.position = Vector2(142, 249)
	formation.size = Vector2(226, 34)
	formation.add_theme_stylebox_override("panel", DarkTheme.panel())
	panel.add_child(formation)
	var formation_label := Label.new()
	formation_label.text = "◆ Formação ativa  ◈ Maestria +5% ◆"
	formation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	DarkTheme.label(formation_label, 9, DarkTheme.GOLD)
	formation.add_child(formation_label)
	EstadoJogo.dados_mudaram.connect(refresh)
	refresh()

func _short(slot_name: String) -> String:
	return str({"arma":"Arma", "cabeca":"Elmo", "peito":"Peito", "pernas":"Botas", "luvas":"Luvas", "arma_secundaria":"Sec.", "amuleto":"Amul.", "anel_1":"Anel I", "anel_2":"Anel II", "insignia":"Insíg."}.get(slot_name, slot_name))

func _switch(direction: int) -> void:
	class_index = wrapi(class_index + direction, 0, CLASSES.size())
	EstadoJogo.active_class = CLASSES[class_index]
	EstadoJogo.salvar()
	EstadoJogo.dados_mudaram.emit()

func refresh() -> void:
	if class_label == null: return
	class_label.text = EstadoJogo.active_class
	for slot_name: String in EQUIPMENT:
		var legacy := "acessorio" if slot_name in ["amuleto", "anel_1", "anel_2", "insignia"] else slot_name
		var item_id := int(EstadoJogo.equipados.get(slot_name, 0))
		if item_id == 0 and slot_name == "amuleto": item_id = int(EstadoJogo.equipados.get(legacy, 0))
		(cells[slot_name] as ItemSlot).set_item(item_id)
	stats.text = "Lv. %d\nVida +%d  •  Ataque +%d" % [EstadoJogo.nivel, EstadoJogo.bonus_vida(), EstadoJogo.bonus_ataque()]

func _equip(item_id: int, _destination: String, index: int) -> void:
	var target := EQUIPMENT[index]
	var data := ItemData.from_legacy(EstadoJogo.item_por_id(item_id))
	if not data.can_equip(EstadoJogo.active_class, EstadoJogo.nivel, target): return
	if EstadoJogo.equipar_no_slot(item_id, target):
		equipment_changed.emit()


