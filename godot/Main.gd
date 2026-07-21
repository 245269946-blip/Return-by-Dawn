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
##   librarianWhere: 管理员当前所在区域（走动模型；内容用 requiresFlag / moveLibrarian 改变）
##
## 内容节点（night_a.json 的 "nodes" / "memories" / "companion"）：
##   notice / enter / revea / ending 四套剧情节点 + memories 记忆 + companian 常驻反应
##
## 界面分区（锈湖式 · 2026-07-16 重排）：
##   StageArea（中间画面）：场景描述 + 可点物件 + 动作 + 线索/记忆 —— 点击互动都在这里
##   DialogueBox（底部对话框）：管理员肖像位 + 台词 —— 对话只在这里
##   管理员「在场」才有肖像与台词；不在场则沉默、肖像隐藏。

var content: Dictionary = {}
var state: Dictionary = {}

# 内容版本号：每次内容数据结构变更时递增。
# 存档中记录该版本，加载时若不匹配则视为过期存档，自动走新游戏。
# 这避免了 F5 启动后因旧存档残留直接跳到书库深处等异常状态。
const CONTENT_VERSION := 3

# 开发期开关：为 true 且当前为 debug 构建（编辑器内 F5）时，
# 忽略任何已有存档，永远从 notice 开场，方便反复点测剧情。
# 导出 release 版（OS.is_debug_build() == false）不受该开关影响，正常恢复进度。
# 想临时验证「存档恢复」逻辑时，把本常量改为 false 即可。
const DEBUG_IGNORE_SAVE := true

# ── 夜程表（框架层 · 内容无关）────────────────────────
# 加一夜 = 在 content/ 放 night_X.json + 把 id 加进此数组；引擎逻辑零改动。
# Main 始终加载 NIGHT_ORDER[0]；多夜顺序 / 跨夜选择后续在框架层扩展。
# 夜序：序章 → 第一幕（夜A…）。加一夜 = 内容 JSON + 此处追加 id；引擎零改其它处。
const NIGHT_ORDER := ["prologue", "night_a", "night_b", "night_c", "night_d", "night_e", "night_f", "night_g", "night_h", "night_i", "night_z"]

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
		"librarianWhere": "",
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
		if not rg.get("void", false):
			unlocked.append(rid)
	ProgressState.unlocked_zones = unlocked
	# 管理员初始位置：内容可声明 librarianHome；缺省 service_desk
	state = _fresh_state()
	if content.has("librarianHome"):
		state["librarianWhere"] = content["librarianHome"]
	elif regs.has("service_desk"):
		state["librarianWhere"] = "service_desk"
	state["node"] = "notice"
	# 跨夜携带：把上一夜经 _carry_forward() 累加进 ProgressState.cross_night 的可携带字段，
	# 并入本夜 state（线索 / 记忆 / 物证形态 / 已选便签）。这是「夜与夜真正串联」的地基。
	# 注意：仅并入 cross_night 中已存在的键，不改动本夜引擎自身的初始化。
	_merge_cross_night()
	AudioManager.set_chapter(id)
	AudioManager.play_sting("notice")
	_render_node("notice")

# ── 跨夜携带（框架层 · F2/F3）────────────────────────
# 收场「继续 —— 下一夜」点击时调用：把本夜的可携带字段快照进 autoload 的
# ProgressState.cross_night（累加，不替换），供 load_night_by_id 末尾并入下一夜。
# 携带字段 = 线索、记忆、已选便签、续借/拼合标记（即「书墙 / 记忆 / 物证形态」跨夜不丢）。
func _carry_forward() -> void:
	var cn: Dictionary = ProgressState.cross_night
	var carry_keys := ["clues", "memories", "hookChosenLine"]
	for k in carry_keys:
		if state.has(k) and state[k] is Dictionary:
			cn[k] = state[k].duplicate()
	# 标量 / 布尔标记
	cn["mailedLetter"] = state.get("mailedLetter", false)
	cn["revealSeen"] = state.get("revealSeen", false)

# load_night_by_id 末尾调用：把 ProgressState.cross_night 中累加的跨夜字段并入本夜 state。
func _merge_cross_night() -> void:
	var cn: Dictionary = ProgressState.cross_night
	if cn.is_empty():
		return
	for k in ["clues", "memories", "hookChosenLine"]:
		if cn.has(k) and cn[k] is Dictionary:
			var src: Dictionary = cn[k]
			for ck in src.keys():
				state[k][ck] = src[ck]
	if cn.has("mailedLetter"):
		state["mailedLetter"] = cn["mailedLetter"]
	if cn.has("revealSeen"):
		state["revealSeen"] = cn["revealSeen"]
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

	# ── 中间画面 StageArea：场景描述 + 可点物件 + 动作 + 线索/记忆 ──
	var stage_area := VBoxContainer.new()
	stage_area.name = "StageArea"
	stage_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(stage_area)

	var title := Label.new()
	title.name = "Stage"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_area.add_child(title)

	var hot := VBoxContainer.new()
	hot.name = "Hotspots"
	stage_area.add_child(hot)

	var clues := VBoxContainer.new()
	clues.name = "Clues"
	stage_area.add_child(clues)

	var mem := VBoxContainer.new()
	mem.name = "Memories"
	stage_area.add_child(mem)

	var acts := VBoxContainer.new()
	acts.name = "Actions"
	stage_area.add_child(acts)

	var save_btn := Button.new()
	save_btn.name = "SaveBtn"
	save_btn.text = "保存进度 (user://)"
	save_btn.pressed.connect(_on_save)
	stage_area.add_child(save_btn)

	# ── 底部对话框 DialogueBox：管理员肖像位 + 台词 ──
	var box := HBoxContainer.new()
	box.name = "DialogueBox"
	box.size_flags_vertical = Control.SIZE_SHRINK_END
	box.custom_minimum_size = Vector2(0, 150.0)
	panel.add_child(box)

	var portrait := Panel.new()
	portrait.name = "Portrait"
	portrait.visible = false
	portrait.custom_minimum_size = Vector2(110.0, 0.0)
	portrait.size_flags_vertical = Control.SIZE_FILL
	portrait.modulate = Color(0.78, 0.74, 0.62, 1.0)
	var pl := Label.new()
	pl.name = "PortraitLabel"
	pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pl.text = "管理员"
	portrait.add_child(pl)
	box.add_child(portrait)

	var cur := Label.new()
	cur.name = "Curator"
	cur.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cur.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(cur)

# ── 节点访问器（锈湖式双区路径）──────────────────────
func _stage_node() -> Label:
	return $Panel/StageArea/Stage
func _curator_node() -> Label:
	return $Panel/DialogueBox/Curator
func _hotspots_node() -> Node:
	return $Panel/StageArea/Hotspots
func _actions_node() -> Node:
	return $Panel/StageArea/Actions
func _clues_node() -> Node:
	return $Panel/StageArea/Clues
func _memories_node() -> Node:
	return $Panel/StageArea/Memories

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
	if d.has("mailedLetter"):  state["mailedLetter"] = d["mailedLetter"]
	# 管理员位置不进存档（运行期走动态），恢复时回到夜家位
	if content.has("librarianHome"):
		state["librarianWhere"] = content["librarianHome"]
	elif content.get("regions", {}).has("service_desk"):
		state["librarianWhere"] = "service_desk"
	# 恢复后直接回到对应节点（跳过开场 notice，避免重复）
	if state["node"] == "ending":
		_stage_node().text = state["endingText"]
		_curator_node().text = "（从上次离开的地方，继续。）"
		_build_ending_actions()
	else:
		_curator_node().text = "（从上次离开的地方，继续。）"
		_render_node(state["node"])
	_refresh_portrait()

# ═══════════════ 管理员在场模型（非无处不在 · 2026-07-16）══════════════
# 管理员是一个会走动的场景人物，不是无处不在的旁白。
# 每个区域用 regions[rid]["librarian"] 声明他在不在、站在哪个点位：
#   - 省略            → 在场（兼容旧内容；点位 = rid）
#   - false / null    → 不在场（无肖像、区域/热点反应沉默）
#   - "<spot>" 字符串 → 在场，点位 = 该字符串（美术落位提示）
#   - {spot, requiresFlag} → 仅当 state[requiresFlag] 为真时在场（某阶段才出现）
# 走动：热点/hook 结果可带 moveLibrarian:"<rid>"，把他移到另一区（置位
#       librarianArrived:<rid> 标志，配合目标区的 requiresFlag 表达「走了过来」）。
# 区域/热点反应（enter:<rid> / hot:<rid>:<hid>）仅在管理员在场时触发；
# 剧情节点反应（enter:<nodeId>）非空间锚定，恒定触发（叙事节拍）。

func _librarian_present(rid: String) -> bool:
	var regs = content.get("regions", {}) as Dictionary
	if not regs.has(rid):
		return false
	var r = regs[rid] as Dictionary
	if not r.has("librarian"):
		return true  # 兼容：省略=在场
	var cfg = r["librarian"]
	if cfg == null:
		return false
	if cfg is bool:
		return cfg  # false→不在场；true→在场
	if cfg is String:
		return true
	if cfg is Dictionary:
		var req = (cfg as Dictionary).get("requiresFlag", "")
		if req != "" and not state.get(req, false):
			return false
		return true
	return false

func _librarian_spot(rid: String) -> String:
	var regs = content.get("regions", {}) as Dictionary
	if not regs.has(rid):
		return ""
	var r = regs[rid] as Dictionary
	if not r.has("librarian"):
		return rid
	var cfg = r["librarian"]
	if cfg is String:
		return cfg
	if cfg is Dictionary:
		return (cfg as Dictionary).get("spot", rid)
	return rid

func _region_from_event(event: String) -> String:
	## 从 companion 事件键解析出空间锚定的区域 id（无则返回 ""）
	var regs = content.get("regions", {}) as Dictionary
	if event.begins_with("enter:"):
		var p = event.substr(6)
		if regs.has(p):
			return p
		return ""
	if event.begins_with("hot:"):
		var parts = event.split(":")
		if parts.size() >= 2 and regs.has(parts[1]):
			return parts[1]
		return ""
	if event.begins_with("enter_closeup:"):
		var p = event.substr(13)
		var parts = p.split(":")
		if parts.size() >= 1 and regs.has(parts[0]):
			return parts[0]
	return ""

func _refresh_portrait() -> void:
	## 按当前区域的管理员在场状态，显示/隐藏底部肖像
	var rid: String = state.get("currentRegion", "")
	var present := false
	var spot := ""
	if rid != "" and _librarian_present(rid):
		present = true
		spot = _librarian_spot(rid)
	_show_portrait(present, spot)

func _show_portrait(visible: bool, spot: String) -> void:
	var p := $Panel/DialogueBox/Portrait
	if p == null:
		return
	p.visible = visible
	if visible:
		var pl := p.get_node("PortraitLabel") as Label
		if pl != null:
			pl.text = "管理员\n" + (spot if spot != "" else "在这里")

func _apply_move_librarian(target: String) -> void:
	if target == "":
		return
	state["librarianWhere"] = target
	state["librarianArrived:" + target] = true

# ── 管理员常驻反应（与 demo 的 _companion 对齐）──────
func _companion(event: String) -> void:
	if not content.has("companion"):
		return
	var comp = content["companion"] as Dictionary
	if not comp.has(event):
		return
	# 空间锚定事件（进区域 / 点热点）受在场门控：不在场则沉默
	var rid := _region_from_event(event)
	if rid != "" and not _librarian_present(rid):
		return
	state["curator"] = comp[event]
	_curator_node().text = comp[event]
	_refresh_portrait()

func _set_curator(text: String) -> void:
	state["curator"] = text
	_curator_node().text = text
	_refresh_portrait()

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
	_stage_node().text = nd["stage"]
	_clear_container(_hotspots_node())
	_clear_container(_clues_node())
	_clear_container(_memories_node())
	# 动作按钮
	_clear_container(_actions_node())
	for a in (nd["actions"] as Array):
		var b := Button.new()
		b.text = a["label"]
		b.pressed.connect(_on_node_action.bind(a["id"]))
		_actions_node().add_child(b)
	# 进入节点时触发一次管理员反应（剧情节点非空间锚定，恒定触发）
	_companion("enter:" + node)
	AudioManager.play_sfx("companion")
	if node == "reveal":
		AudioManager.play_sting("reveal")
	if node == "ending":
		_curator_node().text = "（这是你自己的事了。）"
	_refresh_portrait()

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
			AudioManager.play_sting("exit")
			_render_node("exit")
		"to_close":
			_render_curtain()

# ── 区域图（hub）：可点区域卡（与 demo renderRegionMap 对齐）──
func _render_region_map() -> void:
	_clear_container(_hotspots_node())
	_clear_container(_actions_node())
	_clear_container(_memories_node())
	_clear_container(_clues_node())
	_stage_node().text = "馆里很静。雨声贴着玻璃。你可以去各处看看——每一处都摊着一点关于这本书的线索，拼齐了，才知道它该回哪儿。"
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
			_hotspots_node().add_child(b)
			continue
		b.pressed.connect(_on_goto.bind(rid))
		_hotspots_node().add_child(b)
	# 区域图常驻反应（空事件占位）
	var acts := VBoxContainer.new()
	acts.name = "toRegion"
	var bb := Button.new()
	bb.text = "进入所选区域"
	bb.pressed.connect(_on_enter_first_region)
	_actions_node().add_child(bb)
	_refresh_portrait()

func _on_enter_first_region() -> void:
	# 默认先进服务台（也可让玩家先点区域卡）
	state["node"] = "region"
	state["currentRegion"] = "service_desk"
	_render_node("region")

func _on_goto(rid: String) -> void:
	AudioManager.ensure_started()
	AudioManager.play_sfx("click")
	AudioManager.play_sfx("door")
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
	# 音频：区域切换时同步雨声/环境 mood（无音频素材时 AudioManager 自动静默回退，不报错）
	AudioManager.set_mood(rid)
	var regions = content["regions"] as Dictionary
	if not regions.has(rid):
		_stage_node().text = "这里什么都没有。"
		return
	var r = regions[rid] as Dictionary
	_stage_node().text = r["name"] + "\n" + r.get("metaphor", "") + "\n" + r.get("desc", "")
	# 区域进入时的管理员反应（enter:rid，受在场门控）
	_companion("enter:" + rid)
	# 管理员不在本区：清空底部台词（你独自在这间屋里），肖像由 _refresh_portrait 隐藏
	if not _librarian_present(rid):
		_curator_node().text = ""
	_refresh_region_controls()
	_refresh_portrait()

## 只重建热点 / 出口 / 拼合按钮，不动 Stage 与 Curator（供热点交互后局部刷新）
func _refresh_region_controls() -> void:
	var rid: String = state["currentRegion"]
	var regions = content["regions"] as Dictionary
	if not regions.has(rid):
		return
	var r = regions[rid] as Dictionary
	_clear_container(_hotspots_node())
	var hots = r["hotspots"] as Dictionary
	for hid in hots.keys():
		var h = hots[hid] as Dictionary
		# requiresFlag 门控：未置位前该热点不出现（投信前「与管理员对话」不可见）
		# 置位来源可以是顶层旗标（setFlag / moveLibrarian），也可以是跨夜携带的线索（unlocks 产出的 clue id）
		var rf_flag = h.get("requiresFlag", "")
		if rf_flag != "" and not (state.get(rf_flag, false) or state["clues"].has(rf_flag)):
			continue
		var key = rid + ":" + hid
		var mark = ""
		if state["visitedHot"].has(key):
			mark = "（看过了）"
		var b := Button.new()
		b.text = h["label"] + mark
		b.pressed.connect(_on_hotspot.bind(rid, hid))
		_hotspots_node().add_child(b)
	_clear_container(_actions_node())
	var ex = r["exits"] as Array
	for e in ex:
		var to = e["to"]
		var locked_region := false
		if regions.has(to) and regions[to].get("locked", false):
			locked_region = true
		# 出口门控（限制与引导）：未满足前置条件时灰显不可点，与锁定区一致处理，
		# 不计入可走出口。让场景切换受引导，而非自由乱窜（对应「每夜约 10 分钟」节奏约束）。
		var req_flag: String = e.get("requiresFlag", "")
		var req_reveal: bool = e.get("requiresReveal", false)
		var gated: bool = locked_region or (req_flag != "" and not state.get(req_flag, false)) or (req_reveal and not state.get("revealSeen", false))
		if gated:
			var lb := Button.new()
			lb.text = e.get("lockedLabel", "（还去不了）")
			lb.disabled = true
			_actions_node().add_child(lb)
			continue
		var b := Button.new()
		b.text = e["label"] + " →"
		b.pressed.connect(_on_goto.bind(to))
		_actions_node().add_child(b)
	# 常驻「回到服务台」：服务台是图书馆的家，永远可回（对应 gap1 的回服务台诉求）
	var home := Button.new()
	home.text = "⌂ 回到服务台"
	home.pressed.connect(_on_goto.bind("service_desk"))
	_actions_node().add_child(home)
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
		_stage_node().text = narrative
	if h.has("unlocks"):
		var u = h["unlocks"] as Dictionary
		state["clues"][u["id"]] = u["text"]
	# 走动：先把管理员移到另一区（如「他走到你身边」），再决定台词门控，
	# 这样「走了过来」的热点其台词才会在到达后出现（避免人未到、声先到）。
	if h.has("moveLibrarian"):
		_apply_move_librarian(h["moveLibrarian"])
		_refresh_portrait()
	var cur := ""
	if first:
		cur = h.get("curatorOnce", "")
	else:
		cur = h.get("curatorAgain", h.get("curatorOnce", ""))
	# 在场门控：管理员不在本区，热点自带台词也沉默（避免「有声音没脸」）
	if cur != "" and _librarian_present(rid):
		_set_curator(cur)
	else:
		_companion("hot:" + rid + ":" + hid)
	return h.get("hook", false)

func _on_hotspot(rid: String, hid: String) -> void:
	AudioManager.ensure_started()
	AudioManager.play_sfx("click")
	var regions = content["regions"] as Dictionary
	var r = regions[rid] as Dictionary
	var h = r["hotspots"][hid] as Dictionary
	# 内容可声明 "sfx" 键（drawer/water/breath 等），触发对应专用音效（缺省静默回退）
	AudioManager.play_sfx(h.get("sfx", ""))
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
	# 追问是向管理员发问；他不在本区则不出现追问入口（你不会对着空气提问）
	if h.has("ask") and not state["asking"].has(key) and _librarian_present(rid):
		var a = h["ask"] as Dictionary
		var b := Button.new()
		b.text = a["prompt"]
		b.pressed.connect(_on_ask.bind(rid, hid, ""))
		_actions_node().add_child(b)
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
	_stage_node().text = cu.get("stage", "")
	_companion("enter_closeup:" + rid + ":" + hid)
	_refresh_closeup_controls()
	_refresh_portrait()

func _refresh_closeup_controls() -> void:
	var rid: String = state["currentRegion"]
	var hid: String = state["closeup"]
	var cu = content["regions"][rid]["hotspots"][hid]["closeup"] as Dictionary
	_clear_container(_hotspots_node())
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
			_hotspots_node().add_child(lb)
			continue
		var b := Button.new()
		b.text = s["label"] + mark
		b.pressed.connect(_on_closeup_hotspot.bind(rid, hid, subid))
		_hotspots_node().add_child(b)
	_clear_container(_actions_node())
	var back := Button.new()
	back.text = "退回 · 离开近景"
	back.pressed.connect(_on_closeup_back)
	_actions_node().add_child(back)

func _on_closeup_hotspot(rid: String, hid: String, subid: String) -> void:
	AudioManager.ensure_started()
	AudioManager.play_sfx("page")
	var cu = content["regions"][rid]["hotspots"][hid]["closeup"] as Dictionary
	var s = cu["hotspots"][subid] as Dictionary
	AudioManager.play_sfx(s.get("sfx", ""))
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
	_clear_container(_hotspots_node())
	_clear_container(_actions_node())
	_clear_container(_memories_node())
	var txt: String = "【结算】" + str(d.get("title", "")) + "\n\n" + str(d.get("body", ""))
	if d.has("gained"):
		txt += "\n\n· " + d["gained"]
	_stage_node().text = txt
	var b := Button.new()
	b.text = "继续 ▶"
	b.pressed.connect(_on_settlement_continue)
	_actions_node().add_child(b)

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
	if _librarian_present(rid):
		var line: String = a.get("then", "……")
		# thenByFlag：玩家主动对话时，按其刚经历的状态给对应回应（沉默旁观者的回响）
		# 注意 c_tier_* 以线索形式置位（state["clues"]），非布尔旗标，故查 clues
		if a.has("thenByFlag"):
			var tb: Dictionary = a["thenByFlag"]
			var clues: Dictionary = state.get("clues", {})
			for fk in tb.keys():
				if clues.has(fk):
					line = tb[fk]
					break
		_set_curator(line)
	if subid != "":
		_refresh_closeup_controls()
	else:
		_refresh_region_controls()

# ── 便签钩子：三选一（互斥，只产一个 c_note）──────────
func _open_hook_options(rid: String, hid: String, h: Dictionary, is_closeup := false, closeup_hid := "") -> void:
	var prompt: String = h.get("hookPrompt", "你要写点什么吗？")
	_set_curator(prompt)
	_clear_container(_actions_node())
	for opt in (h["options"] as Array):
		var b := Button.new()
		b.text = opt["label"]
		if is_closeup:
			b.pressed.connect(_on_hook_choice.bind(rid, hid, h, opt["id"], "closeup", closeup_hid))
		else:
			b.pressed.connect(_on_hook_choice.bind(rid, hid, h, opt["id"], "region", ""))
		_actions_node().add_child(b)
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
	_actions_node().add_child(back)

func _on_hook_choice(rid: String, hid: String, h: Dictionary, opt_id: String, return_node := "region", return_closeup := "") -> void:
	AudioManager.ensure_started()
	if opt_id == "mail":
		AudioManager.play_sfx("slot")
	var res = h["hookResults"] as Dictionary
	AudioManager.play_sfx(h.get("sfx", ""))
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
		# 走动：钩子结果可把管理员移到另一区
		if r.has("moveLibrarian"):
			_apply_move_librarian(r["moveLibrarian"])
			_refresh_portrait()
		# 近景钩子回到 closeup，区域钩子回到 region
		if return_node == "closeup":
			state["node"] = "closeup"
		else:
			state["node"] = "region"
		var rr = content["regions"][rid] as Dictionary
		_stage_node().text = rr["name"] + "\n" + rr.get("metaphor", "") + "\n" + rr.get("desc", "")
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
		_actions_node().add_child(b)

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
	_stage_node().text = rv["stage"]
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
	_clear_container(_hotspots_node())
	_clear_container(_actions_node())
	_render_memories()
	for a in (rv["actions"] as Array):
		var b := Button.new()
		b.text = a["label"]
		b.pressed.connect(_on_node_action.bind(a["id"]))
		_actions_node().add_child(b)
	_refresh_portrait()

# ── Ending：return / take / burn 三分支 ────────────────
func _build_ending_actions() -> void:
	_clear_container(_hotspots_node())
	_clear_container(_actions_node())
	if not content.has("ending"):
		return
	var ed = content["ending"] as Dictionary
	for a in (ed["defaultActions"] as Array):
		var b := Button.new()
		b.text = a["label"]
		b.pressed.connect(_on_ending.bind(a["id"]))
		_actions_node().add_child(b)

func _on_ending(aid: String) -> void:
	AudioManager.ensure_started()
	var ed = content["ending"] as Dictionary
	var key := aid.replace("end:", "")
	var ends = ed["endings"] as Dictionary
	if ends.has(key):
		state["endingText"] = ends[key]
		state["node"] = "ending"
		_stage_node().text = ends[key]
		_curator_node().text = "（这是你自己的事了。）"
		_clear_container(_hotspots_node())
		_clear_container(_actions_node())

# ── 收场（curtain）：夜尽，合上书 ──────────────────
func _render_curtain() -> void:
	AudioManager.play_sting("curtain")
	_clear_container(_hotspots_node())
	_clear_container(_actions_node())
	_clear_container(_clues_node())
	_clear_container(_memories_node())
	_stage_node().text = "（今夜闭馆。灯还亮着。）\n\n雨声贴着玻璃，慢慢远了。\n你合上《逾期之书》——可你知道，有些书，合上了也还在原地等你。"
	_curator_node().text = "（夜还长。下次来，灯还亮着。）"
	# 过场帧：本夜声明 next 且夜程表有后继 → 在收场页追加下一夜的 frame（区分两天的非对话载体）
	if content.has("next"):
		var nxt: String = content["next"]
		var cid: String = content.get("id", "")
		if NIGHT_ORDER.has(nxt) and NIGHT_ORDER.find(nxt) > NIGHT_ORDER.find(cid):
			var nxt_content: Dictionary = ContentLoader.get_night(nxt)
			if nxt_content.has("frame"):
				_stage_node().text += "\n\n" + (nxt_content["frame"] as String)
			var bn := Button.new()
			bn.text = "继续 —— 下一夜"
			# 跨夜携带：点击「继续」时先把本夜可携带字段快照进 autoload，再加载下一夜
			bn.pressed.connect(func():
				_carry_forward()
				load_night_by_id(nxt)
			)
			_actions_node().add_child(bn)
	var b := Button.new()
	b.text = "重新翻开《逾期之书》"
	b.pressed.connect(_on_restart)
	_actions_node().add_child(b)
	_refresh_portrait()

func _on_restart() -> void:
	# 开发期 DEBUG_IGNORE_SAVE 下每次启动即从 notice 开场；此处供收场后重玩
	state = _fresh_state()
	if content.has("librarianHome"):
		state["librarianWhere"] = content["librarianHome"]
	elif content.get("regions", {}).has("service_desk"):
		state["librarianWhere"] = "service_desk"
	state["node"] = "notice"
	_render_node("notice")

# ── 记忆（memories）：只显示已解锁的 state.memories ──
func _render_memories() -> void:
	_clear_container(_memories_node())
	if state["memories"].is_empty():
		return
	var head := Label.new()
	head.text = "—— 你想起的事 ——"
	_memories_node().add_child(head)
	for mid in state["memories"].keys():
		var l := Label.new()
		l.text = "· " + state["memories"][mid]
		_memories_node().add_child(l)

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
