extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = -250.0
var target_pos:int = 0
const TILE_SIZE:int = 32
var last_direction:int = 1
var snapping:bool = false
const MOVE_DELAY:float = 0.25
var running_delay:float = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	# Add the gravity.
	
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and velocity.x == 0:
		var dir = get_dir()
		if !dir:
			velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if is_on_floor():
		horizontal_move(delta)

	move_and_slide()
	
	
func horizontal_move(delta):
	running_delay += delta
	
	var direction = get_dir()
	if direction and velocity.x == 0:
		if direction != last_direction:
			last_direction = direction
			$Sprite2D.flip_h = !$Sprite2D.flip_h
			start_delay()
		elif delay_finished():
			velocity.x = direction * SPEED
		
	else:
		if velocity.x != 0:
			if not snapping:
				if last_direction == 1: target_pos = int(ceil(global_position.x / TILE_SIZE))*TILE_SIZE
				else: target_pos = int(floor(global_position.x / TILE_SIZE))*TILE_SIZE
				snapping = true
			elif snapping and abs(global_position.x - target_pos) < 4:
				global_position.x = target_pos
				velocity.x = 0
				snapping = false
				print(target_pos, ", ", global_position.x)

func start_delay():
	running_delay = 0
	
func delay_finished():
	return running_delay > MOVE_DELAY
	
func get_dir():
	var direction = Input.get_axis("ui_left", "ui_right")
	return direction
