class_name StateMachine
extends Node

signal state_changed(current: StringName)
signal action_requested(action: StringName)

@export var initial_state: StringName = &"Walk"
var current: State

func _ready() -> void:
    for child: Node in get_children():
        if child is State:
            var state: State = child as State
            state.action_requested.connect(func(action: StringName) -> void: action_requested.emit(action))
            state.transition_requested.connect(transition_to)
    transition_to(initial_state)

func _physics_process(delta: float) -> void:
    if current != null:
        current.physics_update(delta)

func transition_to(destination: StringName) -> void:
    if current != null and current.name == destination:
        return
    var next: State = get_node_or_null(NodePath(destination)) as State
    if next == null:
        push_error("Estado desconhecido: %s" % destination)
        return
    if current != null:
        current.exit()
    current = next
    current.enter()
    state_changed.emit(destination)

func is_in(name: StringName) -> bool:
    return current != null and current.name == name
