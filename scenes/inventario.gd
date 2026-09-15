extends CanvasLayer

signal equipamento_mudou

const BOTOES = {
	"arma": "Arma",
	"arma_secundaria": "ArmaSecundaria",
	"cabeca": "Cabeca",
	"peito": "Peito",
	"pernas": "Pernas",
	"luvas": "Luvas",
	"acessorio": "Acessorio",
}
const CORES = [
	Color(0.42, 0.43, 0.47),
	Color(0.25, 0.57, 0.85),
	Color(0.64, 0.34, 0.86),
	Color(0.95, 0.72, 0.22),
]

@onready var grade: GridContainer = $Bau/Grade/Itens
@onready var filtro_parte: OptionButton = $Bau/FiltroParte
@onready var filtro_qualidade: OptionButton = $Bau/FiltroQualidade
@onready var filtro_andar: OptionButton = $Bau/FiltroAndar
@onready var so_melhores: CheckButton = $Bau/SoMelhores
@onready var contagem: Label = $Bau/Contagem
@onready var detalhe: Label = $Bau/Detalhe
@onready var equipar_botao: Button = $Bau/Equipar

var selecionado_id = 0

func _ready():
	filtro_parte.add_item("Parte")
	for slot in Itens.SLOTS:
		filtro_parte.add_item("Arma 2" if slot == "arma_secundaria" else Itens.PARTES[slot])
	filtro_qualidade.add_item("Qualid.")
	for qualidade in Itens.QUALIDADES:
		filtro_qualidade.add_item(qualidade)
	filtro_andar.add_item("Andar")
	for andar in range(1, Progressao.TOTAL_ANDARES + 1):
		filtro_andar.add_item("Andar %d" % andar)
	filtro_parte.item_selected.connect(_filtros_mudaram)
	filtro_qualidade.item_selected.connect(_filtros_mudaram)
	filtro_andar.item_selected.connect(_filtros_mudaram)
	so_melhores.toggled.connect(_melhores_mudou)
	equipar_botao.pressed.connect(_equipar_selecionado)
	for slot in BOTOES:
		get_node("Equipamento/" + BOTOES[slot]).pressed.connect(_selecionar_equipado.bind(slot))
	_atualizar()

func _cor_item(item: Dictionary) -> Color:
	return CORES[clampi(int(item.get("qualidade", 0)), 0, CORES.size() - 1)]

func _estilizar(botao: Button, cor: Color, marcado: bool = false):
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = cor.darkened(0.68)
	estilo.border_color = cor
	estilo.set_border_width_all(3 if marcado else 2)
	estilo.set_corner_radius_all(3)
	botao.add_theme_stylebox_override("normal", estilo)
	var hover = estilo.duplicate()
	hover.bg_color = cor.darkened(0.43)
	botao.add_theme_stylebox_override("hover", hover)
	botao.add_theme_color_override("font_color", Color.WHITE)

func _atualizar():
	_atualizar_equipados()
	_atualizar_bau()

func _atualizar_equipados():
	$Equipamento/Nivel.text = "Nível %d" % EstadoJogo.nivel
	$Equipamento/Status.text = "Bônus: +%d HP  +%d ATK" % [EstadoJogo.bonus_vida(), EstadoJogo.bonus_ataque()]
	for slot in Itens.SLOTS:
		var botao: Button = get_node("Equipamento/" + BOTOES[slot])
		var item = EstadoJogo.item_equipado(slot)
		var titulo = "Arma 2" if slot == "arma_secundaria" else Itens.PARTES[slot]
		botao.text = "%s: %s" % [titulo, Itens.QUALIDADES[clampi(int(item.get("qualidade", 0)), 0, 3)] if not item.is_empty() else "vazio"]
		botao.tooltip_text = _descricao(item) if not item.is_empty() else "%s: vazio" % titulo
		_estilizar(botao, _cor_item(item) if not item.is_empty() else Color(0.35, 0.35, 0.38), not item.is_empty())

func _itens_visiveis() -> Array:
	var visiveis: Array = []
	for item in EstadoJogo.inventario:
		if not item is Dictionary:
			continue
		if filtro_parte.selected > 0 and item.get("slot", "") != Itens.SLOTS[filtro_parte.selected - 1]:
			continue
		if filtro_qualidade.selected > 0 and int(item.get("qualidade", 0)) != filtro_qualidade.selected - 1:
			continue
		if filtro_andar.selected > 0 and int(item.get("andar", 1)) != filtro_andar.selected:
			continue
		visiveis.append(item)
	if so_melhores.button_pressed:
		var melhores = {}
		for item in visiveis:
			var chave = "%s_%d" % [item.get("slot", ""), int(item.get("andar", 1))]
			var anterior = melhores.get(chave, {})
			if anterior.is_empty() or int(item.get("qualidade", 0)) > int(anterior.get("qualidade", 0)) or (int(item.get("qualidade", 0)) == int(anterior.get("qualidade", 0)) and int(item.get("id", 0)) > int(anterior.get("id", 0))):
				melhores[chave] = item
		visiveis = melhores.values()
	visiveis.sort_custom(func(a, b): return int(a.get("id", 0)) > int(b.get("id", 0)))
	return visiveis

func _atualizar_bau():
	for botao in grade.get_children():
		grade.remove_child(botao)
		botao.queue_free()
	var visiveis = _itens_visiveis()
	var existe = false
	for item in visiveis:
		if int(item.get("id", 0)) == selecionado_id:
			existe = true
		var botao = Button.new()
		botao.custom_minimum_size = Vector2(62, 56)
		var parte = Itens.PARTES.get(item.get("slot", ""), "Item")
		botao.text = "%s\n%s" % [parte.substr(0, 5), Itens.QUALIDADES[clampi(int(item.get("qualidade", 0)), 0, 3)].substr(0, 4)]
		botao.tooltip_text = _descricao(item)
		_estilizar(botao, _cor_item(item), int(item.get("id", 0)) == selecionado_id)
		botao.pressed.connect(_selecionar.bind(int(item.get("id", 0))))
		grade.add_child(botao)
	if not existe:
		selecionado_id = 0
	contagem.text = "%d itens guardados  |  %d exibidos" % [EstadoJogo.inventario.size(), visiveis.size()]
	_atualizar_detalhe()

func _buscar(id: int) -> Dictionary:
	for item in EstadoJogo.inventario:
		if item is Dictionary and int(item.get("id", 0)) == id:
			return item
	return {}

func _descricao(item: Dictionary) -> String:
	return "%s  |  +%d HP  +%d ATK" % [item.get("nome", "Item"), int(item.get("bonus_vida", 0)), int(item.get("bonus_ataque", 0))]

func _atualizar_detalhe():
	var item = _buscar(selecionado_id)
	detalhe.text = _descricao(item) if not item.is_empty() else "Escolha um item do baú."
	detalhe.tooltip_text = _descricao(item) if not item.is_empty() else ""
	equipar_botao.disabled = item.is_empty() or int(EstadoJogo.equipados.get(item.get("slot", ""), 0)) == selecionado_id
	equipar_botao.text = "Equipado" if not item.is_empty() and equipar_botao.disabled else "Equipar"

func _selecionar(id: int):
	selecionado_id = id
	_atualizar_bau()

func _selecionar_equipado(slot: String):
	var item = EstadoJogo.item_equipado(slot)
	if not item.is_empty():
		selecionado_id = int(item.get("id", 0))
		_atualizar_bau()

func _equipar_selecionado():
	if EstadoJogo.equipar(selecionado_id):
		equipamento_mudou.emit()
		_atualizar()

func _filtros_mudaram(_indice: int):
	_atualizar_bau()

func _melhores_mudou(_ativo: bool):
	_atualizar_bau()

func _on_fechar_pressed():
	queue_free()
