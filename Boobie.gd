extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = -275.0
var target_pos:int = 0
const TILE_SIZE:int = 32
var last_direction:int = 1
var snapping:bool = false
const MOVE_DELAY:float = 0.25
var running_delay:float = 0
var jumping_up:bool = false
signal clearance_height
var y

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	clearance_height.connect(Callable(self, "jump_up"))
	y = global_position.y

func _physics_process(delta):
	
	# Add the gravity.
	
	if not is_on_floor():
		velocity.y += gravity * delta
		if velocity.y < 0 and y - global_position.y >= TILE_SIZE:
			emit_signal("clearance_height")

	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and velocity.x == 0:
		var dir = get_dir()
		if !dir:
			y = global_position.y
			jump()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	horizontal_move(delta)

	move_and_slide()
	
	
func horizontal_move(delta):
	running_delay += delta
	
	var direction = get_dir()
	if direction and velocity.x == 0 and is_on_floor():
		if direction != last_direction:
			last_direction = direction
			$Sprite2D.flip_h = !$Sprite2D.flip_h
			$Colliders.flip()
			start_delay()
		elif delay_finished() and not $Colliders.front_block:
			velocity.x = direction * SPEED
		
	else:
		snap_movement()
		

func snap_movement():
	if velocity.x != 0:
			if not snapping:
				get_target(global_position.x)
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

func jump():
	print($Colliders.normal_jump(), ", ", $Colliders.jump_up())
	
	if $Colliders.normal_jump():
		velocity.y = JUMP_VELOCITY
	elif $Colliders.jump_up():
		jumping_up = true
		velocity.y = JUMP_VELOCITY
	elif $Colliders.jump_over():
		velocity.y = JUMP_VELOCITY
		velocity.x = last_direction * SPEED
		global_position.x += last_direction
		snapping = true
		get_target(global_position.x + last_direction*TILE_SIZE)
	
func jump_up():
	if jumping_up:
		velocity.x = last_direction * SPEED
		global_position.x += last_direction
		jumping_up = false
		snapping = true
		get_target(global_position.x)
	
func get_target(pos):
	if last_direction == 1: target_pos = int(ceil(pos / TILE_SIZE))*TILE_SIZE
	else: target_pos = int(floor(pos / TILE_SIZE))*TILE_SIZE
	
	
