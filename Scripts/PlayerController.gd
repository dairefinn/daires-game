# Following this tutorial: https://www.youtube.com/watch?v=AW3rT-7J8ag
extends CharacterBody3D
class_name PlayerController

@export var MOVEMENT_SPEED: float = 5.0;
@export var ACCELERATION: float = 4.0;
@export var JUMP_SPEED: float = 4.0;
@export var LEAN_ANGLE: float = 30;
@export var DASH_FORCE: float = 10.0;
@export var DASH_COUNT: int = 2;
@export_range(0, 1) var CAMERA_SENSITIVITY: float = 0.25
@export var GRAVITY: int = ProjectSettings.get_setting("physics/3d/default_gravity");

@onready var body = $Body;
@onready var camera = $Body/Head/Camera3D;
@onready var cameraRay = $Body/Head/Camera3D/RayCast3D;


var _mouse_position = Vector2(0, 0);
var _total_pitch = 0.0


enum LeanDirection { LEFT, RIGHT, NONE };
var leaning: LeanDirection = LeanDirection.NONE;


var dashing: bool = false;
var dashesUsed: int = 0;

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);


func _physics_process(delta):
	velocity = performMovementJump(velocity, delta, GRAVITY, JUMP_SPEED);
	velocity = performMovementWalk(velocity, delta);
	velocity = performMovementDash(velocity, delta);
	velocity = performMovementSlide(velocity, delta);
	performMovementLook(delta);
	performMovementLean(delta);
	
	move_and_slide();
	
	processCollisions();


func _input(event: InputEvent) -> void:
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_position = event.relative;
		# print_debug("Mouse X: ", _mouse_position.x, " | Mouse Y: ", _mouse_position.y);


func processCollisions() -> void:
	for col_idx in get_slide_collision_count():
		var col = get_slide_collision(col_idx)
		if col.get_collider() is RigidBody3D:
			col.get_collider().apply_central_impulse(-col.get_normal() * 0.3)
			col.get_collider().apply_impulse(-col.get_normal() * 0.01, col.get_position());


# Will either apply gravity or jump if applicable
func performMovementJump(playerVelocity: Vector3, delta: float, gravity: float, jumpSpeed: float) -> Vector3:
	# Apply gravity to the player as long as they're in the air
	if not is_on_floor():
		playerVelocity.y -= gravity * delta;
	# If jump was pressed and they're on the floor, jump into the air
	elif Input.is_action_just_pressed("jump"):
		playerVelocity.y = jumpSpeed;
	
	return playerVelocity;


# Will move laterally if an appropriate input is pressed
func performMovementWalk(playerVelocity: Vector3, delta: int) -> Vector3:
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "back");
	var input_vector = Vector3(input_dir.x, 0, input_dir.y);
	var direction = (transform.basis * input_vector).normalized();
	
	if direction:
		playerVelocity.x = direction.x * MOVEMENT_SPEED;
		playerVelocity.z = direction.z * MOVEMENT_SPEED;
	else: # Without this, the character will continue to slide in the direction they were moving
		playerVelocity.x = move_toward(playerVelocity.x, 0, MOVEMENT_SPEED);
		playerVelocity.z = move_toward(playerVelocity.z, 0, MOVEMENT_SPEED);
	
	return playerVelocity;


func performMovementLook(delta: int) -> void:
	# Only rotates mouse if the mouse is captured
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_mouse_position *= CAMERA_SENSITIVITY;
		var yaw = _mouse_position.x;
		var pitch = _mouse_position.y;
		
		# Prevents looking up/down too far
		pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch);
		_total_pitch += pitch;
	
		rotate_object_local(Vector3.UP, deg_to_rad(-yaw));
		
		# Rotate the camera only up/down
		camera.rotate_x(deg_to_rad(-pitch));


# Will lean left and right (eg. when Q and E are pressed)
func performMovementLean(delta: int) -> void:
	var targetLeanAngle: float = getTargetLeanAngle(delta, body.rotation.y);
	var currentRotationRad = body.rotation.z;
	var targetRotationRad = deg_to_rad(targetLeanAngle);
	var newRotation = lerp_angle(targetRotationRad, currentRotationRad, 0.5);
	
	if (currentRotationRad == targetRotationRad):
		return;
	
	if targetLeanAngle < 0:
		if leaning != LeanDirection.LEFT:
			#body.rotate_object_local(Vector3.FORWARD, targetLeanAngle);
			leaning = LeanDirection.LEFT;
	elif targetLeanAngle > 0:
		if leaning != LeanDirection.RIGHT:
			#body.rotate_object_local(Vector3.FORWARD, targetLeanAngle);
			leaning = LeanDirection.RIGHT;
	else:
		if leaning != LeanDirection.NONE:
			#body.rotation.z = targetLeanAngle;
			leaning = LeanDirection.NONE;

	body.rotate_object_local(Vector3.FORWARD, newRotation);


# Returns the target lean angle in degrees
func getTargetLeanAngle(delta: int, currentLeanAngle: float) -> float:
	var nonePressed: bool = !(Input.is_action_pressed("lean_left") || Input.is_action_pressed("lean_right"));
	var bothPressed: bool = (Input.is_action_pressed("lean_left") && Input.is_action_pressed("lean_right"));
	
	# No lean if none are pressed or both are pressed
	if nonePressed || bothPressed:
		return 0.0;
	
	if Input.is_action_pressed("lean_left"):
		return -LEAN_ANGLE;
	
	if Input.is_action_pressed("lean_right"):
		return LEAN_ANGLE;
	
	return 0.0;


func performMovementDash(playerVelocity: Vector3, delta: float) -> Vector3:
	# Reset dash count if on the floor
	if is_on_floor():
		dashing = false;
		dashesUsed = 0;
	
	if Input.is_action_just_pressed("dash"):
		dashing = true;
		dashesUsed += 1;
		
		if (dashesUsed > DASH_COUNT):
			return playerVelocity;
		
		# Get the Transform3D indicating where the camera is looking
		var cameraBasis = camera.get_global_transform().basis;
		
		# Create a Vector3D from the transform basis
		var dash_direction = Vector3();
		dash_direction += cameraBasis.x;
		dash_direction += cameraBasis.z;
		
		# Normalize the values and apply the force in the faced direction
		dash_direction = dash_direction.normalized();
		var dash_vector = dash_direction * DASH_FORCE
		
		# Add the force to the players current velocity vector
		playerVelocity -= dash_vector;
	
	return playerVelocity;


func performMovementSlide(playerVelocity: Vector3, delta: float) -> Vector3:
	if Input.is_action_just_pressed("slide"):
		print_debug("Slide")
	return playerVelocity;
