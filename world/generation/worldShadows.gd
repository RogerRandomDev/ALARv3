extends Node

var tex=ImageTexture.new()
var img=Image.new()
var sprite=Sprite2D.new()
func _ready():
	img.create((world.renderDistance*2+1)*16,(world.renderDistance*2+1)*16,false,Image.FORMAT_RGBA8)
	tex.create_from_image(img)
	sprite.scale=Vector2i(8,8);sprite.centered=false
	
	sprite.material=preload("res://world/resources/shadowMat.tres")
	sprite.top_level=true;sprite.z_index=100
	world.chunkHolder.add_child(sprite)
	


func loadShadows(data,tlcorner):
	var offsetDraw= Vector2i(world.renderDistance,world.renderDistance)-tlcorner
	sprite.global_position=(tlcorner-Vector2i(world.renderDistance,world.renderDistance))*8*16
	img.fill(Color(0,0,0,1))
	for chunk in data.keys():
		var pos=chunk+offsetDraw
		
		var fill=data[chunk].get_used_cells(0)
		
		for cell in fill:
			if(cell.x+pos.x*16<0||cell.x+pos.x*16>=(world.renderDistance*2+1)*16||cell.y+pos.y*16<0||cell.y+pos.y*16>=(world.renderDistance*2+1)*16):continue
			img.set_pixelv(cell+(pos*16),Color8(0,0,0,0))
	fillImage()
func fillImage():
	tex.set_image(img)
	sprite.texture=tex;
