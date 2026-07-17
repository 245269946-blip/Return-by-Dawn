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
	return main.get_node("Panel/StageArea/Stage").text
func _curator() -> String:
	return main.get_node("Panel/DialogueBox/Curator").text
func _portrait_visible() -> bool:
	return main.get_node("Panel/DialogueBox/Portrait").visible
func _actions() -> Array:
	var a: Array = []
	for c in main.get_node("Panel/StageArea/Actions").get_children():
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
	for c in main.get_node("Panel/StageArea/Hotspots").get_children():
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

	# ════════════════ P. 序章 · 续借（教学关） ════════════════
	# _ready 已加载 NIGHT_ORDER[0] = prologue；此处显式确认并走一遍主链。
	chk("P0-0 序章为入口夜", main.content["id"] == "prologue")
	chk("P0-1 notice 上屏(系统重发)", _stage().contains("系统重发"), _stage())
	chk("P0-1b notice 含第一天标记", _stage().contains("第一天"), _stage())
	main._on_node_action("read")
	chk("P0-2 read→enter", main.state["node"] == "enter" and _stage().contains("没抬头"), _stage())
	_to_enter()
	main._on_node_action("toss")
	chk("P0-3 toss→enter", main.state["node"] == "enter")
	_to_enter()
	main._on_node_action("desk")
	chk("P0-4 desk→hub+服务台", main.state["node"] == "hub" and main.state["currentRegion"] == "service_desk")
	_to_enter()
	main._on_node_action("door")
	chk("P0-5 door→hub", main.state["node"] == "hub")
	# 区域切换 + 进区反应
	main._on_goto("entry_porch")
	chk("P0-6 门廊(馆员不在场·独处·肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible())+" curator="+_curator())
	main._on_hotspot("entry_porch", "umbrella")
	chk("P0-7 c_umb1", "c_umb1" in _clues())
	main._on_goto("reading_room")
	chk("P0-8 阅览(馆员不在场·独处·肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible())+" curator="+_curator())
	main._on_hotspot("reading_room", "old_lamp")
	chk("P0-9 c_lamp", "c_lamp" in _clues())
	main._on_goto("service_desk")
	# 通知单 → c_name
	main._on_hotspot("service_desk", "notice_card")
	chk("P0-10 c_name(自己逾期通知)", "c_name" in _clues() and _stage().contains("你以为是系统自动重发"), _stage())
	# 种子：他桌上也压着一摞没还的书
	main._on_hotspot("service_desk", "desk_stack")
	chk("P0-11 c_hisbooks 种子", "c_hisbooks" in _clues())
	# 核心：续借决策 hook（双延后选项）
	main._on_hotspot("service_desk", "overdue_book")
	chk("P0-12 续借 hook 提问+选项", _curator().contains("要怎么办") and _actions_has("办续借") and _actions_has("下次吧"), _curator())
	main._on_hook_choice("service_desk", "overdue_book", _hd("service_desk", "overdue_book"), "renew")
	chk("P0-13 续借→c_renewed+结算页", "c_renewed" in _clues() and _stage().contains("【结算】"), _stage())
	main._on_settlement_continue()
	chk("P0-14 续借→exit 节点", main.state["node"] == "exit" and _stage().contains("续借，登记好了"), _stage())
	main._on_node_action("to_close")
	chk("P0-15 收场 curtain", _stage().contains("今夜闭馆"), _stage())
	chk("P0-15b 收场过场帧显示夜A frame", _stage().contains("第二天"), _stage())
	chk("P0-16 续接声明 next=night_a", main.content.has("next") and main.content["next"] == "night_a")
	chk("P0-17 curtain 含「继续」入口", _actions_has("继续"), str(_actions()))
	# 跨夜续接链路：点「继续」即加载夜 A 开场
	for c in main.get_node("Panel/StageArea/Actions").get_children():
		if c is Button and c.text.contains("继续"):
			c.pressed.emit()
			break
	chk("P0-18 续接后进入 night_a notice", main.content["id"] == "night_a" and main.state["node"] == "notice")

	# ════════════════ 0. 开场流（夜 A） ════════════════
	main.load_night_by_id("night_a")   # 确保后续断言跑在夜 A 内容上
	chk("0-1 notice 文案上屏", _stage().contains("未寄出的信"), _stage())
	chk("0-1b notice 含第二天标记", _stage().contains("第二天"), _stage())
	main._on_node_action("read")
	chk("0-2 read→enter", main.state["node"] == "enter" and _stage().contains("没抬头"), _stage())
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
	chk("1-2 again 不重复解锁", _clues().count("c_name") == 1 and _stage().contains("你依旧想不起借过"), _stage())
	main._on_hotspot("service_desk", "drawer_note")
	chk("1-3 便签 hook 提问(三态选项上屏)", _actions_has("写一句真话") and _actions_has("什么都不写"), str(_actions()))
	chk("1-3b 便签三选项(面对/逃避/抹去)", _hd("service_desk", "drawer_note")["options"].size() == 3)
	main._on_hook_choice("service_desk", "drawer_note", _hd("service_desk", "drawer_note"), "face")
	chk("1-4a face→c_tier_face", "c_tier_face" in _clues() and main.state["hookChosenLine"].has("drawer_note"), _curator())
	chk("1-4a 选择台词(替你收着)", _curator().contains("替你收着"), _curator())
	chk("1-4a face 结算页", _stage().contains("【结算】") and _stage().contains("你写下了那句真话"), _stage())
	main._on_settlement_continue()
	chk("1-4a 结算后回区域", main.state["node"] == "region")
	# 三态数据完整性静态校验（face/evade/erase 各自置对应 c_tier_*）
	var dn = main.content["regions"]["service_desk"]["hotspots"]["drawer_note"]
	for tier_opt_a in ["face", "evade", "erase"]:
		var hr_a = dn["hookResults"][tier_opt_a]
		chk("1-4b " + tier_opt_a + " 置 c_tier_" + tier_opt_a, hr_a["clue"]["id"] == "c_tier_" + tier_opt_a, str(hr_a))
	main._on_goto("utility_zone")
	main._on_hotspot("utility_zone", "glue_register")
	main._on_hotspot("utility_zone", "lost_found")
	main._on_closeup_back()
	chk("1-6 c_sign", "c_sign" in _clues())

	# ════════════════ 2. 阅览区 ════════════════
	main._on_goto("reading_room")
	chk("2-0 阅览(馆员不在场·独处·肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible())+" curator="+_curator())
	main._on_hotspot("reading_room", "old_lamp")
	chk("2-1 c_lamp 解锁", "c_lamp" in _clues())
	chk("2-1b 馆员不在场→不出现追问入口", not ("谁？" in _actions()), str(_actions()))
	# 夜A 关系域不应残留夜B 家庭域的相册书（c_album 归夜B 独占）
	chk("2-3 夜A 阅览区无 album_shelf 残留", not main.content["regions"]["reading_room"]["hotspots"].has("album_shelf"))
	chk("2-3b 夜A 不解锁 c_album", not ("c_album" in _clues()))
	chk("2-4 夜A 阅览区含 seats", main.content["regions"]["reading_room"]["hotspots"].has("seats"))

	# ════════════════ 3. 书库深处（含近景） ════════════════
	main._on_goto("stacks_deep")
	chk("3-0 书库(馆员不在场·独处·肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible())+" curator="+_curator())
	# 近景：点书本进入 closeup
	main._on_hotspot("stacks_deep", "letter")
	chk("3-1 进近景(node=closeup)", main.state["node"] == "closeup" and _stage().contains("你把书摊开"), _stage())
	chk("3-1 近景含退回", _actions_has("退回"), str(_actions()))
	# 读信正面 → c_letter + 结算
	main._on_closeup_hotspot("stacks_deep", "letter", "read_front")
	chk("3-2 c_letter(近景)", "c_letter" in _clues())
	chk("3-3 信结算页", _stage().contains("【结算】") and _stage().contains("一封没署名的信"), _stage())
	chk("3-3 信为私阅(馆员不在场→无旁白)", _curator() == "", "curator="+_curator())
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
	chk("4-0 门廊(馆员不在场·独处·肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible())+" curator="+_curator())
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
	# 关系域三态：便签上写下真话（face）——_to_region 已重置态，须在此重建 drawer_note 的 c_tier_*，
	# 以忠实模拟真实游玩（写便签→还信→with_him 按态回响），否则 with_him.thenByFlag 无三态可匹配。
	main._on_hotspot("service_desk", "drawer_note")
	main._on_hook_choice("service_desk", "drawer_note", _hd("service_desk", "drawer_note"), "face")
	main._on_settlement_continue()
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
	# A7-7 沉默旁观者：投信事件触发后他出现在配套区、肖像可见、不自动说话，玩家主动对话才出声（按三态给回响）
	chk("A7-7a 事件触发后配套区出现『他在你身边』入口", _hotspots_has("他就在你身边"))
	chk("A7-7b 配套区肖像可见（他出现）", _portrait_visible())
	chk("A7-7c 触发瞬间未自动开口（沉默陪伴）", _curator().contains("没说话") or _curator().contains("陪着") or _curator().contains("没催"))
	main._on_hotspot("utility_zone", "with_him")
	chk("A7-7d 点入口出现『你想说点什么』", _actions_has("你想说点什么"))
	main._on_ask("utility_zone", "with_him", "")
	chk("A7-7e 主动对话→他按态给回响(面对态·敢让它见人)", _curator().contains("敢让它见人"), _curator())
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

	# ════════════════ 9. 自习区留灯仪式（机制④ · 走动为稀缺事件） ════════════════
	main._on_goto("study_zone")
	chk("9-0 自习区初入·馆员不在场(肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible()))
	main._on_hotspot("study_zone", "keep_lamp")
	chk("9-1 留灯→馆员走动到场(肖像显)", _portrait_visible())
	chk("9-2 留灯台词", _curator().contains("一直替你留着"), _curator())
	chk("9-3 留灯线索 c_lamp_kept", "c_lamp_kept" in _clues())

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

	# ════════════════ B. 夜 B · 满员的书架（家庭域 decoy · 框架） ════════════════
	main.load_night_by_id("night_b")
	chk("B0-0 夜B为家庭域夜", main.content["id"] == "night_b")
	chk("B0-1 notice 上屏(满员的书架)", _stage().contains("满员的书架"), _stage())
	chk("B0-1b notice 含第三天标记", _stage().contains("第三天"), _stage())
	chk("B0-2 系统期面孔(无点破)", not _stage().contains("其实是你") and not _stage().contains("就是你自己") and not _stage().contains("你就是本人"), _stage())
	main._on_node_action("read")
	chk("B0-3 read→enter(冷化)", main.state["node"] == "enter" and _stage().contains("没抬头"), _stage())
	_to_enter()
	main._on_node_action("toss")
	chk("B0-4 toss→enter", main.state["node"] == "enter")
	_to_enter()
	main._on_node_action("desk")
	chk("B0-5 desk→hub+服务台", main.state["node"] == "hub" and main.state["currentRegion"] == "service_desk")
	# 服务台
	_to_region("service_desk")
	chk("B1-0 进区反应", _curator().contains("台面刚擦过"), _curator())
	main._on_hotspot("service_desk", "notice_card")
	chk("B1-1 c_name", "c_name" in _clues() and _stage().contains("你不记得借过"), _stage())
	main._on_hotspot("service_desk", "notice_card")
	chk("B1-2 again 不重复解锁", _clues().count("c_name") == 1 and _stage().contains("你依旧想不起借过"), _stage())
	main._on_hotspot("service_desk", "shelf_tools")
	chk("B1-3 c_tools(书立除尘布)", "c_tools" in _clues())
	# 阅览区：相册书 → closeup → 空位页 c_album
	main._on_goto("reading_room")
	chk("B2-0 阅览(馆员不在场·独处·肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible())+" curator="+_curator())
	main._on_hotspot("reading_room", "old_lamp")
	chk("B2-1 c_lamp", "c_lamp" in _clues())
	main._on_hotspot("reading_room", "album_shelf")
	chk("B2-2 进近景(node=closeup)", main.state["node"] == "closeup" and _stage().contains("你把相册书摊开"), _stage())
	chk("B2-2 近景含退回", _actions_has("退回"), str(_actions()))
	main._on_closeup_hotspot("reading_room", "album_shelf", "read_empty_seat")
	chk("B2-3 c_album(近景)", "c_album" in _clues())
	chk("B2-3 空位结算页", _stage().contains("【结算】") and _stage().contains("年夜饭的空位"), _stage())
	main._on_settlement_continue()
	main._on_closeup_back()
	chk("B2-4 退回区域", main.state["node"] == "region")
	# 书库深处：镜面/墨团/伞（跨夜同款种子）
	main._on_goto("stacks_deep")
	chk("B3-0 书库(馆员不在场·独处·肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible())+" curator="+_curator())
	main._on_hotspot("stacks_deep", "photo_book")
	chk("B3-1 c_photo(镜面映射)", "c_photo" in _clues())
	main._on_hotspot("stacks_deep", "ink_blur")
	chk("B3-2 c_blur(墨团·下次)", "c_blur" in _clues())
	main._on_hotspot("stacks_deep", "umbrella_share")
	chk("B3-3 c_umb2", "c_umb2" in _clues())
	# 门廊
	main._on_goto("entry_porch")
	chk("B4-0 门廊(馆员不在场·独处·肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible())+" curator="+_curator())
	main._on_hotspot("entry_porch", "umbrella")
	chk("B4-1 c_umb1", "c_umb1" in _clues())
	main._on_hotspot("entry_porch", "lamp_behind")
	chk("B4-2 c_lamp2", "c_lamp2" in _clues())
	# Reveal 门控 c_album + c_name（_to_region 会重置状态，逐段重推）
	_to_region("service_desk")
	main._on_hotspot("service_desk", "notice_card")
	main._refresh_region_controls()
	chk("B6-1 只c_name→reveal不解锁", !_actions_has("拼合那一夜"))
	_to_region("reading_room")
	main._on_hotspot("reading_room", "album_shelf")
	main._on_closeup_hotspot("reading_room", "album_shelf", "read_empty_seat")
	main._on_settlement_continue()
	main._on_closeup_back()
	main._refresh_region_controls()
	chk("B6-2 只c_album→reveal不解锁", !_actions_has("拼合那一夜"))
	_to_region("service_desk")
	main._on_hotspot("service_desk", "notice_card")
	main._on_goto("reading_room")
	main._on_hotspot("reading_room", "album_shelf")
	main._on_closeup_hotspot("reading_room", "album_shelf", "read_empty_seat")
	main._on_settlement_continue()
	main._on_closeup_back()
	main._refresh_region_controls()
	chk("B6-3 双clue→reveal解锁", _actions_has("拼合那一夜"), str(_actions()))
	main._on_enter_reveal()
	chk("B6-3 reveal 进入", main.state["node"] == "reveal" and _stage().contains("相册书"), _stage())
	chk("B8-2 reveal 解锁记忆 m_family", main.state["memories"].has("m_family"), str(main.state["memories"]))
	main._on_node_action("to_utility")
	chk("B6-4 reveal→便民区(发红包前置)", main.state["node"] == "region" and main.state["currentRegion"] == "utility_zone")
	# 发红包前：服务台不出现对话入口
	main._on_goto("service_desk")
	chk("B7-0 发红包前不出现对话入口", not _hotspots_has("与管理员说话"))
	# 进便民区发红包（置位 shelvedAlbum）
	main._on_goto("utility_zone")
	main._on_hotspot("utility_zone", "lost_found")
	main._on_closeup_hotspot("utility_zone", "lost_found", "red_packet")
	var rp = main.content["regions"]["utility_zone"]["hotspots"]["lost_found"]["closeup"]["hotspots"]["red_packet"]
	main._on_hook_choice("utility_zone", "lost_found", rp, "hesitate", "closeup", "lost_found")
	chk("B7-1 发红包置位 shelvedAlbum", main.state.get("shelvedAlbum", false))
	main._on_settlement_continue()
	main._on_closeup_back()
	# B7-7 沉默旁观者：发红包事件触发后他出现在配套区、肖像可见、不自动说话，玩家主动对话才出声（按家庭域给回响）
	chk("B7-7a 事件触发后配套区出现『他在你身边』入口", _hotspots_has("他就在你身边"))
	chk("B7-7b 配套区肖像可见（他出现）", _portrait_visible())
	chk("B7-7c 触发瞬间未自动开口（沉默陪伴）", _curator().contains("没说话") or _curator().contains("陪着") or _curator().contains("没催"))
	main._on_hotspot("utility_zone", "with_him")
	chk("B7-7d 点入口出现『你想说点什么』", _actions_has("你想说点什么"))
	main._on_ask("utility_zone", "with_him", "")
	chk("B7-7e 主动对话→他按家庭域给回响(迟疑态·往前了一步)", _curator().contains("往前了一步"), _curator())
	# B7-6 三态数据完整性静态校验（hesitate/direct/extra 各自置对应 c_red_* + shelvedAlbum）
	var rp_s = main.content["regions"]["utility_zone"]["hotspots"]["lost_found"]["closeup"]["hotspots"]["red_packet"]
	var rp_suffix = {"hesitate": "wait", "direct": "send", "extra": "more"}
	for rp_opt in ["hesitate", "direct", "extra"]:
		var hr_rp = rp_s["hookResults"][rp_opt]
		var exp_id = "c_red_" + rp_suffix[rp_opt]
		chk("B7-6 " + rp_opt + " 置 " + exp_id, hr_rp["clue"]["id"] == exp_id and hr_rp["setFlag"] == "shelvedAlbum", str(hr_rp))
	main._on_goto("service_desk")
	chk("B7-2 发红包后出现对话入口", _hotspots_has("与管理员说话"))
	main._on_hotspot("service_desk", "talk_librarian")
	chk("B7-3 对话结算页", _stage().contains("【结算】"), _stage())
	main._on_settlement_continue()
	chk("B7-4 出馆节点", main.state["node"] == "exit" and _stage().contains("正式还了"), _stage())
	main._on_node_action("to_close")
	chk("B7-5 收场 curtain(夜C已建·含继续入口)", _stage().contains("今夜闭馆"), _stage())
	# ════════════════ B9. 自习区留灯仪式（机制④ · 走动为稀缺事件） ════════════════
	main._on_goto("study_zone")
	chk("B9-0 自习区初入·馆员不在场(肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible()))
	main._on_hotspot("study_zone", "keep_lamp")
	chk("B9-1 留灯→馆员走动到场(肖像显)", _portrait_visible())
	chk("B9-2 留灯台词", _curator().contains("一直替你留着"), _curator())
	chk("B9-3 留灯线索 c_lamp_kept", "c_lamp_kept" in _clues())
	# 夜B 区域出口数（同 §2.2 树边）
	var b_expect := {
		"entry_porch": 1, "service_desk": 3, "lounge_stairs": 1,
		"archive_lamp": 1, "utility_zone": 1, "reading_room": 3,
		"stacks_deep": 1, "study_zone": 1
	}
	var b_exits_ok := true
	for rid in b_expect.keys():
		main._on_goto(rid)
		var nn := 0
		for t in _actions():
			if t.ends_with("→"):
				nn += 1
		if nn != b_expect[rid]:
			b_exits_ok = false
			chk("B5 出口数 (" + rid + ")", false, "期望=" + str(b_expect[rid]) + " 实际=" + str(nn))
	chk("B5 各区域出口数符合 §2.2 树边", b_exits_ok)
	chk("B5 void_room 永不开启", not ("void_room" in ProgressState.unlocked_zones))
	# 常驻「回到服务台」
	var b_home_ok := true
	for rid in ["entry_porch","service_desk","reading_room","stacks_deep","study_zone","utility_zone","lounge_stairs","archive_lamp"]:
		main._on_goto(rid)
		if not _actions_has("回到服务台"):
			b_home_ok = false
			chk("B5b 回服务台(" + rid + ")", false)
	chk("B5b 八区均常驻「回到服务台」", b_home_ok)

	# ════════════════ C. 夜 C · 一屋子的雨（自我域 decoy · 三态谱系） ════════════════
	main.load_night_by_id("night_c")
	chk("C0-0 夜C为自我域夜", main.content["id"] == "night_c")
	chk("C0-1 notice 上屏(一屋子的雨)", _stage().contains("一屋子的雨"), _stage())
	chk("C0-1b notice 含第四天标记", _stage().contains("第四天"), _stage())
	chk("C0-2 系统期面孔(无点破)", not _stage().contains("其实是你") and not _stage().contains("就是你自己") and not _stage().contains("你就是本人"), _stage())
	main._on_node_action("read")
	chk("C0-3 read→enter(冷化)", main.state["node"] == "enter" and _stage().contains("没抬头"), _stage())
	_to_enter()
	main._on_node_action("toss")
	chk("C0-4 toss→enter", main.state["node"] == "enter")
	_to_enter()
	main._on_node_action("desk")
	chk("C0-5 desk→hub+服务台", main.state["node"] == "hub" and main.state["currentRegion"] == "service_desk")
	# 服务台
	_to_region("service_desk")
	chk("C1-0 进区反应", _curator().contains("台面刚擦过"), _curator())
	main._on_hotspot("service_desk", "notice_card")
	chk("C1-1 c_name", "c_name" in _clues() and _stage().contains("你不记得借过"), _stage())
	main._on_hotspot("service_desk", "notice_card")
	chk("C1-2 again 不重复解锁", _clues().count("c_name") == 1 and _stage().contains("你依旧想不起借过"), _stage())
	main._on_hotspot("service_desk", "towel")
	chk("C1-3 c_towel(毛巾·功能互动)", "c_towel" in _clues())
	# 阅览区：busy_book（玩家常量③）
	main._on_goto("reading_room")
	chk("C2-0 阅览(馆员不在场·独处·肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible())+" curator="+_curator())
	main._on_hotspot("reading_room", "old_lamp")
	chk("C2-1 c_lamp", "c_lamp" in _clues())
	main._on_hotspot("reading_room", "busy_book")
	chk("C2-2 c_todo(玩家常量·做完同款)", "c_todo" in _clues())
	# 书库深处：rain_book closeup → c_book + c_stain；ink_blur → c_next；basin → c_basin
	main._on_goto("stacks_deep")
	chk("C3-0 书库(馆员不在场·独处·肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible())+" curator="+_curator())
	main._on_hotspot("stacks_deep", "rain_book")
	chk("C3-1 进近景(node=closeup)", main.state["node"] == "closeup" and _stage().contains("你把书摊开"), _stage())
	main._on_closeup_hotspot("stacks_deep", "rain_book", "read_book")
	chk("C3-2 c_book(近景·镜面映射)", "c_book" in _clues())
	chk("C3-2 书结算页", _stage().contains("【结算】") and _stage().contains("鼻子一酸"), _stage())
	main._on_settlement_continue()
	main._on_closeup_hotspot("stacks_deep", "rain_book", "back_note")
	chk("C3-3 c_stain(夹页便条)", "c_stain" in _clues() and _stage().contains("便条"))
	main._on_settlement_continue()
	main._on_closeup_back()
	chk("C3-4 退回区域", main.state["node"] == "region")
	main._on_hotspot("stacks_deep", "ink_blur")
	main._on_closeup_hotspot("stacks_deep", "ink_blur", "trace_next")
	chk("C3-5 c_next(描下次)", "c_next" in _clues())
	main._on_settlement_continue()
	main._on_closeup_back()
	main._on_hotspot("stacks_deep", "basin")
	chk("C3-6 c_basin(搪瓷盆·漏雨裂缝)", "c_basin" in _clues())
	# 门廊
	main._on_goto("entry_porch")
	chk("C4-0 门廊(馆员不在场·独处·肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible())+" curator="+_curator())
	main._on_hotspot("entry_porch", "umbrella")
	chk("C4-1 c_umb1", "c_umb1" in _clues())
	main._on_hotspot("entry_porch", "lamp_behind")
	chk("C4-2 c_lamp2", "c_lamp2" in _clues())
	# Reveal 门控 c_book + c_name
	_to_region("service_desk")
	main._on_hotspot("service_desk", "notice_card")
	main._refresh_region_controls()
	chk("C6-1 只c_name→reveal不解锁", !_actions_has("拼合那一夜"))
	_to_region("stacks_deep")
	main._on_hotspot("stacks_deep", "rain_book")
	main._on_closeup_hotspot("stacks_deep", "rain_book", "read_book")
	main._on_settlement_continue()
	main._on_closeup_back()
	main._refresh_region_controls()
	chk("C6-2 只c_book→reveal不解锁", !_actions_has("拼合那一夜"))
	_to_region("service_desk")
	main._on_hotspot("service_desk", "notice_card")
	main._on_goto("stacks_deep")
	main._on_hotspot("stacks_deep", "rain_book")
	main._on_closeup_hotspot("stacks_deep", "rain_book", "read_book")
	main._on_settlement_continue()
	main._on_closeup_back()
	main._refresh_region_controls()
	chk("C6-3 双clue→reveal解锁", _actions_has("拼合那一夜"), str(_actions()))
	main._on_enter_reveal()
	chk("C6-3 reveal 进入", main.state["node"] == "reveal" and _stage().contains("一屋子的雨"), _stage())
	chk("C8-2 reveal 解锁记忆 m_rain", main.state["memories"].has("m_rain"), str(main.state["memories"]))
	main._on_node_action("to_utility")
	chk("C6-4 reveal→便民区(还书前置)", main.state["node"] == "region" and main.state["currentRegion"] == "utility_zone")
	# 还书前：服务台不出现对话入口
	main._on_goto("service_desk")
	chk("C7-0 还书前不出现对话入口", not _hotspots_has("与管理员说话"))
	# 进便民区（hook 三选项 → c_returned）
	main._on_goto("utility_zone")
	main._on_hotspot("utility_zone", "lost_found")
	main._on_closeup_hotspot("utility_zone", "lost_found", "mailbox_slot")
	var mb_c = main.content["regions"]["utility_zone"]["hotspots"]["lost_found"]["closeup"]["hotspots"]["mailbox_slot"]
	main._on_hook_choice("utility_zone", "lost_found", mb_c, "evade", "closeup", "lost_found")
	chk("C7-1 还书置位 c_returned + c_tier_evade", main.state.get("c_returned", false) and "c_tier_evade" in _clues(), str(_clues()))
	main._on_settlement_continue()
	main._on_closeup_back()
	# C7-7 沉默旁观者：事件触发后出现在配套区、肖像可见、不自动说话，玩家主动对话才出声（按态给回响）
	chk("C7-7a 事件触发后配套区出现『他在你身边』入口", _hotspots_has("他就在你身边"))
	chk("C7-7b 配套区肖像可见（他出现）", _portrait_visible())
	chk("C7-7c 触发瞬间未自动开口（沉默陪伴）", _curator().contains("没说话") or _curator().contains("陪着") or _curator().contains("没催"))
	main._on_hotspot("utility_zone", "with_him")
	chk("C7-7d 点入口出现『你想说点什么』", _actions_has("你想说点什么"))
	main._on_ask("utility_zone", "with_him", "")
	chk("C7-7e evade 态主动对话→他点破『你其实没在收拾，你在躲』", _curator().contains("你其实没在收拾") and _curator().contains("你在躲"), _curator())
	main._on_goto("service_desk")
	chk("C7-2 还书后出现对话入口", _hotspots_has("与管理员说话"))
	main._on_hotspot("service_desk", "talk_librarian")
	chk("C7-3 对话结算页", _stage().contains("【结算】"), _stage())
	main._on_settlement_continue()
	chk("C7-4 出馆节点", main.state["node"] == "exit" and _stage().contains("正式还了"), _stage())
	main._on_node_action("to_close")
	chk("C7-5 收场 curtain(夜C末尾·无继续→落回重开)", _stage().contains("今夜闭馆"), _stage())
	# C7-6 三态数据完整性静态校验（evade/erase/face 各自置对应 c_tier_* + c_returned）
	var mb_s = main.content["regions"]["utility_zone"]["hotspots"]["lost_found"]["closeup"]["hotspots"]["mailbox_slot"]
	for tier_opt in ["evade", "erase", "face"]:
		var hr_s = mb_s["hookResults"][tier_opt]
		chk("C7-6 " + tier_opt + " 置 c_tier_" + tier_opt, hr_s["clue"]["id"] == "c_tier_" + tier_opt and hr_s["setFlag"] == "c_returned", str(hr_s))
	# 自习区留灯
	main._on_goto("study_zone")
	chk("C9-0 自习区初入·馆员不在场(肖像隐)", not _portrait_visible() and _curator() == "", "portrait="+str(_portrait_visible()))
	main._on_hotspot("study_zone", "keep_lamp")
	chk("C9-1 留灯→馆员走动到场(肖像显)", _portrait_visible())
	chk("C9-2 留灯台词", _curator().contains("一直替你留着"), _curator())
	chk("C9-3 留灯线索 c_lamp_kept", "c_lamp_kept" in _clues())
	# 夜C 区域出口数（同 §2.2 树边）
	var c_expect := {
		"entry_porch": 1, "service_desk": 3, "lounge_stairs": 1,
		"archive_lamp": 1, "utility_zone": 1, "reading_room": 3,
		"stacks_deep": 1, "study_zone": 1
	}
	var c_exits_ok := true
	for rid in c_expect.keys():
		main._on_goto(rid)
		var n_c := 0
		for t in _actions():
			if t.ends_with("→"):
				n_c += 1
		if n_c != c_expect[rid]:
			c_exits_ok = false
			chk("C5 出口数 (" + rid + ")", false, "期望=" + str(c_expect[rid]) + " 实际=" + str(n_c))
	chk("C5 各区域出口数符合 §2.2 树边", c_exits_ok)
	chk("C5 void_room 永不开启", not ("void_room" in ProgressState.unlocked_zones))
	var c_home_ok := true
	for rid in ["entry_porch","service_desk","reading_room","stacks_deep","study_zone","utility_zone","lounge_stairs","archive_lamp"]:
		main._on_goto(rid)
		if not _actions_has("回到服务台"):
			c_home_ok = false
			chk("C5b 回服务台(" + rid + ")", false)
	chk("C5b 八区均常驻「回到服务台」", c_home_ok)

	# ── D. 夜D + 跨夜携带验证 ──
	# （验证 Step 2：夜与夜真正串联；以及夜D 闸门双爆点流程。
	#   本块不改动 A/B/C 已断言状态——A/B/C 在上文各自 _to_enter/_to_region 重置过。）
	print("")
	print("==== 夜D + 跨夜携带验证 ====")
	# 模拟：第一幕三夜实际累积的可携带进度，先快照进跨夜位（_carry_forward）
	main.state = main._fresh_state()
	main.state["clues"] = {
		"c_name": "你的名字出现在逾期通知上",
		"c_letter": "夹在书里的信",
		"c_book": "一屋子的雨",
		"c_album": "满员的书架",
		"c_tier_face": "面对",
		"c_lamp_kept": "自习区的灯",
	}
	main.state["memories"] = {"m_forgot": "忘了的事", "m_family": "家里的事"}
	main.state["mailedLetter"] = true
	main.state["hookChosenLine"] = {"drawer_note": "（便签复述）"}
	main._carry_forward()
	# 加载夜D：应自动并入上述携带字段（证明夜与夜串联跑动）
	main.load_night_by_id("night_d")
	chk("D0-0 夜D 加载成功", main.content["id"] == "night_d", main.content.get("id", ""))
	chk("D0-1 跨夜携带: c_name 并入夜D", "c_name" in main.state["clues"])
	chk("D0-2 跨夜携带: c_letter 并入夜D", "c_letter" in main.state["clues"])
	chk("D0-3 跨夜携带: c_book 并入夜D", "c_book" in main.state["clues"])
	chk("D0-4 跨夜携带: c_album 并入夜D", "c_album" in main.state["clues"])
	chk("D0-5 跨夜携带: c_tier_face 并入夜D", "c_tier_face" in main.state["clues"])
	chk("D0-6 跨夜携带: memories 并入夜D", "m_forgot" in main.state["memories"] and "m_family" in main.state["memories"])
	chk("D0-7 跨夜携带: mailedLetter 并入夜D", main.state["mailedLetter"] == true)
	# 管理员专属区夜D 解锁（锁区在夜D 开放）
	chk("D1-0 lounge_stairs 夜D 解锁", not bool(main.content["regions"]["lounge_stairs"].get("locked", false)))
	chk("D1-1 archive_lamp 夜D 解锁", not bool(main.content["regions"]["archive_lamp"].get("locked", false)))
	# 进馆：notice -> enter -> 服务台
	main._on_node_action("read")
	main._on_node_action("desk")
	chk("D1-2 进馆到服务台", main.state["node"] == "hub" and main.state["currentRegion"] == "service_desk")
	# 服务台：废稿（很久没见你的，是他自己）
	main._on_hotspot("service_desk", "desk_draft")
	chk("D2-0 废稿 c_draft", "c_draft" in main.state["clues"])
	# 背后楼梯：管理员习惯与你同款（情感伏笔）
	main._on_goto("lounge_stairs")
	chk("D3-0 背后楼梯上屏", _stage().contains("休息室") or _stage().contains("茶"), _stage())
	main._on_hotspot("lounge_stairs", "his_desk")
	main._on_closeup_hotspot("lounge_stairs", "his_desk", "same_habit")
	chk("D3-1 习惯同款 c_habit", "c_habit" in main.state["clues"])
	main._on_settlement_continue()
	main._on_closeup_back()
	# 档案室：借阅卡机关（逻辑闸门）
	main._on_goto("archive_lamp")
	main._on_hotspot("archive_lamp", "borrow_card")
	main._on_closeup_hotspot("archive_lamp", "borrow_card", "sign")
	chk("D4-0 借阅卡 c_borrow_card", "c_borrow_card" in main.state["clues"])
	main._on_settlement_continue()
	main._on_closeup_back()
	# 返回区域后，拼合按钮应出现（requiresClues 满足）
	chk("D4-1 拼合按钮出现", _actions_has("拼合那一夜"))
	main._on_enter_reveal()
	chk("D5-0 revealSeen 置位", main.state["revealSeen"] == true)
	chk("D5-1 逻辑爆点: 三夜decoy书借阅人全是你自己", _stage().contains("都是我") or _stage().contains("同一个名字"), _stage())
	chk("D5-2 情感爆点: 他本就是你自己遗落的那部分", _stage().contains("遗落的那部分") or _stage().contains("留下的你"), _stage())
	chk("D5-3 记忆解锁 m_self_left", "m_self_left" in main.state["memories"])
	# 出馆 + 收场（夜D 无 next，Act2 未做 → 落回重开）
	main._on_node_action("to_exit")
	chk("D6-0 出馆节点", main.state["node"] == "exit")
	main._on_node_action("to_close")
	chk("D6-1 收场 curtain（夜D 末尾·无继续→落回重开，Act2 未做）", _stage().contains("今夜闭馆"), _stage())

	# ── E. 夜E + 跨夜携带验证（D→E 真正串联 + 赶人/放手对应夜D）──
	print("")
	print("==== 夜E（赶你出去的夜）+ 跨夜携带验证 ====")
	# 模拟：夜D 实际累积的可携带进度（c_draft/c_habit/c_borrow_card + m_self_left + revealSeen），先快照进跨夜位
	main.state = main._fresh_state()
	main.state["clues"] = {
		"c_draft": "废稿字迹=通知字迹",
		"c_habit": "管理员习惯=你的习惯",
		"c_borrow_card": "三本decoy书借阅人全是你"
	}
	main.state["memories"] = {"m_self_left": "留下的自己"}
	main.state["mailedLetter"] = true
	main.state["revealSeen"] = true
	main._carry_forward()
	main.load_night_by_id("night_e")
	chk("E0-0 夜E 加载成功", main.content["id"] == "night_e", main.content.get("id", ""))
	chk("E0-1 跨夜携带: c_draft 并入夜E", "c_draft" in main.state["clues"])
	chk("E0-2 跨夜携带: c_habit 并入夜E", "c_habit" in main.state["clues"])
	chk("E0-3 跨夜携带: c_borrow_card 并入夜E", "c_borrow_card" in main.state["clues"])
	chk("E0-4 跨夜携带: m_self_left 并入夜E", "m_self_left" in main.state["memories"])
	chk("E0-5 跨夜携带: revealSeen 并入夜E", main.state["revealSeen"] == true)
	chk("E0-6 续接声明 next=night_f", main.content.has("next") and main.content["next"] == "night_f")
	# notice 上屏（赶人前兆）
	chk("E1-0 notice 上屏(第六天·门里有人)", _stage().contains("第六天") and _stage().contains("门里有人"), _stage())
	main._on_node_action("read")
	chk("E1-2 read→enter(门被抵住)", main.state["node"] == "enter" and _stage().contains("门从里面被抵住"), _stage())
	main._on_node_action("desk")
	chk("E1-3 desk→hub+服务台", main.state["node"] == "hub" and main.state["currentRegion"] == "service_desk")
	# 服务台：反常（『不急』的茶不在）+ 抽屉便签(物证①)
	main._on_hotspot("service_desk", "desk_empty")
	chk("E2-0 反常 c_no_tea", "c_no_tea" in main.state["clues"])
	main._on_hotspot("service_desk", "drawer_note")
	chk("E2-1 物证① c_kept_note", "c_kept_note" in main.state["clues"])
	# 门廊：门被抵住 + 赶人 hook（stay/go → c_letgo）
	main._on_goto("entry_porch")
	chk("E3-0 门廊(馆员在场·门被抵住)", _portrait_visible() and _curator().contains("没让你进"), "portrait="+str(_portrait_visible())+" curator="+_curator())
	main._on_hotspot("entry_porch", "door_block")
	chk("E3-1 赶人 hook 提问上屏", _actions_has("再多站一会儿") and _actions_has("好，我走"), str(_actions()))
	var eb = main.content["regions"]["entry_porch"]["hotspots"]["door_block"]
	main._on_hook_choice("entry_porch", "door_block", eb, "go", "region", "")
	chk("E3-2 赶人→c_letgo", "c_letgo" in main.state["clues"] and _stage().contains("走吧"), _stage())
	main._on_settlement_continue()
	# 阅览区：物证②（相册书）；书库：物证③（雨水盆）；自习区：留灯
	main._on_goto("reading_room")
	main._on_hotspot("reading_room", "kept_album")
	chk("E4-0 物证② c_kept_album", "c_kept_album" in main.state["clues"])
	main._on_goto("stacks_deep")
	main._on_hotspot("stacks_deep", "kept_basin")
	chk("E4-1 物证③ c_kept_basin", "c_kept_basin" in main.state["clues"])
	main._on_goto("study_zone")
	main._on_hotspot("study_zone", "keep_lamp")
	chk("E4-2 留灯 c_lamp_kept", "c_lamp_kept" in main.state["clues"])
	# 揭示（复用夜D门控线索，跨夜携带触发）——测试『夜与夜真正串联』
	main._refresh_region_controls()
	chk("E5-0 拼合按钮出现(跨夜线索满足)", _actions_has("拼合那一夜"), str(_actions()))
	main._on_enter_reveal()
	chk("E5-1 revealSeen 置位", main.state["revealSeen"] == true)
	chk("E5-2 接受放手: 他替我拖着不走的那本逾期书", _stage().contains("替我拖着不走") or _stage().contains("逾期书"), _stage())
	chk("E5-3 接受放手: 因爱放手(不是赶是放)", _stage().contains("肯放") or _stage().contains("该放"), _stage())
	chk("E5-4 记忆解锁 m_letgo", "m_letgo" in main.state["memories"])
	main._on_node_action("to_exit")
	chk("E6-0 出馆节点(灯在身后亮着)", main.state["node"] == "exit" and _stage().contains("灯还亮着"), _stage())
	main._on_node_action("to_close")
	chk("E6-1 收场 curtain(含继续→夜F)", _stage().contains("今夜闭馆") and _actions_has("继续"), _stage())
	# 夜E 区域出口数（同 §2.2 树边，镜像夜D 图）
	var e_expect := {
		"entry_porch": 1, "service_desk": 5, "lounge_stairs": 1,
		"archive_lamp": 1, "utility_zone": 1, "reading_room": 3,
		"stacks_deep": 1, "study_zone": 1
	}
	var e_exits_ok := true
	for rid in e_expect.keys():
		main._on_goto(rid)
		var n_e := 0
		for t in _actions():
			if t.ends_with("→"):
				n_e += 1
		if n_e != e_expect[rid]:
			e_exits_ok = false
			chk("E5 出口数 (" + rid + ")", false, "期望=" + str(e_expect[rid]) + " 实际=" + str(n_e))
	chk("E5 各区域出口数符合 §2.2 树边", e_exits_ok)
	chk("E5 void_room 永不开启", not ("void_room" in ProgressState.unlocked_zones))
	var e_home_ok := true
	for rid in ["entry_porch","service_desk","reading_room","stacks_deep","study_zone","utility_zone","lounge_stairs","archive_lamp"]:
		main._on_goto(rid)
		if not _actions_has("回到服务台"):
			e_home_ok = false
			chk("E5b 回服务台(" + rid + ")", false)
	chk("E5b 八区均常驻「回到服务台」", e_home_ok)
	# ── F. 夜F《三物证合流》+ 跨夜携带验证（E→F 真正串联·三物证合流锚点）──
	print("")
	print("==== 夜F（三物证合流·预兆夜）+ 跨夜携带验证 ====")
	# 真实链路：点『继续』即 _carry_forward() 后 load 夜F；此处手动复刻，证明 E→F 串联
	main._carry_forward()
	main.load_night_by_id("night_f")
	chk("F0-0 夜F 加载成功", main.content["id"] == "night_f", main.content.get("id", ""))
	chk("F0-1 跨夜携带: c_kept_note(物证①) 并入夜F", "c_kept_note" in main.state["clues"])
	chk("F0-2 跨夜携带: c_kept_album(物证②) 并入夜F", "c_kept_album" in main.state["clues"])
	chk("F0-3 跨夜携带: c_kept_basin(物证③) 并入夜F", "c_kept_basin" in main.state["clues"])
	chk("F0-4 跨夜携带: c_letgo 并入夜F", "c_letgo" in main.state["clues"])
	chk("F0-5 跨夜携带: c_draft/c_habit/c_borrow_card 仍并入夜F", "c_draft" in main.state["clues"] and "c_habit" in main.state["clues"] and "c_borrow_card" in main.state["clues"])
	chk("F0-6 续接声明 next=night_g(第三幕已接通·收场含继续)", main.content.has("next") and main.content["next"] == "night_g")
	# notice 上屏（第七天·没通知·你自己回来）
	chk("F1-0 notice 上屏(第七天·没通知·自己回来)", _stage().contains("第七天") and _stage().contains("没有逾期通知") and _stage().contains("自己回来"), _stage())
	main._on_node_action("read")
	chk("F1-1 read→enter(问出口·他把三样东西摆出来)", main.state["node"] == "enter" and _stage().contains("你到底是谁") and _stage().contains("我替你收着"), _stage())
	main._on_node_action("desk")
	chk("F1-2 desk→hub+服务台", main.state["node"] == "hub" and main.state["currentRegion"] == "service_desk")
	# 门廊：门没锁·你自己回来的
	main._on_goto("entry_porch")
	main._on_hotspot("entry_porch", "door_unlocked")
	chk("F2-0 门廊(门没锁·自己回来)", _stage().contains("门没锁"), _stage())
	# 阅览区：常坐空位·清醒地看自己
	main._on_goto("reading_room")
	main._on_hotspot("reading_room", "empty_seat")
	chk("F2-1 阅览区(常坐空位·躲开自己那一本)", _stage().contains("空位") and _stage().contains("躲开自己"), _stage())
	# 服务台：三物证合流 hook（认领/推回 → 均 c_knowing·Relief 消失）
	main._on_goto("service_desk")
	main._on_hotspot("service_desk", "three_things")
	chk("F3-0 三物证 hook 提问上屏(要认领吗)", _actions_has("都是我落下的") and _actions_has("下次再整理"), str(_actions()))
	var fb = main.content["regions"]["service_desk"]["hotspots"]["three_things"]
	main._on_hook_choice("service_desk", "three_things", fb, "push_back", "region", "")
	chk("F3-1 推回『下次』→c_knowing(清醒地转)", "c_knowing" in main.state["clues"] and _stage().contains("下次"), _stage())
	chk("F3-2 Relief 消失(那口松没来/不再让你轻松)", _stage().contains("那口松没来") or _stage().contains("没让你松"), _stage())
	main._on_settlement_continue()
	# 揭示（复用三物证门控·跨夜携带触发）——测试 E→F『夜与夜真正串联』
	main._refresh_region_controls()
	chk("F4-0 三物证合流 reveal 解锁(三边物证满足)", _actions_has("拼合那一夜"), str(_actions()))
	main._on_enter_reveal()
	chk("F4-1 revealSeen 置位", main.state["revealSeen"] == true)
	chk("F4-2 落点·清醒地转: 看见了还绕/睁着眼", _stage().contains("看见了，还绕") or _stage().contains("睁着眼"), _stage())
	chk("F4-3 落点·新重量: 知道自己在绕开成了新的重量", _stage().contains("知道自己在绕开") and _stage().contains("新的重量"), _stage())
	chk("F4-4 红线: 不写成『现在都做到了』(仍是循环没停)", (_stage().contains("循环没有停") or _stage().contains("还在转")) and not _stage().contains("我做到了"), _stage())
	chk("F4-5 记忆解锁 m_knowing", "m_knowing" in main.state["memories"])
	main._on_node_action("to_exit")
	chk("F5-0 出馆节点(灯还亮着·睁着眼走)", main.state["node"] == "exit" and _stage().contains("灯还亮着") and _stage().contains("睁着眼"), _stage())
	main._on_node_action("to_close")
	chk("F5-1 收场 curtain(夜F 末尾·无 next→落回重开)", _stage().contains("今夜闭馆"), _stage())
	# 夜F 区域出口数（预兆夜·收拢为 3 区 + void）
	var f_expect := { "entry_porch": 1, "service_desk": 2, "reading_room": 1 }
	var f_exits_ok := true
	for rid in f_expect.keys():
		main._on_goto(rid)
		var n_f := 0
		for t in _actions():
			if t.ends_with("→"):
				n_f += 1
		if n_f != f_expect[rid]:
			f_exits_ok = false
			chk("F6 出口数 (" + rid + ")", false, "期望=" + str(f_expect[rid]) + " 实际=" + str(n_f))
	chk("F6 各区域出口数符合预兆夜收拢拓扑", f_exits_ok)
	chk("F6 void_room 永不开启", not ("void_room" in ProgressState.unlocked_zones))
	var f_home_ok := true
	for rid in ["entry_porch","service_desk","reading_room"]:
		main._on_goto(rid)
		if not _actions_has("回到服务台"):
			f_home_ok = false
			chk("F6b 回服务台(" + rid + ")", false)
	chk("F6b 三区均常驻「回到服务台」", f_home_ok)

	# ── G. 夜G《灯是谁装的》+ 跨夜携带验证（F→G 串联·狂欢①·点灯含义）──
	print("")
	print("==== 夜G（灯是谁装的·狂欢①）+ 跨夜携带验证 ====")
	# 模拟夜F 实际累积的可携带进度（三物证 + 放手 + 留灯），先快照进跨夜位
	main.state = main._fresh_state()
	main.state["clues"] = {
		"c_kept_note": "物证①便签", "c_kept_album": "物证②相册",
		"c_kept_basin": "物证③雨水盆", "c_letgo": "接受放手", "c_lamp_kept": "自习区留灯"
	}
	main.state["memories"] = { "m_letgo": "接受放手" }
	main._carry_forward()
	main.load_night_by_id("night_g")
	chk("G0-0 夜G 加载成功", main.content["id"] == "night_g", main.content.get("id", ""))
	chk("G0-1 续接声明 next=night_h", main.content.has("next") and main.content["next"] == "night_h")
	chk("G0-2 跨夜携带: c_kept_note/album/basin 并入夜G", "c_kept_note" in main.state["clues"] and "c_kept_album" in main.state["clues"] and "c_kept_basin" in main.state["clues"])
	chk("G0-3 跨夜携带: c_letgo/m_letgo 并入夜G", "c_letgo" in main.state["clues"] and "m_letgo" in main.state["memories"])
	# notice 上屏（第八天·《灯是谁装的》逾期通知）
	chk("G1-0 notice 上屏(第八天·灯是谁装的·逾期通知)", _stage().contains("第八天") and _stage().contains("灯是谁装的") and _stage().contains("逾期不息"), _stage())
	main._on_node_action("read")
	chk("G1-1 read→enter(比你开朗·带你看馆)", main.state["node"] == "enter" and _stage().contains("带你看看这馆"), _stage())
	main._on_node_action("desk")
	chk("G1-2 desk→hub+服务台", main.state["node"] == "hub" and main.state["currentRegion"] == "service_desk")
	# 服务台：灯是他装的（甜）
	main._on_hotspot("service_desk", "lamp_intro")
	chk("G2-0 灯是他装的 c_lamp_g", "c_lamp_g" in main.state["clues"])
	# 门廊：灯从没灭过（甜里带刺）
	main._on_goto("entry_porch")
	main._on_hotspot("entry_porch", "lamp_behind")
	chk("G2-1 灯没灭过 c_lamp2_g", "c_lamp2_g" in main.state["clues"])
	# 阅览区：整座馆都是他给你留的
	main._on_goto("reading_room")
	main._on_hotspot("reading_room", "his_shelf")
	chk("G2-2 整座馆给你留的 c_shelf_g", "c_shelf_g" in main.state["clues"])
	# 自习区：留灯仪式
	main._on_goto("study_zone")
	main._on_hotspot("study_zone", "keep_lamp")
	chk("G2-3 留灯 c_lamp_kept", "c_lamp_kept" in main.state["clues"])
	# 灯控室：灯是他装的（closeup）→ 点灯含义（灯＝你自己不肯灭的光外化成他）
	main._on_goto("archive_lamp")
	main._on_hotspot("archive_lamp", "lamp_install")
	chk("G3-0 进近景(node=closeup)", main.state["node"] == "closeup")
	main._on_closeup_hotspot("archive_lamp", "lamp_install", "see_lamp")
	chk("G3-1 灯的含义 c_lamp_meaning(灯=你自己不肯灭的光外化成他)", "c_lamp_meaning" in main.state["clues"])
	chk("G3-2 灯的含义文案: 灯不是他的/不肯灭", _stage().contains("灯不是他的") or _stage().contains("不肯灭"), _stage())
	main._on_settlement_continue()
	main._on_closeup_back()
	# 出馆 + 收场（续接夜H）
	main._on_node_action("to_close")
	chk("G4-0 收场 curtain(含继续→夜H)", _stage().contains("今夜闭馆") and _actions_has("继续"), _stage())
	# 夜G 区域出口数（狂欢①·5 区 + void）
	var g_expect := { "service_desk": 4, "entry_porch": 1, "reading_room": 1, "study_zone": 1, "archive_lamp": 1 }
	var g_exits_ok := true
	for rid in g_expect.keys():
		main._on_goto(rid)
		var n_g := 0
		for t in _actions():
			if t.ends_with("→"):
				n_g += 1
		if n_g != g_expect[rid]:
			g_exits_ok = false
			chk("G5 出口数 (" + rid + ")", false, "期望=" + str(g_expect[rid]) + " 实际=" + str(n_g))
	chk("G5 各区域出口数符合狂欢①拓扑", g_exits_ok)
	chk("G5 void_room 永不开启", not ("void_room" in ProgressState.unlocked_zones))
	var g_home_ok := true
	for rid in ["service_desk","entry_porch","reading_room","study_zone","archive_lamp"]:
		main._on_goto(rid)
		if not _actions_has("回到服务台"):
			g_home_ok = false
			chk("G5b 回服务台(" + rid + ")", false)
	chk("G5b 五区均常驻「回到服务台」", g_home_ok)

	# ── H. 夜H《档案室半开的门》+ 跨夜携带验证（G→H 串联·狂欢②·种序章本伏笔）──
	print("")
	print("==== 夜H（档案室半开的门·狂欢②）+ 跨夜携带验证 ====")
	main.state = main._fresh_state()
	main.state["clues"] = {
		"c_kept_note": "物证①便签", "c_kept_album": "物证②相册", "c_kept_basin": "物证③雨水盆",
		"c_lamp_kept": "自习区留灯", "c_lamp_meaning": "灯=你自己不肯灭的光"
	}
	main.state["memories"] = { "m_letgo": "接受放手" }
	main._carry_forward()
	main.load_night_by_id("night_h")
	chk("H0-0 夜H 加载成功", main.content["id"] == "night_h", main.content.get("id", ""))
	chk("H0-1 续接声明 next=night_i", main.content.has("next") and main.content["next"] == "night_i")
	chk("H0-2 跨夜携带: c_lamp_meaning 并入夜H", "c_lamp_meaning" in main.state["clues"])
	# notice 上屏（第九天·《档案室半开的门》逾期通知）
	chk("H1-0 notice 上屏(第九天·档案室半开的门·逾期通知)", _stage().contains("第九天") and _stage().contains("档案室半开的门"), _stage())
	main._on_node_action("read")
	chk("H1-1 read→enter(比昨天更开朗·全是给你留的)", main.state["node"] == "enter" and _stage().contains("全是给你留的"), _stage())
	main._on_node_action("desk")
	chk("H1-2 desk→hub+服务台", main.state["node"] == "hub" and main.state["currentRegion"] == "service_desk")
	# 服务台：他仍在逃分离（甜里带反常）
	main._on_hotspot("service_desk", "sweet_claim")
	chk("H2-0 仍在逃分离 c_claim_h", "c_claim_h" in main.state["clues"])
	# 档案室：半开的门（closeup）→ 序章续借本「等你还」·夜Z回收锚点
	main._on_goto("archive_lamp")
	main._on_hotspot("archive_lamp", "half_open_door")
	chk("H3-0 进近景(node=closeup)", main.state["node"] == "closeup")
	main._on_closeup_hotspot("archive_lamp", "half_open_door", "read_card")
	chk("H3-1 序章本伏笔 c_prologue_book_waiting(夜Z回收锚)", "c_prologue_book_waiting" in main.state["clues"])
	chk("H3-2 伏笔文案: 等你还", _stage().contains("等你还"), _stage())
	main._on_settlement_continue()
	main._on_closeup_back()
	# 门廊：灯暖得反常
	main._on_goto("entry_porch")
	main._on_hotspot("entry_porch", "lamp_behind")
	chk("H3-3 灯暖得反常 c_lamp2_h", "c_lamp2_h" in main.state["clues"])
	# 阅览区：每句炫耀底下藏着『再多留一夜』
	main._on_goto("reading_room")
	main._on_hotspot("reading_room", "his_shelf")
	chk("H3-4 他在逃分离 c_shelf_h", "c_shelf_h" in main.state["clues"])
	# 出馆 + 收场（续接夜I）
	main._on_node_action("to_close")
	chk("H4-0 收场 curtain(含继续→夜I)", _stage().contains("今夜闭馆") and _actions_has("继续"), _stage())
	# 夜H 区域出口数（狂欢②·4 区 + void）
	var h_expect := { "service_desk": 3, "archive_lamp": 1, "entry_porch": 1, "reading_room": 1 }
	var h_exits_ok := true
	for rid in h_expect.keys():
		main._on_goto(rid)
		var n_h := 0
		for t in _actions():
			if t.ends_with("→"):
				n_h += 1
		if n_h != h_expect[rid]:
			h_exits_ok = false
			chk("H5 出口数 (" + rid + ")", false, "期望=" + str(h_expect[rid]) + " 实际=" + str(n_h))
	chk("H5 各区域出口数符合狂欢②拓扑", h_exits_ok)
	chk("H5 void_room 永不开启", not ("void_room" in ProgressState.unlocked_zones))
	var h_home_ok := true
	for rid in ["service_desk","archive_lamp","entry_porch","reading_room"]:
		main._on_goto(rid)
		if not _actions_has("回到服务台"):
			h_home_ok = false
			chk("H5b 回服务台(" + rid + ")", false)
	chk("H5b 四区均常驻「回到服务台」", h_home_ok)

	# ── I. 夜I《最后一盏灯前的玩笑》+ 跨夜携带验证（H→I 串联·狂欢③·双侧逃避同框）──
	print("")
	print("==== 夜I（最后一盏灯前的玩笑·狂欢③）+ 跨夜携带验证 ====")
	main.state = main._fresh_state()
	main.state["clues"] = {
		"c_kept_note": "物证①便签", "c_kept_album": "物证②相册", "c_kept_basin": "物证③雨水盆",
		"c_prologue_book_waiting": "序章续借本等你还", "c_lamp_kept": "自习区留灯"
	}
	main.state["memories"] = { "m_letgo": "接受放手" }
	main._carry_forward()
	main.load_night_by_id("night_i")
	chk("I0-0 夜I 加载成功", main.content["id"] == "night_i", main.content.get("id", ""))
	chk("I0-1 续接声明 next=night_z", main.content.has("next") and main.content["next"] == "night_z")
	chk("I0-2 跨夜携带: c_prologue_book_waiting 并入夜I(夜H锚)", "c_prologue_book_waiting" in main.state["clues"])
	# notice 上屏（第十天·《最后一盏灯前的玩笑》逾期通知）
	chk("I1-0 notice 上屏(第十天·最后一盏灯前的玩笑·逾期通知)", _stage().contains("第十天") and _stage().contains("最后一盏灯前的玩笑"), _stage())
	main._on_node_action("read")
	chk("I1-1 read→enter(话最多·老友)", main.state["node"] == "enter" and (_stage().contains("话最多") or _stage().contains("老友")), _stage())
	main._on_node_action("desk")
	chk("I1-2 desk→hub+服务台", main.state["node"] == "hub" and main.state["currentRegion"] == "service_desk")
	# 服务台：难还的书 hook（双侧逃避同框）→ defer
	var ib = main.content["regions"]["service_desk"]["hotspots"]["hard_book"]
	main._on_hotspot("service_desk", "hard_book")
	chk("I2-0 难还的书 hook 提问上屏(推到明天/今天就还)", _actions_has("推到明天") and _actions_has("今天就还"), str(_actions()))
	main._on_hook_choice("service_desk", "hard_book", ib, "defer", "region", "")
	chk("I2-1 双侧逃避同框 c_stall_defer", "c_stall_defer" in main.state["clues"] and _stage().contains("明天"), _stage())
	main._on_settlement_continue()
	# 阅览区：他排的不是书架，是留住你的理由
	main._on_goto("reading_room")
	main._on_hotspot("reading_room", "his_shelf")
	chk("I3-0 仍在逃分离 c_shelf_i", "c_shelf_i" in main.state["clues"])
	# 便民配套区：登记册上你的名字（夜Z锚呼应）
	main._on_goto("utility_zone")
	main._on_hotspot("utility_zone", "register")
	chk("I3-1 登记册 c_reg_i", "c_reg_i" in main.state["clues"])
	chk("I3-2 登记册文案: 压得最久", _stage().contains("压得最久"), _stage())
	# 自习区：留灯仍在
	main._on_goto("study_zone")
	main._on_hotspot("study_zone", "keep_lamp")
	chk("I3-3 留灯 c_lamp_kept", "c_lamp_kept" in main.state["clues"])
	# 门廊：灯暖得反常
	main._on_goto("entry_porch")
	main._on_hotspot("entry_porch", "lamp_behind")
	chk("I3-4 灯暖得反常 c_lamp2_i", "c_lamp2_i" in main.state["clues"])
	# 出馆 + 收场（续接夜Z·终章）
	main._on_node_action("to_close")
	chk("I4-0 收场 curtain(含继续→夜Z)", _stage().contains("今夜闭馆") and _actions_has("继续"), _stage())
	# 夜I 区域出口数（狂欢③·5 区 + void）
	var i_expect := { "service_desk": 4, "reading_room": 1, "utility_zone": 1, "study_zone": 1, "entry_porch": 1 }
	var i_exits_ok := true
	for rid in i_expect.keys():
		main._on_goto(rid)
		var n_i := 0
		for t in _actions():
			if t.ends_with("→"):
				n_i += 1
		if n_i != i_expect[rid]:
			i_exits_ok = false
			chk("I5 出口数 (" + rid + ")", false, "期望=" + str(i_expect[rid]) + " 实际=" + str(n_i))
	chk("I5 各区域出口数符合狂欢③拓扑", i_exits_ok)
	chk("I5 void_room 永不开启", not ("void_room" in ProgressState.unlocked_zones))
	var i_home_ok := true
	for rid in ["service_desk","reading_room","utility_zone","study_zone","entry_porch"]:
		main._on_goto(rid)
		if not _actions_has("回到服务台"):
			i_home_ok = false
			chk("I5b 回服务台(" + rid + ")", false)
	chk("I5b 五区均常驻「回到服务台」", i_home_ok)

	# ── Z. 夜Z（终章·带书回来的人）+ 跨夜携带验证（单一必然BE＋callback＋收束句）──
	print("")
	print("==== 夜Z（终章·带书回来的人·单一必然BE）====")
	# 模拟夜H/I 实际累积的可携带进度：三物证（reveal门控）＋序章本伏笔（prologue_book门控）
	main.state = main._fresh_state()
	main.state["clues"] = {
		"c_kept_note": "物证①便签", "c_kept_album": "物证②相册", "c_kept_basin": "物证③雨水盆",
		"c_prologue_book_waiting": "序章续借本等你还"
	}
	main.state["memories"] = {}
	main.state["revealSeen"] = false
	main._carry_forward()
	main.load_night_by_id("night_z")
	chk("Z0-0 夜Z 加载成功", main.content["id"] == "night_z", main.content.get("id", ""))
	chk("Z0-1 终局无 next(单一必然BE)", not main.content.has("next"))
	chk("Z0-2 跨夜携带: 三物证并入夜Z", "c_kept_note" in main.state["clues"] and "c_kept_album" in main.state["clues"] and "c_kept_basin" in main.state["clues"])
	chk("Z0-3 跨夜携带: c_prologue_book_waiting 并入(夜H锚)", "c_prologue_book_waiting" in main.state["clues"])
	# notice 上屏（最后一天·没有通知·你自己来）
	chk("Z1-0 notice 上屏(最后一天·没通知·自己来)", _stage().contains("最后一天") and _stage().contains("没有通知"), _stage())
	main._on_node_action("read")
	chk("Z1-1 read→enter(解释一切·门一直没锁)", main.state["node"] == "enter" and _stage().contains("你自己留下来的那部分") and _stage().contains("门一直没锁"), _stage())
	main._on_node_action("desk")
	chk("Z1-2 desk→hub+服务台", main.state["node"] == "hub" and main.state["currentRegion"] == "service_desk")
	# 服务台：最后一次通知落空（桌上已写好未寄出单）
	main._on_hotspot("service_desk", "unwritten_notice")
	chk("Z2-0 未寄出通知 c_unwritten", "c_unwritten" in main.state["clues"])
	chk("Z2-1 他爱你所以放手(因为你自己来了)", _stage().contains("你自己来了") or _stage().contains("放手"), _stage())
	main._on_settlement_continue()
	# 服务台：prologue_book 门控——reveal 前 choose_ending 不可见（requiresReveal 真门控）
	main._on_hotspot("service_desk", "prologue_book")
	chk("Z2-2 prologue_book 进入近景(requiresFlag满足)", main.state["node"] == "closeup")
	chk("Z2-3 门控: reveal前 choose_ending 不可见", not _hotspots_has("把它怎样"), str(_hotspots()))
	main._on_closeup_back()
	# 阅览区：三物证墙（callback 触发物）
	main._on_goto("reading_room")
	main._on_hotspot("reading_room", "three_wall")
	chk("Z3-0 三物证墙 c_wall_z", "c_wall_z" in main.state["clues"])
	# 灯控室：终章心脏瞬间·回声落地
	main._on_goto("archive_lamp")
	main._on_hotspot("archive_lamp", "echo_heart")
	chk("Z4-0 进近景(node=closeup)", main.state["node"] == "closeup")
	main._on_closeup_hotspot("archive_lamp", "echo_heart", "hear_echo")
	chk("Z4-1 回声 c_echo_realized(他的声音=你的逃避回声)", "c_echo_realized" in main.state["clues"])
	chk("Z4-2 推力文案: 把你变成我的样子", _stage().contains("变成我的样子"), _stage())
	main._on_settlement_continue()
	main._on_closeup_back()
	# 门廊：门没锁（最后一道不在场回收）
	main._on_goto("entry_porch")
	main._on_hotspot("entry_porch", "door_unlocked")
	chk("Z5-0 门没锁 c_door_z", "c_door_z" in main.state["clues"])
	# 揭示（三物证门控·跨夜携带触发）→ callback 知≠行闪回
	main._on_goto("service_desk")
	main._refresh_region_controls()
	chk("Z6-0 拼合按钮出现(三物证满足)", _actions_has("拼合那一夜"), str(_actions()))
	main._on_enter_reveal()
	chk("Z6-1 revealSeen 置位", main.state["revealSeen"] == true)
	chk("Z6-2 callback 知≠行: 我从来都知道要怎么做", _stage().contains("我从来都知道要怎么做"), _stage())
	chk("Z6-3 红线: 不写成『我做到了』(仍是知≠行缝隙)", not _stage().contains("我做到了"), _stage())
	chk("Z6-4 记忆解锁 m_final/m_echo_z", "m_final" in main.state["memories"] and "m_echo_z" in main.state["memories"])
	# 终章抉择（reveal 后 choose_ending 可见）：乙·告别必然落点
	main._on_goto("service_desk")
	main._on_hotspot("service_desk", "prologue_book")
	chk("Z7-0 reveal后 choose_ending 可见", _hotspots_has("把它怎样"), str(_hotspots()))
	var zb = main.content["regions"]["service_desk"]["hotspots"]["prologue_book"]["closeup"]["hotspots"]["choose_ending"]
	main._on_closeup_hotspot("service_desk", "prologue_book", "choose_ending")
	chk("Z7-1 抉择 hook 上屏(放回架/真正还他)", _actions_has("放回架") and _actions_has("真正还他"), str(_actions()))
	main._on_hook_choice("service_desk", "prologue_book", zb, "go", "closeup", "prologue_book")
	chk("Z7-2 乙·告别 c_ending_go(必然落点)", "c_ending_go" in main.state["clues"])
	main._on_settlement_continue()
	chk("Z7-3 抉择后→出馆节点(收束句: 灯还亮着——你终于不用等我了)", main.state["node"] == "exit" and _stage().contains("灯还亮着") and _stage().contains("你终于不用等我了"), _stage())
	# 终局收场（无继续）
	main._on_node_action("to_close")
	chk("Z8-0 终局收场无『继续』(单一必然BE)", _stage().contains("今夜闭馆") and not _actions_has("继续"), _stage())
	# 夜Z 区域出口数（终章·4 区 + void）
	var z_expect := { "service_desk": 3, "archive_lamp": 1, "reading_room": 1, "entry_porch": 1 }
	var z_exits_ok := true
	for rid in z_expect.keys():
		main._on_goto(rid)
		var n_z := 0
		for t in _actions():
			if t.ends_with("→"):
				n_z += 1
		if n_z != z_expect[rid]:
			z_exits_ok = false
			chk("Z9 出口数 (" + rid + ")", false, "期望=" + str(z_expect[rid]) + " 实际=" + str(n_z))
	chk("Z9 各区域出口数符合终章拓扑", z_exits_ok)
	chk("Z9 void_room 永不开启", not ("void_room" in ProgressState.unlocked_zones))
	var z_home_ok := true
	for rid in ["service_desk","archive_lamp","reading_room","entry_porch"]:
		main._on_goto(rid)
		if not _actions_has("回到服务台"):
			z_home_ok = false
			chk("Z9b 回服务台(" + rid + ")", false)
	chk("Z9b 四区均常驻「回到服务台」", z_home_ok)

	# ── 汇总 ──
	print("")
	print("==== 点测汇总（序章 + 夜A + 夜B + 夜C + 夜D + 夜E + 夜F + 夜G + 夜H + 夜I + 夜Z + 跨夜携带）====")
	print("PASS=%d  FAIL=%d" % [pass_count, fail_count])
	if fail_count > 0:
		print("FAILED: " + ", ".join(fails))
		get_tree().quit(1)
	else:
		print("ALL GREEN")
		get_tree().quit(0)
