extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Node = root.get_node("EstadoJogo")
	state.caminho_save = "user://hero_inventory_modal_codex_test.json"
	state.maior_fase_liberada = 1
	state.andar_escolhido = 1
	state.fase_escolhida = 1
	state.nivel = 20
	state.gold = 5000
	state.inventario = []
	state.stash_tab_ids = []
	state.bag_ids.clear()
	state.proximo_item_id = 1
	state.active_class = "Bárbaro"
	state.equipados = {"arma":0,"arma_secundaria":0,"cabeca":0,"peito":0,"pernas":0,"luvas":0,"acessorio":0,"amuleto":0,"anel_1":0,"anel_2":0,"insignia":0,"brinco":0,"anel":0}
	var store: Node = root.get_node("InventoryStore")
	store.load_layout()
	var material: Dictionary = {"nome":"Minério de teste","slot":"material","andar":1,"nivel":1,"qualidade":0,"quantidade":1200,"empilhavel":true}
	var first_stack: int = state.adicionar_item(material)
	assert(state.inventario.size() == 2)
	assert(int(state.inventario[0].quantidade) == 999)
	assert(int(state.inventario[1].quantidade) == 201)
	var restricted: Dictionary = Itens.criar_item(1, "arma", 0)
	restricted["class_restriction"] = "Arqueira"
	var restricted_id: int = state.adicionar_item(restricted)
	var restricted_data: ItemData = ItemData.from_legacy(state.item_por_id(restricted_id))
	assert(not restricted_data.can_equip("Bárbaro", state.nivel, "arma"))
	assert(restricted_data.can_equip("Arqueira", state.nivel, "arma"))
	var game: Node2D = (load("res://scenes/world/wildlands_road.tscn") as PackedScene).instantiate() as Node2D
	root.add_child(game)
	game._on_inventario_pressed()
	var modal: CanvasLayer = game.get_node("PainelBau") as CanvasLayer
	assert(modal.process_mode == Node.PROCESS_MODE_ALWAYS)
	assert((modal.get("equipment_cells") as Dictionary).size() == 7)
	assert((modal.get("inventory_grid") as GridContainer).get_child_count() == 21)
	var before: float = (game.get_node("Player") as Player).position.x
	await create_timer(0.4).timeout
	var after: float = (game.get_node("Player") as Player).position.x
	assert(after > before, "Gameplay must continue under modal")
	modal.call("_change_class", 1)
	assert(state.active_class == "Arqueira")
	assert(int(modal.get("current_class_index")) == 1)
	assert(state.equipar_no_slot(restricted_id, "arma"))
	var upgraded: bool = state.aprimorar_item(restricted_id)
	assert(upgraded)
	assert(int(state.item_por_id(restricted_id).get("aprimoramento", 0)) == 1)
	modal.call("_open_hub", "skills")
	assert((modal.get("skill_tree") as Control).visible)
	modal.call("_open_hub", "forge")
	assert(bool(modal.get("forge_mode")) and (modal.get("forge_controls") as Panel).visible)
	modal.call("close")
	await process_frame
	assert(game.get_node_or_null("PainelBau") == null)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.caminho_save))
	print("HERO MODAL OK: 7 slots, 21 cells, classes, restriction, stacks, forge, continuous combat")
	quit()
