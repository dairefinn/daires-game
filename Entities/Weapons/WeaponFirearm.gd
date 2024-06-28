extends Weapon
class_name WeaponFirearm;


var resourceBullet = load("res://Entities/Weapons/Projectile/Bullet.tscn");
@export var bulletEmitter: Node3D;


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func attackPrimary():
	super();
	
	if (bulletEmitter == null):
		print_debug("Bullet emitter is null");
		return;
	
	var newBullet = resourceBullet.instantiate();
	Globals.add_projectile.emit(newBullet);
	newBullet.global_position = bulletEmitter.global_position;
	newBullet.global_rotation = bulletEmitter.global_rotation;
	
	var bulletRotate = newBullet.rotation.y
	newBullet.linear_velocity = Vector3(0, 0, -50).rotated(Vector3.UP, bulletRotate);


func attackSecondary():
	super();
	print_debug("[WeaponFirearm] attackSecondary")
