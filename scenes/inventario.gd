extends CanvasLayer

signal equipamento_mudou
signal craft_concluido

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
@onready var fundir_botao: Button = $Bau/Fundir
@onready var craft_info: Label = $Bau/CraftInfo
@onready var gold_label: Label = $Bau/Gold

var selecionado_id = 0
var tamanho_anterior = Vector2i.ZERO
var modo_mobile = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")

func _ready():
	if not modo_mobile:
		tamanho_anterior = get_window().size
		get_window().size = Vector2i(1000, 600)
		offset = Vector2(0, 300)
	else:
		offset = Vector2.ZERO
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
	fundir_botao.pressed.connect(_fundir_selecionado)
	for slot in BOTOES:
		get_node("Equipamento/" + BOTOES[slot]).pressed.connect(_selecionar_equipado.bind(slot))
	EstadoJogo.dados_mudaram.connect(_atualizar)
	_atualizar()

func _exit_tree():
	if tamanho_anterior != Vector2i.ZERO:
		get_window().size = tamanho_anterior

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
		var categoria = Itens.QUALIDADES[clampi(int(item.get("qualidade", 0)), 0, 3)]
		if not item.is_empty() and int(item.get("qualidade", 0)) == 3:
			categoria = "Lend.%d%%" % int(item.get("qualidade_pct", 100))
		botao.text = "%s: %s" % [titulo, categoria if not item.is_empty() else "vazio"]
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
			if anterior.is_empty() or Itens.pontuacao(item) > Itens.pontuacao(anterior) or (Itens.pontuacao(item) == Itens.pontuacao(anterior) and int(item.get("id", 0)) > int(anterior.get("id", 0))):
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
		var categoria = Itens.QUALIDADES[clampi(int(item.get("qualidade", 0)), 0, 3)].substr(0, 4)
		if int(item.get("qualidade", 0)) == 3:
			categoria = "%d%%" % int(item.get("qualidade_pct", 100))
		botao.text = "%s\n%s" % [parte.substr(0, 5), categoria]
		botao.tooltip_text = _descricao(item)
		_estilizar(botao, _cor_item(item), int(item.get("id", 0)) == selecionado_id)
		botao.pressed.connect(_selecionar.bind(int(item.get("id", 0))))
		grade.add_child(botao)
	if not existe:
		selecionado_id = 0
	contagem.text = "%d/%d itens" % [visiveis.size(), EstadoJogo.inventario.size()]
	gold_label.text = "Gold %d" % EstadoJogo.gold
	_atualizar_detalhe()

func _buscar(id: int) -> Dictionary:
	for item in EstadoJogo.inventario:
		if item is Dictionary and int(item.get("id", 0)) == id:
			return item
	return {}

func _descricao(item: Dictionary) -> String:
	return "%s  |  +%d HP  +%d ATK" % [Itens.nome_exibicao(item), int(item.get("bonus_vida", 0)), int(item.get("bonus_ataque", 0))]

func _atualizar_detalhe():
	var item = _buscar(selecionado_id)
	detalhe.text = _descricao(item) if not item.is_empty() else "Escolha um item do baú."
	detalhe.tooltip_text = _descricao(item) if not item.is_empty() else ""
	equipar_botao.disabled = item.is_empty() or int(EstadoJogo.equipados.get(item.get("slot", ""), 0)) == selecionado_id
	equipar_botao.text = "Equipado" if not item.is_empty() and equipar_botao.disabled else "Equipar"
	var custo = Itens.custo_craft(item)
	var parceiro = EstadoJogo.parceiro_craft(selecionado_id)
	fundir_botao.disabled = custo == 0 or parceiro.is_empty() or EstadoJogo.gold < custo
	if item.is_empty():
		craft_info.text = "Fundir 2 iguais + Gold"
	elif custo == 0:
		craft_info.text = "Lendário já está em 100%"
	elif parceiro.is_empty():
		craft_info.text = "Precisa outra peça igual"
	elif EstadoJogo.gold < custo:
		craft_info.text = "Faltam %d Gold (custa %d)" % [custo - EstadoJogo.gold, custo]
	else:
		craft_info.text = "%d Gold: %s" % [custo, "refinar %" if int(item.get("qualidade", 0)) == 3 else Itens.QUALIDADES[int(item.get("qualidade", 0)) + 1]]
	fundir_botao.tooltip_text = "Funde duas peças da mesma parte, andar e categoria. Custo: %d Gold." % custo

func _selecionar(id: int):
	selecionado_id = id
	_atualizar_bau()

func _selecionar_equipado(slot: String):
	var item = EstadoJogo.item_equipado(slot)
	if not item.is_empty():
		so_melhores.button_pressed = false
		filtro_parte.select(0)
		filtro_qualidade.select(0)
		filtro_andar.select(0)
		selecionado_id = int(item.get("id", 0))
		_atualizar_bau()

func _equipar_selecionado():
	if EstadoJogo.equipar(selecionado_id):
		equipamento_mudou.emit()
		_atualizar()

func _fundir_selecionado():
	var novo_id = EstadoJogo.craft(selecionado_id)
	if novo_id > 0:
		selecionado_id = novo_id
		craft_concluido.emit()
		equipamento_mudou.emit()
		_atualizar()

func _filtros_mudaram(_indice: int):
	_atualizar_bau()

func _melhores_mudou(_ativo: bool):
	_atualizar_bau()

func _on_fechar_pressed():
	queue_free()
