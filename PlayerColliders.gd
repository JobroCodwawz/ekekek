extends Node2D

var front_block:bool = false
var above_block:bool = false
var below_block:bool = false

func _ready():
	front_block = $FrontCollider.get_overlapping_bodies().size() != 0
	above_block = $AboveCollider.get_overlapping_bodies().size() != 0
	below_block = $BelowCollider.get_overlapping_bodies().size() != 0
	
func normal_jump():
	return (below_block and not(front_block)) or (front_block and above_block)
	
func jump_up():
	return front_block and !above_block
	
func jump_over():
	return !(front_block or above_block or below_block)


func flip():
	for child in get_children():
		child.scale.x = -child.scale.x

func _on_front_collider_body_entered(body):
	front_block = true

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
