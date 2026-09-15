class_name Cenario
extends Node2D

const CEU = preload("res://assets/sprites/sky_loop.svg")
const FUNDO = preload("res://assets/sprites/background_far_sheet.svg")
const CHAO = preload("res://assets/sprites/ground_tiles_sheet.svg")
const OBJETOS = preload("res://assets/sprites/props_mid_sheet.svg")

var andar = 1
var fase = 1

func configurar(novo_andar: int, nova_fase: int):
	andar = novo_andar
	fase = nova_fase
	queue_redraw()

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw():
	for coluna in range(8):
		var quadro_ceu = (coluna + andar) % 2
		draw_texture_rect_region(CEU, Rect2(coluna * 128, 0, 128, 180), Rect2(quadro_ceu * 64, 0, 64, 64))
	for coluna in range(7):
		var quadro_fundo = (coluna + andar + int((fase - 1) / 3)) % 6
		draw_texture_rect_region(FUNDO, Rect2(coluna * 160, 70, 160, 170), Rect2(quadro_fundo * 64, 0, 64, 64))
	for coluna in range(10):
		var quadro_chao = (coluna + andar + fase) % 5
		draw_texture_rect_region(CHAO, Rect2(coluna * 100, 240, 100, 60), Rect2(quadro_chao * 64, 38, 64, 26))
	for indice in range(3):
		var quadro_objeto = (andar + fase + indice * 2) % 6
		var x = 215 + indice * 290
		draw_texture_rect_region(OBJETOS, Rect2(x, 177, 64, 64), Rect2(quadro_objeto * 64, 0, 64, 64))
