extends Node


static func build():
	var dir=Directory.new()
	dir.make_dir_recursive("user://Mods")
	dir.make_dir_recursive("user://Saves")
	dir.make_dir_recursive("user://ResourcePacks")
