extends Control

# --- UI REFERENCES ---
@onready var behavior_label = $CanvasLayer/Layout/AIPanel/BehaviorLabel
@onready var response_label = $CanvasLayer/Layout/AIPanel/ResponseLabel
@onready var http_request = $HTTPRequest
@onready var player_hp_label = $"CanvasLayer/Layout/TopBar/Label 1"
@onready var boss_hp_label = $"CanvasLayer/Layout/TopBar/Label 2"
@onready var bright_data_http = $BrightDataHTTP

# --- GAME STATE & STATS ---
var api_key = "rc_f090ac3c4919ffd991d20691f74edc7e29f97c6429041f51d98e77572e910138" 
var bd_api_key = "dfe6b11c-2fd9-4d68-b430-fc936fe72886"
var live_weather = "Heavy Rain and Thunder" # Fallback weather
var player_history = []
var player_hp = 200
var player_max_hp = 200
var boss_hp = 300
var is_phase_two = false
var current_boss_stance = "BALANCED"

# --- POLISH VARIABLES ---
var boss_attack_timer = 0.0 
var game_over = false
var is_evolving = false
var is_fetching_ai = false

func _ready():
	if http_request: http_request.request_completed.connect(_on_ai_response)
	
	if bright_data_http:
		bright_data_http.request_completed.connect(_on_bright_data_response)
		fetch_real_weather() 
		
	self.self_modulate = Color(0.2, 0.2, 0.2)
	update_hp_ui() 
	print("ANTARA Brain Initialized.")
	
	# --- AAA UI UPGRADE ---
	# --- AAA UI UPGRADE & WRAPPING ---
	var text_style = LabelSettings.new()
	text_style.font_size = 18 # (Change this number if it's still too big!)
	text_style.font_color = Color(1.0, 0.9, 0.8) 
	text_style.outline_size = 6
	text_style.outline_color = Color.BLACK
	text_style.shadow_color = Color(0.8, 0.0, 0.0, 0.8) 
	text_style.shadow_size = 5
	text_style.shadow_offset = Vector2(2, 2)
	
	# 1. Apply the epic red glowing style
	if player_hp_label: player_hp_label.label_settings = text_style
	if boss_hp_label: boss_hp_label.label_settings = text_style
	if behavior_label: behavior_label.label_settings = text_style
	if response_label: response_label.label_settings = text_style
	
	# 2. Force the long AI dialogue to wrap cleanly
	if behavior_label: behavior_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if response_label: response_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# 3. Dark cinematic backgrounds
	if has_node("CanvasLayer/Layout/AIPanel"): $"CanvasLayer/Layout/AIPanel".self_modulate = Color(0.0, 0.0, 0.0, 0.6)
	if has_node("CanvasLayer/Layout/TopBar"): $"CanvasLayer/Layout/TopBar".self_modulate = Color(0.0, 0.0, 0.0, 0.6)
	
# --- BRIGHT DATA API LOGIC ---
func fetch_real_weather():
	var url = "dfe6b11c-2fd9-4d68-b430-fc936fe72886" 
	var headers = ["Authorization: Bearer " + bd_api_key, "Content-Type: application/json"]
	bright_data_http.request(url, headers, HTTPClient.METHOD_GET)

func _on_bright_data_response(_result, response_code, _headers, body):
	if response_code == 200:
		var raw_response = body.get_string_from_utf8()
		var json_parser = JSON.new()
		if json_parser.parse(raw_response) == OK:
			var data = json_parser.get_data()
			if data != null and data.has("weather"):
				live_weather = data["weather"]
				print("BRIGHT DATA SUCCESS: Weather is now " + live_weather)
	else:
		print("BRIGHT DATA OFFLINE: Using fallback weather.")

func _input(event):
	if game_over and (event.is_action_pressed("light_attack") or event.is_action_pressed("ui_accept")):
		get_tree().reload_current_scene()

func _process(delta):
	if boss_hp <= 0 or game_over or is_evolving or is_fetching_ai: return 
	
	if current_boss_stance == "AGGRESSIVE" or current_boss_stance == "EVOLVED":
		boss_attack_timer += delta
		var attack_speed = 0.6 if is_phase_two else 1.2
		
		if boss_attack_timer >= attack_speed:
			boss_attack_timer = 0.0
			var damage = 45 if is_phase_two else 25
			damage_player(damage)
			
			if has_node("Boss"):
				var lunge = create_tween()
				lunge.tween_property($Boss, "scale", Vector2($Boss.scale.x * 1.2, $Boss.scale.y * 0.7), 0.1)
				lunge.tween_property($Boss, "scale", Vector2($Boss.scale.x * 0.8, $Boss.scale.y * 1.3), 0.05)
				lunge.tween_property($Boss, "position:x", $Boss.position.x - 80, 0.05)
				lunge.tween_property($Boss, "scale", $Boss.scale, 0.2)
				lunge.tween_property($Boss, "position:x", $Boss.position.x + 80, 0.2)

func update_hp_ui():
	if player_hp_label: player_hp_label.text = "Player HP: " + str(player_hp)
	if boss_hp_label: boss_hp_label.text = "Boss HP: " + str(boss_hp)

func damage_boss(amount: int):
	if game_over or is_evolving or boss_hp <= 0: return 
	
	if is_fetching_ai: amount = int(amount * 0.1) 
		
	if current_boss_stance == "DEFENSIVE":
		amount = int(amount * 0.2) 
	elif current_boss_stance == "EVASIVE":
		if randi() % 100 < 75: 
			amount = 0
			response_label.text = "The Sentinel phases through your strike!"
	elif current_boss_stance == "PARRY":
		amount = 0
		damage_player(30) 
		response_label.text = "FOOL! The Sentinel parries and strikes back!"
		
	boss_hp -= amount
	
	if boss_hp <= 0:
		if not is_phase_two:
			boss_hp = 0
			trigger_evolution()
		else:
			boss_hp = 0
			game_over = true 
			response_label.text = "THE SENTINEL HAS FALLEN. Press 'J' to Restart."
			if has_node("Boss"):
				var death_tween = create_tween()
				death_tween.tween_property($Boss, "modulate", Color(0, 0, 0, 0), 2.0)
	else:
		if has_node("Boss") and amount > 0:
			var hit_tween = create_tween()
			hit_tween.tween_property($Boss, "modulate", Color(5.0, 5.0, 5.0), 0.1)
			hit_tween.tween_property($Boss, "modulate", Color.WHITE, 0.1)
			
	update_hp_ui()

func damage_player(amount: int):
	if game_over or is_evolving: return
	
	player_hp -= amount
	if player_hp <= 0: 
		player_hp = 0
		game_over = true 
		behavior_label.text = "SYSTEM FAILURE"
		response_label.text = "YOU HAVE BEEN CONSUMED. Press 'J' to Restart."
		if has_node("Boss"): $Boss.modulate = Color(0.5, 0, 0) 
	else:
		boss_hp += amount
		var max_boss_hp = 600 if is_phase_two else 300
		if boss_hp > max_boss_hp: boss_hp = max_boss_hp
	
	update_hp_ui()
	var shake = create_tween()
	shake.tween_property(self, "position:x", 15.0, 0.05)
	shake.tween_property(self, "position:x", -15.0, 0.05)
	shake.tween_property(self, "position:x", 0.0, 0.05)

func trigger_evolution():
	is_phase_two = true
	is_evolving = true 
	is_fetching_ai = true
	
	behavior_label.text = "SYSTEM WARNING: THE SENTINEL IS EVOLVING..."
	response_label.text = "It is analyzing your entire combat history..."
	
	boss_hp = 600 
	player_hp += 50 
	update_hp_ui()
	
	transition_background(Color(0.2, 0.0, 0.3)) 
	if has_node("Boss"):
		var evo_tween = create_tween()
		evo_tween.tween_property($Boss, "scale", $Boss.scale * 2.0, 2.0).set_trans(Tween.TRANS_BOUNCE)
		evo_tween.tween_property($Boss, "modulate", Color(1.0, 0.5, 0.0), 2.0)
		
	var history_string = ", ".join(player_history)
	var evo_prompt = """
	You are 'The Sentinel', a god-like boss in a dark fantasy game. The player just "killed" your first form.
	You are evolving into Phase 2 based on their combat history: {history}.
	
	INSTRUCTIONS:
	1. Act like a terrifying, ancient entity. 
	2. Output valid JSON only.
	
	JSON FORMAT:
	{{
		"internal_analysis": "Briefly state how you will counter their specific history.",
		"counter_stance": "EVOLVED",
		"boss_dialogue": "A highly cinematic monologue (2 sentences max). Mock their playstyle and declare your rebirth."
	}}
	""".format({"history": history_string})

	_send_api_request(evo_prompt)

func get_ai_decision(realm_type: String, player_action: String):
	if boss_hp <= 0 or game_over or is_evolving: return 

	player_history.append(player_action)
	if player_history.size() > 4: player_history.pop_front() 
	
	var history_string = ", ".join(player_history)
	
	is_fetching_ai = true
	current_boss_stance = "DEFENSIVE" 
	behavior_label.text = "Tracking Pattern: " + history_string
	response_label.text = "The Sentinel is piercing your mind..."
	if has_node("Boss"): $Boss.modulate = Color(0.8, 0.2, 0.8) 

	var system_prompt = """
	You are 'The Sentinel', a dark, mystical boss. You feed on the player's emotions.
	Current player behavior: {history}. 
	ENVIRONMENT: {weather}
	
	INSTRUCTIONS:
	1. Choose a COUNTER_STANCE (AGGRESSIVE, DEFENSIVE, EVASIVE, PARRY).
	2. Output valid JSON only.
	
	JSON FORMAT:
	{{
		"internal_analysis": "Your tactical reasoning.",
		"counter_stance": "AGGRESSIVE, DEFENSIVE, EVASIVE, or PARRY",
		"boss_dialogue": "A dark, cryptic sentence mocking their emotion. Incorporate the {weather} weather into the threat!"
	}}
	""".format({"history": history_string, "weather": live_weather})
	
	_send_api_request(system_prompt)
	
	await get_tree().create_timer(1.0).timeout 
	is_fetching_ai = false
	if has_node("Boss") and boss_hp > 0: $Boss.modulate = Color.WHITE

func _send_api_request(prompt: String):
	var url = "https://api.featherless.ai/v1/chat/completions"
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + api_key]
	var body = JSON.stringify({
		"model": "meta-llama/Meta-Llama-3.1-70B-Instruct",
		"messages": [{"role": "user", "content": prompt}],
		"max_tokens": 150,
		"response_format": {"type": "json_object"} 
	})
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _on_ai_response(_result, response_code, _headers, body):
	is_fetching_ai = false 
	is_evolving = false    
	
	if has_node("Boss") and boss_hp > 0: $Boss.modulate = Color.WHITE 
	
	if response_code == 200:
		var raw_response = body.get_string_from_utf8()
		var json_parser = JSON.new()
		if json_parser.parse(raw_response) == OK:
			var ai_json = JSON.parse_string(json_parser.get_data()["choices"][0]["message"]["content"])
			if ai_json != null:
				var analysis = ai_json.get("internal_analysis", "Analyzing...")
				var raw_stance = ai_json.get("counter_stance", "BALANCED")
				var dialogue = ai_json.get("boss_dialogue", "...")
				
				current_boss_stance = str(raw_stance).to_upper()
				behavior_label.text = "AI REASONING: " + analysis + "\nBOSS SHIFTING TO: " + current_boss_stance
				response_label.text = dialogue
				
				if has_node("Boss") and $Boss.has_method("react_to_stance"):
					$Boss.react_to_stance(current_boss_stance)
				
				if current_boss_stance == "AGGRESSIVE" or current_boss_stance == "EVOLVED":
					var damage = 35 if is_phase_two else 20
					transition_background(Color(0.5, 0.1, 0.1))
					damage_player(damage) 
				elif current_boss_stance == "DEFENSIVE" or current_boss_stance == "PARRY":
					transition_background(Color(0.1, 0.1, 0.3))
				else:
					transition_background(Color(0.6, 0.6, 0.6))
	else:
		response_label.text = "System Offline."

func transition_background(color: Color):
	var tween = create_tween()
	tween.tween_property(self, "self_modulate", color, 1.5).set_trans(Tween.TRANS_SINE)
