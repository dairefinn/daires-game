extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body: Node):#
	if body.has_method("bounce"):
		print_debug("Body has bounce method");
	
	if body is Player:
		if body.is_on_floor():
			# TODO: Where tf did jump speed come from previously?
			# body.velocity.y += (body.movementController.jumpSpeed * 4);
			body.velocity.y += 8;
	elif body is ItemEquipable:
		body.linear_velocity.y += 8;
