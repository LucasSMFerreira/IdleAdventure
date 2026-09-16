class_name UIFactory
extends RefCounted

const SLOT_SCENE := preload("res://scenes/ui/item_slot.tscn")

static func backdrop(owner: Node) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.02, 0.76)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	owner.add_child(dim)
	return dim

static func frame(owner: Node, at: Vector2, dimensions: Vector2, crimson := false, parchment := false) -> NinePatchRect:
	var value := NinePatchRect.new()
	var texture_path := "res://assets/ui/rune_frame_parchment.svg" if parchment else ("res://assets/ui/rune_frame_crimson.svg" if crimson else "res://assets/ui/rune_frame.svg")
	value.texture = load(texture_path)
	value.patch_margin_left = 12
	value.patch_margin_top = 12
	value.patch_margin_right = 12
	value.patch_margin_bottom = 12
	value.position = at
	value.size = dimensions
	owner.add_child(value)
	return value

static func text(owner: Node, value: String, at: Vector2, dimensions: Vector2, size := 12, color := DarkTheme.TEXT) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size = dimensions
	DarkTheme.label(label, size, color)
	owner.add_child(label)
	return label

static func action(owner: Node, value: String, at: Vector2, dimensions: Vector2, callback: Callable, accent := DarkTheme.BRONZE) -> Button:
	var button := Button.new()
	button.text = value
	button.position = at
	button.size = dimensions
	DarkTheme.button(button, accent)
	button.pressed.connect(callback)
	owner.add_child(button)
	return button

static func slot(owner: Node, at: Vector2, source: String, index: int, item_id: int = 0, accepted := "") -> ItemSlot:
	var value := SLOT_SCENE.instantiate() as ItemSlot
	value.position = at
	value.destination = source
	value.slot_index = index
	value.accepted_slot = accepted
	value.set_item(item_id)
	owner.add_child(value)
	return value

static func navigation(owner: Node, callback: Callable) -> void:
	var items: Array[Array] = [["Baú", "stash", "icon_chest"], ["Herói", "hero", "icon_skills"], ["Talentos", "hero", "icon_talents"], ["Cubo", "cube", "icon_cube"], ["Loja", "shop", "icon_shop"]]
	for index: int in range(items.size()):
		var data: Array = items[index]
		var button := TextureButton.new()
		button.position = Vector2(92 + index * 92, 316)
		button.size = Vector2(82, 42)
		button.texture_normal = load("res://assets/ui/octagon_normal.svg")
		button.texture_hover = load("res://assets/ui/octagon_hover.svg")
		button.texture_pressed = load("res://assets/ui/octagon_pressed.svg")
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.pressed.connect(callback.bind(str(data[1])))
		owner.add_child(button)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/ui/%s.svg" % data[2])
		icon.position = Vector2(29, 2)
		icon.size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		var label := Label.new()
		label.text = str(data[0])
		label.position = Vector2(0, 26)
		label.size = Vector2(82, 12)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 8)
		label.add_theme_color_override("font_color", DarkTheme.TEXT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)

static func open_module(owner: Node, module: String) -> void:
	var root := owner
	var existing := root.get_node_or_null("ActiveModule")
	if existing != null: existing.queue_free()
	var paths := {"stash": "res://scenes/ui/inventory_stash.tscn", "hero": "res://scenes/ui/hero_panel.tscn", "cube": "res://scenes/ui/cube_synthesizer.tscn", "shop": "res://scenes/ui/shop_panel.tscn"}
	if not paths.has(module): return
	var instance := (load(str(paths[module])) as PackedScene).instantiate()
	instance.name = "ActiveModule"
	root.add_child(instance)
