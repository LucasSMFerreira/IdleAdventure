class_name AnimacaoSprites
extends RefCounted

const QUADRO = 64

static func montar(prefixo: String, acoes: Array) -> SpriteFrames:
	var quadros: SpriteFrames = SpriteFrames.new()
	for acao in acoes:
		var caminho: String = "res://assets/sprites/%s_%s_sheet.svg" % [prefixo, acao]
		var textura: Texture2D = ResourceLoader.load(caminho) as Texture2D
		if textura == null or textura.get_height() != QUADRO or textura.get_width() % QUADRO != 0:
			push_error("Spritesheet inválido: " + caminho)
			continue
		quadros.add_animation(acao)
		quadros.set_animation_speed(acao, 10.0)
		quadros.set_animation_loop_mode(acao, SpriteFrames.LOOP_LINEAR if acao == "idle" or acao == "walk" else SpriteFrames.LOOP_NONE)
		for indice in range(textura.get_width() / QUADRO):
			var quadro: AtlasTexture = AtlasTexture.new()
			quadro.atlas = textura
			quadro.region = Rect2(indice * QUADRO, 0, QUADRO, QUADRO)
			quadros.add_frame(acao, quadro)
	return quadros
