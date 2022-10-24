extends CanvasLayer

var consoleCommands=preload("res://DevTools/consoleCommands.gd").new()
@onready var outBox=$PanelContainer/VBoxContainer/RichTextLabel
func _ready():process_mode=Node.PROCESS_MODE_ALWAYS

func submit_command(new_text):
	var command=new_text.split(" ")
	$PanelContainer/VBoxContainer/LineEdit.text=""
	runCommand(command)


func runCommand(commandData):
	commandData[0]=commandData[0].to_lower()
	if consoleCommands.has_method(commandData[0]):
		outBox.text+="\n"+consoleCommands.call(commandData[0],commandData.slice(1))
	else:outBox.text+="\n%s Is not a Command\nType HELP for command list\n"%commandData[0]


func toggleConsole(open):
	outBox.text=""
	visible=open
	if open:$PanelContainer/VBoxContainer/LineEdit.grab_focus.call_deferred()
	
	get_tree().paused=open

func _input(_event):
	if get_tree().current_scene.name!="gameWorld":return
	if Input.is_action_just_pressed("toggleCommands"):toggleConsole(!visible)
