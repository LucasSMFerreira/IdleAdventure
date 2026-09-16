extends Node

signal dados_mudaram

var caminho_save = "user://idle_adventure.json"
var maior_fase_liberada = 1
var andar_escolhido = 1
var fase_escolhida = 1
var torre_concluida = false
var nivel = 1
var xp_atual = 0
var gold = 0
var inventario: Array = []
var equipados = {"arma": 0, "arma_secundaria": 0, "cabeca": 0, "peito": 0, "pernas": 0, "luvas": 0, "acessorio": 0}
var proximo_item_id = 1

func _ready():
	carregar()
	andar_escolhido = int((maior_fase_liberada - 1) / Progressao.FASES_POR_ANDAR) + 1
	fase_escolhida = (maior_fase_liberada - 1) % Progressao.FASES_POR_ANDAR + 1

func carregar():
	if not FileAccess.file_exists(caminho_save):
		return
	var dados = JSON.parse_string(FileAccess.get_file_as_string(caminho_save))
	if dados is Dictionary:
		maior_fase_liberada = clampi(int(dados.get("maior_fase_liberada", 1)), 1, Progressao.TOTAL_ANDARES * Progressao.FASES_POR_ANDAR)
		torre_concluida = bool(dados.get("torre_concluida", false))
		nivel = clampi(int(dados.get("nivel", 1)), 1, Evolucao.NIVEL_MAXIMO)
		xp_atual = maxi(int(dados.get("xp_atual", 0)), 0)
		gold = maxi(int(dados.get("gold", 0)), 0)
		while nivel < Evolucao.NIVEL_MAXIMO and xp_atual >= Evolucao.xp_para_proximo(nivel):
			xp_atual -= Evolucao.xp_para_proximo(nivel)
			nivel += 1
		if nivel == Evolucao.NIVEL_MAXIMO:
			xp_atual = 0
		inventario = dados.get("inventario", []) if dados.get("inventario", []) is Array else []
		for item in inventario:
			if item is Dictionary:
				if item.get("slot", "") == "armadura":
					item["slot"] = "peito"
					item["nome"] = str(item.get("nome", "Armadura")).replace("Armadura", "Peito")
				if not item.has("andar"):
					item["andar"] = clampi(int((int(item.get("nivel", 1)) - 1) / 10) + 1, 1, 10)
				if int(item.get("qualidade", 0)) == 3 and not item.has("qualidade_pct"):
					item["qualidade_pct"] = 100
		var salvos = dados.get("equipados", {})
		equipados = {"arma": 0, "arma_secundaria": 0, "cabeca": 0, "peito": 0, "pernas": 0, "luvas": 0, "acessorio": 0}
		if salvos is Dictionary:
			for slot in equipados:
				equipados[slot] = int(salvos.get(slot, 0))
			if equipados["peito"] == 0:
				equipados["peito"] = int(salvos.get("armadura", 0))
		proximo_item_id = maxi(int(dados.get("proximo_item_id", 1)), 1)

func salvar():
	var arquivo = FileAccess.open(caminho_save, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify({
			"maior_fase_liberada": maior_fase_liberada,
			"torre_concluida": torre_concluida,
			"nivel": nivel,
			"xp_atual": xp_atual,
			"gold": gold,
			"inventario": inventario,
			"equipados": equipados,
			"proximo_item_id": proximo_item_id,
		}))

func ganhar_xp(valor: int) -> bool:
	if valor <= 0 or nivel == Evolucao.NIVEL_MAXIMO:
		return false
	var nivel_anterior = nivel
	xp_atual += valor
	while nivel < Evolucao.NIVEL_MAXIMO and xp_atual >= Evolucao.xp_para_proximo(nivel):
		xp_atual -= Evolucao.xp_para_proximo(nivel)
		nivel += 1
	if nivel == Evolucao.NIVEL_MAXIMO:
		xp_atual = 0
	salvar()
	dados_mudaram.emit()
	return nivel > nivel_anterior

func ganhar_gold(valor: int):
	if valor > 0:
		gold += valor
		salvar()
		dados_mudaram.emit()

func adicionar_item(item: Dictionary) -> int:
	if item.is_empty():
		return 0
	var novo = item.duplicate(true)
	novo["id"] = proximo_item_id
	proximo_item_id += 1
	inventario.append(novo)
	salvar()
	dados_mudaram.emit()
	return int(novo["id"])

func equipar(id: int) -> bool:
	for item in inventario:
		if item is Dictionary and int(item.get("id", 0)) == id and equipados.has(item.get("slot", "")):
			equipados[item["slot"]] = id
			salvar()
			dados_mudaram.emit()
			return true
	return false

func item_por_id(id: int) -> Dictionary:
	for item in inventario:
		if item is Dictionary and int(item.get("id", 0)) == id:
			return item
	return {}

func parceiros_craft(id: int) -> Array:
	var alvo = item_por_id(id)
	var parceiros: Array = []
	if alvo.is_empty() or Itens.custo_craft(alvo) == 0:
		return parceiros
	for item in inventario:
		if not item is Dictionary or int(item.get("id", 0)) == id:
			continue
		if int(item.get("id", 0)) in equipados.values():
			continue
		if item.get("slot", "") == alvo.get("slot", "") and int(item.get("andar", 1)) == int(alvo.get("andar", 1)) and int(item.get("qualidade", 0)) == int(alvo.get("qualidade", 0)):
			parceiros.append(item)
			if parceiros.size() == 5:
				break
	return parceiros

func parceiro_craft(id: int) -> Dictionary:
	var parceiros = parceiros_craft(id)
	return parceiros[0] if not parceiros.is_empty() else {}

func craft(id: int) -> int:
	var parceiros = parceiros_craft(id)
	if parceiros.size() < 5:
		return 0
	var ids: Array[int] = [id]
	for parceiro in parceiros:
		ids.append(int(parceiro.get("id", 0)))
	return craft_com_itens(ids)

func craft_com_itens(ids: Array[int]) -> int:
	if ids.size() != 6:
		return 0
	var vistos = {}
	var entradas: Array = []
	var equipado_id = 0
	for id in ids:
		if id <= 0 or vistos.has(id):
			return 0
		vistos[id] = true
		var item = item_por_id(id)
		if item.is_empty():
			return 0
		if id in equipados.values():
			if equipado_id != 0:
				return 0
			equipado_id = id
		entradas.append(item)
	var alvo: Dictionary = entradas[0]
	for item in entradas:
		if item.get("slot", "") != alvo.get("slot", "") or int(item.get("andar", 1)) != int(alvo.get("andar", 1)) or int(item.get("qualidade", 0)) != int(alvo.get("qualidade", 0)):
			return 0
	var custo = Itens.custo_craft(alvo)
	if custo <= 0 or gold < custo:
		return 0
	var qualidade = int(alvo.get("qualidade", 0))
	var percentual = 0
	if qualidade == 3:
		for item in entradas:
			percentual = maxi(percentual, int(item.get("qualidade_pct", 60)))
		percentual = mini(100, percentual + randi_range(1, 10))
	else:
		qualidade += 1
	var novo = Itens.criar_item(int(alvo.get("andar", 1)), str(alvo.get("slot", "")), qualidade, percentual)
	if novo.is_empty():
		return 0
	for item in entradas:
		inventario.erase(item)
	gold -= custo
	novo["id"] = proximo_item_id
	proximo_item_id += 1
	inventario.append(novo)
	if equipado_id != 0:
		equipados[novo["slot"]] = int(novo["id"])
	salvar()
	dados_mudaram.emit()
	return int(novo["id"])

func reciclar(id: int) -> int:
	if id in equipados.values():
		return 0
	var item = item_por_id(id)
	var ganho = Itens.valor_reciclagem(item)
	if ganho <= 0:
		return 0
	inventario.erase(item)
	gold += ganho
	salvar()
	dados_mudaram.emit()
	return ganho

func item_equipado(slot: String) -> Dictionary:
	var id = int(equipados.get(slot, 0))
	return item_por_id(id)

func bonus_vida() -> int:
	var bonus = 0
	for slot in equipados:
		bonus += int(item_equipado(slot).get("bonus_vida", 0))
	return bonus

func bonus_ataque() -> int:
	var bonus = 0
	for slot in equipados:
		bonus += int(item_equipado(slot).get("bonus_ataque", 0))
	return bonus

func selecionar_fase(andar: int, fase: int) -> bool:
	var indice = (andar - 1) * Progressao.FASES_POR_ANDAR + fase
	if andar < 1 or andar > Progressao.TOTAL_ANDARES or fase < 1 or fase > Progressao.FASES_POR_ANDAR or indice > maior_fase_liberada:
		return false
	andar_escolhido = andar
	fase_escolhida = fase
	return true

func liberar_proxima(andar: int, fase: int):
	var indice = (andar - 1) * Progressao.FASES_POR_ANDAR + fase
	if indice == Progressao.TOTAL_ANDARES * Progressao.FASES_POR_ANDAR:
		torre_concluida = true
	else:
		maior_fase_liberada = maxi(maior_fase_liberada, indice + 1)
	salvar()
	dados_mudaram.emit()
