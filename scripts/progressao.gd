class_name Progressao
extends RefCounted

const TOTAL_ANDARES = 10
const FASES_POR_ANDAR = 10
const CICLOS_POR_FASE = 3

static func guardas_de_chefe(andar: int, fase: int) -> int:
	return mini(1 + int((fase - 1) / 3) + int((andar - 1) / 3), 4)

static func quantidade_inimigos(andar: int, fase: int, ciclo: int) -> int:
	if ciclo == CICLOS_POR_FASE:
		return guardas_de_chefe(andar, fase) + 1
	return mini(2 + int((fase - 1) / 3) + int((andar - 1) / 3) + ciclo - 1, 6)

static func vida_inimigo(andar: int, fase: int) -> int:
	return 3 + int((fase - 1) / 3) + 2 * (andar - 1)

static func dano_inimigo(andar: int) -> int:
	return 1 + int((andar - 1) / 2)

static func vida_chefe(andar: int, fase: int) -> int:
	var vida: int = vida_inimigo(andar, fase)
	return vida * 2 + 4 if fase == FASES_POR_ANDAR else vida + 3

static func dano_chefe(andar: int, fase: int) -> int:
	return dano_inimigo(andar) + (2 if fase == FASES_POR_ANDAR else 1)

static func xp_inimigo(andar: int, tipo: String) -> int:
	if tipo == "boss":
		return 20 + 5 * andar
	if tipo == "mini":
		return 8 + 2 * andar
	return 2 + andar

static func gold_inimigo(andar: int, tipo: String) -> int:
	if tipo == "boss":
		return randi_range(15, 25) * andar
	if tipo == "mini":
		return randi_range(5, 9) * andar
	return randi_range(1, 3) * andar
