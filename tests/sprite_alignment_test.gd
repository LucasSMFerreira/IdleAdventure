extends SceneTree

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var feet: Dictionary = {
        "barbarian": 60,
        "enemy_slime": 58,
        "enemy_goblin": 59,
        "enemy_skeleton": 59,
        "miniboss_orc": 60,
        "boss_orc_king": 60,
    }
    var stats_names: Array[String] = ["barbarian", "slime", "goblin", "skeleton", "orc_warrior", "orc_king"]
    for stats_name: String in stats_names:
        var stats: CharacterStats = load("res://scripts/resources/%s.tres" % stats_name) as CharacterStats
        assert(stats != null and stats.max_health > 0 and stats.attack_range > 0.0)
    for species: String in feet:
        var image: Image = (load("res://assets/sprites/%s_idle_sheet.svg" % species) as Texture2D).get_image()
        for frame: int in range(image.get_width() / 64):
            var bottom: int = -1
            for y: int in range(64):
                for x: int in range(frame * 64, frame * 64 + 64):
                    if image.get_pixel(x, y).a > 0.05:
                        bottom = y
            assert(absi(bottom - feet[species]) <= 1, "Frame inconsistente: %s #%d" % [species, frame])
    var player: Player = load("res://scenes/player.tscn").instantiate() as Player
    root.add_child(player)
    assert(player.visual.offset.y == 32 - feet["barbarian"])
    assert(player.hurtbox.collision_layer == 2 and player.machado_hitbox.collision_layer == 8)
    assert(player.machado_hitbox.target_layer == 4)
    player.queue_free()
    for species: String in ["enemy_slime", "enemy_goblin", "enemy_skeleton", "miniboss_orc", "boss_orc_king"]:
        var enemy: Enemy = load("res://scenes/enemy.tscn").instantiate() as Enemy
        enemy.configurar(10, 1, "boss" if species == "boss_orc_king" else ("mini" if species == "miniboss_orc" else "normal"), species)
        root.add_child(enemy)
        assert(enemy.visual.offset.y == 32 - feet[species])
        assert(enemy.hurtbox.collision_layer == 4 and enemy.hitbox.collision_layer == 8)
        assert(enemy.hitbox.target_layer == 2)
        enemy.queue_free()
    print("SPRITE FEET AND LAYERS OK")
    quit()
