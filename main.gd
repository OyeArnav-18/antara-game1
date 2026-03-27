extends Control  # Matches the 'Inherits' in your screenshot

# UI References - Using 'get_node' to handle the spaces in your names
@onready var behaviour_label = get_node("Layout/AIPanel/Behaviour Label")
@onready var realm_label = get_node("Layout/AIPanel/Realm Label")
@onready var http_request = $HTTPRequest 

# API Configuration
var api_key = "98e77572e910138" # I see you started typing this in the bg!

func _ready():
	# Connect the signal so Godot knows when the AI responds
	http_request.request_completed.connect(_on_ai_response)
	print("ANTARA Brain Initialized. Press ENTER to test AI.")

# This function calls the Featherless AI
func get_ai_decision(realm_type: String, player_action: String):
	var url = "https://api.featherless.ai/v1/chat/completions"
	var headers = [
		"Content-Type: application/json", 
		"Authorization: Bearer " + api_key
	]
	
	var prompt = "Realm: " + realm_type + ". Player did: " + player_action + ". React mystically in 1 short sentence."
	
	var body = JSON.stringify({
		"model": "meta-llama/Llama-3-70B-Instruct",
		"messages": [{"role": "user", "content": prompt}],
		"max_tokens": 50
	})
	
	http_request.request(url, headers, HTTPClient.METHOD_POST, body)

# This function triggers when you press ENTER
func _input(event):
	if event.is_action_pressed("ui_accept"):
		realm_label.text = "The Sentinel considers your path..."
		get_ai_decision("Raudra", "Aggressive Strike")

# This function handles the response
func _on_ai_response(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		var response_text = json["choices"][0]["message"]["content"]
		realm_label.text = response_text
		behaviour_label.text = "SENTINEL: ADAPTING" 
	else:
		realm_label.text = "The void is silent. (Check API Key/Connection)"
