extends Control

# --- UI REFERENCES ---
# Matched perfectly to Arnav's cleaned-up Scene Tree
@onready var behavior_label = $Layout/AIPanel/BehaviorLabel
@onready var response_label = $Layout/AIPanel/ResponseLabel
@onready var http_request = $HTTPRequest

# --- API CONFIGURATION ---
var api_key = "rc_f090ac3c4919ffd991d20691f74edc7e29f97c6429041f51d98e77572e910138" 

func _ready():
	if not http_request:
		print("ERROR: HTTPRequest node missing!")
		return
		
	# Connect the HTTP request completion signal
	http_request.request_completed.connect(_on_ai_response)
	
	# Set initial neutral background color
	self.self_modulate = Color(0.2, 0.2, 0.2)
	print("ANTARA Brain Initialized. Awaiting player combat data...")

# --- AI COMMUNICATION ---
# Called automatically by player.gd
# Add this variable at the very top of your script with the others
var player_history = []

func get_ai_decision(realm_type: String, player_action: String):
	# 1. Build the Memory Array (Crit 4: Meaningful Inputs)
	player_history.append(player_action)
	if player_history.size() > 4:
		player_history.pop_front() # Keep only the last 4 moves
	
	var history_string = ", ".join(player_history)
	
	# Mocking the Bright Data signal for the prompt (Replace with your actual variable later)
	var world_weather = "Heavy Rain and Thunder" 
	
	# Instant UI Feedback
	behavior_label.text = "Tracking Pattern: " + history_string
	response_label.text = "The Sentinel is analyzing your strategy..."

	# 2. The Chain of Thought Prompt (Crit 3: Intelligence & Reasoning)
	var system_prompt = """
	You are the combat AI for 'The Sentinel', a boss in a mystic action game.
	Your goal is to analyze the player's combat history and output a counter-strategy.
	
	ENVIRONMENT (Bright Data): {weather}
	CURRENT REALM: {realm}
	PLAYER'S LAST 4 MOVES: {history}
	
	INSTRUCTIONS:
	1. Analyze the pattern. Is the player spamming attacks? Are they playing defensively?
	2. Choose a tactical COUNTER_STANCE to defeat them (e.g., if they are Aggressive, you should be Evasive or use Heavy Counters).
	3. You MUST respond ONLY in valid JSON format. No extra text.
	
	JSON FORMAT:
	{{
		"internal_analysis": "Explain your tactical reasoning based on the player's history.",
		"counter_stance": "AGGRESSIVE, DEFENSIVE, EVASIVE, or PARRY",
		"boss_dialogue": "One short, mystical sentence addressing their specific pattern."
	}}
	""".format({"weather": world_weather, "realm": realm_type, "history": history_string})

	var url = "https://api.featherless.ai/v1/chat/completions"
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + api_key]
	
	var body = JSON.stringify({
		"model": "meta-llama/Meta-Llama-3.1-70B-Instruct",
		"messages": [{"role": "user", "content": system_prompt}],
		"max_tokens": 150,
		"response_format": {"type": "json_object"} # Forces Llama to output clean JSON
	})
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

# --- AI RESPONSE HANDLING ---
func _on_ai_response(result, response_code, headers, body):
	if response_code == 200:
		var raw_response = body.get_string_from_utf8()
		var json_parser = JSON.new()
		
		# Parse the API wrapper
		var error = json_parser.parse(raw_response)
		if error == OK:
			var api_data = json_parser.get_data()
			var ai_message_string = api_data["choices"][0]["message"]["content"]
			
			# Parse the actual JSON created by the AI
			var ai_json = JSON.parse_string(ai_message_string)
			
			if ai_json != null:
				# CRITERIA 2: Actionable Output! 
				# We now have 3 distinct pieces of data to drive the game
				var analysis = ai_json.get("internal_analysis", "Analyzing...")
				var stance = ai_json.get("counter_stance", "BALANCED")
				var dialogue = ai_json.get("boss_dialogue", "...")
				
				# Update the UI to show the "Thinking" to the judges
				behavior_label.text = "AI REASONING: " + analysis + "\nBOSS SHIFTING TO: " + stance
				response_label.text = dialogue
				
				# Shift Colors based on the STANCE (not just the vibe)
				if stance == "AGGRESSIVE":
					transition_background(Color(0.5, 0.1, 0.1))
				elif stance == "DEFENSIVE" or stance == "PARRY":
					transition_background(Color(0.1, 0.1, 0.3))
				else:
					transition_background(Color(0.6, 0.6, 0.6))
					
			else:
				print("Failed to parse AI's inner JSON.")
	else:
		response_label.text = "System Offline."

# --- VISUAL EFFECTS ---
func transition_background(color: Color):
	var tween = create_tween()
	tween.tween_property(self, "self_modulate", color, 1.5).set_trans(Tween.TRANS_SINE)
