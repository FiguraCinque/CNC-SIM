# generate_ui_nodes.gd
# SCRIPT @tool USA E GETTA - Esegui dall'editor, poi elimina
#@tool
extends EditorScript

func _run() -> void:
	print("=== INIZIO GENERAZIONE NODI UI ===")
	
	# Ottieni la scena attualmente aperta nell'editor
	var edited_scene = get_editor_interface().get_edited_scene_root()
	
	if edited_scene == null:
		printerr("ERRORE: Nessuna scena aperta nell'editor!")
		printerr("Apri la scena CNC_Interface prima di eseguire questo script.")
		return
	
	if edited_scene.name != "CNC_Interface":
		printerr("ATTENZIONE: La scena aperta non si chiama 'CNC_Interface'")
		print("Procedo comunque con la scena: ", edited_scene.name)
	
	var root = edited_scene
	
	# 1. CREA IL RENAME BUTTON
	print("\n1. Creazione RenameButton...")
	var hbox_container = root.get_node_or_null("MarginContainer/TabContainer/Editor/HSplitContainer/VBoxContainer/HBoxContainer")
	if hbox_container == null:
		printerr("ERRORE: HBoxContainer non trovato!")
		printerr("Percorso: MarginContainer/TabContainer/Editor/HSplitContainer/VBoxContainer/HBoxContainer")
		return
	
	# Controlla se esiste già
	if hbox_container.has_node("RenameButton"):
		print("⚠ RenameButton esiste già, lo rimuovo...")
		hbox_container.get_node("RenameButton").queue_free()
	
	var rename_button = Button.new()
	rename_button.name = "RenameButton"
	rename_button.text = "Rinomina"
	rename_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_container.add_child(rename_button)
	rename_button.owner = root
	print("✓ RenameButton creato")
	
	# 2. CREA IL RENAME PROGRAM DIALOG
	print("\n2. Creazione RenameProgramDialog...")
	
	# Controlla se esiste già
	if root.has_node("RenameProgramDialog"):
		print("⚠ RenameProgramDialog esiste già, lo rimuovo...")
		root.get_node("RenameProgramDialog").queue_free()
	
	var rename_dialog = ConfirmationDialog.new()
	rename_dialog.name = "RenameProgramDialog"
	rename_dialog.title = "Rinomina Programma"
	rename_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	rename_dialog.size = Vector2i(300, 150)
	rename_dialog.ok_button_text = "Rinomina"
	rename_dialog.cancel_button_text = "Annulla"
	root.add_child(rename_dialog)
	rename_dialog.owner = root
	
	# VBoxContainer per il dialogo di rinomina
	var rename_vbox = VBoxContainer.new()
	rename_vbox.name = "VBoxContainer"
	rename_dialog.add_child(rename_vbox)
	rename_vbox.owner = root
	
	# Label informativa
	var rename_label = Label.new()
	rename_label.text = "Inserisci il nuovo numero del programma:"
	rename_vbox.add_child(rename_label)
	rename_label.owner = root
	
	# LineEdit per il nuovo numero
	var new_program_number_edit = LineEdit.new()
	new_program_number_edit.name = "NewProgramNumberEdit"
	new_program_number_edit.placeholder_text = "Es: 1234"
	rename_vbox.add_child(new_program_number_edit)
	new_program_number_edit.owner = root
	print("✓ RenameProgramDialog creato con:")
	print("  - VBoxContainer")
	print("  - Label")
	print("  - NewProgramNumberEdit")
	
	# 3. CREA IL DELETE CONFIRM DIALOG
	print("\n3. Creazione DeleteConfirmDialog...")
	
	# Controlla se esiste già
	if root.has_node("DeleteConfirmDialog"):
		print("⚠ DeleteConfirmDialog esiste già, lo rimuovo...")
		root.get_node("DeleteConfirmDialog").queue_free()
	
	var delete_dialog = ConfirmationDialog.new()
	delete_dialog.name = "DeleteConfirmDialog"
	delete_dialog.title = "Conferma Cancellazione"
	delete_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	delete_dialog.size = Vector2i(400, 150)
	delete_dialog.ok_button_text = "Cancella"
	delete_dialog.cancel_button_text = "Annulla"
	root.add_child(delete_dialog)
	delete_dialog.owner = root
	
	# Label per il messaggio di conferma
	var delete_label = Label.new()
	delete_label.name = "Label"
	delete_label.text = "Sei sicuro di voler cancellare?"
	delete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	delete_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	delete_dialog.add_child(delete_label)
	delete_label.owner = root
	print("✓ DeleteConfirmDialog creato con Label")
	
	print("\n=== GENERAZIONE COMPLETATA ===")
	print("\n✓ Tutti i nodi sono stati aggiunti alla scena!")
	print("✓ I nodi dovrebbero essere visibili nell'albero della scena")
	print("\nIMPORTANTE:")
	print("1. Salva la scena (Ctrl+S)")
	print("2. Elimina questo script EditorScript dal progetto")
	
	# Marca la scena come modificata
	get_editor_interface().mark_scene_as_unsaved()
