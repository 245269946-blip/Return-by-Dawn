extends RefCounted
## 通用 UI 覆盖层（设置 / 制作名单 / 暂停）。
## 框架性脚手架：只搭状态机与可用控件，皮肤（配色/字体/布局）留待美术期替换。
## 所有覆盖层以全屏 Control + 半透明底（mouse_filter=STOP）吸收输入，阻断底层点击。

static func open_settings(root: Node, on_close: Callable) -> Control:
	var ov := _overlay(root, "SettingsOverlay")
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.add_child(bg)
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 280)
	ov.add_child(panel)
	var t := Label.new()
	t.text = "设置"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(t)
	var vol_label := Label.new()
	vol_label.text = "主音量"
	panel.add_child(vol_label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	var s = SaveManager.load_settings()
	slider.value = s.get("volume", 1.0)
	panel.add_child(slider)
	var mute := CheckBox.new()
	mute.text = "静音"
	mute.button_pressed = s.get("muted", false)
	panel.add_child(mute)
	var apply := func(_v = 0.0):
		var cur := SaveManager.load_settings()
		cur["volume"] = slider.value
		cur["muted"] = mute.button_pressed
		SaveManager.save_settings(cur)
		AudioManager.set_master_volume(slider.value)
		AudioManager.set_muted(mute.button_pressed)
	slider.value_changed.connect(apply)
	mute.toggled.connect(apply)
	apply.call()
	var back := Button.new()
	back.text = "返回"
	panel.add_child(back)
	back.pressed.connect(func():
		ov.queue_free()
		if on_close.is_valid():
			on_close.call()
	)
	return ov

static func open_credits(root: Node, on_close: Callable) -> Control:
	var ov := _overlay(root, "CreditsOverlay")
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.08, 0.92)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.add_child(bg)
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(440, 340)
	ov.add_child(panel)
	var t := Label.new()
	t.text = "《逾期之书》"
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(t)
	var lines := [
		"编剧 / 叙事设计：——",
		"程序：——",
		"美术：——（制作中）",
		"音频：程序化合成（环境 / 雨 / 交互音效）",
		"特别感谢：每一个『总说下次』的人",
	]
	for L in lines:
		var l := Label.new()
		l.text = "· " + L
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel.add_child(l)
	var back := Button.new()
	back.text = "返回"
	panel.add_child(back)
	back.pressed.connect(func():
		ov.queue_free()
		if on_close.is_valid():
			on_close.call()
	)
	return ov

static func open_pause(root: Node, on_resume: Callable, on_settings: Callable, on_title: Callable) -> Control:
	var ov := _overlay(root, "PauseOverlay")
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.05, 0.9)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	ov.add_child(bg)
	var panel := VBoxContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(300, 240)
	ov.add_child(panel)
	var t := Label.new()
	t.text = "暂停"
	panel.add_child(t)
	var b1 := Button.new()
	b1.text = "继续"
	panel.add_child(b1)
	b1.pressed.connect(func():
		ov.queue_free()
		if on_resume.is_valid():
			on_resume.call()
	)
	var b2 := Button.new()
	b2.text = "设置"
	panel.add_child(b2)
	b2.pressed.connect(func():
		open_settings(root, func(): pass)
	)
	var b3 := Button.new()
	b3.text = "回到标题"
	panel.add_child(b3)
	b3.pressed.connect(func():
		ov.queue_free()
		if on_title.is_valid():
			on_title.call()
	)
	return ov

static func _overlay(root: Node, name: String) -> Control:
	var ov := Control.new()
	ov.name = name
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(ov)
	return ov
