class_name ParallaxDriver
extends ParallaxBackground

@export var player_path: NodePath = NodePath("../Player")
@export var acceleration: float = 4.0
var scroll_velocity: float = 0.0

@onready var player: Player = get_node(player_path) as Player

func _process(delta: float) -> void:
    scroll_velocity = move_toward(scroll_velocity, player.velocity.x, acceleration * player.stats.move_speed * delta)
    scroll_offset.x -= scroll_velocity * delta * 0.08
