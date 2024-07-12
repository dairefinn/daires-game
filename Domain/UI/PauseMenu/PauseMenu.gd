extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	process_mode = Node.PROCESS_MODE_PAUSABLE;


func _on_pause_button_pressed():
	get_tree().paused = true;
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	show();


func _on_button_quit_pressed():
	get_tree().quit();


func _on_button_resume_pressed():
	get_tree().paused = false;
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	hide();

