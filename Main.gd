extends Node3D

@onready var pauseMenu = $PauseMenu;

# Called when the node enters the scene tree for the first time.
func _ready():
	pauseMenu.hide();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (Input.is_action_just_pressed("pause")):
		pauseMenu._on_pause_button_pressed();
