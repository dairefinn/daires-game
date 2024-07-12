extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	print_debug("[ProjectileSpawner] Ready")
	Globals.add_projectile.connect(_on_add_projectile);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_add_projectile(projectile: Projectile) -> void:
	get_parent().add_child(projectile)
	pass;
