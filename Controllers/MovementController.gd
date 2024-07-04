extends Node
class_name MovementController;

@export var playerEntity: Player = null;

@export var GRAVITY: int = ProjectSettings.get_setting("physics/3d/default_gravity");
@export_range(0, 1) var CAMERA_SENSITIVITY: float = 10;
@export var MOVEMENT_SPEED: float = 5.0;
@export var ACCELERATION: float = 20.0;
@export var JUMP_SPEED: float = 4.0;
@export var LEAN_ANGLE: float = 30.0;
@export var DASH_FORCE: float = 10.0;
@export var DASH_COUNT: int = 2;
@export var DASH_Y_REDUCTION_FACTOR = 5;
@export var SLIDE_FORCE: float = 0.5;
@export var SLIDE_DURATION: float = 1.0;
@export var SLIDE_ANGLE: float = 60.0;

enum LeanDirection {LEFT, RIGHT, NONE};
var leaning: LeanDirection = LeanDirection.NONE;

var dashing: bool = false;
var dashesUsed: int = 0;

const VECTOR_SLIDE_DIRECTION = Vector3(0, 0, -1) # Defines the base direction for sliding
var sliding: bool = false;
var slideTimer: float = 0.0;

var _mouse_position = Vector2(0, 0);
var _total_pitch = 0.0;

const JUMP_BUFFER_TIME = 0.1 # Time in seconds
var lastJumpPress = -1.0 # Time since the last jump press, initialized to an invalid value

func _init():
	# Capture the mouse inside of the window while controlling the camera
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	print_debug("Capturing mouse")

func process_input(event: InputEvent):
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_position = event.relative;

func performMovementJump(playerVelocity: Vector3, delta: float, gravity: float, jumpSpeed: float):
	# Update jump press if jump action is just pressed
	if Input.is_action_just_pressed("jump"):
		lastJumpPress = 0

	# Apply gravity
	if not playerEntity.is_on_floor() or lastJumpPress >= 0:
		playerVelocity.y -= gravity * delta

	# Check for jump condition: on the floor and jump was pressed recently
	if playerEntity.is_on_floor() and lastJumpPress >= 0 and lastJumpPress < JUMP_BUFFER_TIME:
		playerVelocity.y = jumpSpeed
		# Reset the jump press timer
		lastJumpPress = -1

	return playerVelocity

func performMovementWalk(playerVelocity: Vector3, delta: float):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	var input_vector = Vector3(input_dir.x, 0, input_dir.y)
	var target_velocity = Vector3.ZERO

	if input_vector.length() > 0:
		var direction = (playerEntity.transform.basis * input_vector).normalized()
		target_velocity = direction * MOVEMENT_SPEED
	
	# Smoothly interpolate the player's velocity towards the target velocity
	playerVelocity.x = move_toward(playerVelocity.x, target_velocity.x, ACCELERATION * delta)
	playerVelocity.z = move_toward(playerVelocity.z, target_velocity.z, ACCELERATION * delta)

	return playerVelocity

func performMovementLook(delta: float):
	# Only rotates if the mouse is captured
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		print_debug("Mouse is not captured")
		return

	# Check if there's significant mouse movement
	if _mouse_position.length_squared() < 0.01: # Adjust the threshold as needed
		return # No significant movement, so don't rotate

	# Apply sensitivity and delta time to mouse movement
	var mouse_delta = _mouse_position * CAMERA_SENSITIVITY * delta
	var yaw = mouse_delta.x
	var pitch = clamp(mouse_delta.y, -90, 90) # Clamp pitch to prevent over-rotation

	# Update total pitch and clamp
	_total_pitch = clamp(_total_pitch + pitch, -90, 90)

	# Convert degrees to radians for rotation
	var yaw_rad = deg_to_rad( - yaw)
	var pitch_rad = deg_to_rad( - _total_pitch) # Use clamped total pitch for rotation

	# Rotate the player entity for yaw
	playerEntity.rotate_object_local(Vector3.UP, yaw_rad)

	# Directly set the head and hands pitch rotation to the clamped value
	playerEntity.head.rotation.x = pitch_rad
	playerEntity.hands.rotation.x = pitch_rad

	# Reset _mouse_position to prevent continuous movement
	_mouse_position = Vector2.ZERO

# Will lean left and right (eg. when Q and E are pressed)
func performMovementLean(delta: float):
	var targetLeanAngle: float = getTargetLeanAngle()
	# Negate the target lean angle to correct the lean direction
	targetLeanAngle = -targetLeanAngle
	var currentRotationRad = playerEntity.body.rotation.z
	var targetRotationRad = deg_to_rad(targetLeanAngle)
	
	# Use delta to make the transition smooth and frame rate independent
	var smoothFactor = 5.0 # Adjust this value to control the speed of the lean
	var newRotation = lerp_angle(currentRotationRad, targetRotationRad, delta * smoothFactor)
	
	# Update the body's rotation directly
	playerEntity.body.rotation.z = newRotation
	
	# Simplify the update of the leaning direction
	if targetLeanAngle == 0:
		leaning = LeanDirection.NONE
	elif targetLeanAngle < 0:
		leaning = LeanDirection.LEFT
	else:
		leaning = LeanDirection.RIGHT

# Returns the target lean angle in degrees
func getTargetLeanAngle():
	var nonePressed: bool = !(Input.is_action_pressed("lean_left")||Input.is_action_pressed("lean_right"));
	var bothPressed: bool = (Input.is_action_pressed("lean_left")&&Input.is_action_pressed("lean_right"));
	
	# No lean if none are pressed or both are pressed
	if nonePressed||bothPressed:
		return 0.0;
	
	if Input.is_action_pressed("lean_left"):
		return - LEAN_ANGLE;
	
	if Input.is_action_pressed("lean_right"):
		return LEAN_ANGLE;
	
	return 0.0;

func performMovementDash(playerVelocity: Vector3) -> Vector3:
	resetDashIfOnFloor()
	
	if not Input.is_action_just_pressed("dash"):
		return playerVelocity
	
	if dashesUsed >= DASH_COUNT:
		return playerVelocity
	
	dashing = true
	dashesUsed += 1
	
	var vectorDash = calculateDashVector()
	print_debug("Dash direction: ", vectorDash)
	playerVelocity += vectorDash
	
	return playerVelocity

func resetDashIfOnFloor():
	if playerEntity.is_on_floor():
		dashing = false
		dashesUsed = 0

func calculateDashVector():
	var playerRotate = playerEntity.rotation.y
	var vectorDash = getMovementVector().rotated(Vector3.UP, playerRotate)

	# Uncomment the following if I decide to rotate the dash vector based on the player's head rotation instead of the player's rotation
	# var headRotateX = playerEntity.head.rotation.x
	# vectorDash = vectorDash.rotated(Vector3(1, 0, 0), -headRotateX)

	vectorDash = vectorDash.normalized() * DASH_FORCE
	vectorDash.y /= DASH_Y_REDUCTION_FACTOR
	return vectorDash


func _process(delta):
	# Existing code for jump press and transitioning
	if lastJumpPress >= 0:
		lastJumpPress += delta

func getMovementVector() -> Vector3:
	# All translation references we might need
	var move_z = Input.get_action_strength("back") - Input.get_action_strength("forward");
	var move_x = Input.get_action_strength("right") - Input.get_action_strength("left");
	return Vector3(move_x, 0, move_z);

func processMovement(delta) -> void:
	if (playerEntity == null):
		return ;
	playerEntity.velocity = performMovementJump(playerEntity.velocity, delta, GRAVITY, JUMP_SPEED);
	playerEntity.velocity = performMovementWalk(playerEntity.velocity, delta);
	playerEntity.velocity = performMovementDash(playerEntity.velocity);
	# playerEntity.velocity = performMovementSlide(playerEntity.velocity, delta); # TODO: Re-add slide mechanic later when I am ready to implement it properly
	performMovementLook(delta);
	performMovementLean(delta);
	
	playerEntity.move_and_slide();
	processCollisions();

# Makes it so that you can push objects around
func processCollisions() -> void:
	for col_idx in playerEntity.get_slide_collision_count():
		var col = playerEntity.get_slide_collision(col_idx)
		if col.get_collider() is RigidBody3D:
			col.get_collider().apply_central_impulse( - col.get_normal() * 0.3)
			col.get_collider().apply_impulse( - col.get_normal() * 0.01, col.get_position());
