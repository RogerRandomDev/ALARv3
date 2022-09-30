extends Node2D


func _ready():
	world.player=self
	world.root=self
	world.chunkHolder=self
	var data=world.chunkFiller.buildChunkData(Vector2i(1,1),false)[0]
	var myGeom=PackedVector2Array()
	for cell in len(data):
		if data[cell]>0:
			var addCell=Vector2(cell%16,int(cell/16))
			
			myGeom=Geometry2D.merge_polygons(myGeom,
			PackedVector2Array([
					addCell,
					Vector2(8,0)+addCell,
					Vector2(8,8)+addCell,
					Vector2(0,8)+addCell
					]))
	var polygon=Polygon2D.new()
	add_child(polygon)
	print(myGeom)
	polygon.polygon=myGeom
