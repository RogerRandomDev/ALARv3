extends Node

const terrainNoise0=preload("res://world/noise/terrainNoise0.tres")



func buildChunkData(chunkPos):
	var out =[[],[]]
	var TLcorner=chunkPos*world.chunkSize
	for x in world.chunkSize:for y in world.chunkSize:
		var cellID=[-1,-1]
		#gets the terrainheight base value from terrainNoise0
		var tH=terrainNoise0.get_noise_1d(TLcorner.x+x)
		if(tH*world.groundLevel<TLcorner.y+y):cellID[0]=0
		var atlasPos=Vector2i(1,1)
		if cellID[0]> -1:out[0].append([Vector2i(x,y),atlasPos,cellID[0]])
		if cellID[1]> -1:out[0].append([Vector2i(x,y),atlasPos,cellID[0]])
	return out
