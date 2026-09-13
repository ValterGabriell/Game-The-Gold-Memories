extends Area2D

@export var areaDeSaida: Area2D
const TEMPO_PARA_DESABILITAR_AREA :float = 5.0

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if areaDeSaida:
			body.global_position = areaDeSaida.global_position
			areaDeSaida.monitoring = false
			await get_tree().create_timer(TEMPO_PARA_DESABILITAR_AREA).timeout
			areaDeSaida.monitoring = true


