# CNC_Interface.gd
# Script per gestire l'interfaccia utente che visualizza e modifica i dati del CncMemory.
extends Control

# =========================================================================
# RIFERIMENTI NODI - TAB OFFSET UTENSILI
# =========================================================================

@onready var tool_offset_tree: Tree = $MarginContainer/TabContainer/OffsetUtensili/ToolOffsetTree

# =========================================================================
# RIFERIMENTI NODI - TAB ORIGINI PEZZO
# =========================================================================

@onready var work_offset_tree: Tree = $MarginContainer/TabContainer/OriginiPezzo/WorkOffsetTree
@onready var work_offset_selector: OptionButton = $MarginContainer/TabContainer/OriginiPezzo/HBoxContainer/OptionButton

# =========================================================================
# RIFERIMENTI NODI - TAB VARIABILI MACRO
# =========================================================================

@onready var macro_var_tree: Tree = $MarginContainer/TabContainer/VariabiliMacro/MacroVarTree

# =========================================================================
# RIFERIMENTI NODI - TAB EDITOR PROGRAMMI
# =========================================================================

@onready var program_list: ItemList = $MarginContainer/TabContainer/Editor/HSplitContainer/VBoxContainer/ProgramList
@onready var selected_program_label: Label = $MarginContainer/TabContainer/Editor/HSplitContainer/VBoxContainer2/SelectedProgramLabel
@onready var program_content_text: TextEdit = $MarginContainer/TabContainer/Editor/HSplitContainer/VBoxContainer2/ProgramContentTextEdit
@onready var set_active_button: Button = $MarginContainer/TabContainer/Editor/HSplitContainer/VBoxContainer/HBoxContainer/SetActiveButton
@onready var delete_button: Button = $MarginContainer/TabContainer/Editor/HSplitContainer/VBoxContainer/HBoxContainer/DeleteButton
@onready var create_button: Button = $MarginContainer/TabContainer/Editor/HSplitContainer/VBoxContainer/HBoxContainer/CreateButton
@onready var rename_button: Button = $MarginContainer/TabContainer/Editor/HSplitContainer/VBoxContainer/HBoxContainer/RenameButton

# =========================================================================
# RIFERIMENTI NODI - DIALOGHI
# =========================================================================

@onready var edit_dialog: ConfirmationDialog = $EditValueDialog
@onready var edit_label: Label = $EditValueDialog/VBoxContainer/Label
@onready var edit_line_edit: LineEdit = $EditValueDialog/VBoxContainer/LineEdit

@onready var create_dialog: ConfirmationDialog = $CreateProgramDialog
@onready var program_number_edit: LineEdit = $CreateProgramDialog/VBoxContainer/ProgramNumberEdit

@onready var rename_dialog: ConfirmationDialog = $RenameProgramDialog
@onready var new_program_number_edit: LineEdit = $RenameProgramDialog/VBoxContainer/NewProgramNumberEdit

@onready var delete_confirm_dialog: ConfirmationDialog = $DeleteConfirmDialog
@onready var delete_confirm_label: Label = $DeleteConfirmDialog/Label

# =========================================================================
# VARIABILI MEMBRO
# =========================================================================

## Timer per il salvataggio ritardato dei programmi
var save_timer: Timer = null

## Flag che indica se c'è un salvataggio in attesa
var pending_program_save: bool = false

# =========================================================================
# METODI CICLO DI VITA GODOT
# =========================================================================

func _ready() -> void:
	"""
	Inizializza l'interfaccia al caricamento del nodo.
	"""
	# Attendi che il singleton sia pronto
	await get_tree().process_frame
	if not get_tree().root.has_node("CncMemory"):
		printerr("ERRORE: Singleton 'CncMemory' non trovato. Assicurati che sia in Autoload.")
		return
	
	# Inizializzazione Interfaccia
	_setup_trees()
	_setup_work_offset_selector()
	_setup_save_timer()
	
	# Popolamento iniziale
	_populate_all()
	
	# Connessione dei segnali
	_connect_signals()
	MacroBPreprocessor.test_preprocessing()

func _input(event: InputEvent) -> void:
	"""
	Gestisce gli input globali (Ctrl+C, Ctrl+V).
	"""
	# Controlla se l'evento è una pressione di un tasto e se il tasto Ctrl è premuto
	if event is InputEventKey and event.is_pressed() and event.is_command_or_control_pressed():
		# Gestione Copia (Ctrl+C)
		if event.keycode == KEY_C:
			_handle_copy_operation()
			
		# Gestione Incolla (Ctrl+V)
		if event.keycode == KEY_V:
			_handle_paste_operation()

# =========================================================================
# SETUP INIZIALE - CONFIGURAZIONE INTERFACCIA
# =========================================================================

func _setup_trees() -> void:
	"""
	Configura le colonne e le proprietà degli alberi (Tree).
	"""
	# Configura le colonne per l'albero degli offset utensile
	tool_offset_tree.set_column_title(0, "Utensile")
	tool_offset_tree.set_column_title(1, "Geom L")
	tool_offset_tree.set_column_title(2, "Usura L")
	tool_offset_tree.set_column_title(3, "Geom R")
	tool_offset_tree.set_column_title(4, "Usura R")
	
	# Configura le colonne per l'albero delle origini pezzo
	work_offset_tree.set_column_title(0, "Origine")
	work_offset_tree.set_column_title(1, "X")
	work_offset_tree.set_column_title(2, "Y")
	work_offset_tree.set_column_title(3, "Z")
	work_offset_tree.set_column_title(4, "B")

	# Configura le colonne per le variabili macro
	macro_var_tree.set_column_title(0, "Indirizzo (#)")
	macro_var_tree.set_column_title(1, "Valore")

	# Abilita la selezione multipla per tutti i tree
	tool_offset_tree.select_mode = Tree.SELECT_MULTI
	work_offset_tree.select_mode = Tree.SELECT_MULTI
	macro_var_tree.select_mode = Tree.SELECT_MULTI

func _setup_work_offset_selector() -> void:
	"""
	Popola il selettore del tipo di origine pezzo.
	"""
	work_offset_selector.add_item("Standard (G54-G59)")
	work_offset_selector.add_item("Estese (G54.1 P1-P48)")

func _setup_save_timer() -> void:
	"""
	Crea e configura il timer per il salvataggio ritardato.
	"""
	save_timer = Timer.new()
	save_timer.wait_time = 1.0  # Salva dopo 1 secondo di inattività
	save_timer.one_shot = true
	save_timer.timeout.connect(_save_pending_program)
	add_child(save_timer)

# =========================================================================
# SETUP INIZIALE - CONNESSIONE SEGNALI
# =========================================================================

func _connect_signals() -> void:
	"""
	Connette tutti i segnali dell'interfaccia.
	"""
	# Segnali per la modifica dei valori negli alberi (Tree)
	tool_offset_tree.item_activated.connect(_on_tree_item_activated)
	work_offset_tree.item_activated.connect(_on_tree_item_activated)
	macro_var_tree.item_activated.connect(_on_tree_item_activated)
	
	# Segnali per la gestione dei programmi
	program_list.item_activated.connect(_on_program_list_item_activated)
	program_list.select_mode = ItemList.SELECT_MULTI
	
	set_active_button.pressed.connect(_on_set_active_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)
	rename_button.pressed.connect(_on_rename_button_pressed)
	create_button.pressed.connect(_on_create_button_pressed)
	
	# Segnali per i dialoghi
	edit_dialog.confirmed.connect(_on_edit_dialog_confirmed)
	create_dialog.confirmed.connect(_on_create_dialog_confirmed)
	rename_dialog.confirmed.connect(_on_rename_dialog_confirmed)
	delete_confirm_dialog.confirmed.connect(_on_delete_confirmed)
	
	# Segnale per il selettore delle origini
	work_offset_selector.item_selected.connect(_on_work_offset_type_selected)
	
	# Segnale per il contenuto del programma
	program_content_text.text_changed.connect(_on_program_content_changed_delayed)

# =========================================================================
# POPOLAMENTO DATI - METODI PRINCIPALI
# =========================================================================

func _populate_all() -> void:
	"""
	Popola tutte le sezioni dell'interfaccia.
	"""
	_populate_tool_offsets()
	_populate_work_offsets()
	_populate_macro_vars()
	_populate_programs()

func _populate_tool_offsets() -> void:
	"""
	Popola l'albero degli offset utensile con i dati dalla memoria.
	"""
	tool_offset_tree.clear()
	var root = tool_offset_tree.create_item()
	for i in range(1, 401):
		var item = tool_offset_tree.create_item(root)
		item.set_text(0, str(i))
		
		var geom_l = CncMemory.system_variables.get(CncMemory.TOOL_GEOM_LENGTH_OFFSET_BASE + i, 0.0)
		var wear_l = CncMemory.system_variables.get(CncMemory.TOOL_WEAR_LENGTH_OFFSET_BASE + i, 0.0)
		var geom_r = CncMemory.system_variables.get(CncMemory.TOOL_GEOM_RADIUS_OFFSET_BASE + i, 0.0)
		var wear_r = CncMemory.system_variables.get(CncMemory.TOOL_WEAR_RADIUS_OFFSET_BASE + i, 0.0)
		
		item.set_text(1, "%.4f" % geom_l)
		item.set_text(2, "%.4f" % wear_l)
		item.set_text(3, "%.4f" % geom_r)
		item.set_text(4, "%.4f" % wear_r)
		
		# Salva metadati per sapere cosa modificare dopo
		item.set_metadata(0, {"type": "tool", "num": i})

func _populate_work_offsets() -> void:
	"""
	Popola l'albero delle origini pezzo con i dati dalla memoria.
	"""
	work_offset_tree.clear()
	var root = work_offset_tree.create_item()
	var selected_type = work_offset_selector.get_selected_id()
	var axes = ["X", "Y", "Z", "B"]

	if selected_type == 0: # Standard
		for i in range(6): # G54-G59
			var g_code = "G" + str(54 + i)
			var item = work_offset_tree.create_item(root)
			item.set_text(0, g_code)
			for axis_idx in range(axes.size()):
				var axis_char = axes[axis_idx]
				var address = g_code + "." + axis_char

				var value = CncMemory.get_variable(address)
				if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
					item.set_text(axis_idx + 1, "%.4f" % value)
				else:
					item.set_text(axis_idx + 1, "ERR")
					
			item.set_metadata(0, {"type": "work_offset", "g_code": g_code})
			
	elif selected_type == 1: # Estese
		for i in range(1, 49): # P1-P48
			var g_code = "G54.1P" + str(i)
			var item = work_offset_tree.create_item(root)
			item.set_text(0, g_code)
			for axis_idx in range(axes.size()):
				var axis_char = axes[axis_idx]
				var address = g_code + "." + axis_char

				var value = CncMemory.get_variable(address)
				if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
					item.set_text(axis_idx + 1, "%.4f" % value)
				else:
					item.set_text(axis_idx + 1, "ERR")

			item.set_metadata(0, {"type": "work_offset", "g_code": g_code})

func _populate_macro_vars() -> void:
	"""
	Popola l'albero delle variabili macro con i dati dalla memoria.
	"""
	macro_var_tree.clear()
	var root = macro_var_tree.create_item()
	
	# Range 1
	for i in range(CncMemory.MACRO_CUSTOM_VAR_RANGE_LOW_1, CncMemory.MACRO_CUSTOM_VAR_RANGE_HIGH_1 + 1):
		var item = macro_var_tree.create_item(root)
		var value = CncMemory.get_variable("#" + str(i))
		item.set_text(0, "#" + str(i))
		item.set_text(1, "%.4f" % value)
		item.set_metadata(0, {"type": "macro", "num": i})
		
	# Range 2
	for i in range(CncMemory.MACRO_CUSTOM_VAR_RANGE_LOW_2, CncMemory.MACRO_CUSTOM_VAR_RANGE_HIGH_2 + 1):
		var item = macro_var_tree.create_item(root)
		var value = CncMemory.get_variable("#" + str(i))
		item.set_text(0, "#" + str(i))
		item.set_text(1, "%.4f" % value)
		item.set_metadata(0, {"type": "macro", "num": i})

func _populate_programs() -> void:
	"""
	Popola la lista dei programmi con i dati dalla memoria.
	"""
	program_list.clear()
	var program_names = CncMemory.get_all_program_names()
	program_names.sort()
	
	var previously_displayed_program = ""
	if selected_program_label.text.begins_with("Contenuto Programma: O"):
		previously_displayed_program = selected_program_label.text.split(": ")[1]
	
	for nameP in program_names:
		program_list.add_item(nameP)
		if nameP == CncMemory.active_program_name:
			var last_idx = program_list.get_item_count() - 1
			program_list.set_item_custom_fg_color(last_idx, Color.BLUE)
	
	# Se il programma visualizzato non esiste più, pulisci la vista
	if previously_displayed_program != "" and not CncMemory.programs.has(previously_displayed_program):
		selected_program_label.text = "Contenuto Programma: (Nessuno)"
		program_content_text.text = ""
	
	# Aggiorna lo stato dei pulsanti
	_on_program_list_item_selected(-1)

# =========================================================================
# GESTIONE ALBERI (TREE) - MODIFICA VALORI
# =========================================================================

func _on_tree_item_activated() -> void:
	"""
	Gestisce l'attivazione di un elemento negli alberi per la modifica.
	"""
	var tree = get_tree().get_root().gui_get_focus_owner()
	if not tree is Tree: return
	
	var item = tree.get_selected()
	var column = tree.get_selected_column()
	if not item or column == 0: return # Non modificare la prima colonna (ID)

	var metadata = item.get_metadata(0)
	var current_value_str = item.get_text(column)
	
	var label_text = ""
	
	# Costruisci un'etichetta descrittiva per il dialogo
	match metadata["type"]:
		"tool":
			var col_name = tree.get_column_title(column)
			label_text = "Nuovo valore per %s Utensile %d:" % [col_name, metadata["num"]]
		"work_offset":
			var axis = tree.get_column_title(column)
			label_text = "Nuovo valore per %s Asse %s:" % [metadata["g_code"], axis]
		"macro":
			label_text = "Nuovo valore per #%d:" % metadata["num"]
	
	# Prepara e mostra il dialogo di modifica
	edit_label.text = label_text
	edit_line_edit.text = current_value_str
	edit_dialog.popup_centered()
	edit_line_edit.grab_focus()
	
	# Salva i metadati nel dialogo stesso per usarli al momento della conferma
	edit_dialog.set_meta("edit_info", {"metadata": metadata, "column": column})

func _on_edit_dialog_confirmed() -> void:
	"""
	Gestisce la conferma della modifica di un valore.
	"""
	var info = edit_dialog.get_meta("edit_info")
	var metadata = info["metadata"]
	var column = info["column"]
	var new_value_str = edit_line_edit.text
	
	if not new_value_str.is_valid_float():
		printerr("Valore non valido: ", new_value_str)
		return
	
	var new_value = float(new_value_str)
	
	# In base al tipo, chiama il metodo corretto di CncMemory
	match metadata["type"]:
		"tool":
			var tool_num = metadata["num"]
			var address_base = 0
			match column:
				1: address_base = CncMemory.TOOL_GEOM_LENGTH_OFFSET_BASE
				2: address_base = CncMemory.TOOL_WEAR_LENGTH_OFFSET_BASE
				3: address_base = CncMemory.TOOL_GEOM_RADIUS_OFFSET_BASE
				4: address_base = CncMemory.TOOL_WEAR_RADIUS_OFFSET_BASE
			if address_base > 0:
				CncMemory.system_variables[address_base + tool_num] = new_value
			_populate_tool_offsets()
			
		"work_offset":
			var g_code = metadata["g_code"]
			var axis = work_offset_tree.get_column_title(column)
			var address = g_code + "." + axis
			CncMemory.set_variable(address, new_value)
			_populate_work_offsets()
			
		"macro":
			var var_num = metadata["num"]
			CncMemory.set_variable("#" + str(var_num), new_value)
			_populate_macro_vars()

@warning_ignore("unused_parameter")
func _on_work_offset_type_selected(index: int) -> void:
	"""
	Gestisce il cambio di tipo di origine pezzo (Standard/Estese).
	"""
	_populate_work_offsets()

# =========================================================================
# GESTIONE PROGRAMMI - SELEZIONE E VISUALIZZAZIONE
# =========================================================================

func _on_program_list_item_activated(index: int) -> void:
	"""
	Chiamato quando l'utente fa doppio click o preme Enter su un programma.
	"""
	_display_program_content(index)

@warning_ignore("unused_parameter")
func _on_program_list_item_selected(index: int) -> void:
	"""
	Chiamato quando la selezione cambia (NON mostra più il contenuto automaticamente).
	Abilita/disabilita i pulsanti in base alla selezione.
	"""
	var selected_items = program_list.get_selected_items()
	
	if selected_items.is_empty():
		delete_button.disabled = true
		set_active_button.disabled = true
		rename_button.disabled = true
	else:
		delete_button.disabled = false
		set_active_button.disabled = (selected_items.size() > 1)
		rename_button.disabled = (selected_items.size() > 1)

func _display_program_content(index: int) -> void:
	"""
	Mostra il contenuto del programma selezionato.
	"""
	if index == -1 or index >= program_list.get_item_count():
		selected_program_label.text = "Contenuto Programma: (Nessuno)"
		program_content_text.text = ""
		return
	
	var program_name = program_list.get_item_text(index)
	var program_num = int(program_name.substr(1))
	var program_content_array = CncMemory.get_program(program_num)
	
	selected_program_label.text = "Contenuto Programma: %s" % program_name
	program_content_text.text = "\n".join(program_content_array)
	
	# Disconnetti temporaneamente il segnale per evitare salvataggi durante il caricamento
	if program_content_text.text_changed.is_connected(_on_program_content_changed):
		program_content_text.text_changed.disconnect(_on_program_content_changed)
	
	# Riconnetti il segnale
	await get_tree().process_frame
	if not program_content_text.text_changed.is_connected(_on_program_content_changed):
		program_content_text.text_changed.connect(_on_program_content_changed)

# =========================================================================
# GESTIONE PROGRAMMI - SALVATAGGIO CONTENUTO
# =========================================================================

func _on_program_content_changed() -> void:
	"""
	Chiamato quando il contenuto del TextEdit viene modificato.
	Salva automaticamente le modifiche nel programma visualizzato.
	"""
	# Verifica che ci sia un programma visualizzato
	if not selected_program_label.text.begins_with("Contenuto Programma: O"):
		return
	
	var program_name = selected_program_label.text.split(": ")[1]
	var program_num = int(program_name.substr(1))
	
	var content_text = program_content_text.text
	var content_lines: Array[String] = []
	
	var lines = content_text.split("\n")
	for line in lines:
		content_lines.append(line.strip_edges(false, true))
	
	CncMemory.add_program(program_num, content_lines)
	
	print("Programma %s aggiornato automaticamente." % program_name)

func _on_program_content_changed_delayed() -> void:
	"""
	Avvia/riavvia il timer per il salvataggio ritardato.
	"""
	pending_program_save = true
	save_timer.start()

func _save_pending_program() -> void:
	"""
	Salva effettivamente il programma dopo che il timer è scaduto.
	"""
	if not pending_program_save:
		return
		
	var selected_items = program_list.get_selected_items()
	if selected_items.is_empty():
		pending_program_save = false
		return
	
	var program_name = program_list.get_item_text(selected_items[0])
	var program_num = int(program_name.substr(1))
	
	var content_text = program_content_text.text
	var content_lines: Array[String] = []
	
	var lines = content_text.split("\n")
	for line in lines:
		content_lines.append(line.strip_edges(false, true))

	CncMemory.add_program(program_num, content_lines)
	
	print("Programma %s salvato automaticamente." % program_name)
	pending_program_save = false

# =========================================================================
# GESTIONE PROGRAMMI - OPERAZIONI (ATTIVO, CREA, RINOMINA, ELIMINA)
# =========================================================================

func _on_set_active_button_pressed() -> void:
	"""
	Imposta il programma selezionato come attivo.
	"""
	var selected_items = program_list.get_selected_items()
	if selected_items.is_empty(): return
	
	var program_name = program_list.get_item_text(selected_items[0])
	if CncMemory.set_active_program_by_name(program_name):
		print("Programma attivo impostato a: ", program_name)
		_populate_programs()
	else:
		printerr("Impossibile impostare il programma attivo.")

func _on_create_button_pressed() -> void:
	"""
	Mostra il dialogo per la creazione di un nuovo programma.
	"""
	program_number_edit.text = ""
	create_dialog.popup_centered()
	program_number_edit.grab_focus()

func _on_create_dialog_confirmed() -> void:
	"""
	Chiamato quando l'utente preme 'OK' nel dialogo di creazione.
	"""
	var number_str = program_number_edit.text
	
	# Validazione dell'input
	if not number_str.is_valid_int():
		printerr("ERRORE: Il numero del programma non è un intero valido.")
		return
		
	var program_num = int(number_str)
	if program_num <= 0:
		printerr("ERRORE: Il numero del programma deve essere positivo.")
		return
		
	# Controlla se il programma esiste già
	var program_name_check = "O%04d" % program_num
	if CncMemory.programs.has(program_name_check):
		printerr("ERRORE: Il programma '%s' esiste già." % program_name_check)
		return

	# Aggiunta del programma (vuoto) alla memoria
	CncMemory.add_program(program_num, [])
	
	# Aggiornamento dell'interfaccia
	_populate_programs()
	
	# Seleziona automaticamente il nuovo programma creato
	for i in range(program_list.get_item_count()):
		if program_list.get_item_text(i) == program_name_check:
			program_list.select(i)
			_on_program_list_item_selected(i)
			break

func _on_rename_button_pressed() -> void:
	"""
	Mostra dialogo di rinomina per il programma selezionato.
	"""
	var selected_items = program_list.get_selected_items()
	if selected_items.is_empty() or selected_items.size() > 1:
		return
	
	var program_name = program_list.get_item_text(selected_items[0])
	var current_num = int(program_name.substr(1))
	
	new_program_number_edit.text = str(current_num)
	rename_dialog.popup_centered()
	new_program_number_edit.grab_focus()
	new_program_number_edit.select_all()
	
	# Salva il programma corrente da rinominare
	rename_dialog.set_meta("old_program_name", program_name)

func _on_rename_dialog_confirmed() -> void:
	"""
	Esegue la rinomina del programma.
	"""
	var old_program_name = rename_dialog.get_meta("old_program_name")
	var new_number_str = new_program_number_edit.text
	
	# Validazione
	if not new_number_str.is_valid_int():
		printerr("ERRORE: Il nuovo numero del programma non è un intero valido.")
		return
	
	var new_program_num = int(new_number_str)
	if new_program_num <= 0:
		printerr("ERRORE: Il numero del programma deve essere positivo.")
		return
	
	var new_program_name = "O%04d" % new_program_num
	
	# Controlla se il nome è uguale (nessuna modifica)
	if old_program_name == new_program_name:
		print("Nessuna modifica al nome del programma.")
		return
	
	# Controlla se il nuovo nome esiste già
	if CncMemory.programs.has(new_program_name):
		printerr("ERRORE: Il programma '%s' esiste già." % new_program_name)
		return
	
	# Esegui la rinomina
	var old_program_num = int(old_program_name.substr(1))
	var program_content = CncMemory.get_program(old_program_num)

	# Crea un nuovo array esplicitamente tipizzato come Array[String]
	var typed_program_content: Array[String] = []
	for line in program_content:
		typed_program_content.append(str(line))
	
	# Aggiungi con il nuovo nome
	CncMemory.add_program(new_program_num, typed_program_content)
	
	# Cancella il vecchio
	CncMemory.delete_program(old_program_num)
	
	# Se era il programma attivo, aggiorna il riferimento
	if CncMemory.active_program_name == old_program_name:
		CncMemory.set_active_program_by_name(new_program_name)
	
	print("Programma rinominato da '%s' a '%s'." % [old_program_name, new_program_name])
	
	# Ricarica l'interfaccia
	_populate_programs()

func _on_delete_button_pressed() -> void:
	"""
	Mostra il dialogo di conferma per la cancellazione.
	"""
	var selected_items = program_list.get_selected_items()
	if selected_items.is_empty():
		return
	
	# Prepara il messaggio di conferma
	var message = ""
	if selected_items.size() == 1:
		var program_name = program_list.get_item_text(selected_items[0])
		message = "Sei sicuro di voler cancellare il programma '%s'?" % program_name
	else:
		message = "Sei sicuro di voler cancellare %d programmi?" % selected_items.size()
	
	delete_confirm_label.text = message
	delete_confirm_dialog.popup_centered()

func _on_delete_confirmed() -> void:
	"""
	Esegue la cancellazione dopo conferma.
	"""
	var selected_items = program_list.get_selected_items()
	if selected_items.is_empty():
		return
	
	var deleted_programs: Array[String] = []
	
	# Raccogli i nomi dei programmi da cancellare
	for idx in selected_items:
		var program_name = program_list.get_item_text(idx)
		deleted_programs.append(program_name)
	
	# Cancella i programmi
	for program_name in deleted_programs:
		var program_num = int(program_name.substr(1))
		if CncMemory.delete_program(program_num):
			CncMemory.handle_program_deletion(program_name)
			print("Programma %s cancellato." % program_name)
	
	# Ricarica la lista
	_populate_programs()

# =========================================================================
# COPIA/INCOLLA - OPERAZIONI
# =========================================================================

func _handle_copy_operation() -> void:
	"""
	Gestisce l'operazione di copia (Ctrl+C) dagli alberi.
	"""
	var focused_control = get_tree().get_root().gui_get_focus_owner()
	if not focused_control is Tree:
		return
		
	var tree: Tree = focused_control
	var selected_items: Array[TreeItem] = _get_all_selected_items(tree)
	if selected_items.is_empty():
		return

	var clipboard_text = ""
	for item in selected_items:
		var line_parts: Array[String] = []
		
		for i in range(1, tree.columns):
			line_parts.append(item.get_text(i))
		
		clipboard_text += "\t".join(line_parts) + "\n"
	
	DisplayServer.clipboard_set(clipboard_text)
	print("Dati copiati nella clipboard.")

func _handle_paste_operation() -> void:
	"""
	Gestisce l'operazione di incolla (Ctrl+V) negli alberi.
	"""
	var focused_control = get_tree().get_root().gui_get_focus_owner()
	if not focused_control is Tree:
		return
		
	var tree: Tree = focused_control
	var start_item = tree.get_selected()
	var start_col = tree.get_selected_column()
	if not start_item or start_col == 0:
		print("Seleziona una cella (non nella prima colonna) per iniziare a incollare.")
		return

	var clipboard_text = DisplayServer.clipboard_get()
	var lines = clipboard_text.strip_edges().split("\n")
	if lines.is_empty():
		return

	var current_item = start_item
	var changed = false

	for line in lines:
		if not current_item: break

		var values = line.split("\t")
		var current_col = start_col
		
		for value_str in values:
			if current_col >= tree.columns: break

			var metadata = current_item.get_metadata(0)
			if metadata == null: continue

			if value_str.is_valid_float():
				var new_value = float(value_str)
				
				match metadata["type"]:
					"tool":
						var tool_num = metadata["num"]
						var address_base = 0
						match current_col:
							1: address_base = CncMemory.TOOL_GEOM_LENGTH_OFFSET_BASE
							2: address_base = CncMemory.TOOL_WEAR_LENGTH_OFFSET_BASE
							3: address_base = CncMemory.TOOL_GEOM_RADIUS_OFFSET_BASE
							4: address_base = CncMemory.TOOL_WEAR_RADIUS_OFFSET_BASE
						if address_base > 0:
							CncMemory.system_variables[address_base + tool_num] = new_value
							changed = true

					"work_offset":
						var g_code = metadata["g_code"]
						var axis = tree.get_column_title(current_col)
						var address = g_code + "." + axis
						CncMemory.set_variable(address, new_value)
						changed = true
						
					"macro":
						var var_num = metadata["num"]
						CncMemory.set_variable("#" + str(var_num), new_value)
						changed = true

			current_col += 1
		current_item = current_item.get_next()

	if changed:
		print("Dati incollati con successo. Aggiornamento della vista...")
		if tree == tool_offset_tree:
			_populate_tool_offsets()
		elif tree == work_offset_tree:
			_populate_work_offsets()
		elif tree == macro_var_tree:
			_populate_macro_vars()

# =========================================================================
# HELPER - UTILITÀ
# =========================================================================

func _get_all_selected_items(tree: Tree) -> Array[TreeItem]:
	"""
	Restituisce tutti gli elementi selezionati in un albero.
	"""
	var selected_items: Array[TreeItem] = []
	var item: TreeItem = tree.get_next_selected(null)
	while item != null:
		selected_items.append(item)
		item = tree.get_next_selected(item)
	return selected_items

# =========================================================================
# CALLBACK EXTRA - GESTIONE CLICK E SELEZIONE
# =========================================================================

@warning_ignore("unused_parameter")
func _on_program_list_multi_selected(index: int, selected: bool) -> void:
	"""
	Callback per selezione multipla (non utilizzata attualmente).
	"""
	pass

@warning_ignore("unused_parameter")
func _on_program_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	"""
	Gestisce il click su un elemento della lista programmi.
	"""
	delete_button.disabled = false
	set_active_button.disabled = false
	rename_button.disabled = false

@warning_ignore("unused_parameter")
func _on_program_list_empty_clicked(at_position: Vector2, mouse_button_index: int) -> void:
	"""
	Gestisce il click su un'area vuota della lista programmi.
	"""
	delete_button.disabled = true
	set_active_button.disabled = true
	rename_button.disabled = true
