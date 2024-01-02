# Following this tutorial: https://www.youtube.com/watch?v=AW3rT-7J8ag
extends CharacterBody3D

@export var speed: float = 5.0;
@export var acceleration: float = 4.0;
@export var jump_speed: float = 4.0;
@export var lean_angle: float = 15;
@export_range(0, 1) var sensitivity: float = 0.25

@onready var body = $Body;
@onready var camera = $Body/Head/Camera3D;
@onready var cameraRay = $Body/Head/Camera3D/RayCast3D;


var GRAVITY: int = ProjectSettings.get_setting("physics/3d/default_gravity");
var _mouse_position = Vector2(0, 0);
var _total_pitch = 0.0

enum LeanDirection { LEFT, RIGHT, NONE };
var leaning: LeanDirection = LeanDirection.NONE;


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);


func _physics_process(delta):
	velocity = performMovementJump(velocity, delta, GRAVITY, jump_speed);
	velocity = performMovementWalk(velocity, delta);
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
		playerVelocity.x = direction.x * speed;
		playerVelocity.z = direction.z * speed;
	else: # Without this, the character will continue to slide in the direction they were moving
		playerVelocity.x = move_toward(playerVelocity.x, 0, speed);
		playerVelocity.z = move_toward(playerVelocity.z, 0, speed);
	
	return playerVelocity;


func performMovementLook(delta: int) -> void:
	# Only rotates mouse if the mouse is captured
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_mouse_position *= sensitivity;
		var yaw = _mouse_position.x;
		var pitch = _mouse_position.y;
		
		# Prevents looking up/down too far
		pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch);
		_total_pitch += pitch;
	
		rotate_object_local(Vector3.UP, deg_to_rad(-yaw));
		
		# Rotate the camera only up/down
		camera.rotate_x(deg_to_rad(-pitch));


# Will lean left and right (eg. when Q and E are pressed)
# TODO: Make this smoother. Will probably have to rotate a node inside player instead of Player itself.
func performMovementLean(delta: int) -> void:
	var nonePressed: bool = !(Input.is_action_pressed("lean_left") || Input.is_action_pressed("lean_right"));
	var bothPressed: bool = (Input.is_action_pressed("lean_left") && Input.is_action_pressed("lean_right"));
	
	# No lean if none are pressed or both are pressed
	if nonePressed || bothPressed:
		if leaning != LeanDirection.NONE:
			body.rotation.z = 0.0;
			leaning = LeanDirection.NONE;
		return;
	
	if Input.is_action_pressed("lean_left"):
		if leaning != LeanDirection.LEFT:
			print_debug("Lean left");
			body.rotate_object_local(Vector3.FORWARD, deg_to_rad(-lean_angle));
			leaning = LeanDirection.LEFT;
	
	if Input.is_action_pressed("lean_right"):
		if leaning != LeanDirection.RIGHT:
			print_debug("Lean right");
			body.rotate_object_local(Vector3.FORWARD, deg_to_rad(lean_angle));
			leaning = LeanDirection.RIGHT;
