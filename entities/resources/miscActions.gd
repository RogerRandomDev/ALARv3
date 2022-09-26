extends Node


func explode(global_pos,explosionRadius):
	var removeTiles=[]
	for x in range(-explosionRadius,explosionRadius):for y in range(-explosionRadius,explosionRadius):
		if(Vector2(x,y).distance_squared_to(Vector2.ZERO)<(explosionRadius)**2):removeTiles.append(Vector2i(x,y))
	var center=world.mapGen.globalToCell(global_pos)
	for tile in removeTiles:
		var c=world.mapGen.globalToCell(global_pos+Vector2(tile*world.tileSize))
		if !world.mapGen.loadedChunks.has(c[1]):continue
		c[0].x=c[0].x%16;c[0].y=c[0].y%16;
		c[0].x+=int(c[0].x<0)*16;c[0].y+=int(c[0].y<0)*16
		world.mapGen.loadedChunks[c[1]].changeCell(c[0],-1)
