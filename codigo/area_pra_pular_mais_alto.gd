extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.jump_type = Player.JumpType.LONG


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		await get_tree().create_timer(0.5).timeout
		body.jump_type = Player.JumpType.SHORT