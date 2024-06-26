extends Weapon
class_name WeaponMelee;


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	print_debug("[Weapon] secondaryAttack")
	pass


func attackPrimary():
	super();
	print_debug("[WeaponMelee] attackPrimary")


func attackSecondary():
	super();
	print_debug("[WeaponMelee] attackSecondary")
