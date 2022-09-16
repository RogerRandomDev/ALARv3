extends TileMap
class_name chunk2D
var _pos:Vector2i
const atlas:=Vector2i.ZERO

func _ready():
	add_layer(1)
	set_layer_z_index(1,-1)
	set_layer_modulate(1,Color(0.5,0.5,0.5))
	
	
func fill(contents):
	for tile in contents[0]:call_deferred('set_cell',0,tile[0],tile[1],atlas,0)
#handles the freeing of the chunk
func prepForRemoval():
	clear_layer(0)
	clear_layer(1)
