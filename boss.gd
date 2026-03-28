extends Sprite2D

var original_position: Vector2
var original_scale: Vector2

func _ready():
	# Save where you placed the boss in the editor
	original_position = position
	original_scale = scale
	
	# Start a permanent, eerie floating animation
	_start_idle_float()

func _start_idle_float():
	# This creates a continuous up-and-down hovering effect
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", original_position.y - 15, 2.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", original_position.y + 15, 2.0).set_trans(Tween.TRANS_SINE)

# This is called by the AI in main.gd!
func react_to_stance(stance: String):
	# Create a new tween to override the floating temporarily
	var tween = create_tween()
	
	if stance == "AGGRESSIVE":
		# Lunge forward, grow 50% larger, and turn enraged red
		tween.tween_property(self, "modulate", Color(1.0, 0.2, 0.2), 0.2)
		tween.tween_property(self, "scale", original_scale * 1.5, 0.2)
		tween.tween_property(self, "position:x", original_position.x - 150, 0.2).set_trans(Tween.TRANS_EXPO)
		
	elif stance == "DEFENSIVE":
		# Shrink back, float away, and turn cool blue
		tween.tween_property(self, "modulate", Color(0.2, 0.5, 1.0), 0.3)
		tween.tween_property(self, "scale", original_scale * 0.8, 0.3)
		tween.tween_property(self, "position:x", original_position.x + 100, 0.3).set_trans(Tween.TRANS_SINE)
		
	elif stance == "PARRY":
		# Flash bright white and pulse quickly
		tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0), 0.1) 
		tween.tween_property(self, "scale", original_scale * 1.2, 0.1)
		tween.tween_property(self, "scale", original_scale, 0.1)
		
	# After 1.5 seconds of holding the pose, return to normal
	tween.tween_interval(1.5)
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	tween.tween_property(self, "scale", original_scale, 0.5)
	tween.tween_property(self, "position:x", original_position.x, 0.5)
