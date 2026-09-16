class_name ItemSlot
extends PanelContainer

signal quick_clicked(item_id: int, source: String)
signal item_dropped(item_id: int, destination: String, index: int)

@export var destination := ""
@export var slot_index := -1
@export var accepted_slot := ""
var item_id := 0
var icon: TextureRect
var overlay: Label
var quantity_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(32, 32)
	icon = TextureRect.new()
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 3)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	overlay = Label.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	overlay.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	overlay.add_theme_font_size_override("font_size", 8)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)
	quantity_label = Label.new()
	quantity_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	quantity_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	quantity_label.add_theme_font_size_override("font_size", 8)
	quantity_label.add_theme_color_override("font_color", DarkTheme.TEXT)
	quantity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(quantity_label)
	gui_input.connect(_input)
	refresh()

func set_item(value: int) -> void:
	item_id = value
	refresh()

func refresh() -> void:
	if not is_node_ready(): return
	if item_id <= 0 or EstadoJogo.item_por_id(item_id).is_empty():
		icon.texture = load("res://assets/ui/empty_slot.svg")
		icon.modulate = Color(0.35, 0.31, 0.28, 0.5)
		overlay.text = ""
		quantity_label.text = ""
		add_theme_stylebox_override("panel", DarkTheme.panel(Color("120f0e"), Color("41362e"), 1))
		tooltip_text = accepted_slot.capitalize() if not accepted_slot.is_empty() else "Slot vazio"
		return
	var data := ItemData.from_legacy(EstadoJogo.item_por_id(item_id))
	icon.texture = data.icon
	icon.modulate = Color.WHITE
	var restricted: bool = EstadoJogo.nivel < data.level_req or not data.class_restriction.is_empty() and data.class_restriction != EstadoJogo.active_class or not data.allowed_classes.is_empty() and not data.allowed_classes.has(EstadoJogo.active_class)
	if not accepted_slot.is_empty(): restricted = not data.can_equip(EstadoJogo.active_class, EstadoJogo.nivel, accepted_slot)
	overlay.text = "✕" if restricted else ("+%d" % data.upgrade_level if data.upgrade_level > 0 else "A%d" % data.floor)
	quantity_label.text = str(mini(data.quantity, 999)) if data.can_stack and data.quantity > 1 else ""
	overlay.add_theme_color_override("font_color", Color("ef4444") if restricted else DarkTheme.GOLD)
	add_theme_stylebox_override("panel", DarkTheme.panel(Color("171311"), DarkTheme.RARITY_COLORS[int(data.rarity)], 2))
	tooltip_text = "%s  +%d\nAndar %d • Nível %d\nVida +%d • Ataque +%d" % [data.name, data.upgrade_level, data.floor, data.level_req, int(data.stats_bonus.get("health", 0)), int(data.stats_bonus.get("attack", 0))]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and item_id > 0:
		quick_clicked.emit(item_id, destination)

func _get_drag_data(_at: Vector2) -> Variant:
	if item_id <= 0: return null
	var preview := TextureRect.new()
	preview.texture = icon.texture
	preview.custom_minimum_size = Vector2(36, 36)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	set_drag_preview(preview)
	return {"item_id": item_id, "source": destination}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	if not data is Dictionary or int(data.get("item_id", 0)) <= 0: return false
	if accepted_slot.is_empty(): return true
	var item := ItemData.from_legacy(EstadoJogo.item_por_id(int(data.item_id)))
	return item.can_equip(EstadoJogo.active_class, EstadoJogo.nivel, accepted_slot)

func _drop_data(_at: Vector2, data: Variant) -> void:
	item_dropped.emit(int(data.item_id), destination, slot_index)

