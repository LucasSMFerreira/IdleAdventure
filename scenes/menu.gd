extends Control

@onready var escolha_andar: OptionButton = $Andar
@onready var lista_fases: GridContainer = $Fases
@onready var estado: Label = $Estado

func _ready():
	var ultimo_andar = int((EstadoJogo.maior_fase_liberada - 1) / Progressao.FASES_POR_ANDAR) + 1
	for andar in range(1, Progressao.TOTAL_ANDARES + 1):
		escolha_andar.add_item("Andar %d" % andar)
		escolha_andar.set_item_disabled(andar - 1, andar > ultimo_andar)
	escolha_andar.select(clampi(EstadoJogo.andar_escolhido, 1, ultimo_andar) - 1)
	escolha_andar.item_selected.connect(_mostrar_fases)
	_mostrar_fases(escolha_andar.selected)

func _mostrar_fases(indice: int):
	for botao in lista_fases.get_children():
		botao.free()
	var andar = indice + 1
	for fase in range(1, Progressao.FASES_POR_ANDAR + 1):
		var botao = Button.new()
		botao.custom_minimum_size = Vector2(120, 38)
		botao.text = "Fase 10 - Boss" if fase == 10 else "Fase %d" % fase
		botao.disabled = (andar - 1) * Progressao.FASES_POR_ANDAR + fase > EstadoJogo.maior_fase_liberada
		botao.pressed.connect(_iniciar_fase.bind(andar, fase))
		lista_fases.add_child(botao)
	var ultimo_andar = int((EstadoJogo.maior_fase_liberada - 1) / Progressao.FASES_POR_ANDAR) + 1
	var ultima_fase = (EstadoJogo.maior_fase_liberada - 1) % Progressao.FASES_POR_ANDAR + 1
	var mensagem = "Torre concluída! Você pode revisitar qualquer fase." if EstadoJogo.torre_concluida else "Liberado até: Andar %d, Fase %d." % [ultimo_andar, ultima_fase]
	estado.text = "%s  |  Nível %d/100" % [mensagem, EstadoJogo.nivel]

func _iniciar_fase(andar: int, fase: int):
	if EstadoJogo.selecionar_fase(andar, fase):
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_inventario_pressed():
	add_child(preload("res://scenes/inventario.tscn").instantiate())
