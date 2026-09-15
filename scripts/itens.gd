class_name Itens
extends RefCounted

const SLOTS = ["arma", "armadura", "acessorio"]
const QUALIDADES = ["Comum", "Raro", "Épico", "Lendário"]
const MULTIPLICADORES = [1, 2, 3, 5]

static func gerar_drop(andar: int, fase: int, tipo: String) -> Dictionary:
	if tipo == "normal" and randf() > 0.35:
		return {}
	var nivel_item = clampi((andar - 1) * 10 + fase, 1, 100)
	var sorteio = randf()
	var qualidade = 0
	if tipo == "boss":
		qualidade = 3 if sorteio > 0.7 else 2
	elif tipo == "mini":
		qualidade = 3 if sorteio > 0.95 else (2 if sorteio > 0.6 else 1)
	else:
		qualidade = 2 if sorteio > 0.98 else (1 if sorteio > 0.8 else 0)
	var slot = "arma" if tipo == "mini" else SLOTS[randi_range(0, SLOTS.size() - 1)]
	var bonus_vida = 0
	var bonus_ataque = 0
	var multiplicador = MULTIPLICADORES[qualidade]
	if slot == "arma":
		bonus_ataque = maxi(1, int((nivel_item + 19) / 20)) * multiplicador
	elif slot == "armadura":
		bonus_vida = maxi(2, int((nivel_item + 4) / 5)) * multiplicador
	else:
		bonus_vida = maxi(1, int((nivel_item + 9) / 10)) * multiplicador
		bonus_ataque = maxi(1, int((nivel_item + 39) / 40)) * multiplicador
	return {
		"nome": "%s %s Nv.%d" % [QUALIDADES[qualidade], slot.capitalize(), nivel_item],
		"slot": slot,
		"nivel": nivel_item,
		"qualidade": qualidade,
		"bonus_vida": bonus_vida,
		"bonus_ataque": bonus_ataque,
	}
