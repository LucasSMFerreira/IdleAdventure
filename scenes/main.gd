extends Node2D

func _on_player_atacou(alvo: Node):
	if is_instance_valid(alvo) and alvo.has_method("receber_dano"):
		alvo.call("receber_dano", 1)
