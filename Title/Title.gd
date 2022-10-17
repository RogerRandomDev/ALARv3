extends Control

@onready var worldsMenu=$Launch/Back/V/Middle/WorldActions
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	world.playerInventory.visible=false
	call_deferred('loadSaveList')
	

#loads saves from fileManager
func loadSaveList():
	var list=worldsMenu.get_node("WorldList/Worlds")
	for save in world.fileManager.allSaves:
		list.add_item(save[0])


func menu_back():
	$Launch.visible=false
	$Main.visible=true


func launch_pressed():
	$Launch.visible=true
	$Main.visible=false


func createWorld():
	var worldName=$Launch/Back/V/Middle/WorldActions/CreateWorld/newWorldName.text
	var worldSeed=$Launch/Back/V/Middle/WorldActions/CreateWorld/newWorldSeed.text
	if worldSeed=="":worldSeed=str(randi()).substr(0,18)
	var can=world.fileManager.createNewSave(worldName,worldSeed)
	if !can:
		print("Name already in use")
		return
	worldsMenu.get_node("WorldList/Worlds").add_item(worldName)
	cancelCreate()


func cancelCreate():
	$Launch/Back/V/Middle/WorldActions/CreateWorld.visible=false
	$Launch/Back/V/Middle/WorldActions/WorldList.visible=true


func beginCreate():
	$Launch/Back/V/Middle/WorldActions/CreateWorld.visible=true
	$Launch/Back/V/Middle/WorldActions/WorldList.visible=false

#removes given world save
func unlink_world():
	var list=worldsMenu.get_node("WorldList/Worlds")
	var selected=list.get_selected_items()
	if len(selected)==0:return
	var worldName=list.get_item_text(selected[0])
	world.fileManager.remove_recursive("user://Saves/%s"%worldName)
	list.remove_item(selected[0])

func connectWorld():
	var list=worldsMenu.get_node("WorldList/Worlds")
	var selected=list.get_selected_items()
	if len(selected)==0:return
	var worldName=list.get_item_text(selected[0])
	world.saveName=worldName
	world.chunkFiller.updateSeed(
		world.fileManager.getWorldData(worldName)[1]
	)
	
	get_tree().change_scene_to_file("res://testing/test.tscn")


func worldSelected(index):
	var list=worldsMenu.get_node("WorldList/Worlds")
	var worldName=list.get_item_text(index)
	var aboutWorld=$Launch/Back/V/TopRow/AboutWorld/worldData
	var worldData=world.fileManager.getWorldData(worldName)
	aboutWorld.text="World Name:\n   %s\nLast Played:\n   %s\nSeed:\n   %s"%[
		worldData[0],
		worldData[2],
		str(worldData[1])
	]
	
