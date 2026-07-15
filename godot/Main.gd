extends Control
## 《逾期之书》Godot 正式线引擎 —— 与 demo 引擎（skeleton/engine/engine.js）
## 同一套状态模型、同一套内容字段。这是整个项目最基础的地基，
## 两条线必须共用一份内容、同一套状态名，避免后期框架分叉出错。
##
## 状态字段（与 demo 的 Game.state 对齐）：
##   node          : 当前节点 notice | enter | hub(=区域图) | region(=区域内) | revea | ending
##   currentRegion : 当前所在区域 id（hub/region 用）
##   clues        : 线索字典  id -> text
##   memories      : 记忆字典  id -> text
##   visitedHot   : 已看热点集合 "rid:hid" -> true
##   examined     : 已展开热点集合 "rid:hid" -> true
##   hookChosenLine: 便签已选后的复述文案  hid -> line（互斥不叠加）
##   curator      : 管理员当前台词
##   asking       : 当前热点是否已追问过
##   puzzleCtx    : 钩子上下文 "hook:rid:hid"
##   endingText   : 结局正文（用于存档恢复后直接显示）
##
## 内容节点（night_a.json 的 "nodes" / "memories" / "companion"）：
##   notice / enter / revea / ending 四套剧情节点 + memories 记忆 + companian 常驻反应

var content: Dictionary = {}
var state: Dictionary = {}

# 内容版本号：每次内容数据结构变更时递增。
# 存档中记录该版本，加载时若不匹配则视为过期存档，自动走新游戏。
# 这避免了 F5 启动后因旧存档残留直接跳到书库深处等异常状态。
const CONTENT_VERSION := 2

# 开发期开关：为 true 且当前为 debug 构建（编辑器内 F5）时，
# 忽略任何已有存档，永远从 notice 开场，方便反复点测剧情。
# 导出 release 版（OS.is_debug_build() == false）不受该开关影响，正常恢复进度。
# 想临时验证「存档恢复」逻辑时，把本常量改为 false 即可。
const DEBUG_IGNORE_SAVE := true

# ── 夜程表（框架层 · 内容无关）────────────────────────
# 加一夜 = 在 content/ 放 night_X.json + 把 id 加进此数组；引擎逻辑零改动。
# Main 始终加载 NIGHT_ORDER[0]；多夜顺序 / 跨夜选择后续在框架层扩展。
# 夜序：序章 → 第一幕（夜A…）。加一夜 = 内容 JSON + 此处追加 id；引擎零改其它处。
const NIGHT_ORDER := ["prologue", "night_a", "night_b"]

# ── 状态初始化（与 demo 的 _freshState 对齐）──────────────
func _fresh_state() -> Dictionary:
	return {
		"node": "notice",
		"currentRegion": "",
		"clues": {},
		"memories": {},
		"visitedHot": {},
		"examined": {},
		"hookChosenLine": {},
		"curator": "",
		"asking": {},
		"puzzleCtx": "",
		"endingText": "",
		"revealSeen": false,
		"mailedLetter": false,
		# 近景 / 结算 瞬时态（不进存档，仅运行期用）
		"closeup": "",
		"settlementReturnNode": "",
		"settlementReturnCloseup": "",
		"settlementData": {},
	}

func _is_save_compatible() -> bool:
	## 检查存档是否与当前内容版本兼容。
	## 返回 false 时 _ready() 会自动走新游戏（notice 开场）。
	var d := SaveManager.load()
	if d.is_empty():
		return false
	return int(d.get("contentVersion", 0)) == CONTENT_VERSION

func _dev_skip_save() -> bool:
	## 开发期跳过存档恢复：DEBUG_IGNORE_SAVE 开启且当前为 debug 构建（F5）时返回 true。
	## 发布版（release 构建）恒为 false，正常恢复进度，不受该开关影响。
	return DEBUG_IGNORE_SAVE and OS.is_debug_build()

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	_build_ui()
	# 加载入口夜（NIGHT_ORDER[0]）；引擎与夜程表解耦，加一夜零改此处
	load_night_by_id(NIGHT_ORDER[0])
	# 存档恢复（B）：有同版存档则恢复，否则走开场 notice
	# 版本不匹配或缺失 contentVersion 字段 → 视为过期存档，自动新游戏
	# 开发期开关：DEBUG_IGNORE_SAVE + debug 构建 → 跳过恢复，直接新游戏
	if (not _dev_skip_save()) and SaveManager.has_save() and _is_save_compatible():
		_restore_from_save()
	else:
		state = _fresh_state()
		state["node"] = "notice"
		_render_node("notice")

## 跨夜加载：引擎与夜程表解耦（加一夜 = 内容 JSON + NIGHT_ORDER 追加 id）
## 供 _ready 开场与收场「继续」按钮复用；测试桩可显式切换任意一夜。
func load_night_by_id(id: String) -> void:
	if not NIGHT_ORDER.has(id):
		push_error("Main: 夜程表无此夜 " + id)
		return
	var c := ContentLoader.get_night(id)
	if c.is_empty():
		push_error("Main: 加载夜失败 " + id)
		return
	content = c
	ProgressState.night_index = NIGHT_ORDER.find(id)
	var unlocked := []
	var regs = content["regions"] as Dictionary
	for rid in regs.keys():
		var rg = regs[rid] as Dictionary
		if not rg.get("locked", false) and not rg.get("void", false):
			unlocked.append(rid)
	ProgressState.unlocked_zones = unlocked
	state = _fresh_state()
	state["node"] = "notice"
	_render_node("notice")

# ── UI 骨架（Godot 专属；与 demo 的 DOM 对应）──────────────
func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.09, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := VBoxContainer.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 24.0
	panel.offset_top = 24.0
	panel.offset_right = -24.0
	panel.offset_bottom = -24.0
	add_child(panel)

	var title := Label.new()
	title.name = "Stage"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(title)

	var hot := VBoxContainer.new()
	hot.name = "Hotspots"
	panel.add_child(hot)

	var acts := VBoxContainer.new()
	acts.name = "Actions"
	panel.add_child(acts)

	var clues := VBoxContainer.new()
	clues.name = "Clues"
	panel.add_child(clues)

	var mem := VBoxContainer.new()
	mem.name = "Memories"
	panel.add_child(mem)

	var cur := Label.new()
	cur.name = "Curator"
	cur.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(cur)

	var save_btn := Button.new()
	save_btn.name = "SaveBtn"
	save_btn.text = "保存进度 (user://)"
	save_btn.pressed.connect(_on_save)
	panel.add_child(save_btn)

func _on_gui_input(_event: InputEvent) -> void:
	AudioManager.ensure_started()

# ── 存档恢复（B）：字段与 demo 的 save() 一一对应 ──────
func _restore_from_save() -> void:
	var d := SaveManager.load()
	if d.is_empty():
		state = _fresh_state()
		state["node"] = "notice"
		_render_node("notice")
		return
	state = _fresh_state()
	if d.has("node"):           state["node"] = d["node"]
	if d.has("currentRegion"):  state["currentRegion"] = d["currentRegion"]
	if d.has("clues"):         state["clues"] = d["clues"]
	if d.has("memories"):       state["memories"] = d["memories"]
	if d.has("visitedHot"):    state["visitedHot"] = d["visitedHot"]
	if d.has("examined"):      state["examined"] = d["examined"]
	if d.has("hookChosenLine"):state["hookChosenLine"] = d["hookChosenLine"]
	if d.has("endingText"):    state["endingText"] = d["endingText"]
	if d.has("revealSeen"):    state["revealSeen"] = d["revealSeen"]
	if d.has("mailedLetter"):    state["mailedLetter"] = d["mailedLetter"]
	# 恢复后直接回到对应节点（跳过开场 notice，避免重复）
	if state["node"] == "ending":
		$Panel/Stage.text = state["endingText"]
		$Panel/Curator.text = "（从上次离开的地方，继续。）"
		_build_ending_actions()
	else:
		$Panel/Curator.text = "（从上次离开的地方，继续。）"
		_render_node(state["node"])

# ── 管理员常驻反应（与 demo 的 _companion 对齐）──────
func _companion(event: String) -> void:
	if not content.has("companion"):
		return
	var comp = content["companion"] as Dictionary
	if comp.has(event):
		state["curator"] = comp[event]
		$Panel/Curator.text = comp[event]

func _set_curator(text: String) -> void:
	state["curator"] = text
	$Panel/Curator.text = text

# ── 节点渲染调度（与 demo 的 render 对齐）──────────────
func _render_node(node: String) -> void:
	if node == "hub":
		_render_region_map()
	elif node == "region":
		_enter_region(state["currentRegion"])
	else:
		_render_content_node(node)

# ── 内容节点（notice / enter / revea / ending）──────────
func _render_content_node(node: String) -> void:
	if not content.has("nodes"):
		return
	var nodes = content["nodes"] as Dictionary
	if not nodes.has(node):
		return
	var nd = nodes[node] as Dictionary
	$Panel/Stage.text = nd["stage"]
	_clear_container($Panel/Hotspots)
	_clear_container($Panel/Clues)
	_clear_container($Panel/Memories)
	# 动作按钮
	_clear_container($Panel/Actions)
	for a in (nd["actions"] as Array):
		var b := Button.new()
		b.text = a["label"]
		b.pressed.connect(_on_node_action.bind(a["id"]))
		$Panel/Actions.add_child(b)
	# 进入节点时触发一次管理员反应
	_companion("enter:" + node)
	if node == "ending":
		$Panel/Curator.text = "（这是你自己的事了。）"

func _on_node_action(aid: String) -> void:
	AudioManager.ensure_started()
	match aid:
		"read", "toss":
			state["node"] = "enter"
			_render_node("enter")
		"desk", "door":
			state["node"] = "hub"
			state["currentRegion"] = "service_desk"
			_render_node("hub")
		"to_utility":
			state["node"] = "region"
			state["currentRegion"] = "utility_zone"
			_enter_region("utility_zone")
		"to_exit":
			state["node"] = "exit"
			_render_node("exit")
		"to_close":
			_render_curtain()

# ── 区域图（hub）：可点区域卡（与 demo renderRegionMap 对齐）──
func _render_region_map() -> void:
	_clear_container($Panel/Hotspots)
	_clear_container($Panel/Actions)
	_clear_container($Panel/Memories)
	_clear_container($Panel/Clues)
	$Panel/Stage.text = "馆里很静。雨声贴着玻璃。你可以去各处看看——每一处都摊着一点关于这本书的线索，拼齐了，才知道它该回哪儿。"
	var regions = content["regions"] as Dictionary
	for rid in regions.keys():
		var r = regions[rid] as Dictionary
		if r.get("void", false):
			continue  # 第9空间：永不开启，不在楼层图出现
		var b := Button.new()
		b.text = r["name"] + " —— " + r.get("metaphor", "")
		if r.get("locked", false):
			b.disabled = true
			b.text = "（门锁着）" + b.text
			$Panel/Hotspots.add_child(b)
			continue
		b.pressed.connect(_on_goto.bind(rid))
		$Panel/Hotspots.add_child(b)
	# 区域图常驻反应（空事件占位）
	var acts := VBoxContainer.new()
	acts.name = "toRegion"
	var bb := Button.new()
	bb.text = "进入所选区域"
	bb.pressed.connect(_on_enter_first_region)
	$Panel/Actions.add_child(bb)

func _on_enter_first_region() -> void:
	# 默认先进服务台（也可让玩家先点区域卡）
	state["node"] = "region"
	state["currentRegion"] = "service_desk"
	_render_node("region")

func _on_goto(rid: String) -> void:
	AudioManager.ensure_started()
	var regions = content["regions"] as Dictionary
	if regions.has(rid) and regions[rid].get("void", false):
		_set_curator("（门虚掩着，推不开。）")
		return
	state["currentRegion"] = rid
	state["node"] = "region"
	_companion("enter:" + rid)
	_render_node("region")

# ── 区域内（region）：描述 + 可点物件 + 出口通道 ──
func _enter_region(rid: String) -> void:
	state["currentRegion"] = rid
	state["node"] = "region"
	var regions = content["regions"] as Dictionary
	if not regions.has(rid):
		$Panel/Stage.text = "这里什么都没有。"
		return
	var r = regions[rid] as Dictionary
	$Panel/Stage.text = r["name"] + "\n" + r.get("metaphor", "") + "\n" + r.get("desc", "")
	# 区域进入时的管理员反应（enter:rid）
	_companion("enter:" + rid)
	_refresh_region_controls()

## 只重建热点 / 出口 / 拼合按钮，不动 Stage 与 Curator（供热点交互后局部刷新）
func _refresh_region_controls() -> void:
	var rid: String = state["currentRegion"]
	var regions = content["regions"] as Dictionary
	if not regions.has(rid):
		return
	var r = regions[rid] as Dictionary
	_clear_container($Panel/Hotspots)
	var hots = r["hotspots"] as Dictionary
	for hid in hots.keys():
		var h = hots[hid] as Dictionary
		# requiresFlag 门控：未置位前该热点不出现（投信前「与管理员对话」不可见）
		if h.get("requiresFlag", "") != "" and not state.get(h["requiresFlag"], false):
			continue
		var key = rid + ":" + hid
		var mark = ""
		if state["visitedHot"].has(key):
			mark = "（看过了）"
		var b := Button.new()
		b.text = h["label"] + mark
		b.pressed.connect(_on_hotspot.bind(rid, hid))
		$Panel/Hotspots.add_child(b)
	_clear_container($Panel/Actions)
	var ex = r["exits"] as Array
	for e in ex:
		var to = e["to"]
		if regions.has(to) and regions[to].get("locked", false):
			# 锁定区（夜D 解锁前）：灰显不可点，不计入出口
			var lb := Button.new()
			lb.text = "（门锁着）" + e["label"]
			lb.disabled = true
			$Panel/Actions.add_child(lb)
			continue
		var b := Button.new()
		b.text = e["label"] + " →"
		b.pressed.connect(_on_goto.bind(to))
		$Panel/Actions.add_child(b)
	# 常驻「回到服务台」：服务台是图书馆的家，永远可回（对应 gap1 的回服务台诉求）
	var home := Button.new()
	home.text = "⌂ 回到服务台"
	home.pressed.connect(_on_goto.bind("service_desk"))
	$Panel/Actions.add_child(home)
	_try_offer_reveal()
	_render_memories()

# ── 通用热点交互内核：叙事 + 解锁 + 管理员反应 ──
# 返回是否为便签钩子（交由调用方处理）。区域热点与近景子热点共用。
func _apply_interaction(rid: String, hid: String, h: Dictionary, key: String) -> bool:
	var first: bool = not state["examined"].has(key)
	state["examined"][key] = true
	state["visitedHot"][key] = true
	var narrative := ""
	if first:
		narrative = h.get("once", "")
	else:
		narrative = h.get("again", h.get("once", ""))
	if narrative != "":
		$Panel/Stage.text = narrative
	if h.has("unlocks"):
		var u = h["unlocks"] as Dictionary
		state["clues"][u["id"]] = u["text"]
	var cur := ""
	if first:
		cur = h.get("curatorOnce", "")
	else:
		cur = h.get("curatorAgain", h.get("curatorOnce", ""))
	if cur != "":
		_set_curator(cur)
	else:
		_companion("hot:" + rid + ":" + hid)
	return h.get("hook", false)

func _on_hotspot(rid: String, hid: String) -> void:
	AudioManager.ensure_started()
	var regions = content["regions"] as Dictionary
	var r = regions[rid] as Dictionary
	var h = r["hotspots"][hid] as Dictionary
	# 近景：有 closeup 的热点先进入近景，不直接摊开全部内容（锈湖式 zoom-in）
	if h.has("closeup"):
		_enter_closeup(rid, hid)
		return
	var key = rid + ":" + hid
	var is_hook: bool = _apply_interaction(rid, hid, h, key)
	if is_hook:
		if state["hookChosenLine"].has(hid):
			_set_curator(state["hookChosenLine"][hid])
		_refresh_region_controls()
		_open_hook_options(rid, hid, h, false)
		return
	# 局部刷新（保留 Stage 叙事 + Curator 反应），再补追问按钮
	_refresh_region_controls()
	if h.has("ask") and not state["asking"].has(key):
		var a = h["ask"] as Dictionary
		var b := Button.new()
		b.text = a["prompt"]
		b.pressed.connect(_on_ask.bind(rid, hid, ""))
		$Panel/Actions.add_child(b)
	# 结算：正确 / 特殊互动的专属反馈页（避免「点一遍就完」）
	if h.has("settlement"):
		if h.get("toExit", false):
			state["pendingExit"] = true
		_open_settlement(h["settlement"], "region", "")

# ── 近景（close-up）：zoom 进物件，子热点需进一步点击 ──
func _enter_closeup(rid: String, hid: String) -> void:
	AudioManager.ensure_started()
	state["currentRegion"] = rid
	state["node"] = "closeup"
	state["closeup"] = hid
	var key = rid + ":" + hid
	state["visitedHot"][key] = true
	var cu = content["regions"][rid]["hotspots"][hid]["closeup"] as Dictionary
	$Panel/Stage.text = cu.get("stage", "")
	_companion("enter_closeup:" + rid + ":" + hid)
	_refresh_closeup_controls()

func _refresh_closeup_controls() -> void:
	var rid: String = state["currentRegion"]
	var hid: String = state["closeup"]
	var cu = content["regions"][rid]["hotspots"][hid]["closeup"] as Dictionary
	_clear_container($Panel/Hotspots)
	var subs = cu["hotspots"] as Dictionary
	for subid in subs.keys():
		var s = subs[subid] as Dictionary
		var key = rid + ":" + hid + ":" + subid
		var mark = ""
		if state["visitedHot"].has(key):
			mark = "（看过了）"
		# requiresReveal 门控：未拼合前灰显，不可点
		if s.get("requiresReveal", false) and not state.get("revealSeen", false):
			var lb := Button.new()
			lb.text = s.get("lockedLabel", "（还打不开）") + mark
			lb.disabled = true
			$Panel/Hotspots.add_child(lb)
			continue
		var b := Button.new()
		b.text = s["label"] + mark
		b.pressed.connect(_on_closeup_hotspot.bind(rid, hid, subid))
		$Panel/Hotspots.add_child(b)
	_clear_container($Panel/Actions)
	var back := Button.new()
	back.text = "退回 · 离开近景"
	back.pressed.connect(_on_closeup_back)
	$Panel/Actions.add_child(back)

func _on_closeup_hotspot(rid: String, hid: String, subid: String) -> void:
	AudioManager.ensure_started()
	var cu = content["regions"][rid]["hotspots"][hid]["closeup"] as Dictionary
	var s = cu["hotspots"][subid] as Dictionary
	var key = rid + ":" + hid + ":" + subid
	# requiresReveal 门控：未拼合前不可投递信件
	if s.get("requiresReveal", false) and not state.get("revealSeen", false):
		_set_curator(s.get("lockedHint", "（还不到时候。）"))
		return
	_apply_interaction(rid, hid, s, key)
	_refresh_closeup_controls()
	if s.get("hook", false):
		_open_hook_options(rid, hid, s, true, hid)
		return
	if s.has("settlement"):
		_open_settlement(s["settlement"], "closeup", hid)

func _on_closeup_back() -> void:
	AudioManager.ensure_started()
	state["node"] = "region"
	state["closeup"] = ""
	_enter_region(state["currentRegion"])

# ── 结算页（settlement）：正确 / 特殊互动的专属反馈 ──
func _open_settlement(data: Dictionary, return_node: String, return_closeup: String) -> void:
	state["node"] = "settlement"
	state["settlementReturnNode"] = return_node
	state["settlementReturnCloseup"] = return_closeup
	state["settlementData"] = data
	_render_settlement()

func _render_settlement() -> void:
	var d = state["settlementData"] as Dictionary
	_clear_container($Panel/Hotspots)
	_clear_container($Panel/Actions)
	_clear_container($Panel/Memories)
	var txt: String = "【结算】" + str(d.get("title", "")) + "\n\n" + str(d.get("body", ""))
	if d.has("gained"):
		txt += "\n\n· " + d["gained"]
	$Panel/Stage.text = txt
	var b := Button.new()
	b.text = "继续 ▶"
	b.pressed.connect(_on_settlement_continue)
	$Panel/Actions.add_child(b)

func _on_settlement_continue() -> void:
	AudioManager.ensure_started()
	if state.get("pendingExit", false):
		state["pendingExit"] = false
		_on_node_action("to_exit")
		return
	var rn: String = state["settlementReturnNode"]
	var rc: String = state["settlementReturnCloseup"]
	if rn == "closeup":
		_enter_closeup(state["currentRegion"], rc)
	else:
		state["node"] = "region"
		_enter_region(state["currentRegion"])

func _on_ask(rid: String, hid: String, subid: String = "") -> void:
	var regions = content["regions"] as Dictionary
	var h: Dictionary
	if subid != "":
		h = regions[rid]["hotspots"][hid]["closeup"]["hotspots"][subid] as Dictionary
	else:
		h = regions[rid]["hotspots"][hid] as Dictionary
	var a = h["ask"] as Dictionary
	var key = rid + ":" + hid
	if subid != "":
		key = key + ":" + subid
	state["asking"][key] = true
	_set_curator(a.get("then", "……"))
	if subid != "":
		_refresh_closeup_controls()
	else:
		_refresh_region_controls()

# ── 便签钩子：三选一（互斥，只产一个 c_note）──────────
func _open_hook_options(rid: String, hid: String, h: Dictionary, is_closeup := false, closeup_hid := "") -> void:
	var prompt: String = h.get("hookPrompt", "你要写点什么吗？")
	_set_curator(prompt)
	_clear_container($Panel/Actions)
	for opt in (h["options"] as Array):
		var b := Button.new()
		b.text = opt["label"]
		if is_closeup:
			b.pressed.connect(_on_hook_choice.bind(rid, hid, h, opt["id"], "closeup", closeup_hid))
		else:
			b.pressed.connect(_on_hook_choice.bind(rid, hid, h, opt["id"], "region", ""))
		$Panel/Actions.add_child(b)
	var back := Button.new()
	back.text = "（什么都不写，退回去）"
	# 退回去只需局部刷新对应控件（近景回近景 / 区域回区域），不走完整 _on_goto
	back.pressed.connect(func():
		_set_curator("")
		if is_closeup:
			_enter_closeup(rid, closeup_hid)
		else:
			_refresh_region_controls()
	)
	$Panel/Actions.add_child(back)

func _on_hook_choice(rid: String, hid: String, h: Dictionary, opt_id: String, return_node := "region", return_closeup := "") -> void:
	AudioManager.ensure_started()
	var res = h["hookResults"] as Dictionary
	if res.has(opt_id):
		var r = res[opt_id] as Dictionary
		# 互斥：记录唯一选择，后续只复述不叠加
		state["hookChosenLine"][hid] = r.get("line", "")
		if r.has("clue"):
			var c = r["clue"] as Dictionary
			state["clues"][c["id"]] = c["text"]
		# setFlag：钩子结果可置位一个状态标志（mail → mailedLetter）
		if r.has("setFlag"):
			state[r["setFlag"]] = true
		# 近景钩子回到 closeup，区域钩子回到 region
		if return_node == "closeup":
			state["node"] = "closeup"
		else:
			state["node"] = "region"
		var rr = content["regions"][rid] as Dictionary
		$Panel/Stage.text = rr["name"] + "\n" + rr.get("metaphor", "") + "\n" + rr.get("desc", "")
		_set_curator(r.get("line", ""))
		if return_node == "closeup":
			_refresh_closeup_controls()
		else:
			_refresh_region_controls()
		if r.has("settlement"):
			if r.get("toExit", false):
				state["pendingExit"] = true
			_open_settlement(r["settlement"], return_node, return_closeup)

# ── Reveal：双 clue 门控（c_letter + c_name）────────────
func _try_offer_reveal() -> void:
	if not content.has("nodes") or not content["nodes"].has("reveal"):
		return
	var rv = content["nodes"]["reveal"] as Dictionary
	var req = rv["requiresClues"] as Array
	var ok := true
	for cid in req:
		if not state["clues"].has(cid):
			ok = false
			break
	if ok:
		var b := Button.new()
		b.name = "RevealBtn"
		b.text = "（碎片已凑齐）拼合那一夜 ▶"
		b.pressed.connect(_on_enter_reveal)
		$Panel/Actions.add_child(b)

func _night_index_of(night_id: String) -> int:
	## 把夜 id 映射成夜序下标（F2/F3 跨夜用）
	return NIGHT_ORDER.find(night_id)

func _on_enter_reveal() -> void:
	if not content.has("nodes") or not content["nodes"].has("reveal"):
		return
	var rv = content["nodes"]["reveal"] as Dictionary
	# 二次门控：缺 key clue 直接拦截
	var req = rv["requiresClues"] as Array
	for cid in req:
		if not state["clues"].has(cid):
			_set_curator("（还差些什么没连上。先回去看看。）")
			return
	state["node"] = "reveal"
	state["revealSeen"] = true
	$Panel/Stage.text = rv["stage"]
	# 拼合时解锁记忆（F3 · 记忆按夜分级）：
	# 记忆条目可为字符串（总是解锁，兼容旧数据）或 {night, text} 字典。
	# 只有 night 归属 <= 当前夜才解锁；归因到夜D 的记忆在夜 A 不泄（待内容 red-line 重归因后生效）。
	if content.has("memories"):
		for mid in (content["memories"] as Dictionary).keys():
			var mv = content["memories"][mid]
			if typeof(mv) == TYPE_STRING:
				state["memories"][mid] = mv
			elif typeof(mv) == TYPE_DICTIONARY:
				var mnight = (mv as Dictionary).get("night", "")
				if mnight == "" or _night_index_of(mnight) <= ProgressState.night_index:
					state["memories"][mid] = (mv as Dictionary).get("text", "")
	_clear_container($Panel/Hotspots)
	_clear_container($Panel/Actions)
	_render_memories()
	for a in (rv["actions"] as Array):
		var b := Button.new()
		b.text = a["label"]
		b.pressed.connect(_on_node_action.bind(a["id"]))
		$Panel/Actions.add_child(b)

# ── Ending：return / take / burn 三分支 ────────────────
func _build_ending_actions() -> void:
	_clear_container($Panel/Hotspots)
	_clear_container($Panel/Actions)
	if not content.has("ending"):
		return
	var ed = content["ending"] as Dictionary
	for a in (ed["defaultActions"] as Array):
		var b := Button.new()
		b.text = a["label"]
		b.pressed.connect(_on_ending.bind(a["id"]))
		$Panel/Actions.add_child(b)

func _on_ending(aid: String) -> void:
	AudioManager.ensure_started()
	var ed = content["ending"] as Dictionary
	var key := aid.replace("end:", "")
	var ends = ed["endings"] as Dictionary
	if ends.has(key):
		state["endingText"] = ends[key]
		state["node"] = "ending"
		$Panel/Stage.text = ends[key]
		$Panel/Curator.text = "（这是你自己的事了。）"
		_clear_container($Panel/Hotspots)
		_clear_container($Panel/Actions)

# ── 收场（curtain）：夜尽，合上书 ──────────────────
func _render_curtain() -> void:
	_clear_container($Panel/Hotspots)
	_clear_container($Panel/Actions)
	_clear_container($Panel/Clues)
	_clear_container($Panel/Memories)
	$Panel/Stage.text = "（今夜闭馆。灯还亮着。）\n\n雨声贴着玻璃，慢慢远了。\n你合上《逾期之书》——可你知道，有些书，合上了也还在原地等你。"
	$Panel/Curator.text = "（夜还长。下次来，灯还亮着。）"
	# 过场帧：本夜声明 next 且夜程表有后继 → 在收场页追加下一夜的 frame（区分两天的非对话载体）
	if content.has("next"):
		var nxt: String = content["next"]
		var cid: String = content.get("id", "")
		if NIGHT_ORDER.has(nxt) and NIGHT_ORDER.find(nxt) > NIGHT_ORDER.find(cid):
			var nxt_content: Dictionary = ContentLoader.get_night(nxt)
			if nxt_content.has("frame"):
				$Panel/Stage.text += "\n\n" + (nxt_content["frame"] as String)
			var bn := Button.new()
			bn.text = "继续 —— 下一夜"
			bn.pressed.connect(load_night_by_id.bind(nxt))
			$Panel/Actions.add_child(bn)
	var b := Button.new()
	b.text = "重新翻开《逾期之书》"
	b.pressed.connect(_on_restart)
	$Panel/Actions.add_child(b)

func _on_restart() -> void:
	# 开发期 DEBUG_IGNORE_SAVE 下每次启动即从 notice 开场；此处供收场后重玩
	state = _fresh_state()
	state["node"] = "notice"
	_render_node("notice")

# ── 记忆（memories）：只显示已解锁的 state.memories ──
func _render_memories() -> void:
	_clear_container($Panel/Memories)
	if state["memories"].is_empty():
		return
	var head := Label.new()
	head.text = "—— 你想起的事 ——"
	$Panel/Memories.add_child(head)
	for mid in state["memories"].keys():
		var l := Label.new()
		l.text = "· " + state["memories"][mid]
		$Panel/Memories.add_child(l)

# ── 存档（B）────────────────────────────────────────────
func _on_save() -> void:
	# 近景 / 结算为瞬时态，不值得存档；落盘时统一归为 region，避免恢复进残缺态
	var save_node: String = state["node"]
	if save_node in ["closeup", "settlement"]:
		save_node = "region"
	SaveManager.save({
		"contentVersion": CONTENT_VERSION,
		"node": save_node,
		"currentRegion": state["currentRegion"],
		"clues": state["clues"],
		"memories": state["memories"],
		"visitedHot": state["visitedHot"],
		"examined": state["examined"],
		"hookChosenLine": state["hookChosenLine"],
		"endingText": state["endingText"],
		"revealSeen": state["revealSeen"],
		"mailedLetter": state["mailedLetter"],
	})
	_set_curator("（进度已存到 user://）")
	# 保存后重渲染当前节点，避免 UI 空着
	if state["node"] == "ending":
		_build_ending_actions()
	else:
		_render_node(state["node"])

# ── 工具：清空容器 ───────────────────────────────────
# 关键设计决策（2026-07-13 修正）：
#   必须用 queue_free() 而非 free()。原因：用户点击按钮时，pressed 信号触发回调，
#   回调内部调用 _clear_container 清理包含该按钮的容器。如果用 free() 同步销毁，
#   会杀掉正在派发信号的对象本身 → Godot 信号链断裂 → 后续新建的按钮不再响应。
#   queue_free() 延迟到帧末释放，当前帧内旧按钮仍可见但不影响新按钮的事件注册。
#   "同帧 clear+add 叠按钮"的担忧不成立——add_child 立即生效，queue_free 的延迟释放
#   只意味着旧节点在本帧剩余时间内仍存在于场景树中（不可见因已被移出容器）。
func _clear_container(c: Node) -> void:
	if c == null:
		return
	# 快照子节点列表，防止 for-in 迭代器在遍历时被修改导致跳过或崩溃
	var snapshot := c.get_children().duplicate()
	for child in snapshot:
		c.remove_child(child)   # 立即从容器摘除，get_children() 不再返回它
		child.queue_free()       # 延迟到帧末彻底释放，避免信号回调中 free 自身
