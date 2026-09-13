extends Node

@export var dialog_scene: PackedScene
@export_file("*.json") var json_path: String = "res://json/dialogos.json"
@export var idioma_atual: String = "en" 

var dialogs_data: Dictionary = {}
var dialog_box = null
var is_showing_dialog: bool = false

func _ready() -> void:
	_carregar_json()

func _carregar_json() -> void:
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		
		if parse_result == OK:
			dialogs_data = json.data.get("dialogs", {})

func obter_textos_por_evento(nome_evento: String) -> Array[String]:
	var resultado: Array[String] = []
	if dialogs_data.has(nome_evento):
		var evento_dict = dialogs_data[nome_evento]
		if evento_dict.has(idioma_atual):
			for linha in evento_dict[idioma_atual]:
				resultado.append(str(linha))
	return resultado
