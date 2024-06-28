extends Node
class_name InventoryController;


@export var playerEntity: Player = null;
@export var equippedItemLeft: ItemPickupable = null;
@export var equippedItemRight: ItemPickupable = null;
@export var handOffset: Vector3 = Vector3(0, 0, -0.1);

var slots: Array[InventorySlot] = [];


func processUpdates():
	performActionInteract();
	performActionDrop()


# TODO: This should be a bit smarter probably. Idk if I want to utilize equippedItemLeft or just have one weapon slot. Versatility good so maybe later
func getEquippedItem():
	return equippedItemRight;


# Get what the player was looking at and do something if possible
func performActionInteract() -> void:
	# Wait for interaction
	if !Input.is_action_just_pressed("interact"):
		return;
	
	print_debug("Interact was pressed")
	
	if !playerEntity.cameraRay.is_colliding():
		return;
	
	var collidingWith: Object = playerEntity.cameraRay.get_collider();
	print_debug("First object colliding with: " + collidingWith.name);
	
	if collidingWith is ItemPickupable:
		equipItem(collidingWith);


func equipItem(equipable: ItemPickupable) -> void:
	if (equippedItemRight != null):
		print_debug("Cannot equip a equipable as you already have one equipped");
		return;
	
	print_debug("Equipping a " + equipable.name);
	
	equippedItemRight = equipable; # Add to hands
	equipable.get_parent().remove_child(equipable); # Remove from world
	playerEntity.handRight.add_child(equipable); # Add to hand
	equipable.freeze = true; # Stop physics
	equipable.position = handOffset; # Position gun just in front of hand
	equipable.rotation = Vector3(0, 0, 0); # Reset rotation


# If drop was pressed, attempt to drop whatever you're holding
func performActionDrop() -> void:
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
	playerEntity.handRight.remove_child(equippedItemRight);
	playerEntity.get_parent().add_child(equippedItemRight); # Add weapon to world
	equippedItemRight.position = currentPosition;
	equippedItemRight.rotation = currentRotation;
	equippedItemRight = null; # Clear equipped weapon
