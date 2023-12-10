extends Area2D

var direction:int
var vel:Vector2
const SPEED = 400
var player

# Called when the node enters the scene tree for the first time.
func _ready():
	vel = Vector2(direction*SPEED, 0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	global_position += vel*delta

func delete():
	queue_free()

func set_dir(dir):
	direction = dir

func _on_body_entered(body):
	if body != player:
		print(body)
		delete()
