extends Node
#none is for empty objects
var itemData={"NONE":{"name":"NONE"}}

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
		if line[3]=="":line[3]="place"
		var _set={
			keys[0]:line[0],
			keys[1]:str_to_var(line[1]),
			keys[2]:str_to_var(line[2]),
			keys[3]:line[3],
			keys[4]:line[4],
			keys[5]:line[5],
			"location":str_to_var(line[6])
		}
		_set.texture=world.loadItemTexture(_set)
		itemData[line[0].replace(" ","")]=_set
func compressToStorage(itemDat):
	return [
		itemDat.quantity,
		itemDat.actionRange,
		itemData.keys().find(itemDat.name),
		itemDat.actionType,
		itemDat.id,
		itemDat.location
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
	return itemData.keys()[id]
