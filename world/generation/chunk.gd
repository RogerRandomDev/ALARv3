extends TileMap
class_name chunk2D
var _pos:Vector2i


func _ready():
	add_layer(1)
	set_layer_z_index(1,-1)
	set_layer_modulate(1,Color(0.5,0.5,0.5))

func fill(contents):
	for tile in contents[0]:set_cell(0,tile[0],tile[2],tile[1],tile[2])
	for tile in contents[1]:set_cell(1,tile[0],tile[2],tile[1],tile[2])
#handles the freeing of the chunk
func prepForRemoval():
	queue_free()
