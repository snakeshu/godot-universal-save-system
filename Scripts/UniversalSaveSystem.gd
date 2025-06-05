# UniversalSaveSystem.gd - 通用保存系统
# 版本: 1.0
# 作者: Your Name
# 许可: MIT License
# 
# 使用方法：
# 1. 复制此文件到你的项目
# 2. 创建SaveData资源类
# 3. 创建save_config.json配置文件
# 4. 在需要的地方调用Save()和Load()方法

extends Node
class_name UniversalSaveSystem

# 可配置的参数
@export var config_file_path: String = "res://save_config.json"
@export var save_file_path: String = "user://save_game.tres"
@export var save_data_class_name: String = "SaveData"

var save_config: Dictionary = {}
var save_data_class: Script

func _ready():
	LoadSaveConfig()
	LoadSaveDataClass()

# 加载保存配置
func LoadSaveConfig():
	if not FileAccess.file_exists(config_file_path):
		print("保存配置文件不存在: ", config_file_path)
		return
		
	var config_file = FileAccess.open(config_file_path, FileAccess.READ)
	if config_file:
		var json_string = config_file.get_as_text()
		config_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			save_config = json.data
			print("成功加载保存配置, 版本: ", save_config.get("save_version", "未知"))
		else:
			print("JSON解析失败: ", json.get_error_message())
	else:
		print("无法打开配置文件: ", config_file_path)

# 加载保存数据类
func LoadSaveDataClass():
	save_data_class = load("res://" + save_data_class_name + ".gd")
	if not save_data_class:
		print("警告: 无法加载保存数据类: ", save_data_class_name)

# 保存函数 - 基于配置
func Save() -> bool:
	print("=== 开始保存游戏 ===")
	
	if save_config.is_empty():
		print("配置未加载，无法保存")
		return false
	
	var save_data = {}
	
	# 遍历配置中的对象类型
	for object_type in save_config.objects.keys():
		var object_config = save_config.objects[object_type]
		print("处理对象类型: ", object_type)
		
		var nodes = GetNodesFromConfig(object_config)
		print("找到 ", nodes.size(), " 个 ", object_type, " 节点")
		
		# 保存每个节点的数据
		for i in range(nodes.size()):
			var node = nodes[i]
			var node_data = ExtractNodeData(node, object_config)
			
			# 存储数据
			var key = object_type
			if object_config.get("is_dynamic", false):
				key = object_type + "_" + str(i)
			
			save_data[key] = node_data
			save_data[key]["_object_type"] = object_type
			
			if object_config.has("scene_path"):
				save_data[key]["_scene_path"] = object_config.scene_path
	
	print("保存的数据: ", save_data.keys())
	
	# 创建保存数据对象
	var save_data_instance
	if save_data_class:
		save_data_instance = save_data_class.new()
		if save_data_instance.has_method("set_save_data"):
			save_data_instance.set_save_data(save_data)
		elif "all_objects_data" in save_data_instance:
			save_data_instance.all_objects_data = save_data
	else:
		# 如果没有指定类，创建一个通用的Resource
		save_data_instance = Resource.new()
		save_data_instance.set_meta("save_data", save_data)
	
	# 保存到文件
	var result = ResourceSaver.save(save_data_instance, save_file_path)
	if result == OK:
		print("游戏保存成功!")
		return true
	else:
		print("保存失败，错误代码: ", result)
		return false

# 加载函数 - 基于配置
func Load() -> bool:
	print("=== 开始加载游戏 ===")
	
	if save_config.is_empty():
		print("配置未加载，无法加载")
		return false
		
	if not ResourceLoader.exists(save_file_path):
		print("保存文件不存在: ", save_file_path)
		return false
		
	var save_data_instance = ResourceLoader.load(save_file_path)
	if not save_data_instance:
		print("加载保存文件失败")
		return false
	
	# 提取保存数据
	var save_data = {}
	if save_data_instance.has_method("get_save_data"):
		save_data = save_data_instance.get_save_data()
	elif "all_objects_data" in save_data_instance:
		save_data = save_data_instance.all_objects_data
	elif save_data_instance.has_meta("save_data"):
		save_data = save_data_instance.get_meta("save_data")
	
	print("加载的数据: ", save_data.keys())
	
	# 清理动态对象
	CleanupDynamicObjects()
	await get_tree().process_frame
	
	# 恢复对象
	for data_key in save_data.keys():
		var object_data = save_data[data_key]
		var object_type = object_data.get("_object_type", "")
		
		if not save_config.objects.has(object_type):
			continue
			
		var object_config = save_config.objects[object_type]
		
		if object_config.get("is_dynamic", false):
			RestoreDynamicObject(object_config, object_data)
		else:
			RestoreStaticObject(object_config, object_data)
	
	print("游戏加载完成!")
	return true

# 根据配置获取节点
func GetNodesFromConfig(object_config: Dictionary) -> Array:
	var nodes = []
	if object_config.has("node_group"):
		nodes = get_tree().get_nodes_in_group(object_config.node_group)
		
		# 如果同时指定了node_name，进一步筛选
		if object_config.has("node_name"):
			var filtered_nodes = []
			for node in nodes:
				if node.name == object_config.node_name:
					filtered_nodes.append(node)
			nodes = filtered_nodes
	elif object_config.has("node_name"):
		# 在整个场景树中查找指定名称的节点
		var found_nodes = []
		SearchNodesByName(get_tree().current_scene, object_config.node_name, found_nodes)
		nodes = found_nodes
	
	return nodes

# 递归搜索指定名称的节点
func SearchNodesByName(parent: Node, target_name: String, result: Array):
	if parent.name == target_name:
		result.append(parent)
	
	for child in parent.get_children():
		SearchNodesByName(child, target_name, result)

# 提取节点数据
func ExtractNodeData(node: Node, object_config: Dictionary) -> Dictionary:
	var node_data = {}
	
	for property_config in object_config.properties:
		var value = GetPropertyValue(node, property_config.path)
		node_data[property_config.name] = value
	
	return node_data

# 获取节点属性值
func GetPropertyValue(node: Node, property_path: String):
	var parts = property_path.split(".")
	var current = node
	
	for part in parts:
		if current == null:
			return null
			
		if part.contains("("):
			# 方法调用
			var method_name = part.split("(")[0]
			if part.contains(")"):
				var args_str = part.split("(")[1].split(")")[0]
				if args_str.is_empty():
					current = current.call(method_name)
				else:
					# 简单处理数字参数
					var args = [int(args_str)] if args_str.is_valid_int() else [args_str]
					current = current.call(method_name, args[0])
			else:
				current = current.call(method_name)
		else:
			# 属性访问
			current = current.get(part)
	
	return current

# 设置节点属性值
func SetPropertyValue(node: Node, property_path: String, value):
	var parts = property_path.split(".")
	var current = node
	
	# 导航到最后一个对象
	for i in range(parts.size() - 1):
		var part = parts[i]
		if current == null:
			return
			
		if part.contains("("):
			var method_name = part.split("(")[0]
			if part.contains(")"):
				var args_str = part.split("(")[1].split(")")[0]
				if args_str.is_empty():
					current = current.call(method_name)
				else:
					var args = [int(args_str)] if args_str.is_valid_int() else [args_str]
					current = current.call(method_name, args[0])
		else:
			current = current.get(part)
	
	# 设置最终属性
	if current != null:
		var final_property = parts[-1]
		current.set(final_property, value)

# 清理动态对象
func CleanupDynamicObjects():
	for object_type in save_config.objects.keys():
		var object_config = save_config.objects[object_type]
		if object_config.get("is_dynamic", false):
			var nodes = GetNodesFromConfig(object_config)
			for node in nodes:
				node.queue_free()

# 恢复动态对象
func RestoreDynamicObject(object_config: Dictionary, object_data: Dictionary):
	var scene_path = object_data.get("_scene_path", "")
	if scene_path.is_empty():
		return
	
	var scene_resource = load(scene_path) as PackedScene
	if not scene_resource:
		print("无法加载场景: ", scene_path)
		return
	
	var new_object = scene_resource.instantiate()
	get_tree().current_scene.add_child(new_object)
	
	await get_tree().process_frame
	
	# 应用属性
	for property_config in object_config.properties:
		var property_name = property_config.name
		if object_data.has(property_name):
			SetPropertyValue(new_object, property_config.path, object_data[property_name])

# 恢复静态对象
func RestoreStaticObject(object_config: Dictionary, object_data: Dictionary):
	var nodes = GetNodesFromConfig(object_config)
	
	if nodes.is_empty():
		print("找不到要恢复的静态对象: ", object_config)
		return
	
	var target_node = nodes[0]
	
	# 应用属性
	for property_config in object_config.properties:
		var property_name = property_config.name
		if object_data.has(property_name):
			SetPropertyValue(target_node, property_config.path, object_data[property_name])

# 工具方法：设置配置文件路径
func SetConfigPath(path: String):
	config_file_path = path

# 工具方法：设置保存文件路径
func SetSaveFilePath(path: String):
	save_file_path = path

# 工具方法：设置保存数据类名
func SetSaveDataClassName(class_name: String):
	save_data_class_name = class_name