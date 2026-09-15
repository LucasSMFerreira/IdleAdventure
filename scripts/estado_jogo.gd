extends Node

var caminho_save = "user://idle_adventure.json"
var maior_fase_liberada = 1
var andar_escolhido = 1
var fase_escolhida = 1
var torre_concluida = false
var nivel = 1
var xp_atual = 0
var inventario: Array = []
var equipados = {"arma": 0, "armadura": 0, "acessorio": 0}
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
		while nivel < Evolucao.NIVEL_MAXIMO and xp_atual >= Evolucao.xp_para_proximo(nivel):
			xp_atual -= Evolucao.xp_para_proximo(nivel)
			nivel += 1
		if nivel == Evolucao.NIVEL_MAXIMO:
			xp_atual = 0
		inventario = dados.get("inventario", []) if dados.get("inventario", []) is Array else []
		var salvos = dados.get("equipados", {})
		equipados = {"arma": 0, "armadura": 0, "acessorio": 0}
		if salvos is Dictionary:
			for slot in equipados:
				equipados[slot] = int(salvos.get(slot, 0))
		proximo_item_id = maxi(int(dados.get("proximo_item_id", 1)), 1)

func salvar():
	var arquivo = FileAccess.open(caminho_save, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify({
			"maior_fase_liberada": maior_fase_liberada,
			"torre_concluida": torre_concluida,
			"nivel": nivel,
			"xp_atual": xp_atual,
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
	return nivel > nivel_anterior

func adicionar_item(item: Dictionary) -> int:
	if item.is_empty():
		return 0
	var novo = item.duplicate(true)
	novo["id"] = proximo_item_id
	proximo_item_id += 1
	inventario.append(novo)
	salvar()
	return int(novo["id"])

func equipar(id: int) -> bool:
	for item in inventario:
		if int(item.get("id", 0)) == id and equipados.has(item.get("slot", "")):
			equipados[item["slot"]] = id
			salvar()
			return true
	return false

func item_equipado(slot: String) -> Dictionary:
	var id = int(equipados.get(slot, 0))
	for item in inventario:
		if int(item.get("id", 0)) == id:
			return item
	return {}

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
