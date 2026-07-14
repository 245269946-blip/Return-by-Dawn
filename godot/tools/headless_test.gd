extends SceneTree
# 《逾期之书》夜 A · Headless 真机点测
# 用法：godot --headless --script tools/headless_test.gd
# 说明：实例化 Main.tscn（与 F5 同一份代码与同一份 night_a.json），直接调用按钮背后的
#       处理函数（等价于点测），逐条断言 NIGHT_A_VERIFY.md 清单，输出 [PASS]/[FAIL] 汇总。
#       全部 PASS 退出码 0；任一 FAIL 退出码 1。

var main = null
var pass_count := 0
var fail_count := 0
var fails := []

func chk(id: String, cond: bool, detail: String = "") -> void:
	if cond:
		pass_count += 1
		print("[PASS] " + id + ((" :: " + detail) if detail != "" else ""))
	else:
		fail_count += 1
		fails.append(id)
		print("[FAIL] " + id + ((" :: " + detail) if detail != "" else ""))

# ── 读数辅助（方法，非 lambda）──
func _stage() -> String:
	return main.get_node("Panel/Stage").text
func _curator() -> String:
	return main.get_node("Panel/Curator").text
func _actions() -> Array:
	var a: Array = []
	for c in main.get_node("Panel/Actions").get_children():
		a.append(c.text)
	return a
func _clues() -> Array:
	return main.state["clues"].keys()
func _hd(rid: String, hid: String):
	return main.content["regions"][rid]["hotspots"][hid]

# ── 路径辅助 ──
func _to_enter() -> void:
	main.state = main._fresh_state()
	main._on_node_action("read")
func _to_region(rid: String) -> void:
	_to_enter()
	main._on_node_action("desk")
	main._on_goto(rid)
func _reach_ending() -> void:
	_to_region("borrowing_desk")
	main._on_hotspot("borrowing_desk", "notice_card")
	main._on_goto("stacks_deep")
	main._on_hotspot("stacks_deep", "letter")
	main._on_enter_reveal()
	main._on_node_action("to_ending")

func _initialize() -> void:
	# 清掉可能残留的存档，保证 _ready 走全新 notice 路径
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		var da := DirAccess.open("user://")
		if da != null:
			da.remove("save_game.json")

	main = load("res://Main.tscn").instantiate()
	root.add_child(main)

	# ════════════════ 0. 开场流 ════════════════
	chk("0-1 notice 占位符替换", _stage().contains("阿迟"), _stage())
	main._on_node_action("read")
	chk("0-2 read→enter", main.state["node"] == "enter" and _stage().contains("又来了"), _stage())
	_to_enter()
	main._on_node_action("toss")
	chk("0-3 toss→enter", main.state["node"] == "enter")
	_to_enter()
	main._on_node_action("desk")
	chk("0-5 desk→hub+借阅台", main.state["node"] == "hub" and main.state["currentRegion"] == "borrowing_desk")
	_to_enter()
	main._on_node_action("door")
	chk("0-6 door→hub", main.state["node"] == "hub")

	# ════════════════ 1. 借阅台 ════════════════
	_to_region("borrowing_desk")
	chk("1-0 进区反应", _curator().contains("台面刚擦过"), _curator())
	main._on_hotspot("borrowing_desk", "notice_card")
	chk("1-1 c_name + 叙事上屏", "c_name" in _clues() and _stage().contains("你从没借过"), _stage())
	chk("1-1 管理员反应", _curator().contains("他没解释"), _curator())
	main._on_hotspot("borrowing_desk", "notice_card")
	chk("1-2 again 不重复解锁", _clues().count("c_name") == 1 and _stage().contains("手改的痕迹"), _stage())
	main._on_hotspot("borrowing_desk", "drawer_note")
	chk("1-3 便签 hook 提问", _curator().contains("写点什么") and "写一句真话" in _actions(), _curator())
	main._on_hook_choice("borrowing_desk", "drawer_note", _hd("borrowing_desk", "drawer_note"), "truth")
	chk("1-4a truth→c_note", "c_note" in _clues() and main.state["hookChosenLine"].has("drawer_note"), _curator())
	chk("1-4a 选择台词", _curator().contains("替你收着"), _curator())
	# 互斥验证：再次打开并改选 safe，c_note 仍只一个 key
	main._on_hotspot("borrowing_desk", "drawer_note")
	main._on_hook_choice("borrowing_desk", "drawer_note", _hd("borrowing_desk", "drawer_note"), "safe")
	chk("1-4 三分支互斥(只一个c_note)", _clues().count("c_note") == 1, "c_note 出现次数=" + str(_clues().count("c_note")))
	main._on_hotspot("borrowing_desk", "lost_found")
	main._on_hotspot("borrowing_desk", "glue_register")
	chk("1-6 c_sign", "c_sign" in _clues())
	main._on_hotspot("borrowing_desk", "return_box")
	chk("1-7 归还箱管理员反应", _curator().contains("有些书，得先想清楚再还"), _curator())

	# ════════════════ 2. 阅览区 ════════════════
	main._on_goto("reading_room")
	chk("2-0 进区反应", _curator().contains("你总坐那边的位子"), _curator())
	main._on_hotspot("reading_room", "old_lamp")
	chk("2-1 c_lamp + 追问按钮", "c_lamp" in _clues() and "谁？" in _actions(), str(_actions()))
	main._on_ask("reading_room", "old_lamp")
	chk("2-2 追问反应", _curator().contains("忘了"), _curator())
	main._on_hotspot("reading_room", "album_shelf")
	chk("2-4 c_album", "c_album" in _clues())

	# ════════════════ 3. 书库深处 ════════════════
	main._on_goto("stacks_deep")
	chk("3-0 进区反应", _curator().contains("漏雨那处"), _curator())
	main._on_hotspot("stacks_deep", "letter")
	chk("3-1 c_letter", "c_letter" in _clues())
	chk("3-3 信的管理员反应", _curator().contains("别人的事"), _curator())
	main._on_hotspot("stacks_deep", "ink_blur")
	chk("3-4 c_next", "c_next" in _clues())
	main._on_hotspot("stacks_deep", "umbrella_share")
	chk("3-5 c_umb2", "c_umb2" in _clues())

	# ════════════════ 4. 雨夜门廊 ════════════════
	main._on_goto("rain_porch")
	chk("4-0 进区反应", _curator().contains("门廊留着你的伞"), _curator())
	main._on_hotspot("rain_porch", "umbrella")
	chk("4-1 c_umb1", "c_umb1" in _clues())
	main._on_hotspot("rain_porch", "lamp_behind")
	chk("4-3 c_lamp2", "c_lamp2" in _clues())

	# ════════════════ 5. 区域出口 ════════════════
	var regions := ["borrowing_desk", "reading_room", "stacks_deep", "rain_porch"]
	var exits_ok := true
	for rid in regions:
		main._on_goto(rid)
		var n := 0
		for t in _actions():
			if t.ends_with("→"):
				n += 1
		if n != 3:
			exits_ok = false
			chk("5 出口 x3 (" + rid + ")", false, "实际出口数=" + str(n))
	chk("5 四区各 3 出口", exits_ok)

	# ════════════════ 6. Reveal 门控 ════════════════
	# 6-1 只 c_name
	_to_region("borrowing_desk")
	main._on_hotspot("borrowing_desk", "notice_card")
	main._refresh_region_controls()
	chk("6-1 只c_name→reveal不解锁", !("拼合那一夜" in _actions()))
	# 6-2 只 c_letter
	_to_region("stacks_deep")
	main._on_hotspot("stacks_deep", "letter")
	main._refresh_region_controls()
	chk("6-2 只c_letter→reveal不解锁", !("拼合那一夜" in _actions()))
	# 6-3 双 clue 齐全
	_to_region("borrowing_desk")
	main._on_hotspot("borrowing_desk", "notice_card")
	main._on_goto("stacks_deep")
	main._on_hotspot("stacks_deep", "letter")
	main._refresh_region_controls()
	chk("6-3 双clue→reveal解锁", "拼合那一夜" in _actions(), str(_actions()))
	main._on_enter_reveal()
	chk("6-3 reveal 进入", main.state["node"] == "reveal" and _stage().contains("信是你写的"), _stage())
	# 记忆解锁（8-2 前置于此）
	chk("8-2 reveal 解锁记忆 m_forgot", main.state["memories"].has("m_forgot"), str(main.state["memories"]))
	# 6-4 → ending
	main._on_node_action("to_ending")
	chk("6-4 reveal→ending", main.state["node"] == "ending")

	# ════════════════ 7. Ending 三分支 ════════════════
	_reach_ending()
	main._on_ending("end:return")
	chk("7-1 ending 归还", _stage().contains("已归还") and main.state["node"] == "ending" and _actions().is_empty(), _stage())
	chk("7-1 结局后记忆仍存", main.state["memories"].has("m_forgot"))
	_reach_ending()
	main._on_ending("end:take")
	chk("7-2 ending 带走", _stage().contains("书贴着心口"), _stage())
	_reach_ending()
	main._on_ending("end:burn")
	chk("7-3 ending 销毁", _stage().contains("很轻的叹气"), _stage())

	# ════════════════ 8. 存档 ═════════════════
	_to_region("borrowing_desk")
	main._on_hotspot("borrowing_desk", "notice_card")
	main._on_goto("stacks_deep")
	main._on_hotspot("stacks_deep", "letter")
	main._on_save()
	var saved := SaveManager.load()
	chk("8-1 存档写入", SaveManager.has_save() and saved.has("clues") and saved.has("region"), str(saved.keys()))
	chk("8-1 存档含双clue", saved.get("clues", {}).has("c_name") and saved.get("clues", {}).has("c_letter"))

	# ── 汇总 ──
	print("")
	print("==== 夜A 点测汇总 ====")
	print("PASS=%d  FAIL=%d" % [pass_count, fail_count])
	if fail_count > 0:
		print("FAILED: " + ", ".join(fails))
		quit(1)
	else:
		print("ALL GREEN")
		quit(0)
