extends Node

enum Flags {
	COLETOU_PRIMEIRA_LUZ
}

@export var player: Node2D

func _ready() -> void:
	SignalManager.flag_evt_coletou_luz.connect(_executar_dialogo_por_luz)

func _executar_dialogo_por_luz(numero_luz: int) -> void:
	SignalManager.emitir_evt_dialogo_iniciado_por_luz(numero_luz)

func executar_primeira_luz() -> void:
	SignalManager.emitir_evt_primeiro_dialogo_iniciado()

func executar_segunda_luz() -> void:
	SignalManager.emitir_evt_segundo_dialogo_iniciado()
