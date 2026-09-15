class_name AreaQuePersegueOJogador extends Area2D

@export_group("Player")
@export var player: Player

@export_group("Movimento")
@export var velocidade_perseguição: float = 20.0

@export var animatedSprite: AnimatedSprite2D
@export var audioStreamPlayer2D: AudioStreamPlayer2D


enum Estado {
	PARADO,
	PERSEGUINDO,
	PAUSADO_POR_DIALOGO
}

enum ModoVelocidadePerseguicao {
	NORMAL,
	TURBO_TERCEIRA_LUZ
}

var estado_atual: Estado = Estado.PARADO
var _estado_antes_do_dialogo: Estado = Estado.PARADO
var tempoParado: float = 0.0
var _modo_velocidade_perseguicao: ModoVelocidadePerseguicao = ModoVelocidadePerseguicao.NORMAL

func _ready() -> void:
	SignalManager.evt_dialogo_iniciado.connect(_on_dialogo_iniciado)
	SignalManager.evt_dialogo_finalizado.connect(_on_dialogo_finalizado)

func _process(delta: float) -> void:
	if estado_atual == Estado.PERSEGUINDO:
		if _modo_velocidade_perseguicao == ModoVelocidadePerseguicao.TURBO_TERCEIRA_LUZ:
			velocidade_perseguição = 45
		else:
			var distance = position.distance_to(player.position)
			if distance > 200.0:
				velocidade_perseguição = 50.0
			else:
				velocidade_perseguição = 20.0

		position.y -= velocidade_perseguição * delta
		audioStreamPlayer2D.volume_db = move_toward(audioStreamPlayer2D.volume_db, -15, 40.0 * delta)
		if not animatedSprite.is_playing():
			animatedSprite.play("default")
	elif estado_atual == Estado.PARADO or estado_atual == Estado.PAUSADO_POR_DIALOGO:
		if animatedSprite.is_playing():
			animatedSprite.stop()
		if audioStreamPlayer2D.playing:
			audioStreamPlayer2D.volume_db = move_toward(audioStreamPlayer2D.volume_db, -80.0, 40.0 * delta)
			if audioStreamPlayer2D.volume_db <= -80.0:
				audioStreamPlayer2D.stop()

func _on_body_entered(body: Node2D) -> void:
	if body == player:
		if audioStreamPlayer2D.playing:
			audioStreamPlayer2D.stop()
		player.morrer()
		return
	if body.name == "LIMITE":
		return
	if body: 
		body.queue_free()

func perseguir_jogador() -> void:
	estado_atual = Estado.PERSEGUINDO
	tempoParado = 0.0
	iniciar_musica()

func iniciar_musica() -> void:
	audioStreamPlayer2D.volume_db = 0.0
	if not audioStreamPlayer2D.playing:
		audioStreamPlayer2D.play()

func _on_dialogo_iniciado() -> void:
	_estado_antes_do_dialogo = estado_atual
	if estado_atual == Estado.PERSEGUINDO:
		estado_atual = Estado.PAUSADO_POR_DIALOGO

func _on_dialogo_finalizado(_deve_tirar_a_luz: bool, _numero_luz: int) -> void:
	if _numero_luz == 3:
		_modo_velocidade_perseguicao = ModoVelocidadePerseguicao.TURBO_TERCEIRA_LUZ

	if estado_atual == Estado.PAUSADO_POR_DIALOGO:
		estado_atual = _estado_antes_do_dialogo
	if estado_atual != Estado.PERSEGUINDO:
		estado_atual = Estado.PERSEGUINDO
	iniciar_musica()
