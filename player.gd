extends CharacterBody2D

@onready var action_label = get_node("/root/Main/ActionLabel")
@onready var behavior_label = get_node("/root/Main/Layout/AIPanel/BehaviorLabel")
@onready var response_label = get_node("/root/Main/Layout/AIPanel/ResponseLabel")

var speed = 200
var gravity = 500
var jump_force = -300

var attack_count = 0
var defend_count = 0
var dodge_count = 0

var input_buffer = []
var buffer_time = 1.0
var timer = 0.0

func _physics_process(delta):
	var direction = 0

	# TIMER
	timer += delta
	if timer > buffer_time:
		input_buffer.clear()
		timer = 0

	# INPUT TRACKING
	if Input.is_action_just_pressed("light_attack"):
		input_buffer.append("J")
		action_label.text = "Light Attack 💥"
		attack_count += 1
		timer = 0

	if Input.is_action_just_pressed("heavy_attack"):
		input_buffer.append("I")
		action_label.text = "Heavy Attack 🔥"
		attack_count += 1
		timer = 0

	if Input.is_action_just_pressed("defend"):
		input_buffer.append("K")
		action_label.text = "Defend 🛡️"
		defend_count += 1
		timer = 0

	if Input.is_action_just_pressed("dodge"):
		input_buffer.append("L")
		action_label.text = "Dodge ⚡"
		dodge_count += 1
		timer = 0

	# COMBO SYSTEM
	if input_buffer.size() >= 2:
		var last_two = input_buffer.slice(input_buffer.size() - 2, input_buffer.size())

		if last_two == ["J", "J"]:
			action_label.text = "Combo Strike 💥🔥"

		elif last_two == ["L", "J"]:
			action_label.text = "Dash Strike ⚡💥"

		elif last_two == ["K", "J"]:
			action_label.text = "Counter Attack 🛡️⚔️"

	# AI ANALYSIS (only when new input happens)
	if timer == 0:
		if attack_count > defend_count and attack_count > dodge_count:
			behavior_label.text = "Behavior Observed: Aggressive"
			response_label.text = "Realm Response: Defensive stance activated"

		elif defend_count > attack_count and defend_count > dodge_count:
			behavior_label.text = "Behavior Observed: Defensive"
			response_label.text = "Realm Response: Increased pressure"

		elif dodge_count > attack_count and dodge_count > defend_count:
			behavior_label.text = "Behavior Observed: Evasive"
			response_label.text = "Realm Response: Tracking movement"

	# MOVEMENT
	if Input.is_action_pressed("move_left"):
		direction -= 1

	if Input.is_action_pressed("move_right"):
		direction += 1

	velocity.x = direction * speed

	# GRAVITY
	if not is_on_floor():
		velocity.y += gravity * delta

	# JUMP
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

	move_and_slide()
