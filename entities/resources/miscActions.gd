extends Node
const explosionFX=preload("res://entities/Explosives/explosionEffect/explosionAnimation.tscn")
func fireBomb(from,to,radius):
	var direction=from.angle_to_point(to)
	var bomb=itemBomb2D.new()
	bomb.explosionRadius=radius
	bomb.global_position=from
	bomb.body.linear_velocity=Vector2(min((from-to).length_squared(),384),0).rotated(direction)
	world.root.call_deferred('add_child',bomb)
	return bomb

#explodes the area in a radius
func explode(global_pos,explosionRadius,removeTiles=[],showFx=true):
	#if it's empty, fills it with a default explosion
	
	if removeTiles==[]:for x in range(-explosionRadius,explosionRadius):for y in range(-explosionRadius,explosionRadius):
		if(Geometry2D.is_point_in_circle(Vector2(x,y),Vector2.ZERO,explosionRadius)):removeTiles.append(Vector2i(x,y))
	
	var _center=world.mapGen.globalToCell(global_pos)
	var outSide={}
	for tile in removeTiles:
		var c=world.mapGen.globalToCell(global_pos+Vector2(tile*world.tileSize))
		
		c[0].x=c[0].x%16;c[0].y=c[0].y%16;
		c[0].x+=int(c[0].x<0)*16;c[0].y+=int(c[0].y<0)*16
		if world.mapGen.loadedChunks.has(c[1]):
			#makes sure you can explode the given cell
			if !world.mapGen.loadedChunks[c[1]].canExplode(c[0]):continue
			world.mapGen.loadedChunks[c[1]].explodeCell(c[0])
			
			continue
		if !outSide.has(c[1]):outSide[c[1]]=[]
		outSide[c[1]].append_array([c[0],-1])
	#fills in unloaded chunks
	for chunk in outSide:
		world.mapGen.modifyUnloaded.call_deferred(chunk,outSide[chunk])
	if showFx:triggerExplosionFx(global_pos,explosionRadius)
#explosion fx
func triggerExplosionFx(global_pos,explosionRadius):
	var fx=explosionFX.instantiate()
	fx.scale*=(explosionRadius/3)
	world.root.add_child(fx)
	fx.global_position=global_pos



#math to get distance to a line
func distToLine(lineNormal,pos):
	#gets the line angle as a slope form
	var line = lineNormal.dot(pos)
	return abs(line)
