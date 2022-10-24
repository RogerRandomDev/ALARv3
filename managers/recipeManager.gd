extends Node

var recipeData={}
var itemNameTable=[]




#builds the data set from the csv file
func buildCSV():
	var file=File.new()
	file.open("res://itemData/RecipeData.csv",File.READ)
	var _keys=file.get_csv_line()
	while true:
		var line=file.get_csv_line()
		if len(line)<3:break
		var insertData=[str_to_var(line[1])]
		#inserts unknown items into the item table for indexing in recipe data
		for i in (len(itemNameTable)-2)/2.:
			insertData.append_array([
				world.itemManager.findItem(line[i*2+2]),
				line[i*2+3].to_int()
			])
		recipeData[line[0]]=insertData
	

#editing the output from this changes the stored version here
func get_recipe_raw(outputName):return recipeData[outputName]
#returns editable copy without influencing this side
func get_recipe(outputName):return recipeData[outputName].duplicate()

#converts the integer stored into the item string name
func convertToRecipe(recipe):
	for i in len(recipe):
		if((i)%2==0):continue
		recipe[i]=itemNameTable[recipe[i]]
	return recipe
#gets if you can make a recipe
func canMakeRecipe(recipeName):
	var recipeData2=convertToRecipe(get_recipe(recipeName))
	#checks quantity of an item in inventory to the amount needed
	#offsets by 1 so it ignores the first index, being the output quantity
	
	for i in (len(recipeData2)-1)/2.0:if !world.inventory.haveEnough(
		recipeData2[i*2+1],
		recipeData2[i*2+2]
		):return false
	return true


#returns any craftable recipe
func getAllCraftableRecipes():
	return recipeData.keys().filter(func(i):return canMakeRecipe(i))

#consumes from inventory what was needed
#for the given recipe
func consumeCraft(recipeName):
	var recipeData2=convertToRecipe(get_recipe(recipeName))
	for i in (len(recipeData2)-1)/2.0:
		world.inventory.removeItemBy(recipeData2[i*2+1],recipeData2[i*2+2])
