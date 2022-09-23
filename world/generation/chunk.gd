extends TileMap
class_name chunk2D
var _pos:Vector2i
const atlas:=Vector2i.ZERO
var biome=null
func _ready():
	add_layer(1)
	set_layer_z_index(1,-1)
	set_layer_modulate(1,Color(0.5,0.5,0.5))
	
	
func fill(contents):
	for tileID in contents[0].size():
		if(contents[0][tileID]==-1):continue
		call_deferred('set_cell',0,Vector2i(tileID%16,tileID/16),contents[0][tileID],atlas,0)
	world.dataStore.chunkData[_pos]=contents
	
#handles the freeing of the chunk
func prepForRemoval():
	clear()


#attempts to fill cell if it is not solid
func attemptFillCell(cell):
	if get_cell_source_id(0,Vector2i(cell.x,cell.y),false)!=-1:return false
	call_deferred('set_cell',0,Vector2i(cell.x,cell.y),cell.z,atlas,0)
	
	return true
