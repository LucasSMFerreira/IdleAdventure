class_name Hitbox
extends Area2D

signal attack_landed(target: Hurtbox)

@export var damage: int = 1
@export var target_layer: int = 4
var active: bool = false

func _ready() -> void:
    collision_layer = 8
    collision_mask = target_layer
    monitoring = true
    monitorable = false

func strike() -> void:
    if not active:
        return
    var hit: Dictionary = {}
    for area: Area2D in get_overlapping_areas():
        if area is Hurtbox and not hit.has(area):
            var target: Hurtbox = area as Hurtbox
            if target.current_health > 0:
                hit[target] = true
                target.damage(damage)
                attack_landed.emit(target)
