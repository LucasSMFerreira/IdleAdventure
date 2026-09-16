extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Node = root.get_node("EstadoJogo")
	state.caminho_save = "user://hero_improvements_codex_test.json"
	state.inventario = []
	state.gold = 5000
	state.nivel = 20
	state.proximo_item_id = 1
	state.active_class = "Bárbaro"
	state.stash_tab_ids = []
	state.bag_ids.clear()
	state.equipados = {"arma":0,"arma_secundaria":0,"cabeca":0,"peito":0,"pernas":0,"luvas":0,"acessorio":0,"amuleto":0,"anel_1":0,"anel_2":0,"insignia":0,"brinco":0,"anel":0}
	var store: Node = root.get_node("InventoryStore")
	store.load_layout()
	var weak_id: int = state.adicionar_item(Itens.criar_item(1, "arma", 0))
	var rare_id: int = state.adicionar_item(Itens.criar_item(1, "arma", 1))
	var material_id: int = state.adicionar_item({"nome":"Minério de teste","slot":"material","andar":1,"nivel":1,"qualidade":0,"quantidade":7,"empilhavel":true})
	var blocked: Dictionary = Itens.criar_item(1, "cabeca", 0)
	blocked["class_restriction"] = "Mago"
	var blocked_id: int = state.adicionar_item(blocked)
	for item_id: int in [weak_id, rare_id, material_id, blocked_id]:
		assert(store.transfer(item_id, "bag"))
	var game: Node2D = (load("res://scenes/world/wildlands_road.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(game)
	game._on_inventario_pressed()
	var modal: CanvasLayer = game.get_node("PainelBau") as CanvasLayer
	var search: LineEdit = modal.get("search_field") as LineEdit
	var filter: OptionButton = modal.get("type_filter") as OptionButton
	var sorter: OptionButton = modal.get("sort_selector") as OptionButton
	var bag: InventoryGrid = store.bag
	search.text = "Minério"
	modal.call("_reset_results")
	assert((modal.call("_visible_entries", bag) as Array).size() == 1, "Search must narrow results")
	search.text = ""
	filter.select(3)
	modal.call("_reset_results")
	assert((modal.call("_visible_entries", bag) as Array).size() == 1, "Material filter must narrow results")
	filter.select(0)
	sorter.select(1)
	modal.call("_reset_results")
	var sorted: Array = modal.call("_visible_entries", bag) as Array
	assert(int(sorted[0].id) == rare_id, "Rarity sort must put rare item first")
	sorter.select(0)
	modal.call("_reset_results")
	assert(state.equipar_no_slot(weak_id, "arma"))
	modal.call("_show_item_details", rare_id)
	var detail: Label = modal.get("detail_label") as Label
	assert(detail.text.contains("ΔHP"))
	assert(detail.text.contains("ATK"))
	modal.call("_quick_equip", blocked_id, "bag")
	assert(detail.text.contains("Classe incompatível"))
	modal.call("_open_hub", "forge")
	modal.call("_quick_equip", rare_id, "bag")
	var forge_detail: Label = modal.get("forge_description") as Label
	assert(forge_detail.text.contains("HP") and forge_detail.text.contains("Gold"))
	modal.call("_recycle_selected")
	assert(not state.item_por_id(rare_id).is_empty(), "Rare item needs confirmation")
	assert((modal.get("recycle_button") as Button).text == "Confirmar")
	modal.call("_recycle_selected")
	assert(state.item_por_id(rare_id).is_empty(), "Second action recycles item")
	game._write_battle_log("Evento A")
	game._write_battle_log("Evento B")
	game._write_battle_log("Evento C")
	assert(game.battle_log.text.contains("Evento B") and game.battle_log.text.contains("Evento C"))
	assert(not game.battle_log.text.contains("Evento A"))
	modal.call("_show_inventory")
	var input: InputEventKey = InputEventKey.new()
	input.keycode = KEY_B
	input.pressed = true
	modal.call("_unhandled_key_input", input)
	assert(str(modal.get("current_source")) == "stash:0", "Keyboard shortcut must open stash")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.caminho_save))
	print("HERO IMPROVEMENTS OK: search, filters, sort, comparison, forge preview, recycle confirmation, log, keyboard")
	quit()

