extends Node

var oreNoise0=preload("res://world/noise/oreNoise0.tres")

const oreList=[
]

#builds the ore list
func _ready():
	addOre(15,[0,40],["Desert","DesertMountains","Desert dLake"],true)
	addOre(16,[0,40],[],false)
	addOre(17,[30,40],[],false)
	addOre(18,[32,40],[],false)
	addOre(19,[10,40],[],false)
	addOre(20,[2,40],[],false)


func addOre(id,depthRange,biomeList,includeOrExclude):
	oreList.append(
		{
			"id":id,
			"range":depthRange,
			"biomes":biomeList,
			"inclusive":includeOrExclude
		})


func getOre(x,y,curBiome,default):
	var newList=oreList.filter(
		func(ore):return (
			ore.range[0]<=int(y/16)&&
			ore.range[1]>=int(y/16)&&
			(ore.inclusive&&ore.biomes.has(curBiome)||
			!ore.inclusive&&!ore.biomes.has(curBiome))
			)
		)
	var length=len(newList);
	if(length<1):return default
	
	return newList[int(abs(oreNoise0.get_noise_2d(x,y)*length)-1)].id
