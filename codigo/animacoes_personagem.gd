extends Node2D

@export var animated:AnimatedSprite2D
@export var player: Player

const ANIM_IDLE := "idle"
const ANIM_WALK := "walk"
const ANIM_JUMP := "jump"
const ANIM_WALL_JUMP := "wall_jump"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if animated != null:
		if animated.sprite_frames != null and animated.sprite_frames.has_animation(ANIM_JUMP):
			animated.sprite_frames.set_animation_loop(ANIM_JUMP, false)
		if animated.sprite_frames != null and animated.sprite_frames.has_animation(ANIM_WALL_JUMP):
			animated.sprite_frames.set_animation_loop(ANIM_WALL_JUMP, false)
		animated.play(ANIM_IDLE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if animated == null or player == null:
		return

	_update_facing_direction()

	var target_animation := _get_target_animation()
	if animated.animation != target_animation:
		animated.play(target_animation)

func _get_target_animation() -> StringName:
	if _is_wall_sliding():
		return ANIM_WALL_JUMP

	if not player.is_on_floor():
		return ANIM_JUMP

	if absf(player.velocity.x) > 0.1:
		return ANIM_WALK

	return ANIM_IDLE

func _is_wall_sliding() -> bool:
	return player.is_on_wall_only() and not player.is_on_floor() and player.velocity.y >= 0.0

func _update_facing_direction() -> void:
	if player.is_on_wall_only():
		var wall_normal_x := player.get_wall_normal().x
		if absf(wall_normal_x) > 0.001:
			animated.flip_h = sign(wall_normal_x) > 0
			return

	if player.look_dir_x != 0:
		animated.flip_h = player.look_dir_x > 0
