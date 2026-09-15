extends Node

var caminho_save = "user://idle_adventure.json"
var maior_fase_liberada = 1
var andar_escolhido = 1
var fase_escolhida = 1
var torre_concluida = false

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

func salvar():
	var arquivo = FileAccess.open(caminho_save, FileAccess.WRITE)
	if arquivo:
		arquivo.store_string(JSON.stringify({
			"maior_fase_liberada": maior_fase_liberada,
			"torre_concluida": torre_concluida,
		}))

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
