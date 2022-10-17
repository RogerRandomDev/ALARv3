extends CanvasLayer


@onready var craftingMenu=$PanelContainer/Craft
@onready var modMenu=$PanelContainer/Mod


func _ready():
	process_mode=Node.PROCESS_MODE_ALWAYS
	updateRecipeList.call_deferred()


func updateRecipeList():
	var list=craftingMenu.get_node("RecipeList")
	list.clear()
	var recipeList=world.craftingManager.getAllCraftableRecipes()
	for recipe in recipeList:
		list.add_item(recipe,world.findItemTexture(world.itemManager.itemData[recipe.replace(" ","")].name))

#loads recipe information to the side for crafting
func loadRecipe(recipeID):
	var list=craftingMenu.get_node("RecipeList")
	var recipeName=list.get_item_text(recipeID)
	var recipeData=world.craftingManager.convertToRecipe(world.craftingManager.get_recipe(recipeName))
	craftingMenu.get_node("RecipeInfo/recipeName").text=recipeName
	craftingMenu.get_node("RecipeInfo/recipeQuantity").text="Manufactures: %s"%str(recipeData[0])
	var recipeIn=craftingMenu.get_node("RecipeInfo/recipeInputs")
	recipeIn.clear()
	for needs in (len(recipeData)-1) /2.0:
		recipeIn.add_item(
			"Requires: %s"%str(recipeData[needs*2+2]),
			world.findItemTexture(world.itemManager.itemData[recipeData[needs*2+1]].name)
		)
	

var cur_particles=[]
#used to start a timer and call the craftRecipe
func manufactureSelectedItem():
	$Timer.start()
	craftRecipe()
#makes the current active recipe
func craftRecipe():
	var list=craftingMenu.get_node("RecipeList")
	var selected=list.get_selected_items()
	if len(selected)==0:return
	var craftingItem=list.get_item_text(selected[0])
	var canCraft=world.craftingManager.canMakeRecipe(craftingItem)
	if !canCraft||!world.inventory.hasRoomFor(craftingItem,world.craftingManager.get_recipe(craftingItem)[0]):return
	var output=world.itemManager.getItemData(craftingItem)
	output.quantity=world.craftingManager.get_recipe(craftingItem)[0]
	world.inventory.storeItem(output)
	world.craftingManager.consumeCraft(craftingItem)
	
	var particle=$Particles/GpuParticles2d.duplicate()
	particle.original=false
	$Particles.add_child(particle)
	particle.emitting=true
	cur_particles.append(particle)
		
#loops the craft as long as repeatPress has timed out
func _physics_process(_delta):
	if !visible:
		for child in $Particles.get_children():child.emitting=false
		return
	
	if Input.is_action_pressed("m1")&&repeatCraft:craftRecipe()
	else:if repeatCraft:
		repeatCraft=false
		$Timer.stop()
	
var repeatCraft=false

func repeatPressTimeout():
	repeatCraft=true
