extends Node
#none is for empty objects
var itemData={"NONE":{"name":"NONE","gameID":-100000}}

# Called when the node enters the scene tree for the first time.
func _ready():
	buildCSV()
	


#builds the data set from the csv file
func buildCSV():
	var file=File.new()
	file.open("res://itemData/DataSheet.csv",File.READ)
	var keys=file.get_csv_line()
	while true:
		var line=file.get_csv_line()
		if(len(line)==1):break
		var _set=buildItem(keys,line)
		itemData[line[0].replace(" ","")]=_set
#builds the item format
func buildItem(keys,line,modItem=""):
	if line[3]=="":line[3]="place"
	var _set={
		keys[0]:line[0],
		keys[1]:line[1].to_int(),
		keys[2]:line[2].to_int(),
		keys[3]:line[3],
		keys[4]:line[4],
		keys[5]:line[5],
		"location":line[6].to_int(),
		"solid":line[7].to_int(),
		"collision":0,
		"gameID":len(itemData)
	}
	if modItem:_set.texture=world.loadModItemTexture(_set,modItem)
	else:_set.texture=world.loadItemTexture(_set)
	return _set

func compressToStorage(itemDat):
	itemDat.id=itemDat.gameID
	return [
		max(itemDat.id,0)%256,
		int((itemDat.id-255)/256),
		itemDat.quantity
		
	]

func getItemTexture(itemName):
	return itemData[itemName.replace(" ","")].texture

func canSmelt(itemName):
	return itemName!="NONE"&&itemData[itemName].SmeltTo!=""
func getDrop(itemName):
	itemName=itemName.replace(" ","")
	if(itemData[itemName].BreakTo==""):return itemName
	return itemData[itemName].BreakTo

func hasItem(itemName):
	return itemData.keys().has(itemName)

func getItemData(itemName):
	return itemData[itemName.replace(" ","")].duplicate()

#gets item from index
func getItemById(id):
	if itemData.size()>id:return itemData.values()[id]
	return -1
#gets name of the item from index
func getItemName(id):
	if itemData.size()>id:
		return itemData.values()[id].name
	return "NONE"
#finds item by id
func findItem(itemName)->int:
	return itemData.keys().find(itemName)
