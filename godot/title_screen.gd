extends Control
## 标题 / 主菜单（框架层）。美术期替换按钮皮肤与背景即可，节点路径不变。
## 「继续」在 debug 构建下因 DEBUG_IGNORE_SAVE 仍会从开场进入（开发期行为），
## 导出 release 版则正常恢复进度。

const UIHelpers := preload("res://ui_helpers.gd")

func _ready() -> void:
	_build_ui()
	# 应用已存设置（主音量 / 静音）
	var s = SaveManager.load_settings()
	AudioManager.set_master_volume(s.get("volume", 1.0))
	AudioManager.set_muted(s.get("muted", false))

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.09, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(320, 380)
	add_child(panel)
	var title := Label.new()
	title.text = "逾期之书"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(title)
	var sub := Label.new()
	sub.text = "—— 灯还亮着 ——"
	panel.add_child(sub)
	var b_new := Button.new()
	b_new.text = "开始新游戏"
	panel.add_child(b_new)
	b_new.pressed.connect(_on_new)
	if SaveManager.has_save():
		var b_cont := Button.new()
		b_cont.text = "继续"
		panel.add_child(b_cont)
		b_cont.pressed.connect(_on_continue)
	var b_set := Button.new()
	b_set.text = "设置"
	panel.add_child(b_set)
	b_set.pressed.connect(_on_settings)
	var b_cred := Button.new()
	b_cred.text = "制作名单"
	panel.add_child(b_cred)
	b_cred.pressed.connect(_on_credits)

func _on_new() -> void:
	SaveManager.delete_save()
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")

func _on_settings() -> void:
	UIHelpers.open_settings(self, func(): pass)

func _on_credits() -> void:
	UIHelpers.open_credits(self, func(): pass)
