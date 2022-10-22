extends Node

const ZERO=Vector2i(0,0)
const EIGHT=Vector2i(8,8)
var TileShapes=[
	PackedVector2Array([Vector2i(-4,-4),Vector2i(4,-4),Vector2i(4,4),Vector2i(-4,4)]),
	PackedVector2Array([Vector2i(-4,-2),Vector2i(4,-2),Vector2i(4,4),Vector2i(-4,4)]),
	PackedVector2Array([Vector2i(-4,0),Vector2i(4,0),Vector2i(4,4),Vector2i(-4,4)]),
	PackedVector2Array([Vector2i(-4,2),Vector2i(4,2),Vector2i(4,4),Vector2i(-4,4)])
]
const liquidShader=preload("res://world/shaders/WaterShader.tres")
var liquidCount=0
var fluidTiles={}
func buildTileSet(tileData):
	var tiles=TileSet.new()
	tiles.tile_size=Vector2i(8,8)
	tiles.add_physics_layer(0)
	tiles.add_physics_layer(1)
	tiles.set_physics_layer_collision_layer(0,3)
	tiles.set_physics_layer_collision_mask(0,1)
	tiles.set_physics_layer_collision_layer(1,16)
	tiles.set_physics_layer_collision_mask(1,0)
	tiles.add_custom_data_layer(0)
	tiles.add_custom_data_layer(1)
	tiles.add_custom_data_layer(2)
	tiles.set_custom_data_layer_name(0,"ExplosionProof")
	tiles.set_custom_data_layer_type(0,TYPE_BOOL)
	tiles.set_custom_data_layer_name(1,"unmineable")
	tiles.set_custom_data_layer_type(1,TYPE_BOOL)
	tiles.set_custom_data_layer_name(2,"replaceable")
	tiles.set_custom_data_layer_type(2,TYPE_BOOL)
	for tile in tileData:
		tiles.add_source(createTile(tile,true),tile.id+liquidCount*4)
	for tile in fluidTiles:
		tiles.add_source(createTile(fluidTiles[tile],false),tile)
#
	world.mapTiles = tiles



#creates a tile data
func createTile(tile,fluidRun):
	var source=TileSetAtlasSource.new()
	source.texture=tile.texture
	source.resource_name=tile.name
	source.texture_region_size=EIGHT
	source.create_tile(ZERO)
	#0 is a solid, 1 is a fluid, everything else is nothing
	
	if tile.solid==0:
		source.set("0:0/0/physics_layer_0/polygon_0/points",TileShapes[0])
	
	else:if tile.solid==1:
		source.set("0:0/0/physics_layer_1/polygon_0/points",TileShapes[0])
		source.set("0:0/0/custom_data_0",true)
		source.set("0:0/0/custom_data_1",true)
		source.set("0:0/0/custom_data_2",true)
		source.set("0:0/0/material",liquidShader)
		if fluidRun:createFluid(tile,liquidCount*4)
		liquidCount+=1
	return source
#creates the liquid states from main texture
func createFluid(tile,offset):
	var id=tile.id+offset
	var i=0
	while i<4:
		var data=tile.duplicate()
		data.texture=makeFluidTexture(data.texture,i)
		
		fluidTiles[id+i]=data
		i+=1
#creates texture for the liquid
func makeFluidTexture(tex:CompressedTexture2D,index):
	if index==1:return tex
	
	var out=tex.get_image()
	if index==0:out.rotate_90(CLOCKWISE)
	out.fill_rect(Rect2i(0,0,8,max(index-2,0)*2),Color8(0,0,0,0))
	
	var nTex=ImageTexture.new()
	nTex.set_image(out)
	
	return nTex
