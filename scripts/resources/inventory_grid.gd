class_name InventoryGrid
extends Resource

@export_range(1, 20) var columns: int = 6
@export_range(1, 20) var rows: int = 6
@export var slot_ids: Array[int] = []

func capacity() -> int:
    return columns * rows

func normalize() -> void:
    slot_ids.resize(capacity())

func item_at(index: int) -> int:
    return slot_ids[index] if index >= 0 and index < slot_ids.size() else 0

func first_empty() -> int:
    for index: int in range(capacity()):
        if item_at(index) == 0:
            return index
    return -1

func add(item_id: int) -> bool:
    if item_id <= 0 or slot_ids.has(item_id):
        return false
    var index: int = first_empty()
    if index == -1:
        return false
    slot_ids[index] = item_id
    return true

func remove(item_id: int) -> bool:
    var index: int = slot_ids.find(item_id)
    if index < 0:
        return false
    slot_ids[index] = 0
    return true

func move(source: int, target: int) -> bool:
    if source < 0 or source >= capacity() or target < 0 or target >= capacity():
        return false
    var previous: int = slot_ids[target]
    slot_ids[target] = slot_ids[source]
    slot_ids[source] = previous
    return true

func occupied_ids() -> Array[int]:
    var result: Array[int] = []
    for item_id: int in slot_ids:
        if item_id > 0:
            result.append(item_id)
    return result
