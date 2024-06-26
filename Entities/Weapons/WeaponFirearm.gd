extends Weapon
class_name WeaponFirearm;


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func getBulletEmitter():
	return get_tree().get_nodes_in_group("BulletEmitter");


func attackPrimary():
	super();
	print_debug("[WeaponFirearm] attackPrimary")
	var bulletEmitter = getBulletEmitter();
	if (bulletEmitter == null):
		print_debug("Bullet emitter is null")
	else:
		print_debug("Bullet emitter is not null")



func attackSecondary():
	super();
	print_debug("[WeaponFirearm] attackSecondary")
