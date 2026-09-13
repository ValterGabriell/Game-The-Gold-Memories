extends Control

@export var quantidade_de_luzes: Label

func _ready() -> void:
	SignalManager.flag_evt_coletou_luz.connect(_on_evt_coletou_luz)

func _on_evt_coletou_luz(_numero_luz: int) -> void:
	quantidade_de_luzes.text = str(int(quantidade_de_luzes.text) + 1)
