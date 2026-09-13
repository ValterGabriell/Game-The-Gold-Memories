extends Area2D

@export var areaDeSaida: Area2D
const TEMPO_PARA_DESABILITAR_AREA: float = 5.0
const DURACAO_TRANSICAO_CAMERA: float = 1.0 # Tempo em segundos para a câmera mover

func _on_body_entered(body: Node2D) -> void:
	if body is Player and areaDeSaida:
		var player = body as Player
		
		# 1. Desabilita entrada e movimento do Player durante o transporte
		player.set_physics_process(false)
		
		# Desativa temporariamente a área de saída para evitar loop de teleporte
		areaDeSaida.monitoring = false
		
		# 2. Pega a câmera atual do Player/Cena
		var camera = get_viewport().get_camera_2d()
		
		if camera:
			# Desativa o acompanhamento automático da câmera enquanto ela se move
			var posicao_original_offset = camera.position
			var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			
			# Move a câmera suavemente até a posição de saída
			tween.tween_property(camera, "global_position", areaDeSaida.global_position, DURACAO_TRANSICAO_CAMERA)
			await tween.finished
			
			# 3. Teleporta o player para o destino e reativa a física
			player.global_position = areaDeSaida.global_position
			camera.position = posicao_original_offset # Reseta o offset relativo ao player
			player.set_physics_process(true)
		else:
			# Fallback caso não encontre a câmera
			player.global_position = areaDeSaida.global_position
			player.set_physics_process(true)

		# Reativa o monitoramento da área após o tempo estipulado
		await get_tree().create_timer(TEMPO_PARA_DESABILITAR_AREA).timeout
		areaDeSaida.monitoring = true