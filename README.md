# Godot 通用保存系统 (Universal Save System)

一个基于配置驱动的Godot 4通用保存/加载系统，无需修改现有游戏对象代码，通过JSON配置即可实现强大的保存功能。

## ✨ 特性

- 🚀 **零代码侵入** - 无需修改现有游戏对象
- ⚙️ **配置驱动** - 通过JSON轻松配置保存内容
- 🔧 **灵活的属性访问** - 支持复杂的节点结构和属性路径
- 📦 **动态对象支持** - 自动处理运行时创建/销毁的对象
- 🎯 **即插即用** - 复制文件即可使用
- 🛡️ **类型安全** - 支持多种数据类型
- 📝 **详细日志** - 便于调试和问题排查

## 🚀 快速开始

### 1. 安装

将以下文件复制到你的Godot项目：

```
Scripts/
├── UniversalSaveSystem.gd
└── SaveData.gd
save_config.json (从Examples复制并修改)
```

### 2. 基本设置

#### 方法A：作为场景节点
1. 在主场景添加一个Node节点
2. 附加`UniversalSaveSystem.gd`脚本
3. 在检查器中配置路径

#### 方法B：作为单例
1. 在项目设置 → AutoLoad 中添加`UniversalSaveSystem.gd`
2. 设置名称为`SaveSystem`

### 3. 使用示例

```gdscript
# 保存游戏
if save_system.Save():
    print("保存成功")

# 加载游戏
if save_system.Load():
    print("加载成功")
```

## 📝 配置文件

### 基本配置结构

```json
{
  "save_version": "1.0",
  "objects": {
    "Player": {
      "node_group": "player",
      "node_name": "Player",
      "properties": [
        {
          "name": "position",
          "path": "global_position",
          "type": "Vector2"
        }
      ]
    }
  }
}
```

### 节点查找方式

- **通过组**: `"node_group": "enemies"`
- **通过名称**: `"node_name": "Player"`
- **组+名称**: 同时指定两者进行精确筛选

### 属性路径语法

- **直接属性**: `"health"`
- **子节点属性**: `"get_child(0).flip_h"`
- **命名节点**: `"get_node('Sprite2D').modulate"`
- **方法调用**: `"get_health()"`
- **嵌套访问**: `"stats.max_health"`

### 动态对象配置

```json
{
  "Enemy": {
    "node_group": "enemies",
    "scene_path": "res://Enemy.tscn",
    "is_dynamic": true,
    "properties": [...]
  }
}
```

## 📁 项目结构

```
GodotUniversalSaveSystem/
├── Scripts/
│   ├── UniversalSaveSystem.gd    # 核心保存系统
│   └── SaveData.gd               # 保存数据资源类
├── Examples/
│   ├── save_config.json          # 配置示例
│   └── SimpleUsageExample.gd     # 使用示例
├── Documentation/
│   └── 移植指南.md               # 详细移植指南
└── README.md                     # 本文件
```

## 🔧 高级配置

### 自定义SaveData类

```gdscript
extends Resource
class_name MyGameSaveData

@export var all_objects_data: Dictionary = {}
@export var level_progress: int = 0
@export var game_settings: Dictionary = {}

func set_save_data(data: Dictionary):
    all_objects_data = data

func get_save_data() -> Dictionary:
    return all_objects_data
```

### 配置路径自定义

```gdscript
save_system.SetConfigPath("res://your_path/save_config.json")
save_system.SetSaveFilePath("user://your_game_save.tres")
save_system.SetSaveDataClassName("MyGameSaveData")
```

## 🎮 支持的游戏类型

- ✅ **平台游戏** - 玩家位置、收集品状态
- ✅ **RPG游戏** - 角色属性、装备、任务进度
- ✅ **解谜游戏** - 关卡状态、解锁情况
- ✅ **策略游戏** - 单位状态、资源数据
- ✅ **任何Godot项目** - 通用架构设计

## 📋 兼容性

- **Godot版本**: 4.0+
- **脚本语言**: GDScript
- **平台**: 所有Godot支持的平台

## 🛠️ 故障排除

### 常见问题

1. **找不到节点**
   - 检查节点是否在正确的组中
   - 确认节点名称拼写正确

2. **属性访问失败**
   - 验证属性路径语法
   - 确认属性在节点中存在

3. **动态对象不显示**
   - 确认scene_path路径正确
   - 检查场景文件是否存在

详细故障排除指南请查看 `Documentation/移植指南.md`

## 📄 许可证

MIT License - 可自由使用、修改和分发

## 🤝 贡献

欢迎提交Issues和Pull Requests来改进这个系统！

## 📞 支持

如果你在使用过程中遇到问题，请：

1. 查看示例配置文件
2. 阅读详细的移植指南
3. 检查控制台输出的调试信息
4. 提交Issue描述具体问题

---

**让保存系统的集成变得简单！** 🎯