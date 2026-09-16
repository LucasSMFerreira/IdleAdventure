extends CanvasLayer

func _ready() -> void:
	layer = 20
	UIFactory.backdrop(self)
	var panel := UIFactory.frame(self, Vector2(150, 78), Vector2(340, 194))
	var info := UIFactory.text(panel, "MERCADOR DA TORRE\n\nGold: %d\n\nNovos estoques são liberados pelos bosses." % EstadoJogo.gold, Vector2(30, 20), Vector2(280, 115), 14, DarkTheme.GOLD)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UIFactory.action(panel, "Fechar", Vector2(110, 145), Vector2(120, 30), queue_free)
