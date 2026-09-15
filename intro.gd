extends CanvasLayer

@export var audio: AudioStreamPlayer2D
@export var fade_rect: ColorRect

# Configuração de tempos
@export var fade_in_duration: float = 2.0
@export var hold_duration: float = 2
@export var fade_out_duration: float = 2.0

# Caminho da próxima cena
@export_file("*.tscn") var next_scene: String = "res://cena.tscn"

func _ready() -> void:
	start_splash_sequence()

func start_splash_sequence() -> void:
	# Garantir que o retângulo cubra a tela e comece totalmente opaco (preto)
	if fade_rect:
		fade_rect.color.a = 1.0
	
	# Iniciar a música se não estiver tocando
	if audio and not audio.playing:
		audio.play()
	
	# Criar o Tween para a sequência de animação
	var tween = create_tween()
	
	# 1. Fade In lento (preto ficando transparente)
	tween.tween_property(fade_rect, "color:a", 0.0, fade_in_duration)
	
	# 2. Espera de 5 segundos na tela
	tween.tween_interval(hold_duration)
	
	# 3. Fade Out lento da tela + Fade Out do volume do áudio (paralelos)
	tween.tween_property(fade_rect, "color:a", 1.0, fade_out_duration)
	
	if audio:
		# Transiciona o volume em dB até o silêncio (-80 dB)
		tween.parallel().tween_property(audio, "volume_db", -80.0, fade_out_duration)
	
	# 4. Trocar de cena ao finalizar as animações
	tween.tween_callback(change_scene)

func change_scene() -> void:
	get_tree().change_scene_to_file(next_scene)