@tool
extends Node3D
## World portal: a doorway that shows what is behind its partner doorway,
## and moves you there when you walk through it.
##
## How to use:
##   1. Put it in a door gap. Its blue axis (+Z) must point INTO the room
##      you look from.
##   2. Put a second portal anywhere else in the world, same size.
##   3. Point them at each other with "partner".

@export var partner: NodePath
@export var size := Vector2(1.0, 2.1)

const SCREEN_LAYER := 1 << 19      # portal cameras never draw portal screens
const FLIP := Basis(Vector3.UP, PI) # walking IN through one door = walking OUT of the other

var _partner: Node3D
var _viewport: SubViewport
var _camera: Camera3D
var _screen: MeshInstance3D

func _ready() -> void:
	add_to_group("portals")
	_screen = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	_screen.mesh = quad
	_screen.position.y = size.y / 2.0
	add_child(_screen)

	if Engine.is_editor_hint():
		# In the editor, just show a green see-through panel so you can find the portal.
		var hint := StandardMaterial3D.new()
		hint.albedo_color = Color(0.45, 0.85, 0.35, 0.35)
		hint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hint.cull_mode = BaseMaterial3D.CULL_DISABLED
		_screen.material_override = hint
		return

	_partner = get_node(partner)

	# A hidden camera that renders into its own little screen (a SubViewport).
	_viewport = SubViewport.new()
	_viewport.size = get_viewport().size
	add_child(_viewport)
	_viewport.world_3d = get_viewport().world_3d   # same world, different camera
	_camera = Camera3D.new()
	_camera.cull_mask &= ~SCREEN_LAYER
	_viewport.add_child(_camera)

	# The doorway shows that screen.
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://portal.gdshader")
	mat.set_shader_parameter("view", _viewport.get_texture())
	_screen.material_override = mat
	_screen.layers = SCREEN_LAYER

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var eye := get_viewport().get_camera_3d()
	# 1. Put the hidden camera where you WOULD be, if this doorway were the partner one.
	_camera.global_transform = to_partner(eye.global_transform)
	_camera.fov = eye.fov
	# 2. Skip everything between that camera and the partner doorway (its walls).
	_camera.near = maxf(0.05, absf(side(eye.global_position)) - 0.05)
	# 3. The screen only makes sense from the front.
	_screen.visible = side(eye.global_position) > 0.0
	_viewport.size = get_viewport().size

## Move a transform from "near this doorway" to "near the partner doorway".
func to_partner(t: Transform3D) -> Transform3D:
	return _partner.global_transform * Transform3D(FLIP) * global_transform.affine_inverse() * t

## Same, for a direction (like the player's velocity).
func to_partner_dir(v: Vector3) -> Vector3:
	return (_partner.global_basis * FLIP * global_basis.inverse()) * v

## How far in front of the doorway a point is (negative = behind it).
func side(p: Vector3) -> float:
	return (global_transform.affine_inverse() * p).z

func in_doorway(p: Vector3) -> bool:
	var l := global_transform.affine_inverse() * p
	return absf(l.x) < size.x / 2.0 and l.y > -0.5 and l.y < size.y + 0.5
