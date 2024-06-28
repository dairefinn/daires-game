extends Area3D


func _on_body_entered(body: Node):#
	if body.has_method("bounce"):
		print_debug("Body has bounce method");
	
	if body is Player:
		if body.is_on_floor():
			# TODO: Where tf did jump speed come from previously?
			# body.velocity.y += (body.movementController.jumpSpeed * 4);
			body.velocity.y += 8;
	elif body is Item:
		body.linear_velocity.y += 8;
