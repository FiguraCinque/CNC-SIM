# SceneGenerator.gd (CORRETTO)
# SCRIPT PER USO SINGOLO (TOOL SCRIPT)
# Eseguire questo script dall'editor di Godot (Click destro -> Run)
# per generare programmaticamente la scena dell'interfaccia CNC.
@tool
extends EditorScript

func _run() -> void:
	var scene_path = "res://CNC_Interface.tscn"
	
	if FileAccess.file_exists(scene_path):
		print("ERRORE: Il file '%s' esiste già. Cancellalo prima di eseguire questo script." % scene_path)
		return

	print("Inizio generazione della scena CNC_Interface.tscn...")

	# --- Nodo Radice ---
	# Il nodo radice è proprietario di se stesso per definizione.
	var root = Control.new()
	root.name = "CNC_Interface"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# --- Contenitore Principale ---
	var margin_container = MarginContainer.new()
	root.add_child(margin_container)
	margin_container.owner = root # <<< LA SOLUZIONE
	
	var tab_container = TabContainer.new()
	margin_container.add_child(tab_container)
	tab_container.owner = root # <<< LA SOLUZIONE
	
	# --- Scheda 1: Offset Utensili ---
	var tab1_vbox = VBoxContainer.new()
	tab1_vbox.name = "Offset Utensili"
	tab_container.add_child(tab1_vbox)
	tab1_vbox.owner = root # <<< LA SOLUZIONE
	
	var tab1_label = Label.new()
	tab1_label.text = "Offset Utensili (Doppio Click per Modificare)"
	tab1_vbox.add_child(tab1_label)
	tab1_label.owner = root # <<< LA SOLUZIONE
	
	var tool_offset_tree = Tree.new()
	tool_offset_tree.name = "ToolOffsetTree"
	tool_offset_tree.columns = 5
	tool_offset_tree.hide_root = true
	tool_offset_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab1_vbox.add_child(tool_offset_tree)
	tool_offset_tree.owner = root # <<< LA SOLUZIONE
	
	# --- Scheda 2: Origini Pezzo ---
	var tab2_vbox = VBoxContainer.new()
	tab2_vbox.name = "Origini Pezzo"
	tab_container.add_child(tab2_vbox)
	tab2_vbox.owner = root # <<< LA SOLUZIONE
	
	var tab2_hbox = HBoxContainer.new()
	tab2_vbox.add_child(tab2_hbox)
	tab2_hbox.owner = root # <<< LA SOLUZIONE
	
	var tab2_label = Label.new()
	tab2_label.text = "Tipo Origine: "
	tab2_hbox.add_child(tab2_label)
	tab2_label.owner = root # <<< LA SOLUZIONE
	
	var work_offset_selector = OptionButton.new()
	work_offset_selector.name = "WorkOffsetTypeSelector"
	tab2_hbox.add_child(work_offset_selector)
	work_offset_selector.owner = root # <<< LA SOLUZIONE
	
	var work_offset_tree = Tree.new()
	work_offset_tree.name = "WorkOffsetTree"
	work_offset_tree.columns = 5
	work_offset_tree.hide_root = true
	work_offset_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab2_vbox.add_child(work_offset_tree)
	work_offset_tree.owner = root # <<< LA SOLUZIONE

	# --- Scheda 3: Variabili Macro ---
	var tab3_vbox = VBoxContainer.new()
	tab3_vbox.name = "Variabili Macro"
	tab_container.add_child(tab3_vbox)
	tab3_vbox.owner = root # <<< LA SOLUZIONE
	
	var tab3_label = Label.new()
	tab3_label.text = "Variabili Macro Comuni (#100-#199, #500-#999)"
	tab3_vbox.add_child(tab3_label)
	tab3_label.owner = root # <<< LA SOLUZIONE

	var macro_var_tree = Tree.new()
	macro_var_tree.name = "MacroVarTree"
	macro_var_tree.columns = 2
	macro_var_tree.hide_root = true
	macro_var_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab3_vbox.add_child(macro_var_tree)
	macro_var_tree.owner = root # <<< LA SOLUZIONE

	# --- Scheda 4: Programmi ---
	var tab4_vbox = VBoxContainer.new()
	tab4_vbox.name = "Programmi"
	tab_container.add_child(tab4_vbox)
	tab4_vbox.owner = root # <<< LA SOLUZIONE

	var h_split = HSplitContainer.new()
	h_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab4_vbox.add_child(h_split)
	h_split.owner = root # <<< LA SOLUZIONE

	# Pannello Sinistro
	var left_panel = VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_split.add_child(left_panel)
	left_panel.owner = root # <<< LA SOLUZIONE
	
	var left_label = Label.new()
	left_label.text = "Programmi in Memoria"
	left_panel.add_child(left_label)
	left_label.owner = root # <<< LA SOLUZIONE
	
	var program_list = ItemList.new()
	program_list.name = "ProgramList"
	program_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(program_list)
	program_list.owner = root # <<< LA SOLUZIONE
	
	var button_hbox = HBoxContainer.new()
	left_panel.add_child(button_hbox)
	button_hbox.owner = root # <<< LA SOLUZIONE
	
	var set_active_btn = Button.new()
	set_active_btn.name = "SetActiveButton"
	set_active_btn.text = "Imposta Attivo"
	button_hbox.add_child(set_active_btn)
	set_active_btn.owner = root # <<< LA SOLUZIONE
	
	var delete_btn = Button.new()
	delete_btn.name = "DeleteButton"
	delete_btn.text = "Cancella"
	button_hbox.add_child(delete_btn)
	delete_btn.owner = root # <<< LA SOLUZIONE
	
	# Pannello Destro
	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_split.add_child(right_panel)
	right_panel.owner = root # <<< LA SOLUZIONE
	
	var right_label = Label.new()
	right_label.name = "SelectedProgramLabel"
	right_label.text = "Contenuto Programma: (Nessuno)"
	right_panel.add_child(right_label)
	right_label.owner = root # <<< LA SOLUZIONE
	
	var program_content = TextEdit.new()
	program_content.name = "ProgramContentTextEdit"
	#program_content.readonly = true
	program_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(program_content)
	program_content.owner = root # <<< LA SOLUZIONE
	
	# --- Finestra di Dialogo per la Modifica ---
	var edit_dialog = ConfirmationDialog.new()
	edit_dialog.name = "EditValueDialog"
	edit_dialog.title = "Modifica Valore"
	root.add_child(edit_dialog)
	edit_dialog.owner = root # <<< LA SOLUZIONE

	var dialog_vbox = VBoxContainer.new()
	edit_dialog.add_child(dialog_vbox)
	dialog_vbox.owner = root # <<< LA SOLUZIONE
	
	var edit_label = Label.new()
	edit_label.name = "EditLabel"
	edit_label.text = "Nuovo valore per: "
	dialog_vbox.add_child(edit_label)
	edit_label.owner = root # <<< LA SOLUZIONE
	
	var edit_line_edit = LineEdit.new()
	edit_line_edit.name = "EditLineEdit"
	dialog_vbox.add_child(edit_line_edit)
	edit_line_edit.owner = root # <<< LA SOLUZIONE
	
	# --- Salvataggio della Scena ---
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(root)
	
	if result == OK:
		var save_result = ResourceSaver.save(packed_scene, scene_path)
		if save_result == OK:
			print("SUCCESSO: Scena salvata correttamente in '%s'" % scene_path)
		else:
			print("ERRORE: Impossibile salvare la scena. Codice errore: %d" % save_result)
	else:
		print("ERRORE: Impossibile 'impacchettare' la scena. Codice errore: %d" % result)
