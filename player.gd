extends CharacterBody2D

@onready var main_node = $".."
@onready var action_label = $"../ActionLabel"

var speed = 200
var gravity = 500
var jump_force = -300

var attack_count = 0
var defend_count = 0
var dodge_count = 0

var input_buffer = []
var buffer_time = 1.5 
var timer = 0.0

# NEW: Cooldown system to stop button mashing
var can_attack = true 

func _physics_process(delta):
	var direction = 0

	timer += delta
	if timer > buffer_time:
		analyze_and_trigger_ai()
		input_buffer.clear()
		timer = 0

	# --- INPUT TRACKING & DAMAGE WITH COOLDOWNS ---
	if Input.is_action_just_pressed("light_attack") and can_attack: # J
		can_attack = false
		input_buffer.append("J")
		if action_label: action_label.text = "Light Attack 💥"
		attack_count += 1
		timer = 0
		if main_node and main_node.has_method("damage_boss"): main_node.damage_boss(15)
		
		await get_tree().create_timer(0.4).timeout # 0.4s cooldown
		can_attack = true

	if Input.is_action_just_pressed("heavy_attack") and can_attack: # I
		can_attack = false
		input_buffer.append("I")
		if action_label: action_label.text = "Heavy Attack 🔥"
		attack_count += 2
		timer = 0
		if main_node and main_node.has_method("damage_boss"): main_node.damage_boss(25)
		
		await get_tree().create_timer(0.8).timeout # 0.8s cooldown
		can_attack = true

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
			if main_node and main_node.has_method("damage_boss"): main_node.damage_boss(20)
		elif last_two == ["L", "J"] and action_label:
			action_label.text = "Dash Strike ⚡💥"
		elif last_two == ["K", "J"] and action_label:
			action_label.text = "Counter Attack 🛡️⚔️"

	# --- MOVEMENT ---
	if Input.is_action_pressed("move_left"): direction -= 1
	if Input.is_action_pressed("move_right"): direction += 1
	velocity.x = direction * speed

	if not is_on_floor(): velocity.y += gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y = jump_force

	move_and_slide()

# --- AI TRIGGER LOGIC ---
func analyze_and_trigger_ai():
	var behavior_state = ""
	
	if attack_count > defend_count and attack_count > dodge_count:
		behavior_state = "Aggression"
	elif defend_count > attack_count and defend_count > dodge_count:
		behavior_state = "Defense"
	elif dodge_count > attack_count and dodge_count > defend_count:
		behavior_state = "Evasion"
		
	if behavior_state != "":
		if main_node and main_node.has_method("get_ai_decision"):
			main_node.get_ai_decision("Raudra", behavior_state)
		
		attack_count = 0
		defend_count = 0
		dodge_count = 0
