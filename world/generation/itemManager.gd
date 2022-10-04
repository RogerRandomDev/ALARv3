extends Node
#none is for empty objects
var itemData={"NONE":{}}
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
		itemData[line[0]]={
			keys[0]:line[0],
			keys[1]:str_to_var(line[1]),
			keys[2]:str_to_var(line[2]),
			keys[3]:line[3],
			keys[4]:line[4],
			keys[5]:line[5]
		}
func compressToStorage(itemData):
	return [
		itemData.quantity,
		itemData.actionRange,
		itemData.Name,
		itemData.actionType,
		itemData.id
	]



func canSmelt(itemName):
	return itemData[itemName].SmeltTo!=""
func getDrop(itemName):
	if(itemData[itemName].BreakTo==""):return itemName
	return itemData[itemName].BreakTo

func getItemData(itemName):
	return itemData[itemName]
