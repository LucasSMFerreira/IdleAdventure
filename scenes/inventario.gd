extends CanvasLayer

signal equipamento_mudou

@onready var lista: VBoxContainer = $Painel/Lista/Itens
@onready var status: Label = $Painel/Status

func _ready():
	_atualizar()

func _atualizar():
	for linha in lista.get_children():
		linha.free()
	var nomes = []
	for slot in ["arma", "armadura", "acessorio"]:
		var item = EstadoJogo.item_equipado(slot)
		nomes.append("%s: %s" % [slot.capitalize(), item.get("nome", "vazio")])
	status.text = "  |  ".join(nomes)
	if EstadoJogo.inventario.is_empty():
		var aviso = Label.new()
		aviso.text = "Nenhum item ainda. Inimigos podem deixar drops."
		lista.add_child(aviso)
	for item in EstadoJogo.inventario:
		var linha = HBoxContainer.new()
		var descricao = Label.new()
		descricao.custom_minimum_size = Vector2(620, 32)
		descricao.text = "%s  |  +%d HP  +%d ATK" % [item["nome"], int(item["bonus_vida"]), int(item["bonus_ataque"])]
		linha.add_child(descricao)
		var botao = Button.new()
		botao.custom_minimum_size = Vector2(130, 32)
		botao.text = "Equipado" if int(EstadoJogo.equipados.get(item["slot"], 0)) == int(item["id"]) else "Equipar"
		botao.disabled = botao.text == "Equipado"
		botao.pressed.connect(_equipar.bind(int(item["id"])))
		linha.add_child(botao)
		lista.add_child(linha)

func _equipar(id: int):
	if EstadoJogo.equipar(id):
		equipamento_mudou.emit()
		_atualizar()

func _on_fechar_pressed():
	queue_free()
