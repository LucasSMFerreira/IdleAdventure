extends SceneTree
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var save: Node = root.get_node("EstadoJogo")
 save.caminho_save = "user://production_boss_codex.json"
 save.andar_escolhido = 1
 save.fase_escolhida = 1
 save.nivel = 1
 save.xp_atual = 0
 save.gold = 0
 save.inventario = []
 save.equipados = {"arma":0,"arma_secundaria":0,"cabeca":0,"peito":0,"pernas":0,"luvas":0,"acessorio":0}
 var game: Node2D = load("res://scenes/world/wildlands_road.tscn").instantiate()
 root.add_child(game)
 var stage: StageManager = game.get_node("StageManager")
 stage.active = false
 for mob: Node in get_nodes_in_group("enemy"): mob.queue_free()
 await process_frame
 var player: Player = game.get_node("Player")
 player.velocidade = 0.0
 player.dano = 0
 player.hurtbox.configure(100)
 var boss: Enemy = load("res://scenes/enemy.tscn").instantiate()
 boss.configurar(100, 1, "boss")
 stage.add_child(boss)
 boss.position = Vector2(150, 240)
 var counter: Dictionary = {"value":0}
 boss.ground_impact.connect(func() -> void: counter["value"] += 1)
 boss.ground_impact.connect(game.get_node("Camera").shake_ground)
 await create_timer(9.0).timeout
 assert(boss.ataques >= 3 and counter["value"] >= 1, "Rei Orc deveria executar Special")
 assert(player.vida_atual < 100, "Special deveria acertar pela Hurtbox")
 print("BOSS SPECIAL OK attacks=",boss.ataques," impacts=",counter["value"]," hp=",player.vida_atual)
 DirAccess.remove_absolute(ProjectSettings.globalize_path(save.caminho_save))
 quit()
