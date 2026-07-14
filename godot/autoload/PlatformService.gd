extends Node
## 平台判断与平台相关功能隔离层。所有平台分支只在本单例内部。

func is_web() -> bool:
	return OS.has_feature("web")

func is_mobile() -> bool:
	return OS.has_feature("mobile")

func is_desktop() -> bool:
	return OS.has_feature("windows") or OS.has_feature("linux") or OS.has_feature("macos")

func platform_name() -> String:
	if is_web():
		return "web"
	if is_mobile():
		return "mobile"
	return "desktop"

func needs_gesture_audio_gate() -> bool:
	## Web 需要首次点击后才允许音频
	return is_web()
