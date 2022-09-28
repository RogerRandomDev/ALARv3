extends Node
const explosionFX=preload("res://entities/Explosives/explosionEffect/explosionAnimation.tscn")
func fireBomb(from,to,radius):
	var direction=from.angle_to_point(to)
	var bomb=itemBomb2D.new()
	bomb.explosionRadius=radius
	bomb.global_position=from
	bomb.body.linear_velocity=Vector2(min((from-to).length()*8,384),0).rotated(direction)
	world.root.call_deferred('add_child',bomb)
	return bomb

#explodes the area in a radius
func explode(global_pos,explosionRadius):
	var removeTiles=[]
	for x in range(-explosionRadius,explosionRadius):for y in range(-explosionRadius,explosionRadius):
		if(Vector2(x,y).distance_squared_to(Vector2.ZERO)<(explosionRadius)**2):removeTiles.append(Vector2i(x,y))
	var center=world.mapGen.globalToCell(global_pos)
	var outSide={}
	for tile in removeTiles:
		var c=world.mapGen.globalToCell(global_pos+Vector2(tile*world.tileSize))

		c[0].x=c[0].x%16;c[0].y=c[0].y%16;
		c[0].x+=int(c[0].x<0)*16;c[0].y+=int(c[0].y<0)*16
		if world.mapGen.loadedChunks.has(c[1]):
			world.mapGen.loadedChunks[c[1]].explodeCell(c[0])
			continue
		if !outSide.has(c[1]):outSide[c[1]]=[]
		outSide[c[1]].append_array([c[0],-1])
		
	for chunk in outSide:
		world.mapGen.modifyUnloaded(chunk,outSide[chunk])
	triggerExplosionFx(global_pos,explosionRadius)
#explosion fx
func triggerExplosionFx(global_pos,explosionRadius):
	var fx=explosionFX.instantiate()
	fx.scale*=(explosionRadius/3)
	world.root.add_child(fx)
	fx.global_position=global_pos
