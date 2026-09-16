class_name CameraFeedback
extends Camera2D

@export var player_path: NodePath = NodePath("../Player")
var impact_time: float = 0.0
var chest_open: bool = false
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var player: Player = get_node(player_path) as Player

func _ready() -> void:
    enabled = true
    rng.randomize()

func _process(delta: float) -> void:
    var destination_x: float = clampf(player.position.x, 320.0, 680.0)
    var destination_y: float = 70.0 if chest_open else 180.0
    global_position = global_position.lerp(Vector2(destination_x, destination_y), minf(1.0, delta * 5.0))
    if impact_time > 0.0:
        impact_time = maxf(impact_time - delta, 0.0)
        var strength: float = impact_time / 0.22
        offset = Vector2(rng.randf_range(-3.0, 3.0), rng.randf_range(-2.0, 2.0)) * strength
    else:
        offset = offset.move_toward(Vector2.ZERO, delta * 24.0)

func shake_ground() -> void:
    impact_time = 0.22
