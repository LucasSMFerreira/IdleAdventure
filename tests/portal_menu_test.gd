extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Node = root.get_node("EstadoJogo")
	state.caminho_save = "user://portal_menu_codex.json"
	state.maior_fase_liberada = 13
	state.andar_escolhido = 2
	state.fase_escolhida = 3
	var scene := load("res://scenes/ui/portal_map.tscn") as PackedScene
	var menu := scene.instantiate()
	root.add_child(menu)
	await process_frame
	assert(menu.shown_floor == 2 and menu.selected_stage == 3, "Menu should remember the current phase")
	assert(menu.next_floor_button.disabled, "Locked floors should not be navigable")
	assert(menu.nodes[3].disabled, "Locked stages should not be selectable")
	menu.previous_floor_button.pressed.emit()
	assert(menu.shown_floor == 1 and menu.selected_stage == 10, "Previous floor should select its last unlocked phase")
	menu.next_floor_button.pressed.emit()
	menu.nodes[1].pressed.emit()
	assert(menu.shown_floor == 2 and menu.selected_stage == 2, "Selecting a stage should update the active destination")
	assert(menu.enter_button.tooltip_text.contains("2-2"), "Entry action should show the selected destination")
	menu.queue_free()
	print("PORTAL MENU OK: floor limits, unlocked stages and destination selection")
	quit()
