extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Node = root.get_node("EstadoJogo")
	state.caminho_save = "user://ui_systems_codex.json"
	state.inventario = []
	state.gold = 5000
	state.proximo_item_id = 1
	state.stash_tab_ids = []
	state.bag_ids.clear()
	state.equipados = {"arma":0, "arma_secundaria":0, "cabeca":0, "peito":0, "pernas":0, "luvas":0, "acessorio":0, "amuleto":0, "anel_1":0, "anel_2":0, "insignia":0}
	var store: Node = root.get_node("InventoryStore")
	store.load_layout()
	var ids: Array[int] = []
	for _index: int in range(9):
		ids.append(state.adicionar_item(Itens.criar_item(1, "arma", 0)))
	assert(store.stash[0].occupied_ids().size() == 9, "New drops must enter stash")
	assert(state.synthesize_nine(ids, true) > 0, "Nine equal items should synthesize")
	assert(state.inventario.size() == 1, "Synthesis must consume exactly nine items")
	assert(int(state.inventario[0].qualidade) == 1, "Synthesis must raise rarity")
	assert(store.stash[0].occupied_ids().size() == 1, "Crafted result must return to stash")
	for path: String in ["res://scripts/resources/items/axe.tres", "res://scripts/resources/items/helm.tres", "res://scripts/resources/items/ring.tres", "res://scripts/resources/items/ore.tres"]:
		assert(load(path) is ItemData, "Item template failed: " + path)
	state.set_difficulty(3)
	assert(state.difficulty_selected == 3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.caminho_save))
	print("UI SYSTEMS OK: stash, item resources, synthesis, difficulty")
	quit()
