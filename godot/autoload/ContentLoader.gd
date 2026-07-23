extends Node
## 内容数据加载层。编写格式 = JSON；运行时读入并做 {name} 插值，缓存。

const CONTENT_DIR := "res://content/"
var _cache := {}

func get_night(id: String) -> Dictionary:
	if _cache.has(id):
		return _cache[id]
	var path := CONTENT_DIR + id + ".json"
	if not FileAccess.file_exists(path):
		push_error("ContentLoader: 找不到内容文件 " + path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("ContentLoader: 无法读取 " + path)
		return {}
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if parsed == null or not (parsed is Dictionary):
		push_error("ContentLoader: JSON 解析失败 " + path)
		return {}
	var name_val: String = parsed.get("playerName", "你")
	parsed = _interp(parsed, name_val)
	_cache[id] = parsed
	return parsed

## 场景层：每个区域恒定挂载的近景（与逐夜 JSON 解耦）。
## 引擎在加载每一夜时把场景层热点并进去，使「场景长什么样」恒定，
## 逐夜只承载当夜的剧情节点与专属叙事物件。
func get_scenes() -> Dictionary:
	if _cache.has("__scenes__"):
		return _cache["__scenes__"]
	var path := CONTENT_DIR + "scenes.json"
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if parsed == null or not (parsed is Dictionary):
		push_error("ContentLoader: JSON 解析失败 " + path)
		return {}
	_cache["__scenes__"] = parsed
	return parsed

func _interp(variant, name_val: String):
	if variant is String:
		return (variant as String).replace("{name}", name_val)
	if variant is Dictionary:
		var out := {}
		for k in variant.keys():
			out[k] = _interp(variant[k], name_val)
		return out
	if variant is Array:
		var out := []
		for e in variant:
			out.append(_interp(e, name_val))
		return out
	return variant
