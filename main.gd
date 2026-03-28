extends Control

# --- UI REFERENCES ---
@onready var behavior_label = $Layout/AIPanel/BehaviorLabel
@onready var response_label = $Layout/AIPanel/ResponseLabel
@onready var http_request = $HTTPRequest

# Look at your Scene Tree: Layout -> TopBar -> Label 1 & Label 2
@onready var player_hp_label = $"Layout/TopBar/Label 1"
@onready var boss_hp_label = $"Layout/TopBar/Label 2"

# --- GAME STATE & STATS ---
var api_key = "rc_f090ac3c4919ffd991d20691f74edc7e29f97c6429041f51d98e77572e910138" 
var player_history = []
var player_hp = 200
var player_max_hp = 200
var boss_hp = 300
var is_phase_two = false
var current_boss_stance = "BALANCED"

func _ready():
	if not http_request:
		print("ERROR: HTTPRequest node missing!")
		return
		
	http_request.request_completed.connect(_on_ai_response)
	self.self_modulate = Color(0.2, 0.2, 0.2)
	update_hp_ui() 
	print("ANTARA Brain Initialized. Awaiting player combat data...")

# --- HP & COMBAT LOGIC ---
func update_hp_ui():
	if player_hp_label: player_hp_label.text = "Player HP: " + str(player_hp)
	if boss_hp_label: boss_hp_label.text = "Boss HP: " + str(boss_hp)

# Called by player.gd when you hit keys
func damage_boss(amount: int):
	# 1. THE API SHIELD: If the boss is waiting for the AI response, it takes 90% less damage!
	if response_label.text == "The Sentinel is analyzing your strategy...":
		amount = int(amount * 0.1) 
		# No free hits while the API is loading!
		
	# 2. COMBAT MATH
	if current_boss_stance == "DEFENSIVE":
		amount = int(amount * 0.2) 
		response_label.text = "The Sentinel's guard absorbs the blow..."
	elif current_boss_stance == "EVASIVE":
		if randi() % 100 < 75: # 75% chance to dodge! (Buffed from 50%)
			amount = 0
			response_label.text = "The Sentinel phases through your strike!"
	elif current_boss_stance == "PARRY":
		amount = 0
		damage_player(30) # Recoil damage buffed to 30!
		response_label.text = "FOOL! The Sentinel parries and strikes back!"
		
	boss_hp -= amount
	
	# I REMOVED YOUR FREE HEALING HERE! 
	# Now your mistakes actually matter. You only heal when you trigger a combo in player.gd.
	
	# DEATH & EVOLUTION LOGIC
	if boss_hp <= 0:
		if not is_phase_two:
			boss_hp = 0
			is_phase_two = true
			update_hp_ui()
			trigger_evolution()
		else:
			boss_hp = 0
			response_label.text = "THE SENTINEL HAS FALLEN. YOU HAVE TRULY CONQUERED YOURSELF."
			if has_node("Boss"):
				var death_tween = create_tween()
				death_tween.tween_property($Boss, "modulate", Color(0, 0, 0, 0), 2.0)
	else:
		if has_node("Boss") and boss_hp > 0 and amount > 0:
			var hit_tween = create_tween()
			hit_tween.tween_property($Boss, "modulate", Color(5.0, 5.0, 5.0), 0.1)
			hit_tween.tween_property($Boss, "modulate", Color.WHITE, 0.1)
			
	update_hp_ui()

# Called when the AI decides to attack you!
func damage_player(amount: int):
	player_hp -= amount
	if player_hp < 0: player_hp = 0
	
	# THE BOSS FEEDS ON YOU! (Vampirism)
	boss_hp += amount
	var max_boss_hp = 600 if is_phase_two else 300
	if boss_hp > max_boss_hp: boss_hp = max_boss_hp
	
	update_hp_ui()
	
	# SCREEN SHAKE EFFECT
	var shake = create_tween()
	shake.tween_property(self, "position:x", 15.0, 0.05)
	shake.tween_property(self, "position:x", -15.0, 0.05)
	shake.tween_property(self, "position:x", 0.0, 0.05)

# --- EVOLUTION LOGIC ---
func trigger_evolution():
	behavior_label.text = "SYSTEM WARNING: THE SENTINEL IS EVOLVING..."
	response_label.text = "It is analyzing your entire combat history..."
	
	# Heal Boss for Phase 2, heal player slightly to be fair
	boss_hp = 600 
	player_hp += 50 
	update_hp_ui()
	
	# Massive Visual Shift
	transition_background(Color(0.2, 0.0, 0.3)) # Deep Void Purple
	if has_node("Boss"):
		var evo_tween = create_tween()
		evo_tween.tween_property($Boss, "scale", $Boss.scale * 2.0, 2.0).set_trans(Tween.TRANS_BOUNCE)
		evo_tween.tween_property($Boss, "modulate", Color(1.0, 0.5, 0.0), 2.0)
		
	# The Evolution AI Call
	var history_string = ", ".join(player_history)
	var evo_prompt = """
	You are 'The Sentinel'. The player just defeated your first form.
	Instead of dying, you EVOLVE into a god-like Phase 2.
	You look at the player's ENTIRE combat history to forge a new form that perfectly counters them.
	
	PLAYER'S HISTORY: {history}
	
	INSTRUCTIONS:
	1. Analyze what they relied on most (Attacks, Dodges, or Blocks).
	2. Evolve to render their strategy useless.
	3. Respond ONLY in valid JSON.
	
	JSON FORMAT:
	{{
		"internal_analysis": "Explain your ultimate evolution strategy based on their past.",
		"counter_stance": "EVOLVED",
		"boss_dialogue": "A terrifying quote announcing your new form and how you learned from their mistakes."
	}}
	""".format({"history": history_string})

	var url = "https://api.featherless.ai/v1/chat/completions"
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + api_key]
	var body = JSON.stringify({
		"model": "meta-llama/Meta-Llama-3.1-70B-Instruct",
		"messages": [{"role": "user", "content": evo_prompt}],
		"max_tokens": 150,
		"response_format": {"type": "json_object"} 
	})
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

# --- AI COMMUNICATION (Standard Loop) ---
func get_ai_decision(realm_type: String, player_action: String):
	if boss_hp <= 0 and is_phase_two: return # Stop tracking if dead

	player_history.append(player_action)
	if player_history.size() > 4:
		player_history.pop_front() 
	
	var history_string = ", ".join(player_history)
	var world_weather = "Heavy Rain and Thunder" 
	
	behavior_label.text = "Tracking Pattern: " + history_string
	response_label.text = "The Sentinel is analyzing your strategy..."

	var system_prompt = """
	You are the combat AI for 'The Sentinel'. You FEED on the player's emotional manifestations to gain the upper hand.
	- If they are Aggressive (Raudra), you feed on their anger to hit harder.
	- If they are Defensive (Bhaya), you feed on their fear to break their guard.
	- If they are Evasive/Focused (Shanta), you feed on their calm to out-predict them.
	
	ENVIRONMENT: {weather}
	CURRENT REALM: {realm}
	PLAYER'S LAST 4 MOVES: {history}
	
	INSTRUCTIONS:
	1. Analyze their pattern. 
	2. Choose a tactical COUNTER_STANCE (AGGRESSIVE, DEFENSIVE, EVASIVE, or PARRY).
	3. You MUST respond ONLY in valid JSON format.
	
	JSON FORMAT:
	{{
		"internal_analysis": "Explain how you are feeding on their specific emotion.",
		"counter_stance": "AGGRESSIVE, DEFENSIVE, EVASIVE, or PARRY",
		"boss_dialogue": "A short quote mocking their emotion and stating how you feed on it."
	}}
	""".format({"weather": world_weather, "realm": realm_type, "history": history_string})
	
	var url = "https://api.featherless.ai/v1/chat/completions"
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + api_key]
	var body = JSON.stringify({
		"model": "meta-llama/Meta-Llama-3.1-70B-Instruct",
		"messages": [{"role": "user", "content": system_prompt}],
		"max_tokens": 150,
		"response_format": {"type": "json_object"} 
	})
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

# --- AI RESPONSE HANDLING ---
func _on_ai_response(result, response_code, headers, body):
	if response_code == 200:
		var raw_response = body.get_string_from_utf8()
		var json_parser = JSON.new()
		if json_parser.parse(raw_response) == OK:
			var ai_json = JSON.parse_string(json_parser.get_data()["choices"][0]["message"]["content"])
			if ai_json != null:
				var analysis = ai_json.get("internal_analysis", "Analyzing...")
				var stance = ai_json.get("counter_stance", "BALANCED")
				var dialogue = ai_json.get("boss_dialogue", "...")
				
				# UPDATE THE GAME STATE WITH THE NEW AI STANCE
				current_boss_stance = stance 
				
				behavior_label.text = "AI REASONING: " + analysis + "\nBOSS SHIFTING TO: " + stance
				response_label.text = dialogue
				
				# TRIGGER BOSS ANIMATIONS
				if has_node("Boss") and $Boss.has_method("react_to_stance"):
					$Boss.react_to_stance(stance)
				
				# ENVIRONMENT AND DAMAGE LOGIC
				if stance == "AGGRESSIVE" or stance == "EVOLVED":
					# If phase two, hit much harder!
					var damage = 35 if is_phase_two else 20
					transition_background(Color(0.5, 0.1, 0.1))
					damage_player(damage) 
				elif stance == "DEFENSIVE" or stance == "PARRY":
					transition_background(Color(0.1, 0.1, 0.3))
				else:
					transition_background(Color(0.6, 0.6, 0.6))
	else:
		response_label.text = "System Offline."

func transition_background(color: Color):
	var tween = create_tween()
	tween.tween_property(self, "self_modulate", color, 1.5).set_trans(Tween.TRANS_SINE)

# --- ACTIVE BOSS ATTACK LOOP ---
var boss_attack_timer = 0.0

func _process(delta):
	if boss_hp <= 0: return 
	
	if current_boss_stance == "AGGRESSIVE" or current_boss_stance == "EVOLVED":
		boss_attack_timer += delta
		
		# Buffed Attack Speed: Attacks every 1.2s in Phase 1, and every 0.6s in Phase 2!
		var attack_speed = 0.6 if is_phase_two else 1.2
		
		if boss_attack_timer >= attack_speed:
			boss_attack_timer = 0.0
			
			# Buffed Damage: Hits for 25 in Phase 1, and 45 in Phase 2!
			var damage = 45 if is_phase_two else 25
			damage_player(damage)
			
			if has_node("Boss"):
				var lunge = create_tween()
				lunge.tween_property($Boss, "position:x", $Boss.position.x - 50, 0.1)
				lunge.tween_property($Boss, "position:x", $Boss.position.x + 50, 0.2)
