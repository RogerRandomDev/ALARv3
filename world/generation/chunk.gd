extends TileMap
class_name chunk2D
var _pos:Vector2i
const atlas:=Vector2i.ZERO
var biome=null
var changedCell={}
var originalData=[]

func _ready():
	z_index=10
	add_layer(1)
	set_layer_z_index(1,-1)
	set_layer_modulate(1,Color(0.5,0.5,0.5))


func fill(contents,randomTick=false):
	for tileID in contents[0].size():
		var cellPos=Vector2i(tileID%16,tileID/16)
		if(changedCell.has(cellPos)):
			contents[0][tileID]=changedCell[cellPos];changedCell.erase(cellPos)
		if(contents[0][tileID]<0):
			if(randomTick&&world.dataStore.chunkData[_pos][0][tileID]>-1):call_deferred('erase_cell',0,cellPos)
			continue
		
		call_deferred('set_cell',0,cellPos,contents[0][tileID],atlas,0)
	
	world.dataStore.chunkData[_pos]=contents
#fills in entities for given chunk
func fillEntities(entities):
	
	for entity in entities:
		var ent = itemDrop2D.new()
		
		ent.position=(_pos*world.chunkSize+entity[len(entity)-1])*world.tileSize+Vector2(
			4,6
		)
		ent.fromStorageFormat(entity)
		get_parent().add_child(ent)


#handles the freeing of the chunk
func prepForRemoval():
	clear()

#gets basic cell data from tileset
func getCellData(cell):
	var id=get_cell_source_id(0,cell)
	if id<0:return {"name":"ERROR"}
	var cellData=get_cell_tile_data(0,cell)
	if cellData.get_custom_data("unmineable"):return {"name":"ERROR"}
	
	var raw=tile_set.get_source(id)
	return {
		"texture":raw.get("texture"),
		"name":raw.get("resource_name"),
		"id":id,
		"actionType":"place"
	}


#changes current cell
func changeCell(cell,id):
	if _pos.y>40:return false
	if id<0:
		if !mineCell(cell):return false
		call_deferred('erase_cell',0,cell)
	else:
		if get_cell_source_id(0,cell)> -1:return false
		call_deferred('set_cell',0,cell,id,atlas,0)
	
	changedCell[cell]=id
	world.dataStore.chunkData[_pos][0][cell.x+cell.y*16]=id
	return true
#explodes the given cell if not immune to it
func explodeCell(cell):
	if _pos.y>40:return false
	if get_cell_source_id(0,cell)<0:return
	var cellData=get_cell_tile_data(0,cell)
	if cellData==null||cellData.get_custom_data("ExplosionProof"):return
	if !mineCell(cell):return
	erase_cell(0,cell)
	changedCell[cell]=-1
	world.dataStore.chunkData[_pos][0][cell.x+cell.y*16]= -1
#attempts to fill cell if it is not solid
func attemptFillCell(cell,ignoreFull=false):
	if get_cell_source_id(0,Vector2i(cell.x,cell.y),false)!=-1&&!ignoreFull:return false
	call_deferred('set_cell',0,Vector2i(cell.x,cell.y),cell.z,atlas,0)
	
	return true

#handles mining a cell
func mineCell(cell):
	var cellData=getCellData(cell)
	if cellData.name=="ERROR":return false
	else:
		cellData.weight=1
		cellData.quantity=1
		world.dropItem(cell+_pos*world.chunkSize,cellData)
	return true
