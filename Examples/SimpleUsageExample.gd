# SimpleUsageExample.gd - 简单使用示例
# 演示如何在你的游戏中使用UniversalSaveSystem

extends Node

# 引用保存系统（可以是场景中的节点或单例）
@onready var save_system: UniversalSaveSystem

func _ready():
	# 方法1：如果作为场景节点
	save_system = get_node("UniversalSaveSystem")
	
	# 方法2：如果作为单例（在项目设置中添加AutoLoad）
	# save_system = UniversalSaveSystem
	
	# 可选：自定义配置路径
	save_system.SetConfigPath("res://your_game/save_config.json")
	save_system.SetSaveFilePath("user://your_game_save.tres")

func _input(event):
	if event.is_action_pressed("save_game"):
		SaveGame()
	elif event.is_action_pressed("load_game"):
		LoadGame()

# 保存游戏
func SaveGame():
	print("正在保存游戏...")
	
	if save_system.Save():
		# 保存成功
		ShowMessage("游戏保存成功!")
		# 可以在这里添加保存成功的UI提示
	else:
		# 保存失败
		ShowMessage("游戏保存失败!")
		# 可以在这里添加错误处理

# 加载游戏
func LoadGame():
	print("正在加载游戏...")
	
	if save_system.Load():
		# 加载成功
		ShowMessage("游戏加载成功!")
		# 可以在这里添加加载成功后的处理
	else:
		# 加载失败
		ShowMessage("游戏加载失败!")
		# 可以在这里添加错误处理

# 显示消息（替换为你的UI系统）
func ShowMessage(message: String):
	print(message)
	# 在这里添加你的UI提示代码