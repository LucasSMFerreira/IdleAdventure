extends SceneTree

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var save: Node = root.get_node("EstadoJogo")
    save.caminho_save = "user://production_combat_codex.json"
    save.andar_escolhido = 1
    save.fase_escolhida = 1
    save.nivel = 1
    save.xp_atual = 0
    save.gold = 0
    save.inventario = []
    save.equipados = {"arma": 0, "arma_secundaria": 0, "cabeca": 0, "peito": 0, "pernas": 0, "luvas": 0, "acessorio": 0}
    var game: Node2D = load("res://scenes/world/wildlands_road.tscn").instantiate() as Node2D
    root.add_child(game)
    var player: Player = game.get_node("Player") as Player
    var stage: StageManager = game.get_node("StageManager") as StageManager
    stage.active = false
    player.velocidade = 0.0
    for mob: Node in get_nodes_in_group("enemy"):
        mob.queue_free()
    await process_frame
    var enemy: Enemy = load("res://scenes/enemy.tscn").instantiate() as Enemy
    enemy.configurar(20, 0)
    stage.add_child(enemy)
    enemy.position = Vector2(300, 240)
    await create_timer(0.15).timeout
    var before: int = enemy.vida_atual
    player.alvo = enemy
    player.inimigo_perto = true
    player._atacar()
    await create_timer(0.75).timeout
    assert(enemy.vida_atual == before, "A Hitbox nao pode acertar fora de alcance")
    enemy.position = Vector2(145, 240)
    await create_timer(0.25).timeout
    assert(player.machado_hitbox.get_overlapping_areas().has(enemy.hurtbox), "Hurtbox proxima precisa sobrepor")
    player._atacar()
    await create_timer(0.75).timeout
    assert(enemy.vida_atual < before, "Machado deveria aplicar dano pela Hurtbox")
    var death_counter: Dictionary = {"value": 0}
    enemy.died.connect(func() -> void: death_counter["value"] += 1)
    enemy.receber_dano(100)
    assert(enemy.vida_atual == 0 and death_counter["value"] == 1)
    player.inimigo_perto = false
    player.alvo = null
    stage.configure(1, 10)
    stage.cycle_number = 3
    stage.spawn_wave()
    var boss_found: bool = false
    for mob: Node in stage.get_children():
        if mob is Enemy and (mob as Enemy).tipo == "boss":
            boss_found = true
    assert(boss_found, "A fase 10 precisa ter Rei Orc")
    print("PRODUCTION COMBAT OK: miss, hit, death, boss")
    DirAccess.remove_absolute(ProjectSettings.globalize_path(save.caminho_save))
    quit()
