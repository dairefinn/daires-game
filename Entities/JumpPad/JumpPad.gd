extends Area3D

const BOUNCE_VELOCITY = 8 # Descriptive constant for bounce velocity

func _on_body_entered(body: Node):
	var bounce_velocity = Vector3(0, BOUNCE_VELOCITY, 0)
	# Attempt to apply bounce effect based on the property type
	if body is Player or body is Item:
		if body.has_method("set_velocity"):
			# If the body has a 'set_velocity' method, use it to apply the bounce effect
			body.set_velocity(body.get_velocity() + bounce_velocity)
		elif body.has_method("set_linear_velocity"):
			# If the body has a 'set_linear_velocity' method, use it to apply the bounce effect
			body.set_linear_velocity(body.get_linear_velocity() + bounce_velocity)
