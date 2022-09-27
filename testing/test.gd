extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	world.root=self
	world.chunkHolder=self
	var playerInventory=load("res://Inventory/inventoryMenu.tscn").instantiate()
	add_child(playerInventory)
	world.itemActions.mineTex=$Sprite2d
