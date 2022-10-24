extends Node

const ZERO=Vector2i(0,0)
const EIGHT=Vector2i(8,8)
#please do not make fun of my janky code for this
#it is very shy
#also it i̶s̶(was) italian
var TileShapes=[
	PackedVector2Array([Vector2i(-4,-4),Vector2i(4,-4),Vector2i(4,4),Vector2i(-4,4)]),
	PackedVector2Array([Vector2i(-4,-2),Vector2i(4,-2),Vector2i(4,4),Vector2i(-4,4)]),
	PackedVector2Array([Vector2i(-4,0),Vector2i(4,0),Vector2i(4,4),Vector2i(-4,4)]),
	PackedVector2Array([Vector2i(-4,2),Vector2i(4,2),Vector2i(4,4),Vector2i(-4,4)])
]
const liquidShader=preload("res://world/shaders/WaterShader.tres")
var liquidCount=0
var fluidTiles={}
var fluidStarts=[]
func buildTileSet(tileData):
	var tiles=TileSet.new();tiles.tile_size=Vector2i(8,8)
	tiles.add_physics_layer(0);tiles.add_physics_layer(1)
	
	tiles.set_physics_layer_collision_layer(0,3)
	tiles.set_physics_layer_collision_mask(0,1)
	tiles.set_physics_layer_collision_layer(1,16)
	tiles.set_physics_layer_collision_mask(1,0)
	for i in 3:
		tiles.add_custom_data_layer(i);tiles.set_custom_data_layer_type(i,TYPE_BOOL)
	
	tiles.set_custom_data_layer_name(0,"ExplosionProof")
	tiles.set_custom_data_layer_name(1,"unmineable")
	tiles.set_custom_data_layer_name(2,"replacable")
	
	for tile in tileData:
		tiles.add_source(createTile(tile,true),tile.id+int(tile.solid==1))
	for tile in fluidTiles:
		tiles.add_source(createTile(fluidTiles[tile],false),tile)
	
	world.mapTiles = tiles



#creates a tile data
func createTile(tile,fluidRun):
	var source=TileSetAtlasSource.new()
	source.texture=tile.texture
	source.resource_name=tile.name
	source.texture_region_size=EIGHT
	source.create_tile(ZERO)
	tile.id+=(liquidCount*4)
	#0 is a solid, 1 is a fluid, everything else is nothing
	if tile.solid==0:
		source.set("0:0/0/physics_layer_0/polygon_0/points",TileShapes[tile.collision])
	else:if tile.solid==1:
		source.set("0:0/0/physics_layer_1/polygon_0/points",TileShapes[tile.collision])
		source.set("0:0/0/custom_data_0",true)
		source.set("0:0/0/custom_data_1",true)
		source.set("0:0/0/custom_data_2",true)
		source.set("0:0/0/material",liquidShader)
		if fluidRun:
			for biome in world.biomeList:biome.addFluidOffset(tile.id)
			createFluid(tile)
			liquidCount+=1
	
	return source
#creates the liquid states from main texture
func createFluid(tile):
	var id=tile.id+1
	var i=0
	while i<4:
		var data=tile.duplicate()
		data.texture=makeFluidTexture(data.texture,i)
		data.id+=i
		data.collision=i
		fluidTiles[id+i-int(i==0)]=data
		i+=1
#creates texture for the liquid
func makeFluidTexture(tex:CompressedTexture2D,index):
	var out=tex.get_image()
	out.convert(Image.FORMAT_RGBA8)
	if index==0:out.rotate_90(CLOCKWISE)
	var replacement=PackedByteArray()
	replacement.resize(64*index)
	var newData=out.get_data()
	newData=replacement+newData.slice(64*index)
	out.create_from_data(8,8,false,Image.FORMAT_RGBA8,newData)
	
	
	
	
	var nTex=ImageTexture.new()
	nTex.set_image(out)
	
	return nTex
