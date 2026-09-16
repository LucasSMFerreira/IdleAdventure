extends CanvasLayer

var active_tab := 0
var stash_grid: GridContainer
var bag_grid: GridContainer
var heading: Label
var detail: Label

func _ready() -> void:
	layer = 20
	UIFactory.backdrop(self)
	var panel := UIFactory.frame(self, Vector2(8, 12), Vector2(624, 298))
	UIFactory.text(panel, "BAÚ DO AVENTUREIRO", Vector2(22, 8), Vector2(300, 24), 16, DarkTheme.GOLD)
	UIFactory.action(panel, "✕", Vector2(574, 8), Vector2(32, 24), queue_free, DarkTheme.CRIMSON)
	for index: int in range(7):
		UIFactory.action(panel, str(index + 1), Vector2(18 + index * 38, 38), Vector2(34, 24), _select_tab.bind(index))
	stash_grid = _grid(panel, Vector2(18, 70), true)
	bag_grid = _grid(panel, Vector2(328, 70), false)
	UIFactory.action(panel, "Pegar tudo", Vector2(18, 252), Vector2(92, 27), func() -> void: InventoryStore.take_all(active_tab))
	UIFactory.action(panel, "Guardar tudo", Vector2(116, 252), Vector2(98, 27), func() -> void: InventoryStore.store_all(active_tab))
	UIFactory.action(panel, "Organizar", Vector2(220, 252), Vector2(90, 27), _organize)
	detail = UIFactory.text(panel, "", Vector2(326, 250), Vector2(275, 30), 10)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	InventoryStore.layout_changed.connect(refresh)
	refresh()

func _grid(owner: Control, at: Vector2, is_stash: bool) -> GridContainer:
	var box := PanelContainer.new()
	box.position = at
	box.size = Vector2(278, 172)
	box.add_theme_stylebox_override("panel", DarkTheme.panel())
	owner.add_child(box)
	var column := VBoxContainer.new()
	box.add_child(column)
	var title := Label.new()
	title.name = "Heading"
	title.text = "BAÚ • ABA 1" if is_stash else "INVENTÁRIO"
	DarkTheme.label(title, 11, DarkTheme.GOLD)
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(262, 142)
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(grid)
	if is_stash: heading = title
	return grid

func refresh() -> void:
	if stash_grid == null: return
	heading.text = "BAÚ • ABA %d" % (active_tab + 1)
	_fill(stash_grid, InventoryStore.stash[active_tab], "stash:%d" % active_tab)
	_fill(bag_grid, InventoryStore.bag, "bag")
	detail.text = "%d itens • %d Gold" % [EstadoJogo.inventario.size(), EstadoJogo.gold]

func _fill(grid: GridContainer, data: InventoryGrid, source: String) -> void:
	for child: Node in grid.get_children(): child.queue_free()
	for index: int in range(data.capacity()):
		var cell := UIFactory.slot(grid, Vector2.ZERO, source, index, data.item_at(index))
		cell.quick_clicked.connect(_quick)
		cell.item_dropped.connect(_drop)

func _select_tab(index: int) -> void:
	active_tab = index
	refresh()

func _quick(item_id: int, source: String) -> void:
	InventoryStore.transfer(item_id, "bag" if source.begins_with("stash") else "stash:%d" % active_tab)

func _drop(item_id: int, destination: String, index: int) -> void:
	InventoryStore.transfer(item_id, destination, index)

func _organize() -> void:
	InventoryStore.organize("stash:%d" % active_tab)
	InventoryStore.organize("bag")
