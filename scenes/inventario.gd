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
const ICONES = {
	"arma": preload("res://assets/items/arma.svg"),
	"arma_secundaria": preload("res://assets/items/arma_secundaria.svg"),
	"cabeca": preload("res://assets/items/cabeca.svg"),
	"peito": preload("res://assets/items/peito.svg"),
	"pernas": preload("res://assets/items/pernas.svg"),
	"luvas": preload("res://assets/items/luvas.svg"),
	"acessorio": preload("res://assets/items/acessorio.svg"),
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
@onready var ordenacao: OptionButton = $Bau/Ordenar
@onready var so_melhores: CheckButton = $Bau/SoMelhores
@onready var contagem: Label = $Bau/Contagem
@onready var detalhe: Label = $Bau/Detalhe
@onready var equipar_botao: Button = $Bau/Equipar
@onready var fundir_botao: Button = $Bau/Fundir
@onready var craft_info: Label = $Bau/CraftInfo
@onready var gold_label: Label = $Bau/Gold
@onready var enviar_botao: Button = $Bau/Enviar
@onready var craft_painel: Panel = $Craft
@onready var modo: OptionButton = $Craft/Modo
@onready var box_itens: GridContainer = $Craft/Box
@onready var resultado: Label = $Craft/Resultado
@onready var custo_label: Label = $Craft/Custo
@onready var sintetizar_botao: Button = $Craft/Sintetizar
@onready var personagem: AnimatedSprite2D = $Equipamento/Personagem

var selecionado_id = 0
var enviados_ids: Array[int] = []
var modo_atual = 0
var tamanho_itens_anterior = -1
var equipados_anteriores = ""
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
	ordenacao.add_item("Recentes")
	ordenacao.add_item("Andar ↓")
	ordenacao.add_item("Categoria ↓")
	modo.add_item("Síntese • 6 peças")
	modo.add_item("Refino lendário • 6 peças")
	modo.add_item("Reciclar • 1 peça")
	filtro_parte.item_selected.connect(_filtros_mudaram)
	filtro_qualidade.item_selected.connect(_filtros_mudaram)
	ordenacao.item_selected.connect(_filtros_mudaram)
	so_melhores.toggled.connect(_melhores_mudou)
	equipar_botao.pressed.connect(_equipar_selecionado)
	sintetizar_botao.pressed.connect(_executar_craft)
	$Craft/Limpar.pressed.connect(_limpar_box)
	enviar_botao.pressed.connect(_enviar_selecionado)
	$Bau/AbaBau.pressed.connect(_abrir_bau)
	$Bau/AbaCraft.pressed.connect(_abrir_craft)
	$Craft/AbaBau.pressed.connect(_abrir_bau)
	$Craft/AbaCraft.pressed.connect(_abrir_craft)
	modo.item_selected.connect(_modo_mudou)
	personagem.sprite_frames = AnimacaoSprites.montar("barbarian", ["idle"])
	personagem.play("idle")
	$Bau/TituloBau.hide()
	_estilizar_painel($Equipamento)
	_estilizar_painel($Bau)
	_estilizar_painel($Craft)
	for slot in BOTOES:
		get_node("Equipamento/" + BOTOES[slot]).pressed.connect(_selecionar_equipado.bind(slot))
	EstadoJogo.dados_mudaram.connect(_atualizar)
	_atualizar()

func _exit_tree():
	if tamanho_anterior != Vector2i.ZERO:
		get_window().size = tamanho_anterior

func _estilizar_painel(painel: Panel):
	var estilo = StyleBoxFlat.new()
	estilo.bg_color = Color(0.22, 0.18, 0.14)
	estilo.border_color = Color(0.57, 0.39, 0.24)
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(4)
	painel.add_theme_stylebox_override("panel", estilo)

func _abrir_bau():
	$Bau.show()
	craft_painel.hide()
	_atualizar_bau()

func _abrir_craft():
	$Bau.hide()
	craft_painel.show()
	_atualizar_craft()

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
	botao.add_theme_font_size_override("font_size", 13)

func _atualizar():
	var assinatura = JSON.stringify(EstadoJogo.equipados)
	var itens_mudaram = tamanho_itens_anterior != EstadoJogo.inventario.size() or assinatura != equipados_anteriores
	tamanho_itens_anterior = EstadoJogo.inventario.size()
	equipados_anteriores = assinatura
	_atualizar_equipados()
	if itens_mudaram:
		for id in enviados_ids.duplicate():
			if _buscar(id).is_empty():
				enviados_ids.erase(id)
		_atualizar_bau()
		_atualizar_craft()
	else:
		gold_label.text = "Gold %d" % EstadoJogo.gold
		$Craft/Gold.text = gold_label.text
		_atualizar_estado_box()

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
		botao.icon = ICONES[slot]
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		botao.text = "%s\n%s" % [titulo.replace(" secundária", " 2"), categoria if not item.is_empty() else "vazio"]
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
		visiveis.append(item)
	if so_melhores.button_pressed:
		var melhores = {}
		for item in visiveis:
			var chave = "%s_%d" % [item.get("slot", ""), int(item.get("andar", 1))]
			var anterior = melhores.get(chave, {})
			if anterior.is_empty() or Itens.pontuacao(item) > Itens.pontuacao(anterior) or (Itens.pontuacao(item) == Itens.pontuacao(anterior) and int(item.get("id", 0)) > int(anterior.get("id", 0))):
				melhores[chave] = item
		visiveis = melhores.values()
	visiveis.sort_custom(func(a, b):
		if ordenacao.selected == 1 and int(a.get("andar", 1)) != int(b.get("andar", 1)):
			return int(a.get("andar", 1)) > int(b.get("andar", 1))
		if ordenacao.selected == 2 and int(a.get("qualidade", 0)) != int(b.get("qualidade", 0)):
			return int(a.get("qualidade", 0)) > int(b.get("qualidade", 0))
		return int(a.get("id", 0)) > int(b.get("id", 0))
	)
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
		botao.custom_minimum_size = Vector2(62, 60)
		botao.icon = ICONES.get(item.get("slot", ""), null)
		botao.expand_icon = true
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var categoria = Itens.QUALIDADES[clampi(int(item.get("qualidade", 0)), 0, 3)].substr(0, 1)
		if int(item.get("qualidade", 0)) == 3:
			categoria = "%d%%" % int(item.get("qualidade_pct", 100))
		botao.text = ""
		var selo = Label.new()
		selo.text = categoria
		selo.position = Vector2(4, 42)
		selo.add_theme_font_size_override("font_size", 11)
		selo.add_theme_color_override("font_color", Color.WHITE)
		selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		botao.add_child(selo)
		var andar_fundo = ColorRect.new()
		andar_fundo.position = Vector2(35, 3)
		andar_fundo.size = Vector2(24, 16)
		andar_fundo.color = Color(0.06, 0.08, 0.11, 0.9)
		andar_fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		botao.add_child(andar_fundo)
		var andar_selo = Label.new()
		andar_selo.text = "A%d" % int(item.get("andar", 1))
		andar_selo.position = Vector2(37, 2)
		andar_selo.add_theme_font_size_override("font_size", 11)
		andar_selo.add_theme_color_override("font_color", Color(1, 0.85, 0.47))
		andar_selo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		botao.add_child(andar_selo)
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
	return "%s  •  Andar %d  •  +%d HP  +%d ATK" % [Itens.nome_exibicao(item), int(item.get("andar", 1)), int(item.get("bonus_vida", 0)), int(item.get("bonus_ataque", 0))]

func _atualizar_detalhe():
	var item = _buscar(selecionado_id)
	detalhe.text = _descricao(item) if not item.is_empty() else "Escolha um item do baú."
	detalhe.tooltip_text = _descricao(item) if not item.is_empty() else ""
	equipar_botao.disabled = item.is_empty() or int(EstadoJogo.equipados.get(item.get("slot", ""), 0)) == selecionado_id
	equipar_botao.text = "Equipado" if not item.is_empty() and equipar_botao.disabled else "Equipar"
	craft_info.text = ""
	fundir_botao.disabled = true
	enviar_botao.disabled = item.is_empty()
	enviar_botao.text = "Retirar" if selecionado_id in enviados_ids else "Enviar"

func _selecionar(id: int):
	selecionado_id = id
	_atualizar_bau()

func _selecionar_equipado(slot: String):
	var item = EstadoJogo.item_equipado(slot)
	if not item.is_empty():
		so_melhores.button_pressed = false
		filtro_parte.select(0)
		filtro_qualidade.select(0)
		ordenacao.select(0)
		selecionado_id = int(item.get("id", 0))
		_atualizar_bau()

func _equipar_selecionado():
	if EstadoJogo.equipar(selecionado_id):
		equipamento_mudou.emit()
		_atualizar()

func _enviar_selecionado():
	var item = _buscar(selecionado_id)
	if item.is_empty():
		return
	if selecionado_id in enviados_ids:
		enviados_ids.erase(selecionado_id)
	else:
		if enviados_ids.size() >= 6:
			detalhe.text = "Caixa cheia. Retire uma peça primeiro."
			return
		if selecionado_id in EstadoJogo.equipados.values() and (not enviados_ids.is_empty() or modo_atual == 2):
			detalhe.text = "Peça equipada só pode ser a primeira da síntese."
			return
		if modo_atual == 2:
			enviados_ids.clear()
		enviados_ids.append(selecionado_id)
		if enviados_ids.size() == 1 and modo_atual != 2:
			so_melhores.button_pressed = false
			filtro_parte.select(Itens.SLOTS.find(item.get("slot", "")) + 1)
			filtro_qualidade.select(int(item.get("qualidade", 0)) + 1)
			if int(item.get("qualidade", 0)) == 3:
				modo_atual = 1
				modo.select(1)
	_atualizar_bau()
	_atualizar_craft()

func _limpar_box():
	enviados_ids.clear()
	_atualizar_bau()
	_atualizar_craft()

func _retirar_da_box(id: int):
	enviados_ids.erase(id)
	_atualizar_bau()
	_atualizar_craft()

func _modo_mudou(indice: int):
	modo_atual = indice
	if modo_atual == 2 and enviados_ids.size() > 1:
		enviados_ids = [enviados_ids[0]]
	_atualizar_craft()

func _executar_craft():
	if sintetizar_botao.disabled:
		return
	if modo_atual == 2:
		var ganho = EstadoJogo.reciclar(enviados_ids[0])
		if ganho > 0:
			enviados_ids.clear()
			craft_concluido.emit()
	else:
		var novo_id = EstadoJogo.craft_com_itens(enviados_ids)
		if novo_id > 0:
			enviados_ids.clear()
			selecionado_id = novo_id
			craft_concluido.emit()
			equipamento_mudou.emit()
	_atualizar()
	_atualizar_craft()

func _filtros_mudaram(_indice: int):
	_atualizar_bau()

func _melhores_mudou(_ativo: bool):
	_atualizar_bau()


func _atualizar_craft():
	if not is_node_ready():
		return
	for antigo in box_itens.get_children():
		box_itens.remove_child(antigo)
		antigo.queue_free()
	for indice in range(6):
		var botao = Button.new()
		botao.custom_minimum_size = Vector2(63, 62)
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if indice < enviados_ids.size():
			var item = _buscar(enviados_ids[indice])
			if not item.is_empty():
				botao.icon = ICONES.get(item.get("slot", ""), null)
				botao.expand_icon = true
				botao.tooltip_text = _descricao(item) + "  •  Clique para retirar"
				_estilizar(botao, _cor_item(item), indice == 0)
				botao.pressed.connect(_retirar_da_box.bind(enviados_ids[indice]))
		else:
			botao.text = "+"
			botao.disabled = true
			_estilizar(botao, Color(0.38, 0.35, 0.3))
		box_itens.add_child(botao)
	$Bau/AbaCraft.text = "Box %d" % enviados_ids.size()
	$Craft/AbaCraft.text = "Box %d" % enviados_ids.size()
	$Craft/Gold.text = "Gold %d" % EstadoJogo.gold
	_atualizar_estado_box()

func _atualizar_estado_box():
	var quantidade = enviados_ids.size()
	if quantidade == 0:
		$Craft/Instrucoes.text = "Envie itens do baú para esta caixa."
		resultado.text = "Caixa vazia. Escolha uma função acima."
		custo_label.text = ""
		$Craft/ResultadoIcone.texture = null
		sintetizar_botao.disabled = true
		return
	var primeiro = _buscar(enviados_ids[0])
	if primeiro.is_empty():
		sintetizar_botao.disabled = true
		return
	$Craft/ResultadoIcone.texture = ICONES.get(primeiro.get("slot", ""), null)
	if modo_atual == 2:
		$Craft/Instrucoes.text = "Reciclar uma peça livre do baú."
		var ganho = Itens.valor_reciclagem(primeiro)
		resultado.text = "Reciclagem: +%d Gold • andar %d" % [ganho, int(primeiro.get("andar", 1))]
		custo_label.text = "%d/1 item • sem custo" % quantidade
		sintetizar_botao.disabled = quantidade != 1 or enviados_ids[0] in EstadoJogo.equipados.values()
		return
	$Craft/Instrucoes.text = "Seis peças da mesma parte, andar e categoria."
	var qualidade = int(primeiro.get("qualidade", 0))
	var saida = "Refinar Lendário %" if modo_atual == 1 else Itens.QUALIDADES[mini(qualidade + 1, 3)]
	resultado.text = "%s • %s • andar %d" % [saida, Itens.PARTES.get(primeiro.get("slot", ""), "Item"), int(primeiro.get("andar", 1))]
	var custo = Itens.custo_craft(primeiro)
	custo_label.text = "%d/6 peças • %d Gold" % [quantidade, custo]
	var valido = quantidade == 6 and custo > 0 and EstadoJogo.gold >= custo
	valido = valido and ((modo_atual == 1 and qualidade == 3) or (modo_atual == 0 and qualidade < 3))
	var equipados_na_box = 0
	for id in enviados_ids:
		var item = _buscar(id)
		if item.is_empty() or item.get("slot", "") != primeiro.get("slot", "") or int(item.get("andar", 1)) != int(primeiro.get("andar", 1)) or int(item.get("qualidade", 0)) != qualidade:
			valido = false
		if id in EstadoJogo.equipados.values():
			equipados_na_box += 1
	if equipados_na_box > 1:
		valido = false
	sintetizar_botao.disabled = not valido
	if quantidade == 6 and not valido:
		$Craft/Instrucoes.text = "Confira andar, categoria, Gold e peças equipadas."

func _on_fechar_pressed():
	queue_free()
