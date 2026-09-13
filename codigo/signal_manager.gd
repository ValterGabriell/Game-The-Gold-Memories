extends  Node

const MAX_DIALOGS: int = 5
const DIALOG_EVENT_BY_LIGHT: Dictionary = {
	1: "evt_coletou_primeira_luz",
	2: "evt_coletou_segunda_luz",
	3: "evt_coletou_terceira_luz",
	4: "evt_coletou_quarta_luz",
	5: "evt_coletou_quinta_luz"
}

signal flag_evt_coletou_luz(numero_luz: int)
signal flag_evt_coletou_primeira_luz
signal flag_evt_coletou_segunda_luz
signal flag_evt_coletou_terceira_luz
signal evt_primeiro_dialogo_finalizado
signal evt_segundo_dialogo_finalizado
signal evt_terceiro_dialogo_finalizado
signal evt_dialogo_finalizado(deveTirarALuz:bool,numeroLuz: int)
signal evt_dialogo_payload_iniciado(texts_to_display: Array[String], event_name: String, numero_luz: int)
signal evt_primeiro_dialogo_iniciado(texts_to_display: Array[String], event_name: String)
signal evt_dialogo_iniciado
signal evt_segundo_dialogo_iniciado(texts_to_display: Array[String], event_name: String)
signal evt_terceiro_dialogo_iniciado(texts_to_display: Array[String], event_name: String)
signal evt_interacao_luz_iniciada(numero_luz: int)
signal evt_interacao_luz_finalizada(numero_luz: int)

func _obter_evento_por_numero_luz(numero_luz: int) -> String:
	if not DIALOG_EVENT_BY_LIGHT.has(numero_luz):
		return ""
	return str(DIALOG_EVENT_BY_LIGHT[numero_luz])

func emitir_evt_coletou_luz(numero_luz: int) -> void:
	if numero_luz < 1 or numero_luz > MAX_DIALOGS:
		push_warning("Numero de luz invalido para dialogo: %d" % numero_luz)
		return

	emit_signal("flag_evt_coletou_luz", numero_luz)

	match numero_luz:
		1:
			emit_signal("flag_evt_coletou_primeira_luz")
		2:
			emit_signal("flag_evt_coletou_segunda_luz")
		3:
			emit_signal("flag_evt_coletou_terceira_luz")

func emitir_evt_coletou_primeira_luz() -> void:
	emitir_evt_coletou_luz(1)

func emitir_evt_coletou_segunda_luz() -> void:
	emitir_evt_coletou_luz(2)

func emitir_evt_dialogo_iniciado_por_luz(numero_luz: int) -> void:
	var event_name: String = _obter_evento_por_numero_luz(numero_luz)
	if event_name.is_empty():
		push_warning("Evento de dialogo nao encontrado para a luz: %d" % numero_luz)
		return

	var texts_to_display: Array[String] = DialogManager.obter_textos_por_evento(event_name)
	emit_signal("evt_dialogo_payload_iniciado", texts_to_display, event_name, numero_luz)

	match numero_luz:
		1:
			emit_signal("evt_primeiro_dialogo_iniciado", texts_to_display, event_name)
		2:
			emit_signal("evt_segundo_dialogo_iniciado", texts_to_display, event_name)
		3:
			emit_signal("evt_terceiro_dialogo_iniciado", texts_to_display, event_name)

	emit_signal("evt_dialogo_iniciado")

func emitir_evt_dialogo_finalizado_por_luz(numero_luz: int) -> void:
	match numero_luz:
		1:
			emit_signal("evt_primeiro_dialogo_finalizado")
		2:
			emit_signal("evt_segundo_dialogo_finalizado")
		3:
			emit_signal("evt_terceiro_dialogo_finalizado")

	emit_signal("evt_dialogo_finalizado", true, numero_luz)

func emitir_evt_primeiro_dialogo_finalizado() -> void:
	emitir_evt_dialogo_finalizado_por_luz(1)

func emitir_evt_segundo_dialogo_finalizado() -> void:
	emitir_evt_dialogo_finalizado_por_luz(2)

func emitir_evt_terceiro_dialogo_finalizado() -> void:
	emitir_evt_dialogo_finalizado_por_luz(3)



func emitir_evt_primeiro_dialogo_iniciado() -> void:
	emitir_evt_dialogo_iniciado_por_luz(1)

func emitir_evt_segundo_dialogo_iniciado() -> void:
	emitir_evt_dialogo_iniciado_por_luz(2)

func emitir_evt_terceiro_dialogo_iniciado() -> void:
	emitir_evt_dialogo_iniciado_por_luz(3)

func emitir_evt_interacao_luz_iniciada(numero_luz: int) -> void:
	emit_signal("evt_interacao_luz_iniciada", numero_luz)

func emitir_evt_interacao_luz_finalizada(numero_luz: int) -> void:
	emit_signal("evt_interacao_luz_finalizada", numero_luz)
