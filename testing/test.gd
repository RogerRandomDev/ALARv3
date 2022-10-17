extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	world.root=self
	world.chunkHolder=self
	world.entityHolder=$entityNode
	world.itemActions.mineTex=$Sprite2d
	world.loadItems(world.entityHolder)
	world.worldShadows.loadScene()
	world.inGame=true
	world.fileManager.loadWorld(world.saveName)
