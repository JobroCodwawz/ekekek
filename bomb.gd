extends StaticBody2D

var amp = 0.4
var offset = 0
var ttl = 5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	ttl -= delta
	if ttl <= 0:
		explode()
		ttl = 3
	
	offset += 6.0 * delta
	var sat = amp * sin(offset * 1.0) + amp
	
	$Sprite2D.modulate = Color.from_hsv(0, sat, 1)
	
func explode():
	var affected = $Area2D.get_overlapping_bodies()
	
	for body in affected:
		if body is TileMap:
			var pos = Vector2i(int(global_position.x/16), int(global_position.y/16))
			for i in range(-3,3):
				for j in range(-3,3):
					var tile_pos = pos+Vector2i(i,j)
					var tile = body.get_cell_tile_data(0, tile_pos)
					if tile != null:
						var breakable = tile.get_custom_data("Breakable")
						if breakable:
							body.erase_cell(0, tile_pos)
		elif body is CharacterBody2D:
			body.damage(10)
	
	queue_free()

