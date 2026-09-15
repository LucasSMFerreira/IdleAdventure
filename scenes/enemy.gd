class_name Enemy
extends CharacterBody2D

signal atacou(alvo: Player, dano: int)
signal morreu(tipo: String)

var vida_maxima = 3
var vida_atual = vida_maxima
var dano = 1
var tipo = "normal"
var especie = "enemy_slime"
var escala_base = 1.0
var ataques = 0
var alvo: Player

@onready var visual: AnimatedSprite2D = $Visual
@onready var texto_vida: Label = $Vida
@onready var barra_vida: ProgressBar = $BarraVida
@onready var tempo_ataque: Timer = $TempoAtaque

func configurar(nova_vida: int, novo_dano: int, novo_tipo: String = "normal", nova_especie: String = "enemy_slime"):
	vida_maxima = nova_vida
	vida_atual = nova_vida
	dano = novo_dano
	tipo = novo_tipo
	especie = nova_especie
	if tipo == "mini":
		especie = "miniboss_orc"
		escala_base = 1.1
	elif tipo == "boss":
		especie = "boss_orc_king"
		escala_base = 1.25

func _ready():
	var acoes = ["idle", "attack", "hit", "death"]
	if tipo == "boss":
		acoes.append("special")
	visual.sprite_frames = AnimacaoSprites.montar(especie, acoes)
	visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual.scale = Vector2.ONE * escala_base
	visual.animation_finished.connect(_on_animation_finished)
	visual.play("idle")
	var fundo = StyleBoxFlat.new()
	fundo.bg_color = Color(0.13, 0.14, 0.17)
	barra_vida.add_theme_stylebox_override("background", fundo)
	var cheio = StyleBoxFlat.new()
	cheio.bg_color = Color(0.88, 0.3, 0.27) if tipo == "normal" else Color(0.96, 0.69, 0.3)
	barra_vida.add_theme_stylebox_override("fill", cheio)
	_atualizar_vida()

func receber_dano(valor: int):
	if vida_atual == 0:
		return
	vida_atual = maxi(vida_atual - valor, 0)
	_atualizar_vida()
	if vida_atual == 0:
		tempo_ataque.stop()
		visual.play("death")
		morreu.emit(tipo)
	else:
		visual.play("hit")

func _on_animation_finished():
	if visual.animation == "death":
		queue_free()
	elif vida_atual > 0:
		visual.play("idle")

func _on_area_ataque_body_entered(body):
	if body is Player and not body.derrotado and vida_atual > 0:
		alvo = body
		_atacar()
		tempo_ataque.start()

func _on_area_ataque_body_exited(body):
	if body == alvo:
		tempo_ataque.stop()
		alvo = null
		if vida_atual > 0:
			visual.play("idle")

func _atacar():
	if vida_atual > 0 and is_instance_valid(alvo) and not alvo.derrotado:
		ataques += 1
		var especial = tipo == "boss" and ataques % 3 == 0
		visual.play("special" if especial else "attack")
		var dano_final = dano + maxi(1, int(dano / 2)) if especial else dano
		atacou.emit(alvo, dano_final)

func _atualizar_vida():
	barra_vida.value = 100.0 * vida_atual / maxi(vida_maxima, 1)
	barra_vida.visible = vida_atual < vida_maxima and vida_atual > 0
	texto_vida.visible = tipo != "normal" and vida_atual > 0
	if tipo != "normal":
		texto_vida.text = "%s %d/%d" % ["BOSS" if tipo == "boss" else "MINI", vida_atual, vida_maxima]
