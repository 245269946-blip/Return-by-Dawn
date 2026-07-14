extends Node
## 平台无关存档层。PC 上 user:// 是真实文件；Web 上 user:// 是 IndexedDB。
## 真实进度以 Windows 为准；Web 仅作测试/传播，易丢档。

const SAVE_PATH := "user://save_game.json"

func save(data: Dictionary) -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: 无法写入存档 " + SAVE_PATH)
		return
	f.store_string(JSON.stringify(data))
	f.close()
	print("[SaveManager] 已保存 -> ", SAVE_PATH)

func load() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var d = JSON.parse_string(txt)
	if d is Dictionary:
		return d
	return {}

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
