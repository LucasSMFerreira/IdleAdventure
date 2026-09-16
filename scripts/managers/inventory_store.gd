extends Node

signal layout_changed
signal item_transferred(item_id: int, from_place: String, to_place: String)

const TAB_COUNT: int = 7
const STASH_SIZE: int = 36
const BAG_SIZE: int = 36
var stash: Array[InventoryGrid] = []
var bag: InventoryGrid
var _syncing: bool = false

func _ready() -> void:
    bag = InventoryGrid.new()
    for _index: int in range(TAB_COUNT):
        var grid: InventoryGrid = InventoryGrid.new()
        stash.append(grid)
    load_layout()
    EstadoJogo.dados_mudaram.connect(_on_game_changed)

func load_layout() -> void:
    _syncing = true
    for index: int in range(TAB_COUNT):
        var source: Variant = EstadoJogo.stash_tab_ids[index] if index < EstadoJogo.stash_tab_ids.size() else []
        stash[index].slot_ids.clear()
        if source is Array:
            for value: Variant in source:
                stash[index].slot_ids.append(int(value))
        stash[index].normalize()
    bag.slot_ids.clear()
    for value: Variant in EstadoJogo.bag_ids:
        bag.slot_ids.append(int(value))
    bag.normalize()
    _sync_missing()
    _syncing = false
    layout_changed.emit()

func _on_game_changed() -> void:
    if not _syncing:
        _syncing = true
        _sync_missing()
        _syncing = false
        layout_changed.emit()

func _sync_missing() -> void:
    var valid: Dictionary = {}
    for record: Variant in EstadoJogo.inventario:
        if record is Dictionary:
            valid[int(record.get("id", 0))] = true
    var placed: Dictionary = {}
    for grid: InventoryGrid in stash + [bag]:
        for index: int in range(grid.slot_ids.size()):
            var item_id: int = grid.slot_ids[index]
            if item_id <= 0:
                continue
            if not valid.has(item_id) or placed.has(item_id):
                grid.slot_ids[index] = 0
            else:
                placed[item_id] = true
    for item_id: int in valid:
        if placed.has(item_id):
            continue
        var added: bool = false
        for grid: InventoryGrid in stash:
            if grid.add(item_id):
                added = true
                break
        if not added:
            if bag.first_empty() == -1:
                bag.rows += 1
                bag.normalize()
            bag.add(item_id)
    save_layout(false)

func save_layout(emit_change: bool = true) -> void:
    EstadoJogo.stash_tab_ids.clear()
    for grid: InventoryGrid in stash:
        EstadoJogo.stash_tab_ids.append(grid.slot_ids.duplicate())
    EstadoJogo.bag_ids = bag.slot_ids.duplicate()
    EstadoJogo.salvar()
    if emit_change:
        layout_changed.emit()

func grid_for(place: String) -> InventoryGrid:
    if place == "bag":
        return bag
    if place.begins_with("stash:"):
        var index: int = int(place.get_slice(":", 1))
        if index >= 0 and index < TAB_COUNT:
            return stash[index]
    return null

func locate(item_id: int) -> String:
    if bag.slot_ids.has(item_id):
        return "bag"
    for index: int in range(TAB_COUNT):
        if stash[index].slot_ids.has(item_id):
            return "stash:%d" % index
    return ""

func transfer(item_id: int, destination: String, target_index: int = -1) -> bool:
    var origin: String = locate(item_id)
    var from_grid: InventoryGrid = grid_for(origin)
    var to_grid: InventoryGrid = grid_for(destination)
    if from_grid == null or to_grid == null:
        return false
    var source_index: int = from_grid.slot_ids.find(item_id)
    if target_index == -1:
        target_index = to_grid.first_empty()
    if target_index < 0 or target_index >= to_grid.capacity():
        return false
    if origin == destination:
        from_grid.move(source_index, target_index)
    else:
        var replaced: int = to_grid.item_at(target_index)
        to_grid.slot_ids[target_index] = item_id
        from_grid.slot_ids[source_index] = replaced
    save_layout()
    item_transferred.emit(item_id, origin, destination)
    return true

func take_all(tab: int) -> int:
    var count: int = 0
    for item_id: int in stash[tab].occupied_ids():
        if transfer(item_id, "bag"):
            count += 1
    return count

func store_all(tab: int) -> int:
    var count: int = 0
    for item_id: int in bag.occupied_ids():
        if item_id in EstadoJogo.equipados.values():
            continue
        if transfer(item_id, "stash:%d" % tab):
            count += 1
    return count

func organize(place: String) -> void:
    var grid: InventoryGrid = grid_for(place)
    if grid == null:
        return
    var ids: Array[int] = grid.occupied_ids()
    ids.sort_custom(func(a: int, b: int) -> bool:
        var left: ItemData = ItemData.from_legacy(EstadoJogo.item_por_id(a))
        var right: ItemData = ItemData.from_legacy(EstadoJogo.item_por_id(b))
        if left.rarity != right.rarity:
            return left.rarity > right.rarity
        if left.item_type != right.item_type:
            return left.item_type < right.item_type
        return left.level_req > right.level_req
    )
    grid.slot_ids.fill(0)
    for index: int in range(ids.size()):
        grid.slot_ids[index] = ids[index]
    save_layout()

func remove_consumed(ids: Array[int]) -> void:
    for item_id: int in ids:
        var grid: InventoryGrid = grid_for(locate(item_id))
        if grid != null:
            grid.remove(item_id)
    save_layout()
