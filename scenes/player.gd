extends CharacterBody2D

var velocidade = 100.0
var inimigo_perto = false

func _physics_process(_delta):
	velocity.x = 0.0 if inimigo_perto else velocidade
	move_and_slide()

func _on_detection_body_entered(body):
	if body.is_in_group("enemy"):
		inimigo_perto = true
