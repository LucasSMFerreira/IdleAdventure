class_name StageManager
extends Node2D

signal wave_started(floor_number: int, stage_number: int, cycle_number: int, encounter: String)
signal enemy_died(kind: String)
signal stage_cleared(floor_number: int, stage_number: int)
signal floor_transition_started(from_floor: int, to_floor: int)
signal tower_finished
signal heal_requested(amount: int)
signal reposition_requested(destination: Vector2)
signal ground_impact

const DIFFICULTY_MULTIPLIERS: Array[float] = [1.0, 2.5, 5.0, 10.0]
@export var enemy_scene: PackedScene
@export var player_path := NodePath("../Player")
var floor_number := 1
var stage_number := 1
var cycle_number := 1
var active := false
var advancing := false
@onready var player: Player = get_node(player_path) as Player

func difficulty_multiplier() -> float:
	var game_state: Node = get_node_or_null("/root/EstadoJogo")
	var selected: int = int(game_state.get("difficulty_selected")) if game_state != null else 0
	return DIFFICULTY_MULTIPLIERS[clampi(selected, 0, 3)]

func configure(floor_value: int, stage_value: int) -> void:
	floor_number = clampi(floor_value, 1, Progressao.TOTAL_ANDARES)
	stage_number = clampi(stage_value, 1, Progressao.FASES_POR_ANDAR)
	cycle_number = 1

func _physics_process(_delta: float) -> void:
	if active and not advancing and not player.derrotado and player.position.x >= 900.0 and get_tree().get_nodes_in_group("enemy").is_empty():
		advancing = true
		advance.call_deferred()

func advance() -> void:
	if cycle_number < Progressao.CICLOS_POR_FASE:
		cycle_number += 1
		heal_requested.emit(4)
	else:
		stage_cleared.emit(floor_number, stage_number)
		if floor_number == Progressao.TOTAL_ANDARES and stage_number == Progressao.FASES_POR_ANDAR:
			active = false
			tower_finished.emit()
			return
		cycle_number = 1
		if stage_number < Progressao.FASES_POR_ANDAR:
			stage_number += 1
		else:
			floor_transition_started.emit(floor_number, floor_number + 1)
			stage_number = 1
			floor_number += 1
		heal_requested.emit(player.vida_maxima)
	reposition_requested.emit(Vector2(100, 240))
	spawn_wave()
	advancing = false

func spawn_wave() -> void:
	active = true
	var encounter := "normal"
	if cycle_number == Progressao.CICLOS_POR_FASE:
		var guards := Progressao.guardas_de_chefe(floor_number, stage_number)
		for index: int in range(guards):
			var x := 450 if guards == 1 else 350 + roundi(350.0 * index / (guards - 1))
			_spawn_enemy(x, Progressao.vida_inimigo(floor_number, stage_number), Progressao.dano_inimigo(floor_number), "normal", _normal_species(index))
		encounter = "boss" if stage_number == Progressao.FASES_POR_ANDAR else "mini"
		_spawn_enemy(850, Progressao.vida_chefe(floor_number, stage_number), Progressao.dano_chefe(floor_number, stage_number), encounter)
	else:
		var count := Progressao.quantidade_inimigos(floor_number, stage_number, cycle_number)
		for index: int in range(count):
			var x := 350 + roundi(500.0 * index / maxi(count - 1, 1))
			_spawn_enemy(x, Progressao.vida_inimigo(floor_number, stage_number), Progressao.dano_inimigo(floor_number), "normal", _normal_species(index))
	wave_started.emit(floor_number, stage_number, cycle_number, encounter)

func reset_stage() -> void:
	for child: Node in get_children():
		if child is Enemy: child.queue_free()
	await get_tree().process_frame
	cycle_number = 1
	reposition_requested.emit(Vector2(100, 240))
	spawn_wave()

func _normal_species(index: int) -> String:
	var species: Array[String] = ["enemy_slime", "enemy_goblin", "enemy_skeleton"]
	return species[(floor_number + stage_number + cycle_number + index) % species.size()]

func _spawn_enemy(x: int, health: int, damage: int, kind: String, species := "enemy_slime") -> void:
	var enemy := enemy_scene.instantiate() as Enemy
	var multiplier := difficulty_multiplier()
	enemy.configurar(roundi(health * multiplier), roundi(damage * multiplier), kind, species)
	add_child(enemy)
	enemy.position = Vector2(x, 240)
	enemy.died.connect(func() -> void: enemy_died.emit(kind))
	enemy.ground_impact.connect(func() -> void: ground_impact.emit())

