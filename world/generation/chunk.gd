extends TileMap
class_name chunk2D
var _pos:Vector2i
const atlas:=Vector2i.ZERO
var biome=null
var changedCell={}
var originalData=[]
var pattern=TileMapPattern.new()

func _ready():
	z_index=10
func _init():
	pattern.set_size(Vector2i(world.chunkSize,world.chunkSize))
func fill(contents,_randomTick=false):
	for tileID in contents[0].size():
		var cellPos=Vector2i(tileID%16,tileID/16)
		#handles updates outside the gametick
		if changedCell.has(cellPos):contents[0][tileID]=changedCell[cellPos];changedCell.erase(cellPos)
			
		
		if(contents[0][tileID]<0):
			
			if pattern.has_cell(cellPos):
				pattern.remove_cell(cellPos,false)
			continue
		pattern.set_cell(cellPos,contents[0][tileID],atlas,0)
	world.dataStore.chunkData[_pos]=contents
	set_pattern.call_deferred(0,atlas,pattern)
	var used =get_used_cells(0).filter(func(cell):return !pattern.has_cell(cell))
	for cell in used:erase_cell(0,cell)


#fills in entities for given chunk
func fillEntities(entities):
	if !len(entities):return
	var entList=[]
	for entity in entities:
		if entity[2]=="ERROR_NAME":continue
		var ent = world.getItem()
		ent.fromStorageFormat(entity)
		ent.position=(_pos*world.chunkSize+entity[len(entity)-1])*world.tileSize+Vector2i(
			4,6
		)
		entList.append(ent)
#	finishFill(entList)
func finishFill(entList):
	for ent in entList:world.chunkHolder.add_child(ent)

#handles the freeing of the chunk
func prepForRemoval():
	pass

#returns cell custom data
func getCustomCellData(cell):
	if !pattern.has_cell(cell):return null
	return getTileData(cell)
#gets basic cell data from tileset
func getCellData(cell):
	if !pattern.has_cell(cell):return {"name":"ERROR"}
	var id=pattern.get_cell_source_id(cell)
	
	var cellData=getTileData(cell)
	if cellData.get_custom_data("unmineable"):return {"name":"ERROR"}
	
	var raw=tile_set.get_source(id)
	return {
		"texture":raw.get("texture"),
		"name":raw.get("resource_name"),
		"id":id,
		"actionType":"place",
		"actionRange":0
	}


#changes current cell
func changeCell(cell,id,dropItem=true):
	if _pos.y>40:return false
	var cellData=null
	
	if id<0:
		if !pattern.has_cell(cell):return false
		if mineCell(cell,dropItem)==null:return false
		cellData=getCellData(cell)
		pattern.remove_cell(cell,false)
	else:
		var cellDat=getCustomCellData(cell)
		if (
			cellDat!=null&&
			!cellDat.get_custom_data("replacable")||
			changedCell.has(cell)):return false
		call_deferred("set_cell",0,cell,id,atlas,0)
		cellData = true
	changedCell[cell]=id
	world.dataStore.chunkData[_pos][0][cell.x+cell.y*16]=id
	return cellData
#checks if can explode given cell
func canExplode(cell):
	if _pos.y>40:return false
	var cellData=getTileData(cell)
	if cellData==null||cellData.get_custom_data("ExplosionProof"):return false
	return true

#explodes the given cell if not immune to it
func explodeCell(cell):
	if !canExplode(cell)||!mineCell(cell):return
	changedCell[cell]=-1
	if !world.dataStore.chunkData.has(_pos):return
	world.dataStore.chunkData[_pos][0][cell.x+cell.y*16]= -1

#attempts to fill cell if it is not solid
func attemptFillCell(cell,ignoreFull=false):
	if pattern.has_cell(cell)&&!ignoreFull:return false
	pattern.set_cell(Vector2i(cell.x,cell.y),cell.z,atlas,0)
	
	return true

#handles mining a cell
func mineCell(cell,dropItem=true):
	var cellData=getCellData(cell)
	if cellData.name=="ERROR":return false
	else:
		cellData=world.itemManager.getItemData(cellData.name)
		cellData.quantity=1
		if dropItem:world.dropItem.call_deferred(cell+_pos*world.chunkSize,cellData)
		
	return true

#removes given cells
func removeCells(cellList):
	for i in cellList:
		explodeCell(i)
	
#returns tile data from the pattern
func getTileData(cell):
	if pattern.has_cell(cell):
		return tile_set.get_source(pattern.get_cell_source_id(cell)).get_tile_data(atlas,0)
	return null


