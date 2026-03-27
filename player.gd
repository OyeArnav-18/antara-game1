extends CharacterBody2D

@onready var action_label = get_node("/root/Main/ActionLabel")

var speed = 200
var gravity = 500
var jump_force = -300

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
		timer = 0

	if Input.is_action_just_pressed("heavy_attack"):
		input_buffer.append("I")
		action_label.text = "Heavy Attack 🔥"
		timer = 0

	if Input.is_action_just_pressed("defend"):
		input_buffer.append("K")
		action_label.text = "Defend 🛡️"
		timer = 0

	if Input.is_action_just_pressed("dodge"):
		input_buffer.append("L")
		action_label.text = "Dodge ⚡"
		timer = 0

	# COMBO CHECK (FIXED)
	if input_buffer.size() >= 2:
		var last_two = input_buffer.slice(input_buffer.size() - 2, input_buffer.size())

		if last_two == ["J", "J"]:
			action_label.text = "Combo Strike 💥🔥"

		elif last_two == ["L", "J"]:
			action_label.text = "Dash Strike ⚡💥"

		elif last_two == ["K", "J"]:
			action_label.text = "Counter Attack 🛡️⚔️"

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
