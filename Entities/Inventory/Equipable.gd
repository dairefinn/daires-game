extends PickupableItem
class_name Equipable


var isHighlighted: bool = false;


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func setHighlighted(boolean: bool):
	if (boolean):
		setHighlightedTrue();
	else:
		setHighlightedFalse();


func setHighlightedTrue():
	isHighlighted = true;


func setHighlightedFalse():
	isHighlighted = false;

