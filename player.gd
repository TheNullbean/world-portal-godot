extends CharacterBody3D
## Simple first-person player: WASD to walk, mouse to look, Esc to free the mouse.
## The only portal-specific part is at the bottom of _physics_process.

@export var speed := 3.0
@export var mouse_sensitivity := 0.002
@export var auto_walk := false   # walks forward on its own (used for recording)

@onready var head: Camera3D = $Head

var _last_side := {}

func _ready() -> void:
	if "walk" in OS.get_cmdline_user_args():
		auto_walk = true
	if not auto_walk:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clampf(head.rotation.x, -1.4, 1.4)
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _physics_process(delta: float) -> void:
	var input := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	if auto_walk:
		input = Vector2(0, -0.6)
	var dir := (global_basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()

	# Portal check: did our head just walk into a doorway?
	for portal in get_tree().get_nodes_in_group("portals"):
		var now: float = portal.side(head.global_position)
		var before: float = _last_side.get(portal, now)
		_last_side[portal] = now
		# 0.1 m early, so the camera never touches the screen itself.
		if before >= 0.1 and now < 0.1 and portal.in_doorway(head.global_position):
			global_transform = portal.to_partner(global_transform)
			velocity = portal.to_partner_dir(velocity)
			_last_side.clear()
			break
