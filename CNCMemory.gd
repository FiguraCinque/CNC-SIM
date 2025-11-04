# CNCMemory.gd
#
# Singleton (Autoload) per la gestione completa della memoria di un simulatore CNC FANUC.
# Gestisce variabili di sistema, programmi, salvataggio e caricamento su file JSON.
class_name CNCMemory
extends Node

# =========================================================================
# COSTANTI - PERCORSI E CONFIGURAZIONE
# =========================================================================

## Percorso del file di salvataggio. "user://" è una directory sicura gestita da Godot.
const SAVE_FILE_PATH = "user://cnc_memory_state.json"

# =========================================================================
# COSTANTI - INDIRIZZI VARIABILI CNC
# =========================================================================

# Compesazione Utensile (400 utensili)
const TOOL_WEAR_LENGTH_OFFSET_BASE = 10000 # Es: 10001 per usura lunghezza Utensile 1
const TOOL_GEOM_LENGTH_OFFSET_BASE = 11000 # Es: 11001 per geometria lunghezza Utensile 1
const TOOL_WEAR_RADIUS_OFFSET_BASE = 12000 # Es: 12001 per usura raggio Utensile 1
const TOOL_GEOM_RADIUS_OFFSET_BASE = 13000 # Es: 13001 per geometria raggio Utensile 1

# Origini Standard (G54 - G59)
# La formula generica è 5220 + (G_num - 54) * 20 + axis_offset
# (dove axis_offset è 1 per X, 2 per Y, 3 per Z, 4 per B)
const STANDARD_WORK_OFFSET_BASE = 5220 # G54 inizia da 5221 (5220 + 1)

# Origini Estese (G54.1 P1 - P48)
# La formula generica è 7000 + (P_num - 1) * 20 + axis_offset
const EXTENDED_WORK_OFFSET_BASE = 7000 # G54.1 P1 inizia da 7001 (7000 + 1)

# Variabili Custom Macro B (range comuni)
const MACRO_CUSTOM_VAR_RANGE_LOW_1 = 100
const MACRO_CUSTOM_VAR_RANGE_HIGH_1 = 199
const MACRO_CUSTOM_VAR_RANGE_LOW_2 = 500
const MACRO_CUSTOM_VAR_RANGE_HIGH_2 = 999

# =========================================================================
# VARIABILI MEMBRO - STRUTTURA DATI PRINCIPALE
# =========================================================================

## Dizionario per i programmi CNC. Chiave: Nome programma (es. "O0001"), Valore: Array[String] del contenuto.
var programs: Dictionary = {}

## "Single Source of Truth" per tutte le variabili numeriche del CNC. Chiave: int (indirizzo variabile), Valore: float.
var system_variables: Dictionary[int, float] = {}

## Nome del programma attualmente attivo (es. "O0001").
var active_program_name: String = ""

# =========================================================================
# METODI CICLO DI VITA GODOT
# =========================================================================

func _ready() -> void:
	"""
	All'avvio del nodo, prova a caricare la memoria da un file JSON.
	Se il file non esiste, procede con l'inizializzazione standard.
	"""
	print("Avvio del sistema di memoria del CNC...")
	if not load_memory():
		print("Nessun file di salvataggio trovato. Inizializzazione della memoria con valori predefiniti...")
		initialize_memory()
	
	var real_path = ProjectSettings.globalize_path(SAVE_FILE_PATH)
	print("Memoria del CNC pronta. %d variabili e %d programmi presenti." % [system_variables.size(), programs.size()])
	print("Il file di salvataggio si trova (o verrà creato) in: ", real_path.get_base_dir())

func _notification(what: int) -> void:
	"""
	Intercetta la notifica di chiusura della finestra per salvare automaticamente lo stato.
	"""
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Chiusura dell'applicazione, salvataggio della memoria...")
		save_memory()

# =========================================================================
# METODI INIZIALIZZAZIONE MEMORIA
# =========================================================================

func initialize_memory() -> void:
	"""
	Popola i dizionari con tutte le variabili e le strutture necessarie.
	Usata solo al primo avvio quando non esiste un file di salvataggio.
	"""
	system_variables.clear()
	programs.clear()
	
	# 1. COMPENSAZIONE UTENSILE (400 UTENSILI)
	for tool_num in range(1, 401):
		system_variables[TOOL_WEAR_LENGTH_OFFSET_BASE + tool_num] = 0.0 # Usura Lunghezza
		system_variables[TOOL_GEOM_LENGTH_OFFSET_BASE + tool_num] = 0.0 # Geometria Lunghezza
		system_variables[TOOL_WEAR_RADIUS_OFFSET_BASE + tool_num] = 0.0 # Usura Raggio
		system_variables[TOOL_GEOM_RADIUS_OFFSET_BASE + tool_num] = 0.0 # Geometria Raggio

	# 2. ORIGINI STANDARD (G54 - G59)
	for origin_index in range(6): # 0 a 5 per rappresentare G54 a G59
		var g_num = 54 + origin_index
		for axis_index in range(1, 5): # 1 a 4 per X, Y, Z, B
			system_variables[STANDARD_WORK_OFFSET_BASE + (g_num - 54) * 20 + axis_index] = 0.0
			
	# 3. ORIGINI ESTESE (G54.1 P1 - G54.1 P48)
	for origin_index in range(1, 49): # 1 a 48 per P1 a P48
		for axis_index in range(1, 5): # 1 a 4 per X, Y, Z, B
			system_variables[EXTENDED_WORK_OFFSET_BASE + (origin_index - 1) * 20 + axis_index] = 0.0

	# 4. VARIABILI CUSTOM MACRO B
	for i in range(MACRO_CUSTOM_VAR_RANGE_LOW_1, MACRO_CUSTOM_VAR_RANGE_HIGH_1 + 1): 
		system_variables[i] = 0.0
	for i in range(MACRO_CUSTOM_VAR_RANGE_LOW_2, MACRO_CUSTOM_VAR_RANGE_HIGH_2 + 1): 
		system_variables[i] = 0.0
	
	print("Memoria inizializzata con valori di default.")

# =========================================================================
# METODI PERSISTENZA - SALVATAGGIO E CARICAMENTO
# =========================================================================

func save_memory() -> void:
	"""
	Salva lo stato corrente dei programmi e delle variabili in un file JSON.
	"""
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if FileAccess.get_open_error() != OK:
		printerr("ERRORE: Impossibile aprire il file per il salvataggio: ", SAVE_FILE_PATH)
		return

	var root_data = {
		"active_program": active_program_name,
		"programs": programs,
		"system_variables": system_variables
	}
	
	var json_string = JSON.stringify(root_data, "\t")
	file.store_string(json_string)
	if FileAccess.get_open_error() != OK:
		printerr("ERRORE: Impossibile scrivere nello stringa nel file: ", SAVE_FILE_PATH)
		file.close()
		return

	file.close()
	print("Memoria salvata con successo.")

func load_memory() -> bool:
	"""
	Carica lo stato dei programmi e delle variabili da un file JSON.
	Restituisce 'true' se il caricamento ha successo, 'false' altrimenti.
	"""
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return false

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		printerr("ERRORE: Impossibile aprire il file per il caricamento.")
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(content)
	if parse_result == null or typeof(parse_result) != TYPE_DICTIONARY:
		printerr("ERRORE: File JSON corrotto o con formato non valido. Il file verrà rimosso.")
		
		var err = DirAccess.remove_absolute(SAVE_FILE_PATH)
		if err != OK:
			printerr("ERRORE: Impossibile rimuovere il file corrotto.")
			
		return false
	
	var root_data = parse_result
	
	programs = root_data.get("programs", {})
	
	# Carica il programma attivo
	active_program_name = root_data.get("active_program", "")
	
	var loaded_vars = root_data.get("system_variables", {})
	var temp_sys_vars: Dictionary[int, float] = {}
	# Le chiavi del JSON sono stringhe, convertile in int per il dizionario system_variables
	for key_str in loaded_vars:
		var key_int = int(key_str)
		# Aggiungere un controllo opzionale per assicurarsi che la chiave sia numerica
		if key_int != null: # Godot 4 non restituisce null per int(), ma per sicurezza generale
			temp_sys_vars[key_int] = loaded_vars[key_str]
		else:
			printerr("ATTENZIONE: Chiave non numerica trovata nel JSON: ", key_str)

	system_variables = temp_sys_vars
	
	print("Memoria caricata con successo dal file.")
	return true

# =========================================================================
# METODI ACCESSO VARIABILI - LETTURA
# =========================================================================

func get_variable(address: String) -> Variant:
	"""
	Legge un valore dalla memoria del CNC usando il suo indirizzo.
	Restituisce 'null' se l'indirizzo non è valido.
	"""
	var addr = address.to_upper()
	
	if addr.begins_with("#"):
		var var_num_str = addr.substr(1)
		if not var_num_str.is_valid_int():
			printerr("ERRORE: Indirizzo variabile sistema non valido: ", addr)
			return null
		var var_num = int(var_num_str)
		return system_variables.get(var_num, null) # Restituisce null se la var non esiste

	elif addr.begins_with("H"): # Compesazione Lunghezza Utensile (Geometria + Usura)
		var tool_num_str = addr.substr(1)
		if not tool_num_str.is_valid_int():
			printerr("ERRORE: Numero utensile non valido per compensazione lunghezza: ", addr)
			return null
		var tool_num = int(tool_num_str)
		
		var wear = system_variables.get(TOOL_WEAR_LENGTH_OFFSET_BASE + tool_num, 0.0)
		var geom = system_variables.get(TOOL_GEOM_LENGTH_OFFSET_BASE + tool_num, 0.0)
		return wear + geom

	elif addr.begins_with("D") or addr.begins_with("R"): # Compesazione Raggio Utensile (Geometria + Usura)
		var tool_num_str = addr.substr(1)
		if not tool_num_str.is_valid_int():
			printerr("ERRORE: Numero utensile non valido per compensazione raggio: ", addr)
			return null
		var tool_num = int(tool_num_str)
		
		var wear = system_variables.get(TOOL_WEAR_RADIUS_OFFSET_BASE + tool_num, 0.0)
		var geom = system_variables.get(TOOL_GEOM_RADIUS_OFFSET_BASE + tool_num, 0.0)
		return wear + geom

	elif addr.begins_with("G"):
		var last_dot_pos = addr.rfind(".")
		if last_dot_pos == -1:
			printerr("ERRORE: Formato origine pezzo non valido (manca asse): ", addr)
			return null
		
		var g_code_part = addr.substr(0, last_dot_pos)
		var axis_part = addr.substr(last_dot_pos + 1)
		
		var var_num = _get_work_offset_var_num(g_code_part, axis_part)
		if var_num != -1:
			return system_variables.get(var_num, null)
		else:
			printerr("ERRORE: Origine pezzo non riconosciuta o asse non valido: ", addr)
			return null

	printerr("ATTENZIONE: Indirizzo non gestito: ", addr)
	return null

# =========================================================================
# METODI ACCESSO VARIABILI - SCRITTURA
# =========================================================================

func set_variable(address: String, value: float) -> void:
	"""
	Scrive un valore nella memoria del CNC usando il suo indirizzo.
	MODIFICA SOLO LA GEOMETRIA per le compensazioni utensile.
	"""
	var addr = address.to_upper()
	
	if addr.begins_with("#"):
		var var_num_str = addr.substr(1)
		if not var_num_str.is_valid_int():
			printerr("ERRORE: Indirizzo variabile sistema non valido: ", addr)
			return
		var var_num = int(var_num_str)
		system_variables[var_num] = value
		return

	elif addr.begins_with("H"): # Compesazione Lunghezza Utensile
		var tool_num_str = addr.substr(1)
		if not tool_num_str.is_valid_int():
			printerr("ERRORE: Numero utensile non valido per compensazione lunghezza: ", addr)
			return
		var tool_num = int(tool_num_str)
		
		# !!! MODIFICA RICHIESTA: Modifica SOLO la Geometria !!!
		# L'usura rimane invariata. Il valore totale sarà geometria + usura_precedente.
		system_variables[TOOL_GEOM_LENGTH_OFFSET_BASE + tool_num] = value # 'value' ora rappresenta solo la geometria
		return

	elif addr.begins_with("D") or addr.begins_with("R"): # Compesazione Raggio Utensile
		var tool_num_str = addr.substr(1)
		if not tool_num_str.is_valid_int():
			printerr("ERRORE: Numero utensile non valido per compensazione raggio: ", addr)
			return
		var tool_num = int(tool_num_str)
		
		# !!! MODIFICA RICHIESTA: Modifica SOLO la Geometria !!!
		system_variables[TOOL_GEOM_RADIUS_OFFSET_BASE + tool_num] = value # 'value' ora rappresenta solo la geometria
		return

	elif addr.begins_with("G"):
		var last_dot_pos = addr.rfind(".")
		if last_dot_pos == -1:
			printerr("ERRORE: Formato origine pezzo non valido (manca asse): ", addr)
			return
			
		var g_code_part = addr.substr(0, last_dot_pos)
		var axis_part = addr.substr(last_dot_pos + 1)

		var var_num = _get_work_offset_var_num(g_code_part, axis_part)
		if var_num != -1:
			system_variables[var_num] = value
		else:
			printerr("ERRORE: Origine pezzo non riconosciuta o asse non valido: ", addr)
		return

	printerr("ATTENZIONE: Indirizzo non gestito per scrittura: ", addr)

# =========================================================================
# METODI ACCESSO VARIABILI - HELPER PRIVATI
# =========================================================================

func _get_work_offset_var_num(g_code: String, axis_char: String) -> int:
	"""
	Helper per tradurre un'origine (G-code) e un asse (X,Y,Z,B) nel numero di variabile del sistema.
	Restituisce -1 se non è un'origine o asse valido.
	"""
	var axis_offset = -1
	match axis_char.to_upper():
		"X": axis_offset = 1
		"Y": axis_offset = 2
		"Z": axis_offset = 3
		"B": axis_offset = 4
	if axis_offset == -1: 
		return -1

	# Gestione Origini Estese (G54.1P1-P48) - CONTROLLARE PRIMA PERCHÉ PIÙ SPECIFICO
	if g_code.begins_with("G54.1P"):
		var p_num_str = g_code.substr(6) # Estrae la parte numerica dopo "G54.1P"
		if p_num_str.is_valid_int():
			var p_num = int(p_num_str)
			if p_num >= 1 and p_num <= 48:
				return EXTENDED_WORK_OFFSET_BASE + (p_num - 1) * 20 + axis_offset
	
	# Gestione Origini Standard (G54-G59)
	elif g_code.begins_with("G"):
		var g_num_str = g_code.substr(1)
		if g_num_str.is_valid_int():
			var g_num = int(g_num_str)
			if g_num >= 54 and g_num <= 59:
				return STANDARD_WORK_OFFSET_BASE + (g_num - 54) * 20 + axis_offset
			
	return -1

# =========================================================================
# METODI GESTIONE PROGRAMMI - OPERAZIONI BASE
# =========================================================================

func add_program(number: int, content: Array[String]) -> void:
	"""
	Aggiunge o sovrascrive un programma nella memoria.
	"""
	if number <= 0:
		printerr("ERRORE: Il numero del programma deve essere positivo.")
		return
	var program_name = "O%04d" % number
	programs[program_name] = content
	print("Programma '%s' aggiunto/sovrascritto." % program_name)

func get_program(number: int) -> Array:
	"""
	Recupera un programma. Restituisce un array vuoto se non trovato.
	"""
	if number <= 0:
		printerr("ERRORE: Il numero del programma deve essere positivo.")
		return []
	var program_name = "O%04d" % number
	return programs.get(program_name, [])

func delete_program(number: int) -> bool:
	"""
	Cancella un programma. Restituisce true se l'operazione ha successo.
	"""
	if number <= 0:
		printerr("ERRORE: Il numero del programma deve essere positivo.")
		return false
	var program_name = "O%04d" % number
	if programs.has(program_name):
		programs.erase(program_name)
		print("Programma '%s' cancellato." % program_name)
		return true
	print("Programma '%s' non trovato per la cancellazione." % program_name)
	return false

func get_all_program_names() -> Array[String]:
	"""
	Restituisce una lista di tutti i nomi dei programmi presenti in memoria.
	"""
	var program_names: Array[String] = []
	program_names.assign(programs.keys())
	return program_names

# =========================================================================
# METODI GESTIONE PROGRAMMI - PROGRAMMA ATTIVO
# =========================================================================

func set_active_program_by_name(program_name: String) -> bool:
	"""
	Imposta il programma attivo. Restituisce true se il programma esiste e viene impostato.
	Se il programma richiesto non esiste, prova a selezionare il primo disponibile.
	Restituisce false se non ci sono programmi.
	"""
	if programs.has(program_name):
		active_program_name = program_name
		print("Programma attivo impostato a: ", active_program_name)
		return true
	else:
		printerr("ATTENZIONE: Programma '%s' non trovato per impostarlo come attivo." % program_name)
		var program_names = programs.keys()
		if not program_names.is_empty():
			active_program_name = program_names[0]
			print("Programma attivo impostato al primo disponibile: ", active_program_name)
			return true
		else:
			active_program_name = ""
			print("Nessun programma disponibile per impostare come attivo.")
			return false

func handle_program_deletion(deleted_name: String) -> void:
	"""
	Gestisce le conseguenze della cancellazione di un programma, in particolare se era quello attivo.
	Deve essere chiamata DOPO che il programma è stato effettivamente rimosso dalla memoria.
	"""
	if active_program_name == deleted_name:
		print("Il programma attivo ('%s') è stato cancellato. Seleziono un nuovo programma attivo..." % deleted_name)
		var program_names = programs.keys()
		# Se ci sono ancora programmi, seleziona il primo della lista aggiornata
		if not program_names.is_empty():
			active_program_name = program_names[0]
			print("Nuovo programma attivo impostato a: ", active_program_name)
		else:
			active_program_name = ""
			print("Nessun programma rimanente in memoria.")
