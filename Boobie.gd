extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -400.0
var target_pos:int = 0
const TILE_SIZE:int = 32
var last_direction:int = 0
var snapping:bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _process(delta):
	# Add the gravity.
	#print(global_position) 
	
	
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		last_direction = direction
	else:
		if velocity.x != 0:
			if not snapping:
				if last_direction == 1: target_pos = int(ceil(global_position.x / TILE_SIZE))*32
				else: target_pos = int(floor(global_position.x / TILE_SIZE))*32
				
				print(target_pos, ", ", global_position.x)
				#print(target_pos)
				snapping = true
			elif snapping and abs(global_position.x - target_pos) < 4:
				global_position.x = target_pos
				velocity.x = 0
				snapping = false

	move_and_slide()
