extends Node2D

signal gane 
var dialog
var textoBienvenida = ["La orquesta tiene que trasladar los instrumentos", "y Buenos Aires es un laberinto de calles, ", "¡cuidado de no perderte!"]

func _ready(): 
	get_node("/root/global").play_bg_music()
	if(get_node("/root/global").esPrimerNivel()):
		animarTextoBienvenida()
	else:
		jugar()
	
func animarTextoBienvenida():
	dialog = get_node("/root/global").get_dialog_jugar()
	var polygon = Vector2Array([Vector2(391, 264), Vector2(391, 530), Vector2(890, 530), Vector2(890, 264)])
	dialog.set_polygon(polygon)
	dialog.posicionarTexto(Vector2(410,280))
	dialog.posicionarBoton(Vector2(520,450))
	dialog.mostrarTexto(textoBienvenida)
	dialog.conectarBoton("_on_empezar_pressed", self)
	add_child(dialog)

func _on_empezar_pressed():
	dialog.ocultar()
	jugar()

func jugar():
	get_node("reloj/tiempo").contarTiempo()
	get_node("personaje").set_fixed_process(true)
	get_node("personaje/camion/humo").show()

func _on_personaje_chocando(colisionador):
	if(colisionador.get_parent().get_name() == "items"):
		agarrarItem(colisionador)
	else: 
		sonarColision()

func sonarColision():
	if(!get_node("sonidos_laberinto").is_playing):
		get_node("sonidos_laberinto").play_sound("collision")

func _on_personaje_caminando():
	if(!get_node("sonidos_laberinto").is_playing):
		get_node("sonidos_laberinto").play_sound("engine_running")

func _on_personaje_parando():
	if(!get_node("sonidos_laberinto").is_playing):
		get_node("sonidos_laberinto").play_sound("engine_idle")

func _on_escena_gane():
	get_node("/root/global").siguienteNivel()
	
func agarrarItem(item):
	get_node("inventario").agregarItem(item.instrumento)
	item.queue_free()
	get_node("sonidos_laberinto/timerLargo").start()
	yield(get_node("sonidos_laberinto/timerLargo"), "timeout")
	if(get_node("tileLaberinto").itemsRestantes() == 0):
		get_node("sonidos_laberinto").play_sound("win")
		get_node("ganaste/anim").play("mostrar")
		get_node("sonidos_laberinto/timerSuperLargo").start()
		yield(get_node("sonidos_laberinto/timerSuperLargo"), "timeout")
		emit_signal("gane")

func esJugable():
	return true
