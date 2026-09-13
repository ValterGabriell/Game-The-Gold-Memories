class_name Luz 
extends Area2D

@export var player: Player
@export var numeroDaLuz: int
@export var dialogo:Dialogo
@export var audioStreamPlayer2D: AudioStreamPlayer2D
var _jogadorTaNaAreaPraColetar: bool = false

func _ready() -> void:
	SignalManager.evt_dialogo_finalizado.connect(_dialogo_finalizado)
func _dialogo_finalizado(deveTirarALuz: bool, numeroLuz: int) -> void:
	if deveTirarALuz and numeroLuz == numeroDaLuz:
		if _jogadorTaNaAreaPraColetar:
			SignalManager.emitir_evt_interacao_luz_finalizada(numeroDaLuz)
		_jogadorTaNaAreaPraColetar = false
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == player:
		_jogadorTaNaAreaPraColetar = true
		SignalManager.emitir_evt_interacao_luz_iniciada(numeroDaLuz)

func _on_body_exited(body: Node2D) -> void:
	if body == player:
		_jogadorTaNaAreaPraColetar = false
		SignalManager.emitir_evt_interacao_luz_finalizada(numeroDaLuz)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("coletar") and _jogadorTaNaAreaPraColetar:
		if audioStreamPlayer2D.playing:
			var tween = create_tween()
			tween.tween_property(audioStreamPlayer2D, "volume_db", 0.0, 0.5) 
		
		SignalManager.emitir_evt_coletou_luz(numeroDaLuz)


func _on_audio_stream_player_2d_finished() -> void:
	audioStreamPlayer2D.play()
		
