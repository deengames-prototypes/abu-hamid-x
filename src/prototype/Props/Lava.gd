extends Area2D


func _on_Lava_body_entered(body):
	if body.has_method('_death'):
		body._death()
