class_name State
extends Node

signal action_requested(action: StringName)
signal transition_requested(destination: StringName)

@export var animation: StringName = &"idle"
@export var duration: float = 0.0
@export var next_state: StringName = &""
@export var move: bool = false

var elapsed: float = 0.0

func enter() -> void:
    elapsed = 0.0
    action_requested.emit(animation)

func exit() -> void:
    pass

func physics_update(delta: float) -> void:
    if move:
        action_requested.emit(&"move")
    if duration > 0.0:
        elapsed += delta
        if elapsed >= duration and not next_state.is_empty():
            transition_requested.emit(next_state)
