extends Button

func _ready():
	pass

func _on_pausa_pressed():
	get_node("/root/global").apretar_ui_button()
	get_node("Timer").start()
	yield(get_node("Timer"), "timeout")
	get_tree().set_pause(!(get_tree().is_paused()))
	if(get_tree().is_paused()):
		get_node("/root/global").pausar()
		set_text("continuar")
	else:
		get_node("/root/global").continuar()
		set_text("pausa")
