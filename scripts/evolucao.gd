class_name Evolucao
extends RefCounted

const NIVEL_MAXIMO = 100

static func xp_para_proximo(nivel: int) -> int:
	return 20 + 5 * nivel

static func vida_maxima(nivel: int) -> int:
	return 20 + int((nivel - 1) / 2)

static func ataque(nivel: int) -> int:
	return 1 + int((nivel - 1) / 10)
