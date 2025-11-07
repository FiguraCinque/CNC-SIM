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

# MacroBPreprocessor.gd - VERSIONE CON VARIABILI CALCOLATE

# Costanti per gestione errori

# Pattern regex compilati una volta sola
static var _simple_var_pattern: RegEx      # #123
static var _computed_var_pattern: RegEx    # #[...]

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

static func _static_init() -> void:
	"""Inizializza i pattern regex una volta sola."""
	_simple_var_pattern = RegEx.new()
	_simple_var_pattern.compile("#(\\d+)")
	
	_computed_var_pattern = RegEx.new()
	_computed_var_pattern.compile("#\\[([^\\[\\]]+)\\]")
	
	_comment_pattern = RegEx.new()
	_comment_pattern.compile("\\([^)]*\\)")
	"""Inizializza i pattern regex una volta sola."""
	_var_pattern = RegEx.new()
	_var_pattern.compile("#(\\d+)")

# =========================================================================
# METODO PRINCIPALE - PIPELINE AGGIORNATA
# =========================================================================

static func preprocess_line(line: String) -> Dictionary:
	"""
	Processa una linea di G-code risolvendo variabili ed espressioni.
	
	Pipeline di risoluzione:
	1. Rimuovi commenti
	2. Gestisci assegnazioni
	3. Risolvi variabili con indice calcolato #[...] 
	4. Risolvi variabili semplici #xxx
	5. Risolvi espressioni matematiche [...]
	"""
	var result = {
		"success": true,
		"result": "",
		"error": "",
		"warnings": []
	}
	
	# 1. Rimuovi commenti
	var clean_line = _remove_comments(line)
	
	# 2. Gestisci block skip "/" 
	var has_block_skip = false
	if clean_line.begins_with("/"):
		has_block_skip = true
		clean_line = clean_line.substr(1)
	
	# 3. Trim spazi
	clean_line = clean_line.strip_edges()
	
	# 4. Se vuota, ritorna
	if clean_line.is_empty():
		result.result = ""
		return result
	
	# 5. Gestisci assegnazioni speciali
	if _is_variable_assignment(clean_line):
		return _process_assignment(clean_line)
	
	# 6. NUOVO: Risolvi variabili con indice calcolato #[...]
	var computed_result = _resolve_computed_variables(clean_line)
	if not computed_result["success"]:
		result.success = false
		result.error = computed_result["error"]
		return result
	clean_line = computed_result["result"]
	
	# 7. Risolvi variabili semplici #xxx
	var var_result = _resolve_simple_variables(clean_line)
	if not var_result["success"]:
		result.success = false
		result.error = var_result["error"]
		return result
	clean_line = var_result["result"]
	
	# 8. Risolvi espressioni matematiche [...]
	var expr_result = _evaluate_all_expressions(clean_line)
	if not expr_result["success"]:
		result.success = false
		result.error = expr_result["error"]
		return result
	clean_line = expr_result["result"]
	
	# 9. Ripristina block skip
	if has_block_skip:
		clean_line = "/" + clean_line
	
	result.result = clean_line
	return result

# =========================================================================
# GESTIONE VARIABILI CON INDICE CALCOLATO
# =========================================================================

static func _resolve_computed_variables(text: String) -> Dictionary:
	"""
	Risolve variabili con indice calcolato #[espressione].
	Deve essere fatto PRIMA di risolvere le variabili semplici.
	"""
	var result = {
		"success": true,
		"result": text,
		"error": ""
	}
	
	var processed = text
	var iterations = 0
	
	# Continua finché ci sono pattern #[...]
	while "#[" in processed:
		iterations += 1
		if iterations > MAX_NESTING_DEPTH:
			result.success = false
			result.error = "Troppe variabili annidate con indice calcolato"
			return result
		
		# Trova il pattern #[...] più interno
		var computed_var = _find_innermost_computed_variable(processed)
		if not computed_var["found"]:
			result.success = false
			result.error = "Variabile con indice calcolato mal formata"
			return result
		
		# Prima risolvi eventuali variabili semplici dentro l'espressione
		var inner_resolved = _resolve_simple_variables(computed_var["content"])
		if not inner_resolved["success"]:
			result.success = false
			result.error = "Errore risolvendo variabili in indice: " + inner_resolved["error"]
			return result
		
		# Poi valuta l'espressione per ottenere il numero della variabile
		var expr_result = _evaluate_expression(inner_resolved["result"])
		if not expr_result["success"]:
			result.success = false
			result.error = "Errore calcolando indice variabile: " + expr_result["error"]
			return result
		
		# Ottieni il numero della variabile (deve essere intero)
		var var_num = int(expr_result["value"])
		
		# Leggi il valore della variabile calcolata
		var var_value = CncMemory.get_variable("#" + str(var_num))
		if var_value == null:
			result.success = false
			result.error = "Variabile #" + str(var_num) + " (calcolata da #[" + computed_var["content"] + "]) non definita"
			return result
		
		# Sostituisci nel testo
		var before = processed.substr(0, computed_var["start"])
		var after = processed.substr(computed_var["end"] + 1)
		processed = before + str(var_value) + after
	
	result.result = processed
	return result

static func _find_innermost_computed_variable(text: String) -> Dictionary:
	"""
	Trova la variabile con indice calcolato più interna #[...].
	Simile a _find_innermost_expression ma cerca il pattern #[...]
	"""
	var result = {
		"found": false,
		"start": -1,
		"end": -1,
		"content": ""
	}
	
	# Trova l'ultimo #[
	var last_open = text.rfind("#[")
	if last_open == -1:
		return result
	
	# Trova la prima ] dopo questa posizione
	var close_pos = text.find("]", last_open + 2)
	if close_pos == -1:
		return result
	
	result.found = true
	result.start = last_open
	result.end = close_pos
	result.content = text.substr(last_open + 2, close_pos - last_open - 2)
	
	return result

# =========================================================================
# GESTIONE VARIABILI SEMPLICI (rinominata da _resolve_all_variables)
# =========================================================================

static func _resolve_simple_variables(text: String) -> Dictionary:
	"""Sostituisce le variabili semplici #xxx con i loro valori."""
	var result = {
		"success": true,
		"result": text,
		"error": ""
	}
	
	if not _simple_var_pattern:
		_static_init()
	
	var resolved_text = text
	var matches = _simple_var_pattern.search_all(text)
	
	# Sostituisci dall'ultimo al primo
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
# GESTIONE ASSEGNAZIONI (aggiornata per variabili calcolate)
# =========================================================================

static func _process_assignment(line: String) -> Dictionary:
	"""
	Processa un'assegnazione di variabile.
	Supporta sia #123 = valore che #[expr] = valore
	"""
	var result = {
		"success": true,
		"result": line,
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
	
	# Determina il numero della variabile target
	var target_var_num: int
	
	if var_part.begins_with("#["):
		# Variabile con indice calcolato
		var close_bracket = var_part.find("]")
		if close_bracket == -1:
			result.success = false
			result.error = "Parentesi quadra non chiusa nella variabile: " + var_part
			return result
		
		var index_expr = var_part.substr(2, close_bracket - 2)
		
		# Risolvi l'espressione dell'indice
		var index_resolved = _resolve_simple_variables(index_expr)
		if not index_resolved["success"]:
			return index_resolved
			
		var index_evaluated = _evaluate_expression(index_resolved["result"])
		if not index_evaluated["success"]:
			return index_evaluated
		
		target_var_num = int(index_evaluated["value"])
		
	elif var_part.begins_with("#"):
		# Variabile semplice
		var var_num_str = var_part.substr(1)
		if not var_num_str.is_valid_int():
			result.success = false
			result.error = "Numero variabile non valido: " + var_part
			return result
		target_var_num = var_num_str.to_int()
		
	else:
		result.success = false
		result.error = "Lato sinistro dell'assegnazione non è una variabile: " + var_part
		return result
	
	# Risolvi l'espressione del lato destro
	# Prima le variabili calcolate
	var expr_computed = _resolve_computed_variables(expr_part)
	if not expr_computed["success"]:
		return expr_computed
	
	# Poi le variabili semplici
	var expr_resolved = _resolve_simple_variables(expr_computed["result"])
	if not expr_resolved["success"]:
		return expr_resolved
	
	# Infine le espressioni
	expr_resolved = _evaluate_all_expressions(expr_resolved["result"])
	if not expr_resolved["success"]:
		return expr_resolved
	
	# Esegui l'assegnazione
	var value = expr_resolved["result"].to_float()
	CncMemory.set_variable("#" + str(target_var_num), value)
	
	# Log per debugging
	result.result = line + " ; [#" + str(target_var_num) + " = " + str(value) + "]"
	return result

# [... mantieni tutte le altre funzioni come _remove_comments, _evaluate_expression, etc ...]

# =========================================================================
# TEST AGGIORNATO
# =========================================================================

static func test_preprocessing2() -> void:
	"""Test completo incluse variabili calcolate."""
	print("\n=== TEST MACRO B PREPROCESSOR CON VARIABILI CALCOLATE ===\n")
	
	# Setup variabili di test
	CncMemory.set_variable("#501", 502.0)
	CncMemory.set_variable("#502", 200.0)
	CncMemory.set_variable("#551", 300.0)  # 501 + 50
	CncMemory.set_variable("#552", 400.0)  # 502 + 50
	CncMemory.set_variable("#599", 15.0)
	CncMemory.set_variable("#13015", 7.5)  # 13000 + 15
	
	var test_cases = [
		"#501 = 502",                    # Assegnazione semplice
		"#[#501] = 200",                  # Assegnazione a var calcolata (#502 = 200)
		"#[501+50] = 300",                # Assegnazione con calcolo indice
		"#[#501+50] = 400",               # Mix: variabile + calcolo
		"G01 X#[#501] Y#[501+50]",       # Uso in G-code
		"#810 = [#[13000+#599]*2]"       # Annidamento complesso
	]
	
	for test_line in test_cases:
		print("Input:  ", test_line)
		var result = preprocess_line(test_line)
		if result["success"]:
			print("Output: ", result["result"])
		else:
			print("ERRORE: ", result["error"])
		print("---")
