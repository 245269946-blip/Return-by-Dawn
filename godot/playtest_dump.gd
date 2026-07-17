extends Node
# 《逾期之书》玩家向全流程试玩 dump（headless）
# 临时把 project.godot 的 run/main_scene 指向本场景，godot --headless 运行。
# 模拟真实玩家：读 notice/enter → 自由探索各区域 → 点击各 hotspot/closeup/hook/ask
# → 触发 reveal（若可）→ 走到 exit/收束句。每个有意义步骤 print 当前叙事文本，
# 供人工读评 叙事通过性 与 叙事剧情感。
# 关键检测：每一夜是否存在「可达出口」（玩家能否在 UI 中走到收场）。
# 注意：引擎钩子为扁平结构——热点含 "hook": true（布尔），options/hookResults/hookPrompt 在同层。

var main = null

func _ready() -> void:
	get_tree().create_timer(240.0).timeout.connect(func():
		print("[PLAYTEST] TIMEOUT — force quit(2)"); get_tree().quit(2))
	main = load("res://Main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(main)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_run_playtest()

# ── helpers（镜像 test_harness） ──
func _stage() -> String: return main.get_node("Panel/StageArea/Stage").text
func _curator() -> String: return main.get_node("Panel/DialogueBox/Curator").text
func _actions() -> Array:
	var a := []
	for c in main.get_node("Panel/StageArea/Actions").get_children():
		a.append(c.text)
	return a
func _actions_has(sub: String) -> bool:
	for t in _actions():
		if t.contains(sub): return true
	return false
func _clues() -> Array: return main.state["clues"].keys()
func _is_settlement() -> bool: return main.state["node"] == "settlement"

# 钩子判定（扁平结构）
func _is_hook(h) -> bool: return h.get("hook", false) == true
func _hook_has_toexit(h) -> bool:
	if not _is_hook(h): return false
	var res = h["hookResults"]
	for opt in h["options"]:
		if res.has(opt["id"]) and res[opt["id"]].get("toExit", false):
			return true
	return false

# ── 主流程 ──
func _run_playtest() -> void:
	var order := ["prologue","night_a","night_b","night_c","night_d","night_e","night_f","night_g","night_h","night_i","night_z"]
	for i in order.size():
		var nid = order[i]
		if i > 0:
			main._carry_forward()
		_playtest_night(nid)
	print("\n[PLAYTEST] ===== 全部夜试玩结束 =====")
	get_tree().quit(0)

func _playtest_night(nid: String) -> void:
	print("\n##################################################")
	print("##########  " + nid + "  ##########")
	print("##################################################")
	main.load_night_by_id(nid)
	print("\n[NOTICE 通知] " + _stage())
	main._on_node_action("read")
	print("\n[ENTER 进场] " + _stage())
	main._on_node_action("desk")
	# 自由探索：逐区域、逐热点
	var regions = main.content["regions"]
	for rid in regions.keys():
		var r = regions[rid]
		if r.get("void", false): continue
		main._on_goto(rid)
		print("\n--- 区域: " + rid + " ---")
		print("[场景描述] " + _stage())
		if _curator() != "": print("[馆员反应] " + _curator())
		var hots = r["hotspots"]
		for hid in hots.keys():
			var h = hots[hid]
			if h.get("requiresFlag","") != "" and not (main.state.get(h["requiresFlag"], false) or main.state["clues"].has(h["requiresFlag"])):
				print("  [门控未满足·探索阶段跳过] " + hid)
				continue
			_interact_hotspot(rid, hid, h)
	# 收场阶段
	_try_reach_exit(nid)
	print("\n[本夜线索] " + str(_clues()))

# ── 热点交互（探索阶段：跳过出口型，留待收场阶段统一触发） ──
func _interact_hotspot(rid: String, hid: String, h) -> void:
	if h.get("toExit", false):
		print("\n  >> 热点(出口型·探索阶段跳过): " + hid)
		return
	if _is_hook(h) and _hook_has_toexit(h):
		print("\n  >> 钩子(出口型·探索阶段跳过): " + hid)
		return
	print("\n  >> 热点: " + hid + " ［" + str(h.get("label","")) + "］")
	main._on_hotspot(rid, hid)
	if main.state["node"] == "closeup":
		print("    [近景] " + _stage())
		if _curator() != "": print("    [馆员] " + _curator())
		var subs = h["closeup"]["hotspots"]
		for subid in subs.keys():
			var s = subs[subid]
			if s.get("requiresReveal", false) and not main.state.get("revealSeen", false):
				print("      [requiresReveal 未满足·跳过] " + subid)
				continue
			if s.get("toExit", false):
				print("      · 近景子(出口型·探索阶段跳过): " + subid)
				continue
			if _is_hook(s) and _hook_has_toexit(s):
				print("      · 近景子钩子(出口型·跳过): " + subid)
				continue
			print("      · 近景子: " + subid)
			main._on_closeup_hotspot(rid, hid, subid)
			_after_interaction(rid, hid, s, true, hid)
		main._on_closeup_back()
		return
	if _is_hook(h):
		_dump_hook_options(h)
		var opt0 = h["options"][0]
		main._on_hook_choice(rid, hid, h, opt0["id"], "region")
		if _is_settlement(): _dump_settlement(); main._on_settlement_continue()
		return
	print("    [叙事] " + _stage())
	if _curator() != "": print("    [馆员] " + _curator())
	if _is_settlement(): _dump_settlement(); main._on_settlement_continue()
	if h.has("ask") and main._librarian_present(rid):
		main._on_ask(rid, hid, "")
		print("    [追问回应] " + _curator())

func _after_interaction(rid, hid, s, is_closeup, closeup_hid) -> void:
	if _is_settlement():
		_dump_settlement(); main._on_settlement_continue(); return
	if _is_hook(s):
		_dump_hook_options(s)
		var opt0 = s["options"][0]
		main._on_hook_choice(rid, hid, s, opt0["id"], "closeup", closeup_hid)
		if _is_settlement(): _dump_settlement(); main._on_settlement_continue()

func _dump_hook_options(h) -> void:
	print("    [钩子·可选分支]")
	for opt in h["options"]:
		print("      - " + str(opt["label"]))

func _dump_settlement() -> void:
	print("    [结算页] " + _stage())

# ── 收场阶段：触发 reveal（若可）+ 找到任意可达出口 ──
func _reveal_ready() -> bool:
	if not main.content.has("nodes") or not main.content["nodes"].has("reveal"):
		return false
	var req = main.content["nodes"]["reveal"]["requiresClues"]
	for cid in req:
		if not main.state["clues"].has(cid): return false
	return true

func _try_reach_exit(nid: String) -> void:
	print("\n--- 收场阶段：尝试走到收场 ---")
	if _reveal_ready():
		print("[reveal 可用] 进入『拼合那一夜』")
		main._on_enter_reveal()
		print("[REVEAL 拼合] " + _stage())
		if _curator() != "": print("[馆员] " + _curator())
		var acts = main.content["nodes"]["reveal"]["actions"]
		var aid = acts[0]["id"]
		main._on_node_action(aid)
		if _is_settlement(): _dump_settlement(); main._on_settlement_continue()
		# reveal 后二次探勘：置位 requiresReveal 门控的线索/旗标（如 night_a mailbox_slot → mailedLetter）
		_re_explore_after_reveal()
	if main.state["node"] != "exit":
		if not _fire_any_toexit():
			print("\n【叙事通过性 BLOCKER】夜 " + nid + "：UI 中无任何可达出口，玩家无法走到收场，exit 节点文本不可见！")
			main._on_node_action("to_close")
			print("[CURTAIN(强制渲染)] " + _stage())
			return
	print("\n[EXIT 出馆] " + _stage())
	if _curator() != "": print("[馆员] " + _curator())
	main._on_node_action("to_close")
	print("[CURTAIN 收场] " + _stage())
	if _actions_has("继续"): print("[收场动作] 含『继续 → 下一夜』")
	else: print("[收场动作] 无『继续』（终章/无后继）")

# reveal 后二次探勘：进入 requiresReveal 门控的近景子热点 / 钩子，置位其旗标（不触发出口）
func _re_explore_after_reveal() -> void:
	var regions = main.content["regions"]
	for rid in regions.keys():
		if regions[rid].get("void", false): continue
		var hots = regions[rid]["hotspots"]
		for hid in hots.keys():
			var h = hots[hid]
			if h.get("toExit", false): continue
			if not h.has("closeup"): continue
			var subs = h["closeup"]["hotspots"]
			var has_gated := false
			for subid in subs.keys():
				if subs[subid].get("requiresReveal", false): has_gated = true
			if not has_gated: continue
			main._on_goto(rid)
			main._on_hotspot(rid, hid)
			if main.state["node"] != "closeup": continue
			for subid in subs.keys():
				var s = subs[subid]
				if not s.get("requiresReveal", false): continue
				if s.get("toExit", false): continue
				if _is_hook(s):
					var opt0 = s["options"][0]
					main._on_closeup_hotspot(rid, hid, subid)
					main._on_hook_choice(rid, hid, s, opt0["id"], "closeup", hid)
				else:
					main._on_closeup_hotspot(rid, hid, subid)
				if _is_settlement(): _dump_settlement(); main._on_settlement_continue()
			main._on_closeup_back()

# 扫描所有区域及其近景，触发第一个 toExit（出口）
func _fire_any_toexit() -> bool:
	var regions = main.content["regions"]
	for rid in regions.keys():
		if regions[rid].get("void", false): continue
		main._on_goto(rid)
		var hots = regions[rid]["hotspots"]
		for hid in hots.keys():
			var h = hots[hid]
			if h.get("requiresFlag","") != "" and not (main.state.get(h["requiresFlag"], false) or main.state["clues"].has(h["requiresFlag"])):
				continue
			# 区域级 toExit 热点
			if h.get("toExit", false) and h.has("settlement"):
				print("[触发出口·区域热点] " + rid + "/" + hid)
				main._on_hotspot(rid, hid)
				if _is_settlement(): _dump_settlement(); main._on_settlement_continue()
				return true
			# 区域级 toExit 钩子
			if _is_hook(h) and _hook_has_toexit(h):
				for opt in h["options"]:
					var res = h["hookResults"]
					if res.has(opt["id"]) and res[opt["id"]].get("toExit", false):
						print("[触发出口·区域钩子] " + rid + "/" + hid + " → " + opt["id"])
						main._on_hotspot(rid, hid)
						main._on_hook_choice(rid, hid, h, opt["id"], "region")
						if _is_settlement(): _dump_settlement(); main._on_settlement_continue()
						return true
			# 近景内 toExit 子热点
			if h.has("closeup"):
				main._on_hotspot(rid, hid)
				if main.state["node"] == "closeup":
					var subs = h["closeup"]["hotspots"]
					for subid in subs.keys():
						var s = subs[subid]
						if s.get("requiresReveal", false) and not main.state.get("revealSeen", false):
							continue
						if s.get("toExit", false) and s.has("settlement"):
							print("[触发出口·近景子] " + rid + "/" + hid + "/" + subid)
							main._on_closeup_hotspot(rid, hid, subid)
							if _is_settlement(): _dump_settlement(); main._on_settlement_continue()
							return true
						if _is_hook(s) and _hook_has_toexit(s):
							for opt in s["options"]:
								var res = s["hookResults"]
								if res.has(opt["id"]) and res[opt["id"]].get("toExit", false):
									print("[触发出口·近景子钩子] " + rid + "/" + hid + "/" + subid + " → " + opt["id"])
									main._on_closeup_hotspot(rid, hid, subid)
									main._on_hook_choice(rid, hid, s, opt["id"], "closeup", hid)
									if _is_settlement(): _dump_settlement(); main._on_settlement_continue()
									return true
					main._on_closeup_back()
	return false
