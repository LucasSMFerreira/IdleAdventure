class_name Itens
extends RefCounted

const SLOTS = ["arma", "arma_secundaria", "cabeca", "peito", "pernas", "luvas", "acessorio"]
const PARTES = {"arma": "Arma", "arma_secundaria": "Arma secundária", "cabeca": "Cabeça", "peito": "Peito", "pernas": "Pernas", "luvas": "Luvas", "acessorio": "Acessório"}
const CONJUNTOS = ["Viajante", "Floresta", "Deserto", "Mar", "Montanha", "Ruínas", "Gelo", "Sombras", "Dragão", "Torre"]
const QUALIDADES = ["Comum", "Raro", "Épico", "Lendário"]
const MULTIPLICADORES = [1, 2, 3, 5]

static func nome_exibicao(item: Dictionary) -> String:
	var nome = str(item.get("nome", "Item"))
	if int(item.get("qualidade", 0)) == 3:
		return nome.replace("Lendário", "Lendário %d%%" % clampi(int(item.get("qualidade_pct", 100)), 60, 100))
	return nome

static func pontuacao(item: Dictionary) -> int:
	if item.is_empty():
		return -1
	var categoria = clampi(int(item.get("qualidade", 0)), 0, 3)
	return categoria * 100 + (clampi(int(item.get("qualidade_pct", 100)), 60, 100) if categoria == 3 else 0)

static func custo_craft(item: Dictionary) -> int:
	if item.is_empty() or not SLOTS.has(item.get("slot", "")) or int(item.get("qualidade", 0)) == 3 and int(item.get("qualidade_pct", 100)) >= 100:
		return 0
	return maxi(1, int(item.get("andar", 1))) * 25 * (clampi(int(item.get("qualidade", 0)), 0, 3) + 1)

static func valor_reciclagem(item: Dictionary) -> int:
	if item.is_empty():
		return 0
	return maxi(1, int(item.get("andar", 1))) * 5 * (clampi(int(item.get("qualidade", 0)), 0, 3) + 1)

static func criar_item(andar: int, slot: String, qualidade: int, percentual_lendario: int = 0) -> Dictionary:
	if not SLOTS.has(slot):
		return {}
	andar = clampi(andar, 1, 10)
	qualidade = clampi(qualidade, 0, 3)
	var nivel_item = 1 + (andar - 1) * 10
	var multiplicador = float(MULTIPLICADORES[qualidade])
	if qualidade == 3:
		percentual_lendario = clampi(percentual_lendario if percentual_lendario > 0 else randi_range(60, 100), 60, 100)
		multiplicador = 3.0 + 2.0 * float(percentual_lendario) / 100.0
	var vida_base = 0
	var ataque_base = 0
	if slot == "arma":
		ataque_base = maxi(1, int((nivel_item + 19) / 20))
	elif slot == "arma_secundaria":
		vida_base = maxi(1, int((nivel_item + 19) / 20))
		ataque_base = maxi(1, int((nivel_item + 39) / 40))
	elif slot == "luvas" or slot == "acessorio":
		vida_base = maxi(1, int((nivel_item + 9) / 10))
		ataque_base = maxi(1, int((nivel_item + 39) / 40))
	else:
		vida_base = maxi(2, int((nivel_item + 4) / 5))
	var item = {
		"nome": "%s %s de %s" % [QUALIDADES[qualidade], PARTES[slot], CONJUNTOS[andar - 1]],
		"slot": slot,
		"andar": andar,
		"nivel": nivel_item,
		"qualidade": qualidade,
		"bonus_vida": roundi(vida_base * multiplicador),
		"bonus_ataque": roundi(ataque_base * multiplicador),
	}
	if qualidade == 3:
		item["qualidade_pct"] = percentual_lendario
	return item

static func gerar_drop(andar: int, _fase: int, tipo: String) -> Dictionary:
	if tipo == "normal" and randf() > 0.35:
		return {}
	var sorteio = randf()
	var qualidade = clampi(int((andar - 1) / 3), 0, 2)
	if tipo == "boss":
		qualidade = mini(qualidade + 2, 3) if sorteio > 0.7 else mini(qualidade + 1, 3)
	elif tipo == "mini":
		qualidade = mini(qualidade + 2, 3) if sorteio > 0.95 else (mini(qualidade + 1, 3) if sorteio > 0.6 else qualidade)
	elif sorteio > 0.98:
		qualidade = mini(qualidade + 2, 3)
	elif sorteio > 0.8:
		qualidade = mini(qualidade + 1, 3)
	var slot = "arma" if tipo == "mini" else SLOTS[randi_range(0, SLOTS.size() - 1)]
	return criar_item(andar, slot, qualidade)
