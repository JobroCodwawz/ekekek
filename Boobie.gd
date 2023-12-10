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

var projectile_scene:PackedScene
var bomb_scene:PackedScene

const cooldown:float = 0.75
var time_since_shoot:float = cooldown
var crouched:bool = false

var walking:bool = false

var jump_queue_time = 10
var jump_queue_countdown = 0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	clearance_height.connect(Callable(self, "jump_up"))
	y = global_position.y
	projectile_scene = preload("res://projectile.tscn")
	bomb_scene = preload("res://bomb.tscn")

func _physics_process(delta):
	jump_queue_countdown -= 1
	
	if velocity.x == 0 and not get_dir():
		walking = false
	
	
	if not walking:
		$AnimatedSprite2D.animation = "default"
	else:
		$AnimatedSprite2D.animation = "walk"
		
	if velocity.y < 0:
		$AnimatedSprite2D.animation = "jump"
	elif velocity.y > 0:
		$AnimatedSprite2D.animation = "fall"
	
	
	time_since_shoot += delta
	# Add the gravity.
	
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = clamp(velocity.y, JUMP_VELOCITY, -JUMP_VELOCITY)
		
		if velocity.y < 0 and y - global_position.y >= TILE_SIZE:
			emit_signal("clearance_height")
	
	var dir = get_dir()
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and velocity.x == 0 and !dir:
		y = global_position.y
		jump()
	elif Input.is_action_just_pressed("ui_up"):
		jump_queue_countdown = jump_queue_time
	elif is_on_floor() and velocity.x == 0 and !dir and jump_queue_countdown > 0:
		print("QUEUED JUMP")
		y = global_position.y
		jump()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	horizontal_move(delta)
	
	
	
	if Input.is_action_pressed("ui_accept") and time_since_shoot > cooldown:
		shoot()
		time_since_shoot = 0
		
	if Input.is_action_just_pressed("ui_down") and is_on_floor() and velocity.x == 0:
		crouch()
		
	if Input.is_action_just_pressed("bomb"):
		place_bomb()

	move_and_slide()
	
	
func horizontal_move(delta):
	running_delay += delta
	
	var direction = get_dir()
	if direction and velocity.x == 0 and is_on_floor():
		if direction != last_direction:
			last_direction = direction
			$AnimatedSprite2D.flip_h = !$AnimatedSprite2D.flip_h
			$Colliders.flip()
			start_delay()
		elif delay_finished() and not $Colliders.front_block:
			velocity.x = direction * SPEED
			walking = true
			uncrouch()
		
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
	if crouched:
		uncrouch()
		return
	
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
	
	
func shoot():
	var proj = projectile_scene.instantiate()
	proj.set_dir(last_direction)
	proj.player = self
	proj.global_position = global_position
	get_parent().add_child(proj)

func crouch():
	crouched = true
	$CollisionShape2D.scale.y = 0.5
	$AnimatedSprite2D.scale.y = 0.5
	
func uncrouch():
	crouched = false
	$CollisionShape2D.scale.y = 1
	$AnimatedSprite2D.scale.y = 1
	
	
func place_bomb():
	if not crouched: return
	var bomb = bomb_scene.instantiate()
	bomb.global_position.y = global_position.y
	bomb.global_position.x = global_position.x
	get_parent().add_child(bomb)
	
func damage(amount):
	print("owie: ", amount)



