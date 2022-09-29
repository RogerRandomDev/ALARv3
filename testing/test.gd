extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	world.root=self
	world.chunkHolder=self
	
	world.itemActions.mineTex=$Sprite2d
