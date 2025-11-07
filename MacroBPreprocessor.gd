# MacroBPreprocessor.gd
class_name MacroBPreprocessor
extends RefCounted

# Costanti per gestione errori
const MAX_NESTING_DEPTH = 20  # Previene ricorsioni infinite
const MAX_EXPRESSION_LENGTH = 1000  # Previene espressioni assurde

# Pattern regex compilati una volta sola (ottimizzazione)
static var _var_pattern: RegEx
@warning_ignore("unused_private_class_variable")
static var _expr_pattern: RegEx
static var _comment_pattern: RegEx

static func _static_init() -> void:
	"""Inizializza i pattern regex una volta sola."""
	_var_pattern = RegEx.new()
	_var_pattern.compile("#(\\d+)")
	
	_comment_pattern = RegEx.new()
	_comment_pattern.compile("\\([^)]*\\)")

# =========================================================================
# METODO PRINCIPALE
# =========================================================================

static func preprocess_line(line: String) -> Dictionary:
	"""
	Processa una linea di G-code risolvendo variabili ed espressioni.
	
	Returns: {
		"success": bool,
		"result": String,  # La linea processata
		"error": String,   # Messaggio di errore (se success = false)
		"warnings": Array[String]  # Avvisi non fatali
	}
	"""
	var result = {
		"success": true,
		"result": "",
		"error": "",
		"warnings": []
	}
	
	# 1. Rimuovi commenti (preservando la struttura)
	var clean_line = _remove_comments(line)
	
	# 2. Gestisci block skip "/" (lo preserviamo per l'interpreter)
	var has_block_skip = false
	if clean_line.begins_with("/"):
		has_block_skip = true
		clean_line = clean_line.substr(1)
	
	# 3. Trim spazi
	clean_line = clean_line.strip_edges()
	
	# 4. Se la linea è vuota dopo la pulizia, ritorna vuota
	if clean_line.is_empty():
		result.result = ""
		return result
	
	# 5. Gestisci assegnazioni di variabili (#xxx = ...)
	if _is_variable_assignment(clean_line):
		return _process_assignment(clean_line)
	
	# 6. Risolvi variabili nella linea
	var var_result = _resolve_all_variables(clean_line)
	if not var_result["success"]:
		result.success = false
		result.error = var_result["error"]
		return result
	clean_line = var_result["result"]
	
	# 7. Risolvi espressioni matematiche
	var expr_result = _evaluate_all_expressions(clean_line)
	if not expr_result["success"]:
		result.success = false
		result.error = expr_result["error"]
		return result
	clean_line = expr_result["result"]
	
	# 8. Ripristina block skip se presente
	if has_block_skip:
		clean_line = "/" + clean_line
	
	result.result = clean_line
	return result

# =========================================================================
# GESTIONE COMMENTI
# =========================================================================

static func _remove_comments(line: String) -> String:
	"""Rimuove i commenti (...) preservando il resto."""
	if not _comment_pattern:
		_static_init()
	
	var cleaned = line
	var matches = _comment_pattern.search_all(line)
	
	# Rimuovi dall'ultimo al primo per mantenere gli indici corretti
	for i in range(matches.size() - 1, -1, -1):
		var match = matches[i]
		var start = match.get_start()
		var end = match.get_end()
		cleaned = cleaned.substr(0, start) + cleaned.substr(end)
	
	return cleaned

# =========================================================================
# GESTIONE ASSEGNAZIONI
# =========================================================================

static func _is_variable_assignment(line: String) -> bool:
	"""Verifica se la linea è un'assegnazione di variabile."""
	# Pattern: #numero = espressione
	return line.contains("=") and line.begins_with("#")

static func _process_assignment(line: String) -> Dictionary:
	"""Processa un'assegnazione di variabile (#xxx = espressione)."""
	var result = {
		"success": true,
		"result": line,  # Le assegnazioni vengono passate all'interpreter
		"error": "",
		"warnings": []
	}
	
	var parts = line.split("=", false, 1)
	if parts.size() != 2:
		result.success = false
		result.error = "Formato assegnazione non valido: " + line
		return result
	
	var var_part = parts[0].strip_edges()
	var expr_part = parts[1].strip_edges()
	
	# Verifica che la parte sinistra sia una variabile valida
	if not var_part.begins_with("#"):
		result.success = false
		result.error = "Lato sinistro dell'assegnazione non è una variabile: " + var_part
		return result
	
	var var_num_str = var_part.substr(1)
	if not var_num_str.is_valid_int():
		result.success = false
		result.error = "Numero variabile non valido: " + var_part
		return result
	
	# Risolvi l'espressione del lato destro
	var expr_resolved = _resolve_all_variables(expr_part)
	if not expr_resolved["success"]:
		return expr_resolved
		
	expr_resolved = _evaluate_all_expressions(expr_resolved["result"])
	if not expr_resolved["success"]:
		return expr_resolved
	
	# Esegui l'assegnazione
	var value = expr_resolved["result"].to_float()
	CncMemory.set_variable(var_part, value)
	
	# Ritorna la linea originale per logging/display
	result.result = line + " ; [Risultato: " + str(value) + "]"
	return result

# =========================================================================
# RISOLUZIONE VARIABILI
# =========================================================================

static func _resolve_all_variables(text: String) -> Dictionary:
	"""Sostituisce tutte le variabili #xxx con i loro valori."""
	var result = {
		"success": true,
		"result": text,
		"error": ""
	}
	
	if not _var_pattern:
		_static_init()
	
	var resolved_text = text
	var matches = _var_pattern.search_all(text)
	
	# Sostituisci dall'ultimo al primo per mantenere gli indici
	for i in range(matches.size() - 1, -1, -1):
		var match = matches[i]
		var var_num = match.get_string(1).to_int()
		var var_address = "#" + str(var_num)
		
		var value = CncMemory.get_variable(var_address)
		if value == null:
			result.success = false
			result.error = "Variabile non definita: " + var_address
			return result
		
		var start = match.get_start()
		var end = match.get_end()
		resolved_text = resolved_text.substr(0, start) + str(value) + resolved_text.substr(end)
	
	result.result = resolved_text
	return result

# =========================================================================
# VALUTAZIONE ESPRESSIONI
# =========================================================================

static func _evaluate_all_expressions(text: String) -> Dictionary:
	"""
	Valuta tutte le espressioni [...] nel testo, gestendo annidamenti multipli.
	"""
	var result = {
		"success": true,
		"result": text,
		"error": ""
	}
	
	var processed = text
	var iterations = 0
	
	# Continua finché ci sono parentesi quadre
	while "[" in processed:
		iterations += 1
		if iterations > MAX_NESTING_DEPTH * 10:  # Safeguard
			result.success = false
			result.error = "Troppe iterazioni nella valutazione espressioni"
			return result
		
		# Debug: mostra lo stato corrente
		# print("  Iterazione ", iterations, ": ", processed)
		
		# Trova l'espressione più interna
		var inner_expr = _find_innermost_expression(processed)
		if not inner_expr["found"]:
			result.success = false
			result.error = "Parentesi quadre non bilanciate"
			return result
		
		# Valuta l'espressione
		var expr_value = _evaluate_expression(inner_expr["content"])
		if not expr_value["success"]:
			result.success = false
			result.error = "Errore in espressione '" + inner_expr["content"] + "': " + expr_value["error"]
			return result
		
		# Sostituisci l'espressione con il risultato
		var before = processed.substr(0, inner_expr["start"])
		var after = processed.substr(inner_expr["end"] + 1)
		processed = before + str(expr_value["value"]) + after
	
	# Verifica finale che non ci siano parentesi rimaste
	if "]" in processed:
		result.success = false
		result.error = "Parentesi quadre ] senza corrispondente ["
		return result
	
	result.result = processed
	return result

static func _find_innermost_expression(text: String) -> Dictionary:
	"""
	Trova l'espressione più interna (quella che si può valutare senza dover 
	prima risolvere altre espressioni al suo interno).
	"""
	var result = {
		"found": false,
		"start": -1,
		"end": -1,
		"content": ""
	}
	
	# Trova l'ultima [ (la più interna)
	var last_open = text.rfind("[")
	if last_open == -1:
		return result
	
	# Trova la prima ] dopo questa [
	var close_pos = text.find("]", last_open)
	if close_pos == -1:
		return result
	
	# L'espressione tra queste due parentesi non può contenere altre [ o ]
	# per definizione (abbiamo preso l'ultima [)
	result.found = true
	result.start = last_open
	result.end = close_pos
	result.content = text.substr(last_open + 1, close_pos - last_open - 1)
	
	return result

static func _evaluate_expression(expr: String) -> Dictionary:
	"""
	Valuta un'espressione matematica semplice (senza parentesi quadre).
	Supporta: +, -, *, /, operatori unari, parentesi tonde
	"""
	var result = {
		"success": true,
		"value": 0.0,
		"error": ""
	}
	
	# Rimuovi spazi
	expr = expr.replace(" ", "")
	
	if expr.is_empty():
		result.success = false
		result.error = "Espressione vuota"
		return result
	
	# Usa l'Expression class di Godot per valutare
	var expression = Expression.new()
	var parse_error = expression.parse(expr)
	
	if parse_error != OK:
		result.success = false
		result.error = "Errore parsing espressione: " + expr
		return result
	
	var exec_result = expression.execute()
	
	if expression.has_execute_failed():
		result.success = false
		result.error = "Errore esecuzione espressione: " + expr
		return result
	
	result.value = float(exec_result)
	return result

# =========================================================================
# UTILITY E DEBUG
# =========================================================================

static func test_preprocessing() -> void:
	"""Funzione di test per verificare il preprocessor."""
	print("\n=== TEST MACRO B PREPROCESSOR ===\n")
	
	# Imposta alcune variabili di test
	CncMemory.set_variable("#810", 16.0)
	CncMemory.set_variable("#811", 23.0)
	CncMemory.set_variable("#812", 1.5)
	CncMemory.set_variable("#820", 200.0)
	
	var test_cases = [
		"G01 X100 Y200 F300",  # G-code puro
		"G#810 X#811 Y#812",   # Variabili semplici
		"X[[#811-#810]/2]",     # Espressione annidanta doppia
		"X[[[#811-#810]/2]+0.06]",  # Triplo annidamento
		"/G91 G3 X[-[[#811-#810]/2]] I[-[[#811-#810]/4]] Z[#812/4] F[#820*1.25]",  # Annidamento complesso con negazione
		"/G3 X[[[#811-#810]/2]+0.06] I[[[#811-#810]/4]+0.03] Z[#812/4] F[#820*1.25]",  # Multi-annidamento
		"#500 = [[1000*50]/[3.14*15]]",  # Assegnazione con calcolo
		"#501 = 502",  # Assegnazione con calcolo
		"#[#501] = 503",  # Assegnazione con calcolo
		"#[#502] = 504",  # Assegnazione con calcolo
		"(Questo è un commento) G01 X100 (altro commento) Y200"  # Con commenti
	]
	
	for test_line in test_cases:
		print("Input:  ", test_line)
		var result = preprocess_line(test_line)
		if result["success"]:
			print("Output: ", result["result"])
		else:
			print("ERRORE: ", result["error"])
		if not result.get("warnings", []).is_empty():
			print("AVVISI: ", result["warnings"])
		print("---")
	
	# Test specifico per vedere il processo step-by-step
	print("\n=== TEST DETTAGLIATO ANNIDAMENTO ===")
	var test_expr = "X[[[#811-#810]/2]+0.06]"
	print("Espressione: ", test_expr)
	
	# Prima risolvi le variabili
	var step1 = _resolve_all_variables(test_expr)
	print("Dopo risoluzione variabili: ", step1["result"])
	
	# Poi valuta le espressioni
	var step2 = _evaluate_all_expressions(step1["result"])
	print("Dopo valutazione espressioni: ", step2["result"])
