extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	print_debug("[MagazineSpawner] Ready")
	Globals.add_magazine.connect(_on_add_magazine);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_add_magazine(magazine: Magazine) -> void:
	get_parent().add_child(magazine)
	pass;
