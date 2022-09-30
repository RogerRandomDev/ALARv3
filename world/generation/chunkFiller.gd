extends Node

const terrainNoise0=preload("res://world/noise/terrainNoise0.tres")
const underTerrainNoise0=preload("res://world/noise/terrainNoise1.tres")
const tempNoise=preload("res://world/noise/BiomeNoise0.tres")
const humidNoise=preload("res://world/noise/BiomeNoise2.tres")
const heightNoise=preload("res://world/noise/BiomeNoise1.tres")
const caveNoise0=preload("res://world/noise/caveNoise0.tres")
const caveNoise1=preload("res://world/noise/caveNoise1.tres")
const plantNoise0=preload("res://world/noise/plantNoise0.tres")
const plantNoise1=preload("res://world/noise/plantNoise1.tres")





func caveNoise2D(x,y):
	var a      : float = (caveNoise0.get_noise_2d(x, y) + 1.0) / 2.0
	var b      : float = (caveNoise1.get_noise_2d(x, y) + 1.0) / 2.0
	var border : float = 0.77
	var persistence:float=0.5
	return(float(
		a >= (persistence) and
		b >= (1.5 - border)      and
		b <= (-2.0 * border / (-2))
	))
#get biomeCell 
#put the noise straight into the average calculation
#it saves some ram from a variable this way
func getBiomeCell(x):
	var curBiome=[null,10000000000000]
	var height=heightNoise.get_noise_1d(x)
	var humid=humidNoise.get_noise_1d(x)
	var temp=tempNoise.get_noise_1d(x)
	for biome in world.biomeList:
		#average % off from the desired value for the given biome
		var aveOff=(abs((biome.Temperature-temp)/biome.Temperature)+
		abs((biome.Humidity-humid)/biome.Humidity)+
		abs((biome.Depth+height)/biome.Depth)
		)/3
		if(curBiome[1]>aveOff):curBiome=[biome,aveOff]
	return curBiome[0]
#gets the biome for a given tile
#efficiency of this bit has been greatly improved
#if you face any problems with it being slow, check the above part
func getBiome(tilePos):
	
	
	#i dont bother looping, since it is a bit more taxing
	#so i just used a new function up top for this
	var nearBiomes=[
	getBiomeCell(-3+tilePos.x),
	getBiomeCell(tilePos.x),
	getBiomeCell(3+tilePos.x)]
	#slowly, this becomes more and more efficient
	var modifiers=[0,0];
	#removed loop since i only need to grab a small number of values
	modifiers[0]=(nearBiomes[0].groundVariance+nearBiomes[1].groundVariance+nearBiomes[2].groundVariance)/3
	modifiers[1]=(nearBiomes[0].groundOffset+nearBiomes[1].groundOffset+nearBiomes[2].groundOffset)/3
	
	return [nearBiomes,modifiers]


#builds the chunk

func buildChunkData(chunkPos,stored=true):
	var dat=null
	if stored:
		dat=world.dataStore.getChunk(chunkPos)
	if dat!=null:return dat
	
	var out =[[],[]]
	out[0]=world.dataStore.emptyChunk
	var TLcorner=chunkPos*world.chunkSize
	for x in world.chunkSize:
		#only horizontal based checks
		var biomes=getBiome(TLcorner+Vector2i(x,0))
		var biomeCells=biomes[0][1].baseTiles
		var groundVariance=biomes[1][0]
		var groundOffset=biomes[1][1]
		var canGrowPlant=biomes[0][1].growPlants&&plantNoise0.get_noise_1d(x+TLcorner.x)>biomes[0][1].plantCull
		var plantSize=int(
			abs(plantNoise1.get_noise_1d(x+TLcorner.x)*(biomes[0][1].plantSizeMax-biomes[0][1].plantSizeMin))+
			biomes[0][1].plantSizeMin)
		var tH= - abs(terrainNoise0.get_noise_1d(TLcorner.x+x))
		var groundLevel=tH*(world.groundLevel*groundVariance)+groundOffset
		var ores=biomes[0][1].oreTiles
		var oreLen=len(ores)
		#per cell in here
		for y in world.chunkSize:
			var cellID=[-1,-1]
			#bottom of the world here
			if(chunkPos.y>40):
				out[0][x+y*16]=1;continue
			#gets the terrainheight base value from terrainNoise0
			
			#basic grass,dirt.stone
			#grass
			cellID[0]=(int(groundLevel<TLcorner.y+y)*(biomeCells[0]-cellID[0])+cellID[0])
			#dirt
			cellID[0]=(int(groundLevel<TLcorner.y+y-1+int(canGrowPlant))*(biomeCells[1]-cellID[0])+cellID[0])
			#middle layer
			cellID[0]=(int(groundLevel<TLcorner.y+y-3)*(biomeCells[2]-cellID[0])+cellID[0])
			#stone
			cellID[0]=(int(groundLevel<TLcorner.y+y-12)*(biomeCells[3]-cellID[0])+cellID[0])
			#deals with water
			if(
				TLcorner.y+y>0&&
				tH*(world.groundLevel*groundVariance)+groundOffset>TLcorner.y+y&&
				cellID[0]==-1):
				cellID[0]=8
			#handles caves
			if (caveNoise2D(TLcorner.x+x,TLcorner.y+y)>0&&groundLevel<TLcorner.y+y):cellID[0]=-1
			
			
			#handles plant generation
			if(canGrowPlant&&cellID[0]==-1&&
			(int(groundLevel<TLcorner.y+y+plantSize))&&
			(int(groundLevel>TLcorner.y+y))
			):
				#regular handler for plants
				cellID[0]=biomes[0][1].plantTiles[(int(groundLevel>TLcorner.y+y+int(plantSize*0.75)))]
			if(int(groundLevel)==TLcorner.y+y):canGrowPlant=cellID[0]!=-1&&canGrowPlant
			
			out[0][x+y*16]=cellID[0]
			

	#		if cellID[1]> -1:out[0].append([Vector2i(x,y),atlasPos,cellID[0]])
	return out
