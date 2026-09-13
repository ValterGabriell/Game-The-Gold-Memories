class_name Dialogo extends Control


var texts_to_display: Array[String] = []
var current_index : int = 0
var typing_speed : float = 0.05
var is_typing : bool = false

@export var canvas : CanvasLayer
var text_label: Label

var _dialogo_atual_event_name: String = ""
var _dialogo_atual_numero_luz: int = 0

func _ready() -> void:
	text_label = canvas.get_node("Sprite2D/Texto")
	pivot_offset = size / 2
	self.scale = Vector2.ZERO
	
	SignalManager.evt_dialogo_payload_iniciado.connect(_exibir_dialogo)
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	
	if texts_to_display.size() > 0:
		show_text()

func show_text() -> void:
	if current_index < texts_to_display.size():
		is_typing = true
		
		text_label.text = ""
		_type_text(texts_to_display[current_index])
	else:
		_close_dialog()

func _type_text(text: String) -> void:
	for i in range(text.length()):
		if not is_typing:
			break
		text_label.text += text[i]
		await get_tree().create_timer(typing_speed).timeout
	
	text_label.text = text
	is_typing = false
	

func _close_dialog() -> void:
	is_typing = true
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK)
	await tween.finished
	canvas.visible = false
	_checa_qual_foi_o_evento_pra_disparar_algo()
	

	_dialogo_atual_event_name = ""
	_dialogo_atual_numero_luz = 0
	texts_to_display.clear()
	current_index = 0
	is_typing = false
	

func _unhandled_input(event: InputEvent) -> void:
	if not canvas.visible or texts_to_display.is_empty():
		return

	if event.is_action_pressed("ui_accept"):
		if is_typing:
			is_typing = false
			text_label.text = texts_to_display[current_index]
		else:
			if current_index + 1 < texts_to_display.size():
				current_index += 1
				show_text()
			else:
				_close_dialog()

func _exibir_dialogo(texts: Array[String], event_name: String, numero_luz: int) -> void:
	_exibir_canvas_layer()
	_dialogo_atual_event_name = event_name
	_dialogo_atual_numero_luz = numero_luz
	texts_to_display = texts
	show_text()

func _exibir_canvas_layer() -> void:
	canvas.visible = true

func _checa_qual_foi_o_evento_pra_disparar_algo() -> void:
	if _dialogo_atual_numero_luz <= 0:
		return
	SignalManager.emitir_evt_dialogo_finalizado_por_luz(_dialogo_atual_numero_luz)
	
