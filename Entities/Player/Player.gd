# Following this tutorial: https://www.youtube.com/watch?v=AW3rT-7J8ag
extends CharacterBody3D
class_name Player


@onready var body = $Body;

@onready var head = $Body/Head;
@onready var camera = $Body/Head/Camera3D;
@onready var cameraRay = $Body/Head/Camera3D/RayCast3D;

@onready var handLeft = $Body/Hands/HandLeft;
@onready var handRight = $Body/Hands/HandRight;


var movementController: MovementController = null;
var inventoryController: InventoryController = null;


func _ready() -> void:
	# Instantiate and populate MovementController
	movementController = MovementController.new();
	movementController.playerEntity = self;
	
	# Instantiate and populate InventoryController
	inventoryController = InventoryController.new();
	inventoryController.playerEntity = self;


func _physics_process(delta):
	movementController.processMovement(delta);
	inventoryController.processUpdates();


func _input(event: InputEvent) -> void:
	movementController.process_input(event);
	if Input.is_action_just_pressed("mouseLeft"):
		var equippedItem = inventoryController.getEquippedItem();
		if (equippedItem != null && equippedItem is Weapon):
			var equippedWeapon = equippedItem as Weapon;
			equippedWeapon.attackPrimary();


# TODO: Make objects highlight a bit when they are colliding with the camera ray (to indicate that they can be used)
var highlighted: Object = null;
func markItemAsHighlighted() -> void:
	if !cameraRay.is_colliding():
		return;
	
	var collidingWith: Object = cameraRay.get_collider();
	print_debug("First object colliding with: " + collidingWith.name);
	if collidingWith is ItemEquipable:
		highlighted = collidingWith;
