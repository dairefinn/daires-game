extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body: Node3D):
	if body is Player:
		if body.is_on_floor():
			# TODO: Where tf did jump speed come from previously?
			# body.velocity.y += (body.movementController.jumpSpeed * 4);
			var jumpSpeed = 2;
			body.velocity.y += (jumpSpeed * 4);
	# TODO: Make weapon go boing boing
	#elif body is Equipable:
		#if body.is_on_floor():
			#var jumpSpeed = 4;
			#body.velocity.y += (jumpSpeed * 4);
