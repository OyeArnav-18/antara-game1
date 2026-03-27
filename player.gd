extends CharacterBody2D

# --- NODE REFERENCES ---
# Using safe relative paths to avoid "null instance" crashes
@onready var main_node = $".."
@onready var action_label = $"../ActionLabel"

# --- PHYSICS VARS ---
var speed = 200
var gravity = 500
var jump_force = -300

# --- COMBAT TRACKING ---
var attack_count = 0
var defend_count = 0
var dodge_count = 0

var input_buffer = []
var buffer_time = 1.5 # 1.5 seconds gives the player enough time to do a combo
var timer = 0.0

func _physics_process(delta):
	var direction = 0

	# --- TIMER LOGIC ---
	timer += delta
	if timer > buffer_time:
		analyze_and_trigger_ai()
		input_buffer.clear()
		timer = 0

	# --- INPUT TRACKING ---
	if Input.is_action_just_pressed("light_attack"): # J
		input_buffer.append("J")
		if action_label: action_label.text = "Light Attack 💥"
		attack_count += 1
		timer = 0

	if Input.is_action_just_pressed("heavy_attack"): # I
		input_buffer.append("I")
		if action_label: action_label.text = "Heavy Attack 🔥"
		attack_count += 1
		timer = 0

	if Input.is_action_just_pressed("defend"): # K
		input_buffer.append("K")
		if action_label: action_label.text = "Defend 🛡️"
		defend_count += 1
		timer = 0

	if Input.is_action_just_pressed("dodge"): # L
		input_buffer.append("L")
		if action_label: action_label.text = "Dodge ⚡"
		dodge_count += 1
		timer = 0

	# --- COMBO SYSTEM ---
	if input_buffer.size() >= 2:
		var last_two = input_buffer.slice(input_buffer.size() - 2, input_buffer.size())
		if last_two == ["J", "J"] and action_label:
			action_label.text = "Combo Strike 💥🔥"
		elif last_two == ["L", "J"] and action_label:
			action_label.text = "Dash Strike ⚡💥"
		elif last_two == ["K", "J"] and action_label:
			action_label.text = "Counter Attack 🛡️⚔️"

	# --- MOVEMENT ---
	if Input.is_action_pressed("move_left"):
		direction -= 1
	if Input.is_action_pressed("move_right"):
		direction += 1

	velocity.x = direction * speed

	# --- GRAVITY & JUMP ---
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()

# --- AI TRIGGER LOGIC ---
func analyze_and_trigger_ai():
	var behavior_state = ""
	
	# Determine the dominant behavior
	if attack_count > defend_count and attack_count > dodge_count:
		behavior_state = "Aggression"
	elif defend_count > attack_count and defend_count > dodge_count:
		behavior_state = "Defense"
	elif dodge_count > attack_count and dodge_count > defend_count:
		behavior_state = "Evasion"
		
	# If the player actually made a move, send it to the Brain
	if behavior_state != "":
		if main_node and main_node.has_method("get_ai_decision"):
			main_node.get_ai_decision("Raudra", behavior_state)
		
		# Reset counters for the next analysis window
		attack_count = 0
		defend_count = 0
		dodge_count = 0
