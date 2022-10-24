#console commands are stored here

#lists the commands
func help(_input):
	var out=get_method_list().reduce(func(a="",command=""):return "%s\n%s"%[a,command.name])
	out=out.split("is_queued_for_deletion\n")[1]
	return out
#gives player n of item id
func give(inputs):
	if len(inputs)<1:return "[color=#f00]give requires ID QUANTITY(optional)[/color]"
	var quantity=1
	if len(inputs)>1:quantity=inputs[1].to_int()
	if quantity<1:return "[color=#f00]Quantity must be greater than 0[/color]"
	var itemID=inputs[0].to_int()
	var fail="[color=#f00]%s is not a valid item id[/color]"%inputs[0]
	var item=null
	if str(itemID)!=inputs[0]:
		itemID=inputs[0]
		if !world.itemManager.hasItem(itemID):return fail
		item=world.itemManager.getItemData(itemID)
	else:item=world.itemManager.getItemById(itemID)
	if item.name=="NONE":return fail
	item.quantity=quantity
	world.inventory.storeItem(
		item
	)
	return "gave player %s %s"%[str(quantity),item.name]
#gets nearest point for the biome you search
func findbiome(inputs):
	if len(inputs)<1:return "[color=#f00]findbiome requires BIOMENAME[/color]"
	var check=0
	var playerPos=int(world.player.global_position.x/8)
	while check <2000:
		if world.chunkFiller.getBiomeCell(playerPos+check).biomeName.replace(" ","").to_lower()==inputs[0].to_lower():
			break
		if world.chunkFiller.getBiomeCell(playerPos-check).biomeName.replace(" ","").to_lower()==inputs[0].to_lower():
			check*=-1
			break
		check+=1
	if check!=2000:
		return "%s found %s to the %s"%[inputs[0],str(abs(check)),"right" if sign(check) else "left"]
	return "Could not find biome %s within 2000 blocks"%inputs[0]

#big boom
func bigboom(_inputs):
	world.miscFunctions.explode(world.player.global_position,32)
	return "exit console to explode"
