@tool
extends EditorScript

# Colori ispirati ai controlli numerici FANUC
const FANUC_BG_COLOR = Color(0.8, 0.8, 0.8, 1.0)  # Grigio chiaro
const FANUC_TEXT_COLOR = Color(0.0, 0.0, 0.0, 1.0)  # Nero
const FANUC_BUTTON_BG = Color(0.7, 0.7, 0.7, 1.0)  # Grigio medio
const FANUC_BUTTON_HOVER = Color(0.75, 0.75, 0.75, 1.0)  # Grigio leggermente più chiaro
const FANUC_BUTTON_PRESSED = Color(0.6, 0.6, 0.6, 1.0)  # Grigio più scuro
const FANUC_PANEL_BG = Color(0.85, 0.85, 0.85, 1.0)  # Grigio molto chiaro per pannelli
const FANUC_BORDER_COLOR = Color(0.4, 0.4, 0.4, 1.0)  # Grigio scuro per bordi

func _run():
	# Carica o crea il theme
	var theme_path = "res://Varie/GIU_theme_1.tres"  # MODIFICA QUESTO PERCORSO
	var theme: Theme
	
	if ResourceLoader.exists(theme_path):
		theme = load(theme_path)
		print("Theme caricato da: ", theme_path)
	else:
		theme = Theme.new()
		print("Creato nuovo theme")
	
	# Applica i colori FANUC a tutti i controlli comuni
	apply_fanuc_colors(theme)
	
	# Salva il theme
	var err = ResourceSaver.save(theme, theme_path)
	if err == OK:
		print("Theme salvato con successo in: ", theme_path)
	else:
		print("Errore nel salvare il theme: ", err)

func apply_fanuc_colors(theme: Theme):
	# Lista dei tipi di controllo da modificare
	var control_types = [
		"Button", "Label", "LineEdit", "TextEdit", "Panel", 
		"TabContainer", "TabBar", "Tree", "ItemList", "OptionButton",
		"CheckBox", "CheckButton", "MenuBar", "PopupMenu",
		"ProgressBar", "SpinBox", "HSlider", "VSlider",
		"HSplitContainer", "VSplitContainer", "WindowDialog",
		"ConfirmationDialog", "AcceptDialog", "FileDialog"
	]
	
	for control_type in control_types:
		apply_colors_to_control(theme, control_type)
	
	print("Colori FANUC applicati a tutti i controlli")

func apply_colors_to_control(theme: Theme, control_type: String):
	# Colori di base - MANTIENI IL TESTO NERO ANCHE IN HOVER
	theme.set_color("font_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_hover_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_pressed_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_focus_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_disabled_color", control_type, Color(0.3, 0.3, 0.3, 1.0))
	theme.set_color("font_placeholder_color", control_type, Color(0.4, 0.4, 0.4, 1.0))
	theme.set_color("font_outline_color", control_type, Color(0, 0, 0, 0))
	
	# Colori di sfondo specifici per tipo
	match control_type:
		"Button", "OptionButton", "CheckBox", "CheckButton":
			create_button_styleboxes(theme, control_type)
		
		"LineEdit", "TextEdit", "SpinBox":
			create_input_styleboxes(theme, control_type)
		
		"Panel":
			create_panel_styleboxes(theme, control_type)
		
		"TabContainer":
			create_tabcontainer_styleboxes(theme, control_type)
		
		"TabBar":
			create_tabbar_styleboxes(theme, control_type)
		
		"Tree", "ItemList":
			create_list_styleboxes(theme, control_type)
			theme.set_color("font_selected_color", control_type, FANUC_TEXT_COLOR)
		
		"PopupMenu", "MenuBar":
			create_menu_styleboxes(theme, control_type)
		
		"ConfirmationDialog", "AcceptDialog", "FileDialog", "WindowDialog":
			create_dialog_styleboxes(theme, control_type)

func create_button_styleboxes(theme: Theme, control_type: String):
	# Stile normale
	var normal = StyleBoxFlat.new()
	normal.bg_color = FANUC_BUTTON_BG
	normal.border_color = FANUC_BORDER_COLOR
	normal.set_border_width_all(1)
	normal.set_content_margin_all(4)
	theme.set_stylebox("normal", control_type, normal)
	
	# Stile hover
	var hover = StyleBoxFlat.new()
	hover.bg_color = FANUC_BUTTON_HOVER
	hover.border_color = FANUC_BORDER_COLOR
	hover.set_border_width_all(1)
	hover.set_content_margin_all(4)
	theme.set_stylebox("hover", control_type, hover)
	
	# Stile pressed
	var pressed = StyleBoxFlat.new()
	pressed.bg_color = FANUC_BUTTON_PRESSED
	pressed.border_color = FANUC_BORDER_COLOR
	pressed.set_border_width_all(2)
	pressed.set_content_margin_all(4)
	theme.set_stylebox("pressed", control_type, pressed)
	
	# Stile disabled
	var disabled = StyleBoxFlat.new()
	disabled.bg_color = Color(0.75, 0.75, 0.75, 1.0)
	disabled.border_color = Color(0.5, 0.5, 0.5, 1.0)
	disabled.set_border_width_all(1)
	disabled.set_content_margin_all(4)
	theme.set_stylebox("disabled", control_type, disabled)

func create_input_styleboxes(theme: Theme, control_type: String):
	# Stile normale
	var normal = StyleBoxFlat.new()
	normal.bg_color = Color(1.0, 1.0, 1.0, 1.0)  # Bianco per input
	normal.border_color = FANUC_BORDER_COLOR
	normal.set_border_width_all(1)
	normal.set_content_margin_all(4)
	theme.set_stylebox("normal", control_type, normal)
	
	# Stile focus
	var focus = StyleBoxFlat.new()
	focus.bg_color = Color(1.0, 1.0, 1.0, 1.0)
	focus.border_color = Color(0.2, 0.2, 0.2, 1.0)
	focus.set_border_width_all(2)
	focus.set_content_margin_all(4)
	theme.set_stylebox("focus", control_type, focus)
	
	# Colore del testo per input
	theme.set_color("font_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_selected_color", control_type, Color(1.0, 1.0, 1.0, 1.0))
	theme.set_color("selection_color", control_type, Color(0.3, 0.3, 0.3, 1.0))

func create_panel_styleboxes(theme: Theme, control_type: String):
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = FANUC_PANEL_BG
	panel_style.border_color = FANUC_BORDER_COLOR
	panel_style.set_border_width_all(1)
	panel_style.set_content_margin_all(4)
	theme.set_stylebox("panel", control_type, panel_style)

func create_tabcontainer_styleboxes(theme: Theme, control_type: String):
	# Sfondo del pannello principale
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = FANUC_PANEL_BG
	panel_style.border_color = FANUC_BORDER_COLOR
	panel_style.set_border_width_all(1)
	panel_style.set_content_margin_all(4)
	theme.set_stylebox("panel", control_type, panel_style)
	
	# Tab non selezionata
	var tab_unselected = StyleBoxFlat.new()
	tab_unselected.bg_color = FANUC_BUTTON_BG
	tab_unselected.border_color = FANUC_BORDER_COLOR
	tab_unselected.set_border_width_all(1)
	tab_unselected.set_content_margin_all(6)
	theme.set_stylebox("tab_unselected", control_type, tab_unselected)
	
	# Tab selezionata
	var tab_selected = StyleBoxFlat.new()
	tab_selected.bg_color = FANUC_PANEL_BG
	tab_selected.border_color = FANUC_BORDER_COLOR
	tab_selected.set_border_width_all(2)
	tab_selected.set_content_margin_all(6)
	theme.set_stylebox("tab_selected", control_type, tab_selected)
	
	# Tab hover
	var tab_hovered = StyleBoxFlat.new()
	tab_hovered.bg_color = FANUC_BUTTON_HOVER
	tab_hovered.border_color = FANUC_BORDER_COLOR
	tab_hovered.set_border_width_all(1)
	tab_hovered.set_content_margin_all(6)
	theme.set_stylebox("tab_hovered", control_type, tab_hovered)
	
	# Tab disabilitata
	var tab_disabled = StyleBoxFlat.new()
	tab_disabled.bg_color = Color(0.75, 0.75, 0.75, 1.0)
	tab_disabled.border_color = Color(0.5, 0.5, 0.5, 1.0)
	tab_disabled.set_border_width_all(1)
	tab_disabled.set_content_margin_all(6)
	theme.set_stylebox("tab_disabled", control_type, tab_disabled)
	
	# Sfondo area tab
	var tabbar_bg = StyleBoxFlat.new()
	tabbar_bg.bg_color = FANUC_BG_COLOR
	theme.set_stylebox("tabbar_background", control_type, tabbar_bg)
	
	# Colori font per le tab - TUTTI NERI
	theme.set_color("font_selected_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_unselected_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_hovered_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_disabled_color", control_type, Color(0.3, 0.3, 0.3, 1.0))

func create_tabbar_styleboxes(theme: Theme, control_type: String):
	# Tab non selezionata
	var tab_unselected = StyleBoxFlat.new()
	tab_unselected.bg_color = FANUC_BUTTON_BG
	tab_unselected.border_color = FANUC_BORDER_COLOR
	tab_unselected.set_border_width_all(1)
	tab_unselected.set_content_margin_all(6)
	theme.set_stylebox("tab_unselected", control_type, tab_unselected)
	
	# Tab selezionata
	var tab_selected = StyleBoxFlat.new()
	tab_selected.bg_color = FANUC_PANEL_BG
	tab_selected.border_color = FANUC_BORDER_COLOR
	tab_selected.set_border_width_all(2)
	tab_selected.set_content_margin_all(6)
	theme.set_stylebox("tab_selected", control_type, tab_selected)
	
	# Tab hover
	var tab_hovered = StyleBoxFlat.new()
	tab_hovered.bg_color = FANUC_BUTTON_HOVER
	tab_hovered.border_color = FANUC_BORDER_COLOR
	tab_hovered.set_border_width_all(1)
	tab_hovered.set_content_margin_all(6)
	theme.set_stylebox("tab_hovered", control_type, tab_hovered)
	
	# Tab disabilitata
	var tab_disabled = StyleBoxFlat.new()
	tab_disabled.bg_color = Color(0.75, 0.75, 0.75, 1.0)
	tab_disabled.border_color = Color(0.5, 0.5, 0.5, 1.0)
	tab_disabled.set_border_width_all(1)
	tab_disabled.set_content_margin_all(6)
	theme.set_stylebox("tab_disabled", control_type, tab_disabled)
	
	# Sfondo della tabbar
	var tabbar_bg = StyleBoxFlat.new()
	tabbar_bg.bg_color = FANUC_BG_COLOR
	theme.set_stylebox("panel", control_type, tabbar_bg)
	
	# Colori font per le tab
	theme.set_color("font_selected_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_unselected_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_hovered_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_disabled_color", control_type, Color(0.3, 0.3, 0.3, 1.0))

func create_list_styleboxes(theme: Theme, control_type: String):
	# Sfondo principale
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.95, 0.95, 0.95, 1.0)
	bg.border_color = FANUC_BORDER_COLOR
	bg.set_border_width_all(1)
	theme.set_stylebox("panel", control_type, bg)
	
	if control_type == "Tree":
		theme.set_stylebox("bg", control_type, bg)
	
	# Item selezionato
	var selected = StyleBoxFlat.new()
	selected.bg_color = FANUC_BUTTON_PRESSED
	theme.set_stylebox("selected", control_type, selected)
	
	# Item con focus
	var selected_focus = StyleBoxFlat.new()
	selected_focus.bg_color = FANUC_BUTTON_HOVER
	selected_focus.border_color = FANUC_BORDER_COLOR
	selected_focus.set_border_width_all(1)
	theme.set_stylebox("selected_focus", control_type, selected_focus)
	
	# Colori aggiuntivi per Tree
	if control_type == "Tree":
		theme.set_color("font_outline_color", control_type, Color(0, 0, 0, 0))
		theme.set_color("title_button_color", control_type, FANUC_TEXT_COLOR)
		theme.set_color("drop_position_color", control_type, FANUC_BORDER_COLOR)
		
		# Cursor e hover per Tree
		var cursor = StyleBoxFlat.new()
		cursor.bg_color = FANUC_BUTTON_HOVER
		cursor.border_color = FANUC_BORDER_COLOR
		cursor.set_border_width_all(1)
		theme.set_stylebox("cursor", control_type, cursor)
		theme.set_stylebox("cursor_unfocused", control_type, cursor)
	
	# Colori aggiuntivi per ItemList
	if control_type == "ItemList":
		var cursor = StyleBoxFlat.new()
		cursor.bg_color = FANUC_BUTTON_HOVER
		cursor.border_color = FANUC_BORDER_COLOR
		cursor.set_border_width_all(1)
		theme.set_stylebox("cursor", control_type, cursor)
		theme.set_stylebox("cursor_unfocused", control_type, cursor)
		
		theme.set_color("guide_color", control_type, FANUC_BORDER_COLOR)

func create_menu_styleboxes(theme: Theme, control_type: String):
	var panel = StyleBoxFlat.new()
	panel.bg_color = FANUC_BG_COLOR
	panel.border_color = FANUC_BORDER_COLOR
	panel.set_border_width_all(1)
	panel.set_content_margin_all(2)
	theme.set_stylebox("panel", control_type, panel)
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = FANUC_BUTTON_HOVER
	theme.set_stylebox("hover", control_type, hover_style)
	
	# Mantieni il testo nero anche in hover per i menu
	theme.set_color("font_hover_color", control_type, FANUC_TEXT_COLOR)
	theme.set_color("font_color", control_type, FANUC_TEXT_COLOR)

func create_dialog_styleboxes(theme: Theme, control_type: String):
	# Sfondo del dialog
	var panel = StyleBoxFlat.new()
	panel.bg_color = FANUC_PANEL_BG
	panel.border_color = FANUC_BORDER_COLOR
	panel.set_border_width_all(2)
	panel.set_content_margin_all(8)
	theme.set_stylebox("panel", control_type, panel)
	
	# Colori del testo
	theme.set_color("font_color", control_type, FANUC_TEXT_COLOR)
