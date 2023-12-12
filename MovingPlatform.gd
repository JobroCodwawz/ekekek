extends Node2D

@export var positions : Array[Vector2] = [Vector2(0,0)]
@export var loop:bool
@export var duration:float = 1.0
@export var size:Vector2
var tween
var sprite_scene

# Called when the node enters the scene tree for the first time.
func _ready():
	sprite_scene = preload("res://move_sprite.tscn")
	snap_to_grid()
	tween = create_tween().set_loops()
	for pos in positions:
		tween.tween_property(self, "position", pos, duration).as_relative()
	if loop: return
	for i in range(positions.size()-1, -1, -1):
		print("wha")
		tween.tween_property(self, "position", positions[i]*-1, duration).as_relative()

func snap_to_grid():
	var grid_pos = Vector2(floor(global_position.x/32), floor(global_position.y/32))*32 + Vector2(16,0)
	global_position = grid_pos
	
	var odd_offset = Vector2(0, 0)
	if int(size.y) % 2 == 1:
		odd_offset = Vector2(0, 8)
	
	global_position -= odd_offset
	for i in range(positions.size()):
		positions[i] = Vector2(floor(positions[i].x/32), floor(positions[i].y/32))*32
		
	var shape = $Move/CollisionShape2D.get_shape()
	shape.extents = Vector2(size.x/2*16,size.y/2*16)
	$Move/CollisionShape2D.set_shape(shape)
	
	for x in range(floor(-size.x/2), floor(size.x/2)):
		for y in range(floor(-size.y/2), floor(size.y/2)):
			var offset = Vector2(x,y)*16 + Vector2(0,16) + odd_offset
			var sprite = sprite_scene.instantiate()
			sprite.position = offset
			add_child(sprite)
		
