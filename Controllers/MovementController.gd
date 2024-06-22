extends Node
class_name MovementController;


@export var playerEntity: Player = null;

@export var GRAVITY: int = ProjectSettings.get_setting("physics/3d/default_gravity");
@export_range(0, 1) var CAMERA_SENSITIVITY: float = 0.25
@export var MOVEMENT_SPEED: float = 5.0;
@export var ACCELERATION: float = 4.0;
@export var JUMP_SPEED: float = 4.0;
@export var LEAN_ANGLE: float = 30.0;
@export var DASH_FORCE: float = 10.0;
@export var DASH_COUNT: int = 2;
@export var SLIDE_FORCE: float = 5.0;
@export var SLIDE_DURATION: float = 1.0;
@export var SLIDE_ANGLE: float = 60.0;

enum LeanDirection { LEFT, RIGHT, NONE };
var leaning: LeanDirection = LeanDirection.NONE;

var dashing: bool = false;
var dashesUsed: int = 0;

var sliding: bool = false;
var slideTimer: float = 0.0;

var _mouse_position = Vector2(0, 0);
var _total_pitch = 0.0;


func _init():
	# Capture the mouse inside of the window while controlling the camera
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	print_debug("Capturing mouse")


func process_input(event: InputEvent) -> void:
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_position = event.relative;
		# print_debug("Mouse X: ", _mouse_position.x, " | Mouse Y: ", _mouse_position.y);


# Will either apply gravity or jump if applicable
func performMovementJump(playerVelocity: Vector3, delta: float, gravity: float, jumpSpeed: float) -> Vector3:
	# Apply gravity to the player as long as they're in the air
	if not playerEntity.is_on_floor():
		playerVelocity.y -= gravity * delta;
		return playerVelocity;
	
	# If jump was pressed jump into the air
	if Input.is_action_just_pressed("jump"):
		playerVelocity.y = jumpSpeed;
		return playerVelocity;
	
	return playerVelocity;


# Will move laterally if an appropriate input is pressed
func performMovementWalk(playerVelocity: Vector3, delta: int) -> Vector3:
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "back");
	var input_vector = Vector3(input_dir.x, 0, input_dir.y);
	var direction = (playerEntity.transform.basis * input_vector).normalized();
	
	if direction:
		playerVelocity.x = direction.x * MOVEMENT_SPEED;
		playerVelocity.z = direction.z * MOVEMENT_SPEED;
	else: # Without this, the character will continue to slide in the direction they were moving
		playerVelocity.x = move_toward(playerVelocity.x, 0, MOVEMENT_SPEED);
		playerVelocity.z = move_toward(playerVelocity.z, 0, MOVEMENT_SPEED);
	
	return playerVelocity;


func performMovementLook(delta: int) -> void:
	# Only rotates mouse if the mouse is captured
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		print_debug("Mouse is not captured");
		return;
	
	print_debug("Captured")
	_mouse_position *= CAMERA_SENSITIVITY;
	var yaw = _mouse_position.x;
	var pitch = _mouse_position.y;
	
	# Prevents looking up/down too far
	pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch);
	_total_pitch += pitch;
	
	playerEntity.rotate_object_local(Vector3.UP, deg_to_rad(-yaw));
	
	# Rotate the head only up/down
	playerEntity.head.rotate_x(deg_to_rad(-pitch));


# Will lean left and right (eg. when Q and E are pressed)
func performMovementLean(delta: int) -> void:
	var targetLeanAngle: float = getTargetLeanAngle(delta, playerEntity.body.rotation.y);
	var currentRotationRad = playerEntity.body.rotation.z;
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
	
	playerEntity.body.rotate_object_local(Vector3.FORWARD, newRotation);


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
	if playerEntity.is_on_floor():
		dashing = false;
		dashesUsed = 0;
	
	if Input.is_action_just_pressed("dash"):
		dashing = true;
		dashesUsed += 1;
		
		if (dashesUsed > DASH_COUNT):
			return playerVelocity;
		
		# Some rotations we might need to angle the dash
		var headRotateX = playerEntity.head.rotation.x;
		var playerRotate = playerEntity.rotation.y
		
		var vectorDash = getMovementVector();
		
		# Create a vector to represent the dash movement
		vectorDash = vectorDash.rotated(Vector3.UP, playerRotate);
		# vectorDash = vectorDash.rotated(Vector3(1, 0, 0), -headRotateX);
		vectorDash = vectorDash.normalized();
		vectorDash *= DASH_FORCE;
		vectorDash.y = vectorDash.y / 5;
		
		print_debug("Dash direction: ", vectorDash);
		playerVelocity += vectorDash;
	
	return playerVelocity;


# Slide if on ground. Ground pound if in air.
# TODO: This works but needs tidying up because the logic sucks :). There's probably a better way to do the slide/rotate animations
func performMovementSlide(playerVelocity: Vector3, delta: float) -> Vector3:
	if sliding:
		# print_debug("Slide timer: ", slideTimer);
		if slideTimer < SLIDE_DURATION:
			var currentRotationRad = playerEntity.body.rotation.x;
			var targetRotationRad = deg_to_rad(SLIDE_ANGLE);
			
			if currentRotationRad != targetRotationRad:
				var halfSlideDuration = (SLIDE_DURATION / 2);
				var lerpProgress = 0.0;
				
				# For the first half of the dash, rotate to a sliding position
				if slideTimer <= halfSlideDuration:
					lerpProgress = (slideTimer / halfSlideDuration);
				else:
					targetRotationRad = 0.0;
					var slideTimerForHalf = (slideTimer - halfSlideDuration);
					lerpProgress = slideTimerForHalf / halfSlideDuration;
				
				var newRotation = lerp_angle(currentRotationRad, targetRotationRad, lerpProgress);
				var rotationDiff = currentRotationRad - newRotation;
				playerEntity.body.rotation.x = newRotation;
				playerEntity.head.rotation.x += rotationDiff;
			
			slideTimer += delta
			
			# Defines the direction the slide should push the player in
			var vectorSlide = Vector3(0, 0, -1);
			var playerRotation = playerEntity.rotation.y;
			vectorSlide = vectorSlide.rotated(Vector3.UP, playerRotation);
			
			# Add the slide force to the slide vector
			vectorSlide *= SLIDE_FORCE;
			
			playerVelocity += vectorSlide;
		else:
			print_debug("Slide ending");
			sliding = false;
			slideTimer = 0.0;
			
			var currentRotationRad = playerEntity.body.rotation.x;
			#body.rotation.x = 0;
			#head.rotation.x = 0;
		
		return playerVelocity;
	
	if Input.is_action_just_pressed("slide"):
		# Cannot slide in the air
		if !playerEntity.is_on_floor():
			print_debug("Cannot slide in the air");
			return playerVelocity;
		
		print_debug("Started sliding");
		sliding = true;
	
	return playerVelocity;


func getMovementVector() -> Vector3:
	# All translation references we might need
	var move_z = Input.get_action_strength("back") - Input.get_action_strength("forward");
	var move_x = Input.get_action_strength("right") - Input.get_action_strength("left");
	return Vector3(move_x, 0, move_z);


func processMovement(delta) -> void:
	if (playerEntity == null):
		return;
	playerEntity.velocity = performMovementJump(playerEntity.velocity, delta, GRAVITY, JUMP_SPEED);
	playerEntity.velocity = performMovementWalk(playerEntity.velocity, delta);
	playerEntity.velocity = performMovementDash(playerEntity.velocity, delta);
	playerEntity.velocity = performMovementSlide(playerEntity.velocity, delta);
	performMovementLook(delta);
	performMovementLean(delta);
	
	playerEntity.move_and_slide();
	processCollisions();


# Makes it so that you can push objects around
func processCollisions() -> void:
	for col_idx in playerEntity.get_slide_collision_count():
		var col = playerEntity.get_slide_collision(col_idx)
		if col.get_collider() is RigidBody3D:
			col.get_collider().apply_central_impulse(-col.get_normal() * 0.3)
			col.get_collider().apply_impulse(-col.get_normal() * 0.01, col.get_position());
