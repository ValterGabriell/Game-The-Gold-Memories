class_name Player
extends CharacterBody2D

enum JumpType {
	NONE,
	SHORT,
	LONG
}

enum ControlState {
	PLAYER_CONTROLLED,
	LOCKED_BY_DIALOG,
	LOCKED_BY_CAMERA
}

const SPEED = 50.0
const JUMP_VELOCITY: float = -130.0
const JUMP_WHEN_CAN_GO_UPPER: float = -300

const GRAVITY_WALL: float = 60.0
const WALL_JUMP_PUSH_FORCE: float = 120.0
@export var wall_jump_coyote_time: float = 1.15
var wall_jump_coyote_timer: float = 0.0

var wall_jump_lock: float = 0.0
const WALL_JUMP_LOCK_TIME: float = 0.1

var look_dir_x: int = 1 

var control_state: ControlState = ControlState.PLAYER_CONTROLLED

@export var max_jump_time: float = 0.12
var jump_timer: float = 0.0
var is_jumping: bool = false
var jump_type: JumpType = JumpType.NONE

# PRE-CARREGAMENTO DOS SONS
const SFX_WALK = preload("res://arte/msc/walk.mp3")
const SFX_JUMP = preload("res://arte/msc/jump.mp3")
const SFX_JUMP_HIGH = preload("res://arte/msc/jump-high_square.mp3")
const SFX_GAME_OVER = preload("res://arte/msc/gameo_over.wav")

var _walk_player: AudioStreamPlayer2D
var _jump_player: AudioStreamPlayer2D
var _jump_high_player: AudioStreamPlayer2D
var _game_over_player: AudioStreamPlayer

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
	add_child(_walk_player)

	_jump_player = AudioStreamPlayer2D.new()
	_jump_player.stream = SFX_JUMP
	add_child(_jump_player)

	_jump_high_player = AudioStreamPlayer2D.new()
	_jump_high_player.stream = SFX_JUMP_HIGH
	add_child(_jump_high_player)

	_game_over_player = AudioStreamPlayer.new()
	_game_over_player.stream = SFX_GAME_OVER
	add_child(_game_over_player)

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
			velocity.y = JUMP_WHEN_CAN_GO_UPPER if jump_type == JumpType.LONG else JUMP_VELOCITY
			is_jumping = true
			jump_timer = 0.0
			_tocar_som_pulo()
		elif wall_jump_coyote_timer > 0.0:
			velocity.y = JUMP_WHEN_CAN_GO_UPPER if jump_type == JumpType.LONG else JUMP_VELOCITY
			velocity.x = 0.0
			wall_jump_lock = WALL_JUMP_LOCK_TIME
			is_jumping = true
			jump_timer = 0.0
			wall_jump_coyote_timer = 0.0 
			_tocar_som_pulo()

	if Input.is_action_pressed("ui_accept") and is_jumping:
		jump_timer += delta
		if jump_timer < max_jump_time:
			velocity.y = JUMP_WHEN_CAN_GO_UPPER if jump_type == JumpType.LONG else JUMP_VELOCITY
		else:
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
	get_tree().reload_current_scene()