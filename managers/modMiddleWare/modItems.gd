extends Node


static func loadModItems(modPath):
	var file=File.new()
	file.open("user://Mods/%s/itemSheet.csv"%modPath,File.READ)
	var keys=file.get_csv_line()
	while true:
		var line=file.get_csv_line()
		if(len(line)==1):break
		var _set=world.itemManager.buildItem(keys,line,modPath)
		world.itemManager.itemData[line[0].replace(" ","")]=_set
