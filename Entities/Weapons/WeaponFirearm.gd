extends Weapon
class_name WeaponFirearm;


var resourceBullet = load("res://Entities/Weapons/Projectile/Bullet.tscn");
@export var bulletEmitter: Node3D;

var ammoLeft = 10;


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func attackPrimary():
	super();
	spawnBullet(bulletEmitter);


func attackSecondary():
	super();
	print_debug("[WeaponFirearm] attackSecondary")


func spawnBullet(_bulletEmitter: Node3D) -> void:
	if (_bulletEmitter == null):
		print_debug("Bullet emitter is null");
		return;
	
	if (ammoLeft == 0):
		print_debug("You have no ammo left");
		return;
	
	var newBullet = resourceBullet.instantiate();
	Globals.add_projectile.emit(newBullet);
	newBullet.global_position = _bulletEmitter.global_position;
	newBullet.global_rotation = _bulletEmitter.global_rotation;
	
	var bulletRotate = newBullet.rotation.y
	newBullet.linear_velocity = Vector3(0, 0, -50).rotated(Vector3.UP, bulletRotate);
	
	ammoLeft -= 1;
