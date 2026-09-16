class_name Cenario
extends Node2D

const CEU = preload("res://assets/sprites/sky_loop.svg")
const SOL = preload("res://assets/sprites/sun.svg")
const FUNDO = preload("res://assets/sprites/background_far_sheet.svg")
const CHAO = preload("res://assets/sprites/ground_tiles_sheet.svg")
const OBJETOS = preload("res://assets/sprites/props_mid_sheet.svg")
const BIOMAS = preload("res://assets/sprites/floor_biomes_sheet.svg")

var andar = 1
var fase = 1
var tempo = 0.0
const TONS_CEU = [
	Color(1, 1, 1), Color(0.92, 0.85, 1), Color(1, 0.94, 0.82),
	Color(0.86, 1, 0.9), Color(1, 0.85, 0.86), Color(0.9, 0.94, 1),
	Color(1, 0.9, 0.78), Color(0.87, 0.86, 1), Color(0.84, 1, 0.96),
	Color(1, 0.82, 0.74),
]

func configurar(novo_andar: int, nova_fase: int):
	andar = novo_andar
	fase = nova_fase
	queue_redraw()

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta):
	tempo += delta
	queue_redraw()

func _draw():
	var cor_ceu = TONS_CEU[(andar - 1) % TONS_CEU.size()]
	var cor_fundo = cor_ceu.lerp(Color(0.95, 0.95, 0.95), 0.5)
	var passo_ceu = fmod(tempo * 8.0, 128.0)
	var passo_fundo = fmod(tempo * 2.0, 160.0)
	for coluna in range(9):
		var quadro_ceu = (coluna + andar) % 2
		draw_texture_rect_region(CEU, Rect2(coluna * 128 - passo_ceu, 0, 128, 180), Rect2(quadro_ceu * 64, 0, 64, 64), cor_ceu)
	draw_texture_rect(SOL, Rect2(580, 10, 105, 105), false, cor_ceu)
	for coluna in range(8):
		var quadro_fundo = (coluna + andar + int((fase - 1) / 3)) % 6
		draw_texture_rect_region(FUNDO, Rect2(coluna * 160 - passo_fundo, 70, 160, 170), Rect2(quadro_fundo * 64, 0, 64, 64), cor_fundo)
	for coluna in range(10):
		var quadro_chao = (coluna + andar + fase) % 5
		draw_texture_rect_region(CHAO, Rect2(coluna * 100, 240, 100, 60), Rect2(quadro_chao * 64, 0, 64, 64))
	var quantidade_biomas = 2 if andar <= 2 else (3 if andar <= 5 else 5)
	for indice in range(quantidade_biomas):
		var x_bioma = 180 + int(640.0 * indice / maxi(quantidade_biomas - 1, 1))
		draw_texture_rect_region(BIOMAS, Rect2(x_bioma, 184, 48, 56), Rect2((andar - 1) * 64, 0, 64, 64))
	for indice in range(3):
		var quadro_objeto = (andar + fase + indice * 2) % 6
		var x = 215 + indice * 290
		draw_texture_rect_region(OBJETOS, Rect2(x, 177, 64, 64), Rect2(quadro_objeto * 64, 0, 64, 64))
