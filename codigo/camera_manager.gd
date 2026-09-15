extends Camera2D

@export var area_que_persegue_o_jogador: AreaQuePersegueOJogador
@export var player: Player
@export var camera_do_jogador: CameraDoJogador

var _alvo_atual_para_focar: Node2D = null
var _seguindo_monstro: bool = false
var _sequencia_camera_em_andamento: bool = false

enum CameraShakeState {
	INACTIVE,
	ACTIVE
}

@export_group("Tremor")
@export var intensidade_tremor_jogo: float = 0.2
@export var velocidade_transicao_tremor: float = 1.6

var _camera_shake_state: CameraShakeState = CameraShakeState.INACTIVE
var _intensidade_tremor_atual: float = 0.0
var _interacoes_luz_ativas: int = 0
var _has_played_monster_focus_sequence: bool = false

func _ready() -> void:
	SignalManager.evt_dialogo_finalizado.connect(_on_dialogo_finalizado)
	SignalManager.flag_evt_coletou_luz.connect(_on_coletou_luz)
	SignalManager.evt_interacao_luz_iniciada.connect(_on_interacao_luz_iniciada)
	SignalManager.evt_interacao_luz_finalizada.connect(_on_interacao_luz_finalizada)

func _process(delta: float) -> void:
	# Acompanha o monstro com validação de segurança contra null
	if _seguindo_monstro and is_instance_valid(area_que_persegue_o_jogador):
		global_position.y = area_que_persegue_o_jogador.global_position.y

	_atualizar_tremor_em_jogo(delta)

func _on_coletou_luz(numero_luz: int) -> void:
	if numero_luz == 1 and _camera_shake_state == CameraShakeState.INACTIVE:
		_camera_shake_state = CameraShakeState.ACTIVE

func _on_interacao_luz_iniciada(_numero_luz: int) -> void:
	_interacoes_luz_ativas += 1

func _on_interacao_luz_finalizada(_numero_luz: int) -> void:
	_interacoes_luz_ativas = max(_interacoes_luz_ativas - 1, 0)

func _atualizar_tremor_em_jogo(delta: float) -> void:
	if _sequencia_camera_em_andamento:
		return

	var tremor_pode_ficar_ativo: bool = _camera_shake_state == CameraShakeState.ACTIVE
	tremor_pode_ficar_ativo = tremor_pode_ficar_ativo and is_instance_valid(area_que_persegue_o_jogador)
	tremor_pode_ficar_ativo = tremor_pode_ficar_ativo and player != null
	tremor_pode_ficar_ativo = tremor_pode_ficar_ativo and player.control_state == Player.ControlState.PLAYER_CONTROLLED
	tremor_pode_ficar_ativo = tremor_pode_ficar_ativo and area_que_persegue_o_jogador.estado_atual == AreaQuePersegueOJogador.Estado.PERSEGUINDO

	var intensidade_alvo: float = 0.0
	if tremor_pode_ficar_ativo and _interacoes_luz_ativas == 0:
		intensidade_alvo = intensidade_tremor_jogo

	_intensidade_tremor_atual = move_toward(
		_intensidade_tremor_atual,
		intensidade_alvo,
		velocidade_transicao_tremor * delta
	)

	if _intensidade_tremor_atual <= 0.001:
		offset = Vector2.ZERO
		return

	offset = Vector2(
		randf_range(-_intensidade_tremor_atual, _intensidade_tremor_atual),
		randf_range(-_intensidade_tremor_atual, _intensidade_tremor_atual)
	)

func _on_dialogo_finalizado(_deve_tirar_a_luz: bool, _numero_luz: int) -> void:
	if _numero_luz != 1 or _has_played_monster_focus_sequence:
		return

	if _sequencia_camera_em_andamento:
		return

	_sequencia_camera_em_andamento = true
	await _executar_sequencia_camera_pos_dialogo()
	_sequencia_camera_em_andamento = false
	_has_played_monster_focus_sequence = true

func _executar_sequencia_camera_pos_dialogo() -> void:
	# Fallback: Tenta buscar o nó do monstro pelo grupo caso não tenha sido atribuído no Inspetor
	if not is_instance_valid(area_que_persegue_o_jogador):
		area_que_persegue_o_jogador = get_tree().get_first_node_in_group("Monstro") as AreaQuePersegueOJogador
		
	# Trava de segurança extra se a área do monstro continuar nula
	if not is_instance_valid(area_que_persegue_o_jogador):
		push_error("AreaQuePersegueOJogador não foi atribuída e não foi encontrada na cena.")
		return

	area_que_persegue_o_jogador.iniciar_musica()
	_alvo_atual_para_focar = area_que_persegue_o_jogador
	
	if player:
		player.set_control_state(Player.ControlState.LOCKED_BY_CAMERA)
	
	if camera_do_jogador:
		camera_do_jogador.camera_mode = CameraDoJogador.CameraMode.ANIMATING

	# 1. Descer tremendo até o alvo
	var pos_alvo = Vector2(global_position.x, _alvo_atual_para_focar.global_position.y)
	await _mover_e_tremer(pos_alvo, 2.0, 3.0)

	# 2. Monstro começa a perseguir
	if is_instance_valid(area_que_persegue_o_jogador):
		area_que_persegue_o_jogador.perseguir_jogador()

	# 3. A câmera acompanha o monstro perseguindo por 4 segundos
	_seguindo_monstro = true
	await get_tree().create_timer(3.0).timeout
	_seguindo_monstro = false

	# 4. Volta a câmera suavemente para a posição atual do jogador
	if player:
		var pos_retorno = Vector2(global_position.x, player.global_position.y)
		var tween_voltar = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween_voltar.tween_property(self, "global_position", pos_retorno, 1.2)
		await tween_voltar.finished

	# Reativa o acompanhamento automático e libera os controles
	if camera_do_jogador:
		camera_do_jogador.camera_mode = CameraDoJogador.CameraMode.FOLLOW_PLAYER
	if player:
		player.set_control_state(Player.ControlState.PLAYER_CONTROLLED)

func _mover_e_tremer(posicao_destino: Vector2, duracao: float, intensidade: float) -> void:
	var tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", posicao_destino, duracao)
	
	var tempo_decorrido = 0.0
	while tempo_decorrido < duracao:
		offset = Vector2(
			randf_range(-intensidade, intensidade),
			randf_range(-intensidade, intensidade)
		)
		tempo_decorrido += get_process_delta_time()
		await get_tree().process_frame

	offset = Vector2.ZERO
	await tween.finished

func _tremer_camera(duracao: float, intensidade: float) -> void:
	var tempo_decorrido = 0.0
	while tempo_decorrido < duracao:
		offset = Vector2(
			randf_range(-intensidade, intensidade),
			randf_range(-intensidade, intensidade)
		)
		tempo_decorrido += get_process_delta_time()
		await get_tree().process_frame

	offset = Vector2.ZERO
