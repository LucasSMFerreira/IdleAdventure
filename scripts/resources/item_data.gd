class_name ItemData
extends Resource

enum ItemType { WEAPON, ARMOR, ACCESSORY, MATERIAL }
enum Rarity { COMMON, RARE, EPIC, LEGENDARY }

@export var id: int = 0
@export var name: String = ""
@export var icon: Texture2D
@export var item_type: ItemType = ItemType.ARMOR
@export var rarity: Rarity = Rarity.COMMON
@export var level_req: int = 1
@export var stats_bonus: Dictionary = {}
@export var can_stack: bool = false
@export var quantity: int = 1
@export var equipment_slot: String = ""
@export var floor: int = 1
@export var tier: int = 1
@export var legendary_quality_pct: int = 0
@export var allowed_classes: Array[String] = []
@export var unique: bool = false

const ICONS: Dictionary = {
    "arma": "res://assets/items/arma.svg",
    "arma_secundaria": "res://assets/items/arma_secundaria.svg",
    "cabeca": "res://assets/items/cabeca.svg",
    "peito": "res://assets/items/peito.svg",
    "pernas": "res://assets/items/pernas.svg",
    "luvas": "res://assets/items/luvas.svg",
    "acessorio": "res://assets/items/acessorio.svg",
    "botas": "res://assets/items/pernas.svg",
    "amuleto": "res://assets/items/acessorio.svg",
    "anel": "res://assets/items/acessorio.svg",
    "insignia": "res://assets/items/acessorio.svg",
}

static func from_legacy(record: Dictionary) -> ItemData:
    var result: ItemData = ItemData.new()
    result.id = int(record.get("id", 0))
    result.name = str(record.get("nome", "Item"))
    result.equipment_slot = str(record.get("slot", ""))
    result.floor = maxi(1, int(record.get("andar", 1)))
    result.tier = result.floor
    result.level_req = maxi(1, int(record.get("nivel", 1)))
    result.rarity = clampi(int(record.get("qualidade", 0)), 0, 3)
    result.legendary_quality_pct = int(record.get("qualidade_pct", 0)) if result.rarity == Rarity.LEGENDARY else 0
    result.stats_bonus = {"health": int(record.get("bonus_vida", 0)), "attack": int(record.get("bonus_ataque", 0))}
    result.quantity = maxi(1, int(record.get("quantidade", 1)))
    result.can_stack = bool(record.get("empilhavel", false))
    result.unique = bool(record.get("unico", false))
    result.allowed_classes.assign(record.get("classes", []))
    if result.equipment_slot in ["arma", "arma_secundaria"]:
        result.item_type = ItemType.WEAPON
    elif result.equipment_slot in ["acessorio", "amuleto", "anel", "insignia"]:
        result.item_type = ItemType.ACCESSORY
    elif result.equipment_slot == "material":
        result.item_type = ItemType.MATERIAL
    else:
        result.item_type = ItemType.ARMOR
    var icon_path: String = str(ICONS.get(result.equipment_slot, "res://assets/ui/icon_cube.svg"))
    result.icon = load(icon_path) as Texture2D
    return result

func to_legacy() -> Dictionary:
    var record: Dictionary = {
        "id": id, "nome": name, "slot": equipment_slot, "andar": floor,
        "nivel": level_req, "qualidade": int(rarity),
        "bonus_vida": int(stats_bonus.get("health", 0)),
        "bonus_ataque": int(stats_bonus.get("attack", 0)),
    }
    if rarity == Rarity.LEGENDARY:
        record["qualidade_pct"] = legendary_quality_pct
    if quantity > 1:
        record["quantidade"] = quantity
    if can_stack:
        record["empilhavel"] = true
    if unique:
        record["unico"] = true
    if not allowed_classes.is_empty():
        record["classes"] = allowed_classes
    return record

func can_equip(hero_class: String, hero_level: int, slot: String) -> bool:
    if hero_level < level_req or not allowed_classes.is_empty() and not allowed_classes.has(hero_class):
        return false
    if slot == equipment_slot:
        return true
    return equipment_slot == "acessorio" and slot in ["amuleto", "anel_1", "anel_2", "insignia"]
