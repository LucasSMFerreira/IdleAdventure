class_name Progressao
extends RefCounted

const TOTAL_ANDARES = 10
const FASES_POR_ANDAR = 10
const CICLOS_POR_FASE = 3

static func quantidade_inimigos(andar: int, fase: int, ciclo: int) -> int:
	return mini(2 + int((fase - 1) / 3) + int((andar - 1) / 3) + ciclo - 1, 6)

static func vida_inimigo(andar: int, fase: int) -> int:
	return 3 + int((fase - 1) / 3) + andar - 1

static func dano_inimigo(andar: int) -> int:
	return 1 + int((andar - 1) / 3)
