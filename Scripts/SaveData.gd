# SaveData.gd - 通用保存数据资源
# 版本: 1.0
# 许可: MIT License
# 这是一个可复用的保存数据模板

extends Resource
class_name SaveData

# 通用的保存数据字典
@export var all_objects_data: Dictionary = {}

# 可选：项目特定的数据字段
@export var save_version: String = "1.0"
@export var save_timestamp: String = ""
@export var level_name: String = ""
@export var player_name: String = ""

# 兼容方法
func set_save_data(data: Dictionary):
	all_objects_data = data

func get_save_data() -> Dictionary:
	return all_objects_data

# 保存时自动记录时间戳
func _init():
	save_timestamp = Time.get_datetime_string_from_system()