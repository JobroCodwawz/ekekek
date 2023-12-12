extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = -275.0
var target_pos:int = 0
const TILE_SIZE:int = 32
var last_direction:int = 1
var last_climb_dir:int = 0

var snapping:bool = false
var climb_snapping:bool = false

const MOVE_DELAY:float = 0.25
var running_delay:float = 0
var jumping_up:bool = false
signal clearance_height
var y
var y_offset:float
var y_pos
var in_jump:bool = false

var projectile_scene:PackedScene
var bomb_scene:PackedScene

const cooldown:float = 0.75
var time_since_shoot:float = cooldown
var crouched:bool = false

var walking:bool = false
var climbing:bool = false

var jump_queue_time = 10
var jump_queue_countdown = 0

var on_ladder = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	y_offset = global_position.y
	clearance_height.connect(Callable(self, "jump_up"))
	y = global_position.y
	projectile_scene = preload("res://projectile.tscn")
	bomb_scene = preload("res://bomb.tscn")

func _physics_process(delta):
	if in_jump and velocity.x == 0 and velocity.y == 0:
		in_jump = false
		if $Colliders.is_ladder($CrouchCollider.global_position) and not $Colliders.is_one_way($Colliders/FootCollider.get_child(0).global_position, true):
			print("from jump")
			on_ladder = true

	y_pos = global_position.y - y_offset
	
	jump_queue_countdown -= 1
	
	if velocity.x == 0 and not get_dir():
		walking = false
	
	#if $Colliders.is_ladder($Colliders/HeadCollider.global_position) or climbing:
	#	on_ladder = true
	#else:
	#	on_ladder = false
	if not $Colliders.is_ladder($Colliders/HeadCollider.global_position) and not climbing:
		on_ladder = false
	
	if not walking:
		$AnimatedSprite2D.animation = "default"
	else:
		$AnimatedSprite2D.animation = "walk"
		
	if velocity.y < 0:
		$AnimatedSprite2D.animation = "jump"
	elif velocity.y > 0:
		$AnimatedSprite2D.animation = "fall"
		
	if on_ladder:
		$AnimatedSprite2D.animation = "climb_idle"
		if climbing:
			$AnimatedSprite2D.animation = "climb"
	
	
	time_since_shoot += delta
	# Add the gravity.
	
	if not is_on_floor() and not on_ladder:
		velocity.y += gravity * delta
		velocity.y = clamp(velocity.y, JUMP_VELOCITY, -JUMP_VELOCITY)
		
		if velocity.y < 0 and y - global_position.y >= TILE_SIZE:
			emit_signal("clearance_height")
	
	var dir = get_dir()
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and velocity.x == 0 and !dir:
		y = global_position.y
		jump()
	elif Input.is_action_just_pressed("ui_up") and not $Colliders.is_ladder($Colliders/HeadCollider.global_position):
		jump_queue_countdown = jump_queue_time
	elif is_on_floor() and velocity.x == 0 and !dir and jump_queue_countdown > 0:
		print("QUEUED JUMP")
		y = global_position.y
		jump()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	horizontal_move(delta)
	
	if on_ladder:
		climb(0)
	
	if Input.is_action_pressed("ui_accept") and time_since_shoot > cooldown:
		shoot()
		time_since_shoot = 0
		
	if Input.is_action_just_pressed("ui_down") and is_on_floor() and velocity.x == 0 and not on_ladder:
		if $Colliders.is_ladder($Colliders/FootCollider.get_child(0).global_position):
			on_ladder = true
			climb(1)
		else:
			crouch()
		
	if Input.is_action_just_pressed("bomb"):
		place_bomb()

	move_and_slide()
	
func climb(dir):
	var direction = vert_dir()
	if get_dir(): return
	
	if dir != 0:
		direction = dir
		
	if direction and not climbing:
		if (not $Colliders.is_ladder($Colliders/HeadCollider.get_child(0).global_position) and dir == 0) or not $Colliders.is_ladder($Colliders/FootCollider.get_child(0).global_position):
			get_target(y_pos, last_climb_dir)
			climb_snapping = true
			snap_climb()
			return
			
		if direction != last_climb_dir:
			last_climb_dir = direction
		
		velocity.y = direction * SPEED
		$FullCollider.disabled = true
		climbing = true
	else:
		snap_climb()
		
func snap_climb():
	
	if velocity.y != 0 and climbing:
		if not climb_snapping:
			get_target(y_pos, last_climb_dir)
			climb_snapping = true
		elif climb_snapping and abs(y_pos - target_pos) < 4:
			global_position.y = target_pos + y_offset
			velocity.y = 0
			climb_snapping = false
			climbing = false
			$FullCollider.disabled = false
			if not $Colliders.is_ladder($Colliders/FootCollider.get_child(0).global_position):
				print("GROUND")
				on_ladder = false
			print("SNAPPED ", target_pos, ", ", y_pos, ", ", global_position.y)
	
	
func horizontal_move(delta):
	running_delay += delta
	
	var direction = get_dir()
	if direction and velocity.x == 0 and is_on_floor():
		if direction != last_direction:
			last_direction = direction
			$AnimatedSprite2D.flip_h = !$AnimatedSprite2D.flip_h
			$Colliders.flip()
			start_delay()
		elif delay_finished() and $Colliders.can_move():
			velocity.x = direction * SPEED
			walking = true
			uncrouch()
		
	else:
		snap_movement()
		

func snap_movement():
	if velocity.x != 0:
		#print(target_pos, ", ", global_position.x, " ", snapping)
		if not snapping:
			get_target(global_position.x, last_direction)
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
	
func vert_dir():
	var direction = Input.get_axis("ui_up", "ui_down")
	return direction

func jump():
	
	if on_ladder:
		return
	elif $Colliders.is_ladder($CrouchCollider.global_position) and not in_jump and not crouched:
		print("NOW ON LADDER")
		on_ladder = true
	
	if crouched:
		uncrouch()
		return
	
	if not on_ladder:
		in_jump = true
		
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
		get_target(global_position.x + last_direction*TILE_SIZE, last_direction)
	
func jump_up():
	if jumping_up:
		velocity.x = last_direction * SPEED
		global_position.x += last_direction
		jumping_up = false
		snapping = true
		get_target(global_position.x, last_direction)
	
func get_target(pos, dir):
	if dir == 1: target_pos = int(ceil(pos / TILE_SIZE))*TILE_SIZE
	else: target_pos = int(floor(pos / TILE_SIZE))*TILE_SIZE
	
	
func shoot():
	var proj = projectile_scene.instantiate()
	proj.set_dir(last_direction)
	proj.player = self
	proj.global_position = global_position
	get_parent().add_child(proj)

func crouch():
	var was_crouched = crouched
	
	if not crouched:
		crouched = true
		toggleCollider()
		$AnimatedSprite2D.scale.y = 0.5
	
	if $Colliders.platform_below() and was_crouched:
		uncrouch()
		global_position.y += 1
	
func toggleCollider():
	$FullCollider.disabled = !$FullCollider.disabled
	$CrouchCollider.disabled = !$CrouchCollider.disabled

	
func uncrouch():
	if crouched:
		toggleCollider()
		$AnimatedSprite2D.scale.y = 1
		
	crouched = false
	
func place_bomb():
	if not crouched: return
	var bomb = bomb_scene.instantiate()
	bomb.global_position.y = $CrouchCollider.global_position.y
	bomb.global_position.x = global_position.x
	get_parent().add_child(bomb)
	
func damage(amount):
	print("owie: ", amount)



