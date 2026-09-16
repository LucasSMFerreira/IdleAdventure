class_name Hurtbox
extends Area2D

signal health_changed(current: int, maximum: int)
signal died
signal damaged(amount: int)

@export var stats: CharacterStats
var current_health: int = 0
var maximum_health: int = 1

func _ready() -> void:
    collision_layer = 2 if owner != null and owner.is_in_group("player") else 4
    collision_mask = 0
    if stats != null:
        configure(stats.max_health)

func configure(health: int, preserve_ratio: bool = false) -> void:
    var previous_max: int = maximum_health
    var previous_health: int = current_health
    maximum_health = maxi(health, 1)
    current_health = clampi(roundi(float(previous_health) * maximum_health / previous_max) if preserve_ratio else maximum_health, 0, maximum_health)
    health_changed.emit(current_health, maximum_health)

func damage(amount: int) -> void:
    if current_health <= 0 or amount <= 0:
        return
    current_health = maxi(current_health - amount, 0)
    health_changed.emit(current_health, maximum_health)
    damaged.emit(amount)
    if current_health == 0:
        died.emit()

func heal(amount: int) -> void:
    if current_health <= 0:
        return
    current_health = mini(current_health + maxi(amount, 0), maximum_health)
    health_changed.emit(current_health, maximum_health)
