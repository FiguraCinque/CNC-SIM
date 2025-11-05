@tool
extends Resource
class_name CustomThemeEditor

@export var base_theme: Theme
@export var background_color: Color = Color("222222") # Colore di sfondo scuro
@export var accent_color: Color = Color("4a90e2")   # Colore per evidenziare (es. pulsanti attivi)
@export var text_color: Color = Color("ffffff")      # Colore del testo
@export var disabled_color: Color = Color("555555")  # Colore per elementi disabilitati
@export var border_color: Color = Color("444444")    # Colore per bordi e separatori

func _init():
	if base_theme == null:
		base_theme = Theme.new()

func apply_custom_theme():
	if base_theme == null:
		print("Errore: Nessun tema base assegnato.")
		return

	# ------------- Stili base -------------
	# Modifica lo stile predefinito di tutti i Control
	base_theme.set_color("font_color", "Label", text_color)
	base_theme.set_color("font_color", "Button", text_color)
	base_theme.set_color("font_color", "LineEdit", text_color)
	base_theme.set_color("font_color", "TextEdit", text_color)
	base_theme.set_color("font_color", "CheckBox", text_color)
	base_theme.set_color("font_color", "OptionButton", text_color)
	base_theme.set_color("font_color", "Tree", text_color)
	base_theme.set_color("font_color", "TabContainer", text_color) # Colore del testo delle schede

	base_theme.set_color("font_color_disabled", "Button", disabled_color)
	base_theme.set_color("font_color_disabled", "LineEdit", disabled_color)
	base_theme.set_color("font_color_disabled", "TextEdit", disabled_color)
	base_theme.set_color("font_color_disabled", "OptionButton", disabled_color)
	base_theme.set_color("font_color_disabled", "CheckBox", disabled_color)

	# Colore di sfondo generale per pannelli e contenitori
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = background_color
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = border_color
	base_theme.set_stylebox("panel", "Panel", panel_style)
	base_theme.set_stylebox("panel", "Tree", panel_style) # Sfondo per il Tree

	# ------------- Button -------------
	var button_normal = StyleBoxFlat.new()
	button_normal.bg_color = background_color
	button_normal.set_border_width_all(1)
	button_normal.border_color = border_color
	button_normal.set_corner_radius_all(3)
	button_normal.content_margin_left = 8
	button_normal.content_margin_right = 8
	button_normal.content_margin_top = 4
	button_normal.content_margin_bottom = 4
	base_theme.set_stylebox("normal", "Button", button_normal)

	var button_hover = button_normal.duplicate()
	button_hover.bg_color = background_color.lightened(0.1)
	base_theme.set_stylebox("hover", "Button", button_hover)

	var button_pressed = button_normal.duplicate()
	button_pressed.bg_color = accent_color
	button_pressed.border_color = accent_color
	base_theme.set_stylebox("pressed", "Button", button_pressed)

	var button_disabled = button_normal.duplicate()
	button_disabled.bg_color = background_color.darkened(0.2)
	button_disabled.border_color = background_color.darkened(0.1)
	base_theme.set_stylebox("disabled", "Button", button_disabled)

	# ------------- LineEdit e TextEdit -------------
	var line_edit_style = StyleBoxFlat.new()
	line_edit_style.bg_color = background_color.darkened(0.1)
	line_edit_style.set_border_width_all(1)
	line_edit_style.border_color = border_color
	line_edit_style.set_corner_radius_all(3)
	line_edit_style.content_margin_left = 5
	line_edit_style.content_margin_right = 5
	line_edit_style.content_margin_top = 3
	line_edit_style.content_margin_bottom = 3
	base_theme.set_stylebox("normal", "LineEdit", line_edit_style)
	base_theme.set_stylebox("focus", "LineEdit", line_edit_style.duplicate().set_border_color(accent_color))
	base_theme.set_stylebox("read_only", "LineEdit", line_edit_style.duplicate().set_bg_color(background_color.darkened(0.2)))

	base_theme.set_stylebox("normal", "TextEdit", line_edit_style)
	base_theme.set_stylebox("focus", "TextEdit", line_edit_style.duplicate().set_border_color(accent_color))
	base_theme.set_stylebox("read_only", "TextEdit", line_edit_style.duplicate().set_bg_color(background_color.darkened(0.2)))
	base_theme.set_color("font_color_readonly", "TextEdit", disabled_color)
	base_theme.set_color("caret_color", "TextEdit", text_color)
	base_theme.set_color("selection_color", "TextEdit", Color(accent_color, 0.5)) # Correzione: Color(color, alpha)
	base_theme.set_color("current_line_color", "TextEdit", background_color.lightened(0.05))

	# ------------- CheckBox -------------
	base_theme.set_color("font_color", "CheckBox", text_color)
	base_theme.set_color("font_color_pressed", "CheckBox", text_color)
	base_theme.set_color("font_color_hover", "CheckBox", text_color)
	base_theme.set_color("font_color_focus", "CheckBox", text_color)
	base_theme.set_color("font_color_disabled", "CheckBox", disabled_color)

	# La box della checkbox
	var check_box_box = StyleBoxFlat.new()
	check_box_box.bg_color = background_color.darkened(0.1)
	check_box_box.set_border_width_all(1)
	check_box_box.border_color = border_color
	check_box_box.set_corner_radius_all(2)
	check_box_box.set_default_size(10, 10) # Dimensione della box
	base_theme.set_stylebox("normal", "CheckBox", check_box_box)
	base_theme.set_stylebox("pressed", "CheckBox", check_box_box)
	base_theme.set_stylebox("hover", "CheckBox", check_box_box.duplicate().set_border_color(accent_color))
	base_theme.set_stylebox("focus", "CheckBox", check_box_box.duplicate().set_border_color(accent_color))
	base_theme.set_stylebox("disabled", "CheckBox", check_box_box.duplicate().set_bg_color(background_color.darkened(0.2)))

	# Il "check" all'interno della checkbox
	var check_mark = StyleBoxFlat.new()
	check_mark.bg_color = accent_color
	check_mark.set_default_size(6, 6) # Dimensione del segno di spunta
	base_theme.set_stylebox("checked", "CheckBox", check_mark) # Per la parte "check"
	base_theme.set_icon("checked", "CheckBox", make_check_icon(accent_color)) # Icona di spunta (o puoi crearne una tua)
	base_theme.set_icon("radio_checked", "CheckBox", make_radio_checked_icon(accent_color)) # Icona per RadioButton
	base_theme.set_icon("radio_unchecked", "CheckBox", make_radio_unchecked_icon(border_color)) # Icona per RadioButton

	# ------------- OptionButton -------------
	var option_button_normal = button_normal.duplicate()
	option_button_normal.set_expand_margin_left(15) # Spazio per la freccia
	base_theme.set_stylebox("normal", "OptionButton", option_button_normal)
	base_theme.set_stylebox("hover", "OptionButton", option_button_normal.duplicate().set_bg_color(background_color.lightened(0.1)))
	base_theme.set_stylebox("pressed", "OptionButton", option_button_normal.duplicate().set_bg_color(accent_color))
	base_theme.set_stylebox("disabled", "OptionButton", option_button_normal.duplicate().set_bg_color(background_color.darkened(0.2)))
	base_theme.set_icon("arrow", "OptionButton", make_dropdown_arrow(text_color)) # Icona freccia

	# ------------- Switch (Interruttore) -------------
	# Questo richiede di definire un tuo stile per il "ToggleSwitch" se lo usi come Control custom.
	# Se intendi il CheckBox con uno stile visivo da interruttore, puoi sovrascrivere gli stili "on" e "off".
	# Per una vera UI custom, dovresti creare un Control dedicato o usare un tema esterno.
	# Per semplicità, ipotizziamo un CheckBox con l'aspetto di uno switch:
	# La parte "traccia" dello switch
	var switch_track = StyleBoxFlat.new()
	switch_track.bg_color = disabled_color
	switch_track.set_border_width_all(1)
	switch_track.border_color = border_color
	switch_track.set_corner_radius_all(10) # Forma ovale
	switch_track.set_default_size(40, 20)
	base_theme.set_stylebox("off", "CheckBox", switch_track) # Per lo stato "off" del tuo switch

	var switch_track_on = switch_track.duplicate()
	switch_track_on.bg_color = accent_color
	switch_track_on.border_color = accent_color
	base_theme.set_stylebox("on", "CheckBox", switch_track_on) # Per lo stato "on" del tuo switch

	# La parte "manopola" dello switch
	var switch_handle = StyleBoxFlat.new()
	switch_handle.bg_color = text_color
	switch_handle.set_corner_radius_all(8) # Forma circolare
	switch_handle.set_default_size(16, 16)
	base_theme.set_stylebox("handle", "CheckBox", switch_handle) # Per la manopola

	# Queste icone sono per posizionare la manopola
	base_theme.set_icon("on", "CheckBox", make_switch_handle_icon(text_color, accent_color, true))
	base_theme.set_icon("off", "CheckBox", make_switch_handle_icon(text_color, disabled_color, false))


	# ------------- Tree -------------
	var tree_selected_style = StyleBoxFlat.new()
	tree_selected_style.bg_color = Color(accent_color, 0.3) # Correzione: Color(color, alpha)
	tree_selected_style.set_border_width_all(0)
	base_theme.set_stylebox("selected", "Tree", tree_selected_style)
	base_theme.set_color("font_color_selected", "Tree", text_color)
	base_theme.set_color("guide_color", "Tree", border_color) # Linee guida
	base_theme.set_color("item_custom_fg_color", "Tree", text_color) # Colore testo personalizzato per item
	
	# Per la selezione attiva (es. nella tua immagine "GUI TARGET" con "6 G53 G0 X0 Y0" in giallo)
	# Potrebbe essere un colore font personalizzato o uno stile di selezione specifico.
	# Qui userò il colore di accent per un item "evidenziato".
	# Questo è un esempio, potresti dover assegnare dinamicamente il colore all'item del Tree.
	base_theme.set_color("font_color", "Tree", text_color)
	base_theme.set_color("drop_draw_bgcolor", "Tree", Color(accent_color, 0.2)) # Correzione: Color(color, alpha) # Sfondo per drag and drop
	
	# ------------- TabContainer -------------
	var tab_normal_style = StyleBoxFlat.new()
	tab_normal_style.bg_color = background_color.darkened(0.1)
	tab_normal_style.set_border_width_all(1)
	tab_normal_style.border_color = border_color
	tab_normal_style.border_width_bottom = 0 # Le schede non hanno il bordo inferiore
	tab_normal_style.set_corner_radius_top_left(3)
	tab_normal_style.set_corner_radius_top_right(3)
	tab_normal_style.content_margin_left = 10
	tab_normal_style.content_margin_right = 10
	tab_normal_style.content_margin_top = 5
	tab_normal_style.content_margin_bottom = 5
	base_theme.set_stylebox("tab_normal", "TabContainer", tab_normal_style)

	var tab_selected_style = tab_normal_style.duplicate()
	tab_selected_style.bg_color = accent_color
	tab_selected_style.border_color = accent_color
	base_theme.set_stylebox("tab_selected", "TabContainer", tab_selected_style)
	base_theme.set_color("font_color_selected", "TabContainer", text_color) # Testo bianco per scheda selezionata

	var tab_panel_style = StyleBoxFlat.new()
	tab_panel_style.bg_color = background_color
	tab_panel_style.set_border_width_all(1)
	tab_panel_style.border_color = border_color
	tab_panel_style.set_corner_radius_bottom_left(3)
	tab_panel_style.set_corner_radius_bottom_right(3)
	tab_panel_style.content_margin_left = 5
	tab_panel_style.content_margin_right = 5
	tab_panel_style.content_margin_top = 5
	tab_panel_style.content_margin_bottom = 5
	base_theme.set_stylebox("panel", "TabContainer", tab_panel_style)

	print("Tema personalizzato applicato con successo!")

# Funzioni helper per creare icone semplici
func make_check_icon(color: Color) -> Texture2D:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0)) # Trasparente
	
	# Disegna un semplice checkmark
	# I valori esatti dei pixel possono essere ottimizzati
	image.set_pixel(4, 8, color)
	image.set_pixel(5, 9, color)
	image.set_pixel(6, 10, color)
	image.set_pixel(7, 9, color)
	image.set_pixel(8, 8, color)
	image.set_pixel(9, 7, color)
	image.set_pixel(10, 6, color)
	
	return ImageTexture.create_from_image(image)

func make_radio_checked_icon(color: Color) -> Texture2D:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))
	
	# Cerchio esterno (bordo)
	image.draw_circle(Vector2(7.5, 7.5), 7, border_color)
	image.draw_circle(Vector2(7.5, 7.5), 6, Color(0,0,0,0)) # Trasparente interno per il bordo
	
	# Punto interno
	image.draw_circle(Vector2(7.5, 7.5), 3, color)
	
	return ImageTexture.create_from_image(image)

func make_radio_unchecked_icon(color: Color) -> Texture2D:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))
	
	# Cerchio vuoto (solo bordo)
	image.draw_circle(Vector2(7.5, 7.5), 7, color)
	image.draw_circle(Vector2(7.5, 7.5), 6, Color(0,0,0,0)) # Trasparente interno
	
	return ImageTexture.create_from_image(image)

func make_dropdown_arrow(color: Color) -> Texture2D:
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0))
	
	# Disegna un triangolo semplice che punta in basso
	var points = PackedVector2Array([
		Vector2(4, 6), Vector2(12, 6), Vector2(8, 11)
	])
	image.draw_polygon(points, PackedColorArray([color]), PackedVector2Array(), PackedColorArray()) # Disegna un triangolo riempito
	
	return ImageTexture.create_from_image(image)

func make_switch_handle_icon(handle_color: Color, track_color: Color, is_on: bool) -> Texture2D:
	var image = Image.create(40, 20, false, Image.FORMAT_RGBA8)
	image.fill(Color(0,0,0,0)) # Trasparente

	# Disegna la "traccia" (sfondo) dello switch
	var track_rect = Rect2(Vector2(0,0), Vector2(40,20))
	# Ho semplificato il disegno della StyleBoxFlat direttamente sull'Image
	image.draw_rect(track_rect, track_color, true, 1.0, true) # Riempie la traccia
	
	# Disegna la "manopola"
	var handle_size = Vector2(16, 16)
	var handle_rect: Rect2
	if is_on:
		handle_rect = Rect2(Vector2(40 - handle_size.x - 2, 2), handle_size) # A destra
	else:
		handle_rect = Rect2(Vector2(2, 2), handle_size) # A sinistra

	image.draw_rect(handle_rect, handle_color, true, 1.0, true) # Riempie la manopola

	# Per arrotondare gli angoli, Image.draw_rect non lo fa direttamente
	# Se vuoi angoli arrotondati, dovresti disegnare pixel per pixel o usare un TextureRect con un'immagine pre-fatta.
	# Per questo esempio, li lascio rettangolari.
	# Se vuoi arrotondare, dovrai usare tecniche di disegno più complesse o immagini pre-generate.

	return ImageTexture.create_from_image(image)
