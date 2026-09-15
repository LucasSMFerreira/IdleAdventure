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
@onready var filtro_andar: OptionButton = $Bau/FiltroAndar
@onready var so_melhores: CheckButton = $Bau/SoMelhores
@onready var contagem: Label = $Bau/Contagem
@onready var detalhe: Label = $Bau/Detalhe
@onready var equipar_botao: Button = $Bau/Equipar
@onready var fundir_botao: Button = $Bau/Fundir
@onready var craft_info: Label = $Bau/CraftInfo
@onready var gold_label: Label = $Bau/Gold
@onready var craft_painel: Panel = $Craft
@onready var receitas: OptionButton = $Craft/Receitas
@onready var ingredientes: GridContainer = $Craft/Ingredientes
@onready var resultado: Label = $Craft/Resultado
@onready var custo_label: Label = $Craft/Custo
@onready var sintetizar_botao: Button = $Craft/Sintetizar
@onready var personagem: AnimatedSprite2D = $Equipamento/Personagem

var selecionado_id = 0
var receitas_ids: Array[int] = []
var receita_id = 0
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
	filtro_andar.add_item("Andar")
	for andar in range(1, Progressao.TOTAL_ANDARES + 1):
		filtro_andar.add_item("Andar %d" % andar)
	filtro_parte.item_selected.connect(_filtros_mudaram)
	filtro_qualidade.item_selected.connect(_filtros_mudaram)
	filtro_andar.item_selected.connect(_filtros_mudaram)
	so_melhores.toggled.connect(_melhores_mudou)
	equipar_botao.pressed.connect(_equipar_selecionado)
	sintetizar_botao.pressed.connect(_fundir_selecionado)
	$Bau/AbaBau.pressed.connect(_abrir_bau)
	$Bau/AbaCraft.pressed.connect(_abrir_craft)
	$Craft/AbaBau.pressed.connect(_abrir_bau)
	$Craft/AbaCraft.pressed.connect(_abrir_craft)
	receitas.item_selected.connect(_selecionar_receita)
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
	if not _buscar(selecionado_id).is_empty():
		receita_id = selecionado_id
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
		_atualizar_bau()
		_atualizar_craft()
	else:
		gold_label.text = "Gold %d" % EstadoJogo.gold
		$Craft/Gold.text = gold_label.text
		_atualizar_custo()

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
	craft_info.text = ""
	fundir_botao.disabled = true

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
	var novo_id = EstadoJogo.craft(receita_id if craft_painel.visible else selecionado_id)
	if novo_id > 0:
		selecionado_id = novo_id
		receita_id = novo_id
		craft_concluido.emit()
		equipamento_mudou.emit()
		_atualizar()
		_abrir_craft()

func _filtros_mudaram(_indice: int):
	_atualizar_bau()

func _melhores_mudou(_ativo: bool):
	_atualizar_bau()


func _atualizar_craft():
	if not is_node_ready():
		return
	var grupos = {}
	for item in EstadoJogo.inventario:
		if not item is Dictionary or Itens.custo_craft(item) == 0:
			continue
		var chave = "%s|%d|%d" % [item.get("slot", ""), int(item.get("andar", 1)), int(item.get("qualidade", 0))]
		if not grupos.has(chave):
			grupos[chave] = []
		grupos[chave].append(item)
	var chaves = grupos.keys()
	chaves.sort_custom(func(a, b):
		var quantidade_a = grupos[a].size()
		var quantidade_b = grupos[b].size()
		return quantidade_a > quantidade_b if quantidade_a != quantidade_b else str(a) < str(b)
	)
	receitas.clear()
	receitas_ids.clear()
	var indice_escolhido = 0
	for chave in chaves:
		var grupo: Array = grupos[chave]
		var preferido = receita_id if craft_painel.visible and receita_id > 0 else selecionado_id
		var selecionado_no_grupo = false
		for candidato in grupo:
			if int(candidato.get("id", 0)) == preferido:
				selecionado_no_grupo = true
		if grupo.size() < 2 and not selecionado_no_grupo:
			continue
		var alvo = grupo[0]
		for item in grupo:
			if int(item.get("id", 0)) == preferido:
				alvo = item
				indice_escolhido = receitas_ids.size()
		var disponiveis = 1 + EstadoJogo.parceiros_craft(int(alvo.get("id", 0))).size()
		receitas.add_item("%s • %s • andar %d  (%d/6)" % [Itens.PARTES.get(alvo.get("slot", ""), "Item"), Itens.QUALIDADES[int(alvo.get("qualidade", 0))], int(alvo.get("andar", 1)), disponiveis])
		receitas_ids.append(int(alvo.get("id", 0)))
	if receitas_ids.is_empty():
		receitas.add_item("Nenhuma receita disponível")
		receita_id = 0
	else:
		receitas.select(indice_escolhido)
		receita_id = receitas_ids[indice_escolhido]
	_atualizar_receita()

func _selecionar_receita(indice: int):
	if indice >= 0 and indice < receitas_ids.size():
		receita_id = receitas_ids[indice]
		_atualizar_receita()

func _atualizar_custo():
	var item = _buscar(receita_id)
	if item.is_empty():
		return
	var custo = Itens.custo_craft(item)
	var entradas = 1 + EstadoJogo.parceiros_craft(receita_id).size()
	custo_label.text = "%d/6 peças  •  %d Gold" % [entradas, custo]
	sintetizar_botao.disabled = entradas < 6 or EstadoJogo.gold < custo
	sintetizar_botao.tooltip_text = "Faltam %d Gold" % maxi(custo - EstadoJogo.gold, 0) if EstadoJogo.gold < custo else "Consome seis peças e cria uma melhor."

func _atualizar_receita():
	for antigo in ingredientes.get_children():
		ingredientes.remove_child(antigo)
		antigo.queue_free()
	var item = _buscar(receita_id)
	var parceiros = EstadoJogo.parceiros_craft(receita_id)
	var entradas = [item] if not item.is_empty() else []
	entradas.append_array(parceiros)
	for indice in range(6):
		var botao = Button.new()
		botao.custom_minimum_size = Vector2(63, 62)
		botao.mouse_filter = Control.MOUSE_FILTER_IGNORE
		botao.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if indice < entradas.size():
			var entrada: Dictionary = entradas[indice]
			botao.icon = ICONES.get(entrada.get("slot", ""), null)
			botao.expand_icon = true
			botao.tooltip_text = _descricao(entrada)
			_estilizar(botao, _cor_item(entrada), indice == 0)
		else:
			botao.text = "+"
			_estilizar(botao, Color(0.36, 0.31, 0.27))
		ingredientes.add_child(botao)
	$Craft/Gold.text = "Gold %d" % EstadoJogo.gold
	if item.is_empty():
		resultado.text = "Reúna seis peças para começar."
		custo_label.text = ""
		$Craft/ResultadoIcone.texture = null
		sintetizar_botao.disabled = true
		return
	var qualidade = int(item.get("qualidade", 0))
	var saida = "refinar Lendário %" if qualidade == 3 else Itens.QUALIDADES[qualidade + 1]
	resultado.text = "Resultado: %s • %s • andar %d" % [saida, Itens.PARTES[item.get("slot", "")], int(item.get("andar", 1))]
	$Craft/ResultadoIcone.texture = ICONES.get(item.get("slot", ""), null)
	_atualizar_custo()

func _on_fechar_pressed():
	queue_free()
