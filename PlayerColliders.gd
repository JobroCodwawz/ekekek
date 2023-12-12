extends Node2D

var front_block:bool = false
var above_block:bool = false
var below_block:bool = false
var above_head:bool = false
var head:bool = false
var foot:bool = false
var mapref:TileMap

func _ready():
	front_block = $FrontCollider.get_overlapping_bodies().size() != 0
	above_block = $AboveCollider.get_overlapping_bodies().size() != 0
	below_block = $BelowCollider.get_overlapping_bodies().size() != 0
	mapref = get_node("/root/World/TileMap")
	
func normal_jump():
	head = $HeadCollider.overlaps_body(mapref)
	return ((below_block and not(front_block)) or (front_block and above_block) or above_head or head) and not is_ladder($AboveCollider.get_child(0).global_position)
	
func jump_up():
	return front_block and !above_block and not above_head and not head or is_ladder($AboveCollider.get_child(0).global_position)
	
func jump_over():
	return !(front_block or above_block or below_block) and not above_head and not head

func can_move():
	return !front_block or is_one_way($FrontCollider.get_child(0).global_position, front_block)
	
func is_one_way(pos, blockcheck):
	if not blockcheck:
		return false
	
	var tile = get_tile_data(pos)
	return tile.is_collision_polygon_one_way(1,0)
	
func is_ladder(pos):
	var tile = get_tile_data(pos)
	if tile == null: return false
	return tile.get_custom_data("Climbable")
	
	
func get_tile_data(pos):
	var grid_pos = Vector2i(floor(pos.x/16), floor(pos.y/16))

	var offset = get_parent().velocity.normalized()
	offset = Vector2i(offset)
	
	var tile = mapref.get_cell_tile_data(0, grid_pos+offset)
	return tile
	
		
func platform_above():
	return head
	
func platform_below():
	foot = $FootCollider.overlaps_body(mapref)
	return is_one_way($FootCollider.get_child(0).global_position, foot)
	

func flip():
	for child in get_children():
		child.scale.x = -child.scale.x

func _on_front_collider_body_entered(body):
	front_block = true
	#print(is_one_way($FrontCollider.get_child(0).global_position))

func _on_above_collider_body_entered(body):
	above_block = true

func _on_below_collider_body_entered(body):
	below_block = true

func _on_front_collider_body_exited(body):
	front_block = false

func _on_above_collider_body_exited(body):
	above_block = false

func _on_below_collider_body_exited(body):
	below_block = false

func _on_above_head_collider_body_entered(body):
	above_head = true

func _on_above_head_collider_body_exited(body):
	above_head = false

func _on_head_collider_body_entered(body):
	if body != get_parent(): head = true

func _on_head_collider_body_exited(body):
	head = false

func _on_foot_collider_body_entered(body):
	foot = true

func _on_foot_collider_body_exited(body):
	foot = false
