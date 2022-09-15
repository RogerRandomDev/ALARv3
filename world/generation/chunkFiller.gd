extends Node

const terrainNoise0=preload("res://world/noise/terrainNoise0.tres")
const underTerrainNoise0=preload("res://world/noise/terrainNoise1.tres")
const tempNoise=preload("res://world/noise/BiomeNoise0.tres")
const humidNoise=preload("res://world/noise/BiomeNoise2.tres")
const heightNoise=preload("res://world/noise/BiomeNoise1.tres")
const caveNoise0=preload("res://world/noise/caveNoise0.tres")
const caveNoise1=preload("res://world/noise/caveNoise1.tres")
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

#gets the biome for a given tile
func getBiome(tilePos):
	
	
	
	var nearBiomes=[]
	for x in range(-6,6,2):
		var curBiome=[null,0]
		var nextBest=[null,0]
		var temp=tempNoise.get_noise_1d(tilePos.x+x)
		var humid=humidNoise.get_noise_1d(tilePos.x+x)
		var height=1-heightNoise.get_noise_1d(tilePos.x+x)
		for biome in world.biomeList:
			#average % off from the desired value for the given biome
			var aveOff=(abs((biome.Temperature-temp)/biome.Temperature)+
			abs((biome.Humidity-humid)/biome.Humidity)+
			abs((biome.Depth-height)/biome.Depth)
			)/3
			if(curBiome[0]==null||curBiome[1]>aveOff):
				nextBest=[curBiome[0],curBiome[1]]
				
				curBiome=[biome,aveOff]
		if nextBest[0]==null:nextBest=curBiome
		nearBiomes.push_back(curBiome[0])
	var modifiers=[0,0]
	for biome in nearBiomes:
		modifiers[0]+=biome.groundVariance
		modifiers[1]+=biome.groundOffset
	modifiers[0]/=6
	modifiers[1]/=6
	return [nearBiomes[2],modifiers]

#builds the chunk
func buildChunkData(chunkPos):
	var out =[[],[]]
	var TLcorner=chunkPos*world.chunkSize
	var atlasPos=Vector2i(0,0)
	for x in world.chunkSize:for y in world.chunkSize:
		var biomes=getBiome(TLcorner+Vector2i(x,y))
		var biome=biomes[0]
		var cellID=[-1,-1]
		var groundVariance=biomes[1][0]
		var groundOffset=biomes[1][1]
		var caveNoise=caveNoise2D(TLcorner.x+x,TLcorner.y+y)
		
		
		#gets the terrainheight base value from terrainNoise0
		var tH= - abs(terrainNoise0.get_noise_1d(TLcorner.x+x))
		#basic grass,dirt.stone
		if(tH*(world.groundLevel*groundVariance)+groundOffset<TLcorner.y+y):
			cellID[0]=biome.baseTiles[0];
			if(tH*(world.groundLevel*groundVariance)+groundOffset<TLcorner.y+y-1):
				cellID[0]=biome.baseTiles[1];
				if(tH*(world.groundLevel*groundVariance)+groundOffset<TLcorner.y+y-3):cellID[0]=biome.baseTiles[2]
		
		#handles caves
		if caveNoise>0:
			cellID[0]=-1
		
		
		if cellID[0]> -1:out[0].append([Vector2i(x,y),cellID[0]])
#		if cellID[1]> -1:out[0].append([Vector2i(x,y),atlasPos,cellID[0]])
		
	return out
