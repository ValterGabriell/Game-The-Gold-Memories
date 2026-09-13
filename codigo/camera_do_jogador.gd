class_name CameraDoJogador 
extends Node2D

@export var camera: Camera2D
@export var player: Node2D

enum CameraMode {
	FOLLOW_PLAYER,
	ANIMATING
}

var camera_mode: CameraMode = CameraMode.FOLLOW_PLAYER

func _process(_delta: float) -> void:
	if camera and player and camera_mode == CameraMode.FOLLOW_PLAYER:
		camera.global_position.y = player.global_position.y