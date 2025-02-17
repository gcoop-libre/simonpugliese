extends Node2D

var currentPosicion = 0
var patronTocado = []
var textoBienvenida = ["¡Bienvenidos, bienvenidas!", "Osvaldito Pugliese y los músicos quieren armar \nla orquesta y necesitan tu ayuda.", "Te proponemos un desafío ¿Te sumás?", "Prepará las antenas que vas a tener que \nrepetir la melodía"]
var nivel_1 = ["C#1", "A1", "B1", "A1", "A1", "G#1", "F#1", "C#2", "A1"]
var nivel_2 = ["G1", "A1", "F1", "E1", "E1", "G1", "F1", "E1", "G1", "F1", "E1", "D1"]
var nivel_3 = ["D2", "C#1", "D2", "E2", "F1", "E2", "C#2", "D2", "C#2", "D2", "E2", "F2", "E2"]
var niveles = [nivel_1, nivel_2, nivel_3]
var patron = null
var cantidadNiveles
var dialog
var telon 

signal nivelGanado

func _ready():
	var fondo_nivel = get_node("/root/global").get_fondo_principal()
	get_node("fondo").add_child(fondo_nivel)
	var nroPatron = get_node("/root/global").subNivelActual
	patron = niveles[nroPatron]
	cantidadNiveles = niveles.size()
	get_node("fondo/fondo/escenario").add_child(get_node("/root/global").get_orquesta())
	deshabilitarInput(true)
	conectarTeclado()
	get_node("/root/global").play_bg_music()
	mostrarPugliese()
	instanciarTelon()
	telon.abrir_telon()

func instanciarTelon():
	telon = get_node("/root/global").get_telon()
	add_child(telon)
	telon.connect("telonAbierto", self, "_on_telon_abierto", [], CONNECT_ONESHOT)

func _on_telon_abierto():
	remove_child(telon)
	if(get_node("/root/global").esPrimerNivel()):
		animarTextoBienvenida()
	else:
		get_node("btnEmpezar").show()
		get_node("btnEmpezar").set_fixed_process(true)
		get_node("btnEmpezar").set_disabled(false)

func animarTextoBienvenida():
	dialog = get_node("/root/global").get_dialog_jugar()
	var polygon = Vector2Array([Vector2(64, 310), Vector2(64, 700), Vector2(610, 700), Vector2(610, 310)])
	dialog.set_polygon(polygon)
	dialog.posicionarTexto(Vector2(92,330))
	dialog.posicionarBoton(Vector2(230,632))
	dialog.mostrarTexto(textoBienvenida)
	dialog.conectarBoton("_on_empezar_pressed", self)
	add_child(dialog)

func conectarTeclado():
	for octava in get_node("teclado").get_children():
		for boton in octava.get_children():
			boton.connect("apretado", self, "boton_apretado" )

func boton_apretado(quien):
	deshabilitarInput(true)
	patronTocado.append(str(quien.get_name()))
	# chequeamos si la nota es la correcta
	if ( checkPatronTocado() ):
		# chequeamos si ya toque las notas que me piden (patron parcial)
		if patronTocado.size() == currentPosicion + 1:
			currentPosicion += 1  
			# chequeamos si ya termine de tocar el patron del nivel
			if currentPosicion == patron.size():
				get_node("teclado/sonidos_ui").play("aplausos")
				animarMusicosOrquesta()
				get_node("label/ganaste").show()
				get_node("label/anim").play("mostrar")
				yield(get_node("label/anim"), "finished")
				get_node("label/ganaste").hide()
				tocarCancion()
				yield(get_node("canciones"), "song_finished")
				get_node("cuadro_texto").queue_free()
				if hayMasNiveles():
					instanciarTelon()
					telon.cerrar_telon()
					yield(telon, "telonCerrado")
					get_node("/root/global").siguienteNivel()
					pass
				else:
					ganarJuego()
			else: 
				get_node("timerRespuesta").start()
				yield( get_node("timerRespuesta"), "timeout" )
				continuarPatron()
		else:
			# si todavia me faltan notas del patron parcial, habilito input
			deshabilitarInput(false)
			get_node("timerHelp").start()
	else:
		get_node("teclado/sonidos_ui").play("error")
		get_node("label/error").show()
		get_node("label/anim").play("mostrar")
		yield(get_node("label/anim"), "finished")
		get_node("label/error").hide()
		patronTocado = [] 
		continuarPatron()

func checkPatronTocado():
	for i in range(patronTocado.size()):
		ocultarAyuda(patron[i])
		if str(patronTocado[i]) != str(patron[i]):
			return false
	return true

func ocultarAyuda(nombreBoton):
	get_node("timerHelp").stop()
	var nombreOctava = "octava" + str(nombreBoton[-1])
	var posAyuda = get_node("teclado/"+nombreOctava+"/" + nombreBoton + "/pos_ayuda")
	for child in posAyuda.get_children(): 
		child.queue_free()

func jugar():
	mostrarTeclado()
	get_node("teclado/sonidos_ui").play("click")
	currentPosicion = 0
	get_node("btnEmpezar/anim").play("ocultar")
	yield(get_node("btnEmpezar/anim"), "finished")
	get_node("btnEmpezar").set_disabled(true)
	get_node("btnEmpezarDeNuevo").set_fixed_process(false)
	get_node("timerCortito").start()
	yield(get_node("timerCortito"), "timeout")
	continuarPatron()

func continuarPatron():
	patronTocado = []
	for i in range(0,currentPosicion+1):
		var nombreBoton = patron[i]
		var nombreOctava = "octava" + str(nombreBoton[-1])
		var boton = get_node("teclado/"+nombreOctava+"/" + nombreBoton )
		boton.apretar()
		yield(boton, "finApretado")
		get_node("timerSuperCortito").start()
		yield(get_node("timerSuperCortito"), "timeout")
	deshabilitarInput(false)
	get_node("timerHelp").start()

func _on_timerHelp_timeout():
	var nombreBoton = patron[patronTocado.size()]
	var nombreOctava = "octava" + str(nombreBoton[-1])
	var ayuda = get_node("/root/global").get_ayuda()
	var posAyuda = get_node("teclado/"+nombreOctava+"/" + nombreBoton + "/pos_ayuda")
	posAyuda.add_child(ayuda)

func deshabilitarInput(booleano):
	for octava in get_node("teclado").get_children():
		for boton in octava.get_children():
			get_node("teclado/"+octava.get_name()+"/"+boton.get_name()+"/boton-lb").set_disabled(booleano)
			get_node("teclado/"+octava.get_name()+"/"+boton.get_name()+"/boton-lb").set_ignore_mouse(booleano)

func hayMasNiveles():
	return cantidadNiveles - 1 > get_node("/root/global").subNivelActual

func ganarJuego():
	get_node("teclado/sonidos_ui").play("aplausos")
	get_node("label/fin").show()
	get_node("label/anim").play("mostrar")
	yield(get_node("label/anim"), "finished")
	get_node("label/fin").hide()
	get_node("/root/global").stop_bg_music()
	get_node("teclado/sonidos_ui").play("intro_la_yumba")
	get_node("btnEmpezarDeNuevo/anim").play("mostrar")
	get_node("btnEmpezarDeNuevo").set_fixed_process(true)

func _on_btnEmpezarDeNuevo_pressed():
	get_node("btnEmpezarDeNuevo").set_fixed_process(false)
	get_node("btnEmpezarDeNuevo/anim").play("ocultar")
	yield(get_node("btnEmpezarDeNuevo/anim"), "finished")
	instanciarTelon()
	telon.cerrar_telon()
	yield(telon, "telonCerrado")
	get_tree().get_root().get_node("/root/global").empezarJuego()

func animarMusicosOrquesta():
	get_node("fondo/fondo/escenario/orquesta").animarMusicos()

func mostrarPugliese():
	get_node("teclado").quitar_teclas()
	get_node("fondo/fondo/posicionPugliese/pugliese").show()
	animarMusicosOrquesta()
	get_node("fondo/fondo/posicionPugliese/pugliese").play()

func mostrarTeclado():
	get_node("teclado").mostrar_teclas()

func _on_empezar_pressed():
	dialog.ocultar()
	_on_btnEmpezar_pressed()

func _on_btnEmpezar_pressed():
	get_node("fondo/fondo/posicionPugliese/pugliese").hide()
	jugar()

func esJugable():
	return true

func tocarCancion():
	mostrarPugliese()
	var canciones = get_node("canciones")
	animarTextoCancion()
	canciones.sonar()

func animarTextoCancion():
	var textoCancion = get_node("canciones").get_texto_cancion()
	dialog = get_node("/root/global").get_dialog()
	dialog = setPolygonCancion(dialog, textoCancion)
	add_child(dialog) 
	dialog.mostrarTexto(textoCancion)

func setPolygonCancion(dialog, texto):
	# Traer posición del objeto nombre_cancion
	var posicion = (get_node("nombre_cancion").get_pos())
	# Calcular ancho y posición x del dialogo en funcion del texto
	var lenTexto = texto[0].length()
	var ancho = lenTexto * 11.3
	var posx = posicion.x - (ancho / 2)
	var polygon = Vector2Array([Vector2(posx, posicion.y), Vector2(posx, posicion.y + 80), Vector2(posx + ancho, posicion.y + 80), Vector2(posx + ancho, posicion.y)])
	# Posicionar dialogo y texto
	dialog.set_polygon(polygon)
	dialog.posicionarTexto(Vector2(posx + (ancho * 0.08), posicion.y + 20))
	return dialog