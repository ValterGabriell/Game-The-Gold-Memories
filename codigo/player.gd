class_name Player
extends CharacterBody2D

enum JumpType {
	NONE,
	SHORT,
	LONG,
	END_GAME
}

enum ControlState {
	PLAYER_CONTROLLED,
	LOCKED_BY_DIALOG,
	LOCKED_BY_CAMERA
}

enum EndGameState {
	INACTIVE,
	ARMED,
	TRANSITIONING
}

const SPEED = 50.0
const JUMP_VELOCITY: float = -130.0
const JUMP_WHEN_CAN_GO_UPPER: float = -200
const LONG_JUMP_HOLD_TIME: float = 0.3
const END_GAME_TIME_SCALE: float = 0.5
const END_GAME_CREDITS_SCENE_PATH: String = "res://creditos.tscn"
const END_GAME_FADE_DURATION: float = 4.8
const END_GAME_FADE_COLOR: Color = Color("#fafbf6")

const GRAVITY_WALL: float = 60.0
const WALL_JUMP_PUSH_FORCE: float = 120.0
@export var wall_jump_coyote_time: float = 1.15
var wall_jump_coyote_timer: float = 0.0

var wall_jump_lock: float = 0.0
const WALL_JUMP_LOCK_TIME: float = 0.1

var look_dir_x: int = 1 

var control_state: ControlState = ControlState.PLAYER_CONTROLLED
var end_game_state: EndGameState = EndGameState.INACTIVE

@export var max_jump_time: float = 0.12
var jump_timer: float = 0.0
var is_jumping: bool = false
var jump_type: JumpType = JumpType.NONE

# PRE-CARREGAMENTO DOS SONS
const SFX_WALK = preload("res://arte/msc/walk.mp3")
const SFX_JUMP = preload("res://arte/msc/jump.mp3")
const SFX_JUMP_HIGH = preload("res://arte/msc/jump-high_square.mp3")
const SFX_GAME_OVER = preload("res://arte/msc/gameo_over.wav")
const SFX_END_GAME = preload("res://arte/msc/end_game.wav")

var _walk_player: AudioStreamPlayer2D
var _jump_player: AudioStreamPlayer2D
var _jump_high_player: AudioStreamPlayer2D
var _game_over_player: AudioStreamPlayer
var _end_game_player: AudioStreamPlayer

# ELEMENTOS VISUAIS PARA TRANSICAO (FADE)
var _canvas_layer: CanvasLayer
var _fade_rect: ColorRect
var _esta_morto: bool = false

func _ready() -> void:
	SignalManager.evt_dialogo_iniciado.connect(_on_dialog_started)
	SignalManager.evt_dialogo_finalizado.connect(_on_dialog_finished)
	
	# Criação dos nós de áudio
	_walk_player = AudioStreamPlayer2D.new()
	_walk_player.stream = SFX_WALK
	_walk_player.volume_db = -15
	add_child(_walk_player)

	_jump_player = AudioStreamPlayer2D.new()
	_jump_player.stream = SFX_JUMP
	_jump_player.volume_db = -10
	add_child(_jump_player)

	_jump_high_player = AudioStreamPlayer2D.new()
	_jump_high_player.stream = SFX_JUMP_HIGH
	_jump_high_player.volume_db = -10
	add_child(_jump_high_player)

	_game_over_player = AudioStreamPlayer.new()
	_game_over_player.stream = SFX_GAME_OVER
	_game_over_player.volume_db = -10
	add_child(_game_over_player)

	_end_game_player = AudioStreamPlayer.new()
	_end_game_player.stream = SFX_END_GAME
	_end_game_player.volume_db = -20
	add_child(_end_game_player)

	# Criação do Overlay de Fade em código
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 100
	add_child(_canvas_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 1) # Começa preto ao carregar a cena
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas_layer.add_child(_fade_rect)

	# FADE IN: Clareia a tela ao iniciar/recarregar a cena
	var tween = create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, 0.5)

func set_control_state(new_state: ControlState) -> void:
	control_state = new_state
	if control_state != ControlState.PLAYER_CONTROLLED and _walk_player and _walk_player.playing:
		_walk_player.stop()

func arm_end_game_jump() -> void:
	if end_game_state == EndGameState.INACTIVE:
		end_game_state = EndGameState.ARMED

func _get_jump_velocity() -> float:
	if end_game_state == EndGameState.ARMED or end_game_state == EndGameState.TRANSITIONING:
		return JUMP_WHEN_CAN_GO_UPPER

	return JUMP_WHEN_CAN_GO_UPPER if jump_type == JumpType.LONG else JUMP_VELOCITY

func _get_jump_hold_time() -> float:
	if end_game_state == EndGameState.INACTIVE and jump_type == JumpType.LONG:
		return LONG_JUMP_HOLD_TIME

	return max_jump_time

func _start_end_game_transition() -> void:
	if end_game_state != EndGameState.TRANSITIONING:
		return

	Engine.time_scale = END_GAME_TIME_SCALE
	set_control_state(ControlState.LOCKED_BY_DIALOG)
	_stop_all_playing_audio(_end_game_player)
	_end_game_player.play()

	_fade_rect.color = Color(END_GAME_FADE_COLOR.r, END_GAME_FADE_COLOR.g, END_GAME_FADE_COLOR.b, 0.0)
	var tween = create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, END_GAME_FADE_DURATION)
	await tween.finished

	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(END_GAME_CREDITS_SCENE_PATH)

func _stop_all_playing_audio(except_player: Node = null) -> void:
	_stop_playing_audio_in_node(get_tree().current_scene, except_player)

func _stop_playing_audio_in_node(node: Node, except_player: Node) -> void:
	if node == null:
		return

	if node != except_player:
		if node is AudioStreamPlayer:
			var audio_player := node as AudioStreamPlayer
			if audio_player.playing:
				audio_player.stop()
		elif node is AudioStreamPlayer2D:
			var audio_player_2d := node as AudioStreamPlayer2D
			if audio_player_2d.playing:
				audio_player_2d.stop()

	for child in node.get_children():
		_stop_playing_audio_in_node(child, except_player)

func _physics_process(delta: float) -> void:
	if control_state != ControlState.PLAYER_CONTROLLED:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Input.get_axis("ui_left", "ui_right")
	
	if direction != 0:
		look_dir_x = sign(direction)

	if is_on_wall_only() and velocity.y > 0 and direction != 0:
		velocity.y = move_toward(velocity.y, GRAVITY_WALL, SPEED * delta)
		wall_jump_coyote_timer = wall_jump_coyote_time
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
		wall_jump_coyote_timer = max(wall_jump_coyote_timer - delta, 0.0)

	# LÓGICA DO PULO COM SOM
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = _get_jump_velocity()
			is_jumping = true
			jump_timer = 0.0
			_tocar_som_pulo()
			if end_game_state == EndGameState.ARMED:
				end_game_state = EndGameState.TRANSITIONING
				_start_end_game_transition()
		elif wall_jump_coyote_timer > 0.0:
			velocity.y = _get_jump_velocity()
			velocity.x = 0.0
			wall_jump_lock = WALL_JUMP_LOCK_TIME
			is_jumping = true
			jump_timer = 0.0
			wall_jump_coyote_timer = 0.0 
			_tocar_som_pulo()
			if end_game_state == EndGameState.ARMED:
				end_game_state = EndGameState.TRANSITIONING
				_start_end_game_transition()

	if Input.is_action_pressed("ui_accept") and is_jumping:
		jump_timer += delta
		if jump_timer < _get_jump_hold_time():
			velocity.y = _get_jump_velocity()
		else:
			if end_game_state == EndGameState.INACTIVE and jump_type == JumpType.LONG:
				velocity.y = JUMP_VELOCITY
			is_jumping = false

	if Input.is_action_just_released("ui_accept"):
		is_jumping = false

	if wall_jump_lock > 0.0:
		wall_jump_lock -= delta
	else:
		if direction != 0:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	_gerenciar_som_passos(direction)

func _gerenciar_som_passos(direction: float) -> void:
	if is_on_floor() and direction != 0:
		if not _walk_player.playing:
			_walk_player.play()
	else:
		if _walk_player.playing:
			_walk_player.stop()

func _tocar_som_pulo() -> void:
	if _walk_player.playing:
		_walk_player.stop()

	if jump_type == JumpType.LONG:
		_jump_high_player.play()
	else:
		_jump_player.play()

func _on_dialog_started() -> void:
	set_control_state(ControlState.LOCKED_BY_DIALOG)

func _on_dialog_finished(_deve_tirar_a_luz: bool, _numero_luz: int) -> void:
	if control_state != ControlState.LOCKED_BY_CAMERA:
		set_control_state(ControlState.PLAYER_CONTROLLED)

func morrer() -> void:
	if _esta_morto:
		return
	
	_esta_morto = true
	print("Player morreu")
	
	# Desativa os controles e para o som de passos
	set_control_state(ControlState.LOCKED_BY_DIALOG)
	if _walk_player and _walk_player.playing:
		_walk_player.stop()

	# 1. Toca o som de Game Over
	_game_over_player.play()

	# 2. FADE OUT: Escurece a tela suavemente
	var tween = create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, 3.5)
	
	# Aguarda a animação de escurecer terminar
	await tween.finished
	
	# 3. Reinicia a cena atual imediatamente
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()