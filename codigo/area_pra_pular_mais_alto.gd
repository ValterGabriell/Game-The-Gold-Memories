extends Area2D

@export var is_end_game_area: bool = false


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var player_body := body as Player
		player_body.jump_type = Player.JumpType.LONG
		if is_end_game_area:
			player_body.arm_end_game_jump()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		var player_body := body as Player
		await get_tree().create_timer(1.5).timeout
		if is_instance_valid(player_body):
			player_body.jump_type = Player.JumpType.SHORT