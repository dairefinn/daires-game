extends Weapon
class_name WeaponFirearm;


var resourceBullet = load("res://Entities/Weapons/Projectile/Bullet.tscn");
@export var bulletEmitter: Node3D;

var BULLET_FORCE = 20;
var BASE_AMMO_CAPACITY = 10;
var ammoLeft = 0;


# Called when the node enters the scene tree for the first time.
func _ready():
	ammoLeft = BASE_AMMO_CAPACITY;


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

	var oldScale = newBullet.scale;

	# Set the bullet's global transform to match the emitter's exactly
	newBullet.global_transform = _bulletEmitter.global_transform;
	newBullet.scale = oldScale;

	# # Debugging to confirm the match
	# print_debug("Emitter Global Transform: ", _bulletEmitter.global_transform)
	# print_debug("Bullet Global Transform: ", newBullet.global_transform)

	# This is used to freeze the bullet in the air for testing the bullet spawn angles
	# newBullet.gravity_scale = 0;

	# Assuming the bullet's forward direction is along its local Z-axis
	# This line might not be necessary if the bullet's physics or movement logic
	# automatically handles forward motion based on its orientation
	newBullet.apply_central_impulse(newBullet.transform.basis.z.normalized() * -BULLET_FORCE);

	ammoLeft -= 1;


func reload() -> void:
	print_debug("Reloading your weapon");
	ammoLeft = BASE_AMMO_CAPACITY;
