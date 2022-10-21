extends Node

var tex=ImageTexture.new()
var img=Image.new()
var sprite=null

func _ready():
	img.create((world.renderDistance*2+1)*16,(world.renderDistance*2+1)*16,false,Image.FORMAT_RGBA8)
	tex.create_from_image(img)

func loadScene():
	sprite=Sprite2D.new()
	sprite.scale=Vector2i(8,8);sprite.centered=false
	sprite.material=preload("res://world/resources/shadowMat.tres")
	sprite.top_level=true;sprite.z_index=100
	world.chunkHolder.add_child(sprite)
	sprite.texture=tex

func loadNewTex(dataIN):
	if world==null:return
	
	var nImg=Image.new()
	nImg.create_from_data(112,112,false,Image.FORMAT_RGBA8,dataIN)
	tex.set_image(nImg)
	sprite.set_deferred('global_position',(world.mapGen.centerChunk-Vector2i(
		world.renderDistance,
		world.renderDistance))*128
		)
	img=nImg
	
