extends Node
#none is for empty objects
var itemData={"NONE":{"name":"NONE"}}

# Called when the node enters the scene tree for the first time.
func _ready():
	buildCSV()
	ModManager.buildTileSet(
		itemData.values().filter(
			func(item):return item.name!="NONE"&&item.actionType=="place"
		)
	)



#builds the data set from the csv file
func buildCSV():
	var file=File.new()
	file.open("res://itemData/DataSheet.csv",File.READ)
	var keys=file.get_csv_line()
	while true:
		var line=file.get_csv_line()
		if(len(line)==1):break
		if line[3]=="":line[3]="place"
		var _set={
			keys[0]:line[0],
			keys[1]:line[1].to_int(),
			keys[2]:line[2].to_int(),
			keys[3]:line[3],
			keys[4]:line[4],
			keys[5]:line[5],
			"location":line[6].to_int(),
			"solid":line[7].to_int()
		}
		_set.texture=world.loadItemTexture(_set)
		itemData[line[0].replace(" ","")]=_set
func compressToStorage(itemDat):
	itemDat.id=itemData.keys().find(itemDat.name)
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


func getItemData(itemName):
	return itemData[itemName.replace(" ","")].duplicate()


#gets name of the item from index
func getItemName(id):
	if itemData.size()>id:return itemData.keys()[id]
	return "NONE"
