extends CanvasLayer

signal equipamento_mudou

@onready var lista: VBoxContainer = $Painel/Lista/Itens
@onready var slots: VBoxContainer = $Painel/Equipados

func _ready():
	_atualizar()

func _atualizar():
	for linha in slots.get_children():
		linha.free()
	for linha in lista.get_children():
		linha.free()
	for slot in Itens.SLOTS:
		var item = EstadoJogo.item_equipado(slot)
		var linha = Label.new()
		linha.custom_minimum_size = Vector2(365, 23)
		linha.text = "%s: %s" % [Itens.PARTES[slot], item.get("nome", "vazio")]
		linha.modulate = Color(0.6, 1.0, 0.7) if not item.is_empty() else Color(0.8, 0.8, 0.8)
		slots.add_child(linha)
	if EstadoJogo.inventario.is_empty():
		var aviso = Label.new()
		aviso.text = "Nenhum item ainda."
		lista.add_child(aviso)
	for item in EstadoJogo.inventario:
		var linha = HBoxContainer.new()
		var descricao = Label.new()
		descricao.custom_minimum_size = Vector2(265, 35)
		descricao.text = "%s\n+%d HP  +%d ATK" % [item["nome"], int(item["bonus_vida"]), int(item["bonus_ataque"])]
		linha.add_child(descricao)
		var botao = Button.new()
		botao.custom_minimum_size = Vector2(90, 35)
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
