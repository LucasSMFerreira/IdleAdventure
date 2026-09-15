extends CharacterBody2D

var velocidade = 100.0

func _physics_process(delta):
	velocity.x = velocidade
	move_and_slide()
