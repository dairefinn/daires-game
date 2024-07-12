extends Node3D
class_name LevelTesting;


@onready var pauseMenu = $PauseMenu;


# Called when the node enters the scene tree for the first time.
func _ready():
	pauseMenu.hide();


func _on_add_projectile(projectile: Node3D):
		add_child(projectile);


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (Input.is_action_just_pressed("pause")):
		pauseMenu._on_pause_button_pressed();
