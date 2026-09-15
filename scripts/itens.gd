class_name Itens
extends RefCounted

const SLOTS = ["arma", "arma_secundaria", "cabeca", "peito", "pernas", "luvas", "acessorio"]
const PARTES = {"arma": "Arma", "arma_secundaria": "Arma secundária", "cabeca": "Cabeça", "peito": "Peito", "pernas": "Pernas", "luvas": "Luvas", "acessorio": "Acessório"}
const CONJUNTOS = ["Viajante", "Floresta", "Deserto", "Mar", "Montanha", "Ruínas", "Gelo", "Sombras", "Dragão", "Torre"]
const QUALIDADES = ["Comum", "Raro", "Épico", "Lendário"]
const MULTIPLICADORES = [1, 2, 3, 5]

static func gerar_drop(andar: int, _fase: int, tipo: String) -> Dictionary:
	if tipo == "normal" and randf() > 0.35:
		return {}
	var nivel_item = clampi(1 + (andar - 1) * 10, 1, 100)
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
	var bonus_vida = 0
	var bonus_ataque = 0
	var multiplicador = MULTIPLICADORES[qualidade]
	if slot == "arma":
		bonus_ataque = maxi(1, int((nivel_item + 19) / 20)) * multiplicador
	elif slot == "arma_secundaria":
		bonus_vida = maxi(1, int((nivel_item + 19) / 20)) * multiplicador
		bonus_ataque = maxi(1, int((nivel_item + 39) / 40)) * multiplicador
	elif slot == "luvas":
		bonus_vida = maxi(1, int((nivel_item + 9) / 10)) * multiplicador
		bonus_ataque = maxi(1, int((nivel_item + 39) / 40)) * multiplicador
	elif slot == "acessorio":
		bonus_vida = maxi(1, int((nivel_item + 9) / 10)) * multiplicador
		bonus_ataque = maxi(1, int((nivel_item + 39) / 40)) * multiplicador
	else:
		bonus_vida = maxi(2, int((nivel_item + 4) / 5)) * multiplicador
	return {
		"nome": "%s %s de %s" % [QUALIDADES[qualidade], PARTES[slot], CONJUNTOS[clampi(andar, 1, 10) - 1]],
		"slot": slot,
		"andar": andar,
		"nivel": nivel_item,
		"qualidade": qualidade,
		"bonus_vida": bonus_vida,
		"bonus_ataque": bonus_ataque,
	}
