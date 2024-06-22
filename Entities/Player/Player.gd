# Following this tutorial: https://www.youtube.com/watch?v=AW3rT-7J8ag
extends CharacterBody3D
class_name Player


@export var equippedItemLeft: Equipable = null;
@export var equippedItemRight: Equipable = null;


@onready var body = $Body;

@onready var head = $Body/Head;
@onready var camera = $Body/Head/Camera3D;
@onready var cameraRay = $Body/Head/Camera3D/RayCast3D;

@onready var hands = $Body/Hands;
@onready var handLeft = $Body/Hands/HandLeft;
@onready var handRight = $Body/Hands/HandRight;


var movementController: MovementController = null;

var _mouse_position = Vector2(0, 0);
var _total_pitch = 0.0;


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	movementController = MovementController.new();
	movementController.setPlayerEntity(self)


func _physics_process(delta):
	movementController.processMovement(delta);
	
	markItemAsHighlighted(delta);
	performActionInteract(delta);
	performActionDrop(delta)
	
	move_and_slide();
	
	processCollisions();


func _input(event: InputEvent) -> void:
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_position = event.relative;
		# print_debug("Mouse X: ", _mouse_position.x, " | Mouse Y: ", _mouse_position.y);


# Makes it so that you can push objects around
func processCollisions() -> void:
	for col_idx in get_slide_collision_count():
		var col = get_slide_collision(col_idx)
		if col.get_collider() is RigidBody3D:
			col.get_collider().apply_central_impulse(-col.get_normal() * 0.3)
			col.get_collider().apply_impulse(-col.get_normal() * 0.01, col.get_position());


func markItemAsHighlighted(delta) -> void:
	if !cameraRay.is_colliding():
		return;
	
	var collidingWith: Object = cameraRay.get_collider();
	print_debug("First object colliding with: " + collidingWith.name);


# Get what the player was looking at and do something if possible
func performActionInteract(delta: float) -> void:
	# Wait for interaction
	if !Input.is_action_just_pressed("interact"):
		return;
	
	print_debug("Interact was pressed")
	
	if !cameraRay.is_colliding():
		return;
	
	var collidingWith: Object = cameraRay.get_collider();
	print_debug("First object colliding with: " + collidingWith.name);
	
	if collidingWith is Equipable:
		equipItem(collidingWith);


func equipItem(equipable: Equipable) -> void:
	if (equippedItemRight != null):
		print_debug("Cannot equip a equipable as you already have one equipped");
		return;
	
	print_debug("Equipping a " + equipable.name);
	
	equippedItemRight = equipable; # Add to hands
	equipable.get_parent().remove_child(equipable); # Remove from world
	handRight.add_child(equipable); # Add to hand
	equipable.freeze = true; # Stop physics
	equipable.position = Vector3(0, 0, -0.1); # Position gun just in front of hand
	equipable.rotation = Vector3(0, 0, 0); # Reset rotation


# If drop was pressed, attempt to drop whatever you're holding
func performActionDrop(delta: float) -> void:
	if !Input.is_action_just_pressed("drop"):
		return;
	
	dropItem();


func dropItem() -> void:
	if (equippedItemRight == null):
		print_debug("Cannot drop weapon - You do not have a weapon equipped");
		return;
	
	equippedItemRight.freeze = false; # Activate physics
	equippedItemRight.position += Vector3(0, 0.1, -1); # Move the weapon forward so it doesn't drop inside our character
	var currentPosition = equippedItemRight.global_position;
	var currentRotation = equippedItemRight.global_rotation;
	handRight.remove_child(equippedItemRight);
	get_parent().add_child(equippedItemRight); # Add weapon to world
	equippedItemRight.position = currentPosition;
	equippedItemRight.rotation = currentRotation;
	equippedItemRight = null; # Clear equipped weapon
