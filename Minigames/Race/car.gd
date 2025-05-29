extends RigidBody2D

@export var acceleration_force := 180.0
@export var brake_force := 100.0
@export var max_forward_speed := 1400.0
@export var max_reverse_speed := -100.0
@export var base_turn_torque := 5500.0
@export var angular_damping_base := 10.0
@export var linear_damping_base := 2.0
@export var friction_force := 30.0  # Lowered for stability

var player_number := 1

func _ready():
	linear_damp = linear_damping_base
	angular_damp = angular_damping_base

func _physics_process(delta):
	var acc_input := Input.get_action_strength("game_main_p%d" % player_number)
	var dec_input := Input.get_action_strength("game_second_p%d" % player_number)

	var forward_dir := Vector2.RIGHT.rotated(rotation)
	var lateral_dir := Vector2.UP.rotated(rotation)

	# --- Apply forward/reverse force ---
	var current_speed := linear_velocity.dot(forward_dir)
	
	if acc_input > 0.01 and current_speed < max_forward_speed:
		apply_force(forward_dir * acceleration_force * acc_input)

	elif dec_input > 0.01 and current_speed > max_reverse_speed:
		apply_force(-forward_dir * brake_force * dec_input)

	# --- Apply turning torque, scaled by speed ---
	var steer_input := Input.get_axis("game_left_p%d" % player_number, "game_right_p%d" % player_number)

	if abs(steer_input) > 0.01:
		# Reverse steering if moving backward
		if current_speed < 0.0:
			steer_input *= -1

		# Apply torque scaled by speed and input magnitude
		var turn_scaling = clamp(abs(current_speed) / max_forward_speed, 0.0, 1.0)
		var torque = base_turn_torque * steer_input * turn_scaling
		apply_torque(torque)



	# --- Lateral friction (tire grip) ---
	var lateral_speed := linear_velocity.dot(lateral_dir)
	var max_side_slip := 150.0  # Clamp for stability
	lateral_speed = clamp(lateral_speed, -max_side_slip, max_side_slip)
	var lateral_correction := -lateral_dir * lateral_speed * friction_force
	apply_force(lateral_correction)
