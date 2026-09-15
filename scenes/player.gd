extends CharacterBody2D

signal atacou(alvo)

var velocidade = 100.0
var inimigo_perto = false
var alvo: CharacterBody2D

@onready var aviso_ataque: Label = $AvisoAtaque
@onready var tempo_ataque: Timer = $TempoAtaque
@onready var tempo_aviso: Timer = $TempoAviso

func _physics_process(_delta):
	velocity.x = 0.0 if inimigo_perto else velocidade
	move_and_slide()

func _on_detection_body_entered(body):
	if body is CharacterBody2D and body.is_in_group("enemy") and not inimigo_perto:
		alvo = body
		inimigo_perto = true
		_atacar()
		tempo_ataque.start()

func _atacar():
	if not is_instance_valid(alvo):
		return
	atacou.emit(alvo)
	aviso_ataque.show()
	tempo_aviso.start()

func _on_tempo_aviso_timeout():
	aviso_ataque.hide()
