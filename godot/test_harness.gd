extends Node
# 《逾期之书》夜 A · Headless 真机点测（作为临时主场景运行）
# 用法：临时把 project.godot 的 run/main_scene 指向本场景，godot --headless --path . 运行。
# 正常 headless 运行会加载 autoload，故 SaveManager/ContentLoader/ProgressState 等全局单例可用。
# 实例化 Main.tscn（与 F5 同一份代码与 night_a.json），直接调用按钮背后的处理函数（等价于点测），
# 逐条断言 NIGHT_A_VERIFY.md 清单，输出 [PASS]/[FAIL] 汇总。全部 PASS 退出码 0；任一 FAIL 退出码 1。

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

func _stage() -> String:
	return main.get_node("Panel/Stage").text
func _curator() -> String:
	return main.get_node("Panel/Curator").text
func _actions() -> Array:
	var a: Array = []
	for c in main.get_node("Panel/Actions").get_children():
		a.append(c.text)
	return a
# GDScript 的 `"x" in array` 是【精确成员匹配】，不是子串匹配；
# 按钮文案常带后缀（如「写一句真话（如…）」「（碎片已凑齐）拼合那一夜 ▶」），
# 故此处用子串助手判断某个 action 文案是否含目标片段。
func _actions_has(sub: String) -> bool:
	for t in _actions():
		if t.contains(sub):
			return true
	return false
func _hotspots() -> Array:
	var a: Array = []
	for c in main.get_node("Panel/Hotspots").get_children():
		a.append(c.text)
	return a
func _hotspots_has(sub: String) -> bool:
	for t in _hotspots():
		if t.contains(sub):
			return true
	return false
func _clues() -> Array:
	return main.state["clues"].keys()
func _hd(rid: String, hid: String):
	return main.content["regions"][rid]["hotspots"][hid]

func _to_enter() -> void:
	main.state = main._fresh_state()
	main._on_node_action("read")
func _to_region(rid: String) -> void:
	_to_enter()
	main._on_node_action("desk")
	main._on_goto(rid)
func _reach_ending() -> void:
	_to_region("service_desk")
	main._on_hotspot("service_desk", "notice_card")
	main._on_goto("stacks_deep")
	main._on_hotspot("stacks_deep", "letter")                       # 进入近景
	main._on_closeup_hotspot("stacks_deep", "letter", "read_front")  # 读信 → c_letter
	main._on_settlement_continue()
	main._on_closeup_back()                                          # 退回区域
	main._on_enter_reveal()
	main._on_node_action("to_ending")

func _ready() -> void:
	# 安全超时：无论如何 120 秒后退出，防止 headless 挂死
	print("[HARNESS] test harness _ready start")
	get_tree().create_timer(120.0).timeout.connect(func():
		print("[HARNESS] TIMEOUT — force quit(2)")
		get_tree().quit(2)
	)
	# 清理上一轮残留存档（保证 8-1 存档断言从干净态开始）
	print("[HARNESS] cleaning save...")
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		var da := DirAccess.open("user://")
		if da != null:
			da.remove("save_game.json")
	# 关键：本场景作为主场景被加入树时 root 正 "busy setting up children"，
	# 直接 add_child(main) 会被 Godot 拒绝并静默失败。改用 call_deferred 加入树，
	# 然后等 3 个 process_frame 确保 main._ready 完整执行（headless 下帧调度可能
	# 与桌面不同，多等几帧更安全）。
	print("[HARNESS] loading Main.tscn...")
	main = load("res://Main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	print("[HARNESS] awaiting process_frame x3...")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	print("[HARNESS] Main ready, running tests...")
	_run_tests()

func _run_tests() -> void:

	# ════════════════ 0. 开场流 ════════════════
	chk("0-1 notice 文案上屏", _stage().contains("未寄出的信"), _stage())
	main._on_node_action("read")
	chk("0-2 read→enter", main.state["node"] == "enter" and _stage().contains("又来了"), _stage())
	_to_enter()
	main._on_node_action("toss")
	chk("0-3 toss→enter", main.state["node"] == "enter")
	_to_enter()
	main._on_node_action("desk")
	chk("0-5 desk→hub+服务台", main.state["node"] == "hub" and main.state["currentRegion"] == "service_desk")
	_to_enter()
	main._on_node_action("door")
	chk("0-6 door→hub", main.state["node"] == "hub")

	# ════════════════ 1. 服务台 ════════════════
	_to_region("service_desk")
	chk("1-0 进区反应", _curator().contains("台面刚擦过"), _curator())
	main._on_hotspot("service_desk", "notice_card")
	chk("1-1 c_name + 叙事上屏", "c_name" in _clues() and _stage().contains("你不记得借过"), _stage())
	chk("1-1 管理员反应", _curator().contains("他没解释"), _curator())
	main._on_hotspot("service_desk", "notice_card")
	chk("1-2 again 不重复解锁", _clues().count("c_name") == 1 and _stage().contains("手改的痕迹"), _stage())
	main._on_hotspot("service_desk", "drawer_note")
	chk("1-3 便签 hook 提问", _curator().contains("写点什么") and _actions_has("写一句真话"), _curator())
	main._on_hook_choice("service_desk", "drawer_note", _hd("service_desk", "drawer_note"), "truth")
	chk("1-4a truth→c_note", "c_note" in _clues() and main.state["hookChosenLine"].has("drawer_note"), _curator())
	chk("1-4a 选择台词", _curator().contains("替你收着"), _curator())
	chk("1-4a truth 结算页", _stage().contains("【结算】") and _stage().contains("你写下了那句话"), _stage())
	main._on_settlement_continue()
	chk("1-4a 结算后回区域", main.state["node"] == "region")
	main._on_hotspot("service_desk", "drawer_note")
	main._on_hook_choice("service_desk", "drawer_note", _hd("service_desk", "drawer_note"), "safe")
	chk("1-4 三分支互斥(只一个c_note)", _clues().count("c_note") == 1, "c_note 出现次数=" + str(_clues().count("c_note")))
	main._on_goto("utility_zone")
	main._on_hotspot("utility_zone", "glue_register")
	main._on_hotspot("utility_zone", "lost_found")
	main._on_closeup_back()
	chk("1-6 c_sign", "c_sign" in _clues())

	# ════════════════ 2. 阅览区 ════════════════
	main._on_goto("reading_room")
	chk("2-0 进区反应", _curator().contains("你总坐那边的位子"), _curator())
	main._on_hotspot("reading_room", "old_lamp")
	chk("2-1 c_lamp + 追问按钮", "c_lamp" in _clues() and "谁？" in _actions(), str(_actions()))
	main._on_ask("reading_room", "old_lamp")
	chk("2-2 追问反应", _curator().contains("忘了"), _curator())
	main._on_hotspot("reading_room", "album_shelf")
	chk("2-4 c_album", "c_album" in _clues())

	# ════════════════ 3. 书库深处（含近景） ════════════════
	main._on_goto("stacks_deep")
	chk("3-0 进区反应", _curator().contains("漏雨那处"), _curator())
	# 近景：点书本进入 closeup
	main._on_hotspot("stacks_deep", "letter")
	chk("3-1 进近景(node=closeup)", main.state["node"] == "closeup" and _stage().contains("你把书摊开"), _stage())
	chk("3-1 近景含退回", _actions_has("退回"), str(_actions()))
	# 读信正面 → c_letter + 结算
	main._on_closeup_hotspot("stacks_deep", "letter", "read_front")
	chk("3-2 c_letter(近景)", "c_letter" in _clues())
	chk("3-3 信结算页", _stage().contains("【结算】") and _stage().contains("一封没署名的信"), _stage())
	chk("3-3 信的管理员反应", _curator().contains("别人的事"), _curator())
	main._on_settlement_continue()
	chk("3-3 结算后回近景", main.state["node"] == "closeup")
	# 特殊：信背面咖啡渍 → c_stain + 结算
	main._on_closeup_hotspot("stacks_deep", "letter", "back_stain")
	chk("3-4 特殊 c_stain", "c_stain" in _clues())
	chk("3-4 特殊结算", _stage().contains("一行没署名的字"), _stage())
	main._on_settlement_continue()
	main._on_closeup_back()
	chk("3-5 退回区域", main.state["node"] == "region")
	# 借书卡近景 → 描「下次」→ c_next
	main._on_hotspot("stacks_deep", "ink_blur")
	chk("3-6 借书卡进近景", main.state["node"] == "closeup")
	main._on_closeup_hotspot("stacks_deep", "ink_blur", "trace_next")
	chk("3-7 c_next(近景)", "c_next" in _clues())
	chk("3-7 描字结算", _stage().contains("你描了一遍"), _stage())
	main._on_settlement_continue()
	main._on_closeup_back()
	# 旧测试保留：umbrella_share 仍是区域级普通热点
	main._on_hotspot("stacks_deep", "umbrella_share")
	chk("3-8 c_umb2", "c_umb2" in _clues())

	# ════════════════ 4. 雨夜门廊 ════════════════
	main._on_goto("entry_porch")
	chk("4-0 进区反应", _curator().contains("门廊留着你的伞"), _curator())
	main._on_hotspot("entry_porch", "umbrella")
	chk("4-1 c_umb1", "c_umb1" in _clues())
	main._on_hotspot("entry_porch", "lamp_behind")
	chk("4-3 c_lamp2", "c_lamp2" in _clues())

	# ════════════════ 5. 区域出口（严格楼层树 · §2.2） ════════════════
	# 出口数 = 区域图中以「→」结尾的按钮数（锁定区出口灰显、不计入）
	var expect_exits := {
		"entry_porch": 1,
		"service_desk": 3,
		"lounge_stairs": 1,
		"archive_lamp": 1,
		"utility_zone": 1,
		"reading_room": 3,
		"stacks_deep": 1,
		"study_zone": 1
	}
	var exits_ok := true
	for rid in expect_exits.keys():
		main._on_goto(rid)
		var n := 0
		for t in _actions():
			if t.ends_with("→"):
				n += 1
		if n != expect_exits[rid]:
			exits_ok = false
			chk("5 出口数 (" + rid + ")", false, "期望=" + str(expect_exits[rid]) + " 实际=" + str(n))
	chk("5 各区域出口数符合 §2.2 树边", exits_ok)
	# void_room 永不开启：不在解锁列表、不出现在楼层图
	chk("5 void_room 永不开启", not ("void_room" in ProgressState.unlocked_zones))

	# ════════════════ 5b. 常驻「回到服务台」 ════════════════
	var home_regions := ["entry_porch","service_desk","reading_room","stacks_deep","study_zone","utility_zone","lounge_stairs","archive_lamp"]
	var home_ok := true
	for rid in home_regions:
		main._on_goto(rid)
		if not _actions_has("回到服务台"):
			home_ok = false
			chk("5b 回服务台(" + rid + ")", false)
	chk("5b 八区均常驻「回到服务台」", home_ok)

	# ════════════════ 6. Reveal 门控 ════════════════
	# 仅 c_name（区域级） → 不解锁
	_to_region("service_desk")
	main._on_hotspot("service_desk", "notice_card")
	main._refresh_region_controls()
	chk("6-1 只c_name→reveal不解锁", !("拼合那一夜" in _actions()))
	# 仅 c_letter（近景） → 不解锁
	_to_region("stacks_deep")
	main._on_hotspot("stacks_deep", "letter")
	main._on_closeup_hotspot("stacks_deep", "letter", "read_front")
	main._on_settlement_continue()
	main._on_closeup_back()
	main._refresh_region_controls()
	chk("6-2 只c_letter→reveal不解锁", !("拼合那一夜" in _actions()))
	# 双 clue → 解锁
	_to_region("service_desk")
	main._on_hotspot("service_desk", "notice_card")
	main._on_goto("stacks_deep")
	main._on_hotspot("stacks_deep", "letter")
	main._on_closeup_hotspot("stacks_deep", "letter", "read_front")
	main._on_settlement_continue()
	main._on_closeup_back()
	main._refresh_region_controls()
	chk("6-3 双clue→reveal解锁", _actions_has("拼合那一夜"), str(_actions()))
	main._on_enter_reveal()
	chk("6-3 reveal 进入", main.state["node"] == "reveal" and _stage().contains("没署名的信"), _stage())
	chk("8-2 reveal 解锁记忆 m_forgot", main.state["memories"].has("m_forgot"), str(main.state["memories"]))
	main._on_node_action("to_utility")
	chk("6-4 reveal→便民区(投信前置)", main.state["node"] == "region" and main.state["currentRegion"] == "utility_zone")

	# ════════════════ 7. 新流程：投信不强制出馆 → 对话 → 出馆 ════════════════
	_to_region("service_desk")
	main._on_hotspot("service_desk", "notice_card")
	main._on_goto("stacks_deep")
	main._on_hotspot("stacks_deep", "letter")
	main._on_closeup_hotspot("stacks_deep", "letter", "read_front")
	main._on_settlement_continue()
	main._on_closeup_back()
	main._on_enter_reveal()
	main._on_node_action("to_utility")
	# 投信前：服务台不应出现「与管理员对话」
	main._on_goto("service_desk")
	chk("7-0 投信前不出现对话入口", not _hotspots_has("与管理员说话"))
	# 进便民区投信（置位 mailedLetter）
	main._on_goto("utility_zone")
	main._on_hotspot("utility_zone", "lost_found")
	main._on_closeup_hotspot("utility_zone", "lost_found", "mailbox_slot")
	var mb = main.content["regions"]["utility_zone"]["hotspots"]["lost_found"]["closeup"]["hotspots"]["mailbox_slot"]
	main._on_hook_choice("utility_zone", "lost_found", mb, "mail", "closeup", "lost_found")
	chk("7-1 投信置位 mailedLetter", main.state.get("mailedLetter", false))
	main._on_settlement_continue()
	main._on_closeup_back()
	# 投信后：回服务台出现对话入口
	main._on_goto("service_desk")
	chk("7-2 投信后出现对话入口", _hotspots_has("与管理员说话"))
	# 与管理员对话 → 确认归还 → 出馆
	main._on_hotspot("service_desk", "talk_librarian")
	chk("7-3 对话结算页", _stage().contains("【结算】"), _stage())
	main._on_settlement_continue()
	chk("7-4 出馆节点", main.state["node"] == "exit" and _stage().contains("正式还了"), _stage())
	chk("7-4 结局后记忆仍存", main.state["memories"].has("m_forgot"))
	main._on_node_action("to_close")
	chk("7-5 收场 curtain", _stage().contains("今夜闭馆"), _stage())

	# ════════════════ 8. 存档 ═══════════════
	_to_region("service_desk")
	main._on_hotspot("service_desk", "notice_card")
	main._on_goto("stacks_deep")
	main._on_hotspot("stacks_deep", "letter")
	main._on_closeup_hotspot("stacks_deep", "letter", "read_front")
	main._on_settlement_continue()
	main._on_closeup_back()
	main._on_save()
	var saved := SaveManager.load()
	chk("8-1 存档写入", SaveManager.has_save() and saved.has("clues") and saved.has("currentRegion"), str(saved.keys()))
	chk("8-1 存档含双clue", saved.get("clues", {}).has("c_name") and saved.get("clues", {}).has("c_letter"))

	# ── 汇总 ──
	print("")
	print("==== 夜A 点测汇总 ====")
	print("PASS=%d  FAIL=%d" % [pass_count, fail_count])
	if fail_count > 0:
		print("FAILED: " + ", ".join(fails))
		get_tree().quit(1)
	else:
		print("ALL GREEN")
		get_tree().quit(0)
