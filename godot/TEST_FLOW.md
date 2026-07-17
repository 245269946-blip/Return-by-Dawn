# 《逾期之书》测试流程 · 全夜程自测（序章 → 夜A~I → 终章Z）

> 本文档是一份**可复用自测流程**。目标：把本次对话里敲定的「内容要求」与「实机要求」
> 全部写进同一份 runbook，使后续推进新一夜 / 改旧一夜时，AI 可以直接照此自我验证，
> 不必再回头翻聊天记录。
>
> 适用范围：夜 E（《赶你出去的夜》）与夜 D（《背后楼梯》·闸门夜）的**严格对应**验证；
> 夜 E→F 的**跨夜携带 + 三物证合流**验证；**第三幕·最后的狂欢（夜 G/H/I）+ 终章·夜 Z** 的
> 完整可玩验证；以及 spine 护栏（night_e/f/g/h/i/z 均在豁免区）。
>
> 配套文件：`content/night_{a,b,c,d,e,f,g,h,i,z}.json`、`test_harness.gd`（序章+P~Z 全块）、
> `tools/spine_check.py`、`Main.gd`（`NIGHT_ORDER`）。

---

## 0. 自测总览（先读这张表）

| 验证项 | 命令 / 入口 | 通过标准 |
|---|---|---|
| 脊柱泄漏 | `python tools/spine_check.py` | 退出码 0，受护栏夜（< night_d）全绿 |
| 实机点测 | Godot headless 跑 `test_harness.tscn` | 日志 `PASS=N  FAIL=0` + `ALL GREEN`，退出码 0 |
| 跨夜串联 | `test_harness.gd` 各块（X0-1~X0-N） | 跨夜线索/记忆成功并入 |
| D↔E 对应 | `test_harness.gd` E 块 + 人工读 `night_e.json` | 见 §1.1 对照清单 |
| 第三幕/终章 | `test_harness.gd` G/H/I/Z 块 + 人工读 json | 见 §1.7 内容铁律 |
| 区域出口数 | `test_harness.gd` 各块 `x_expect` 断言 | 见 §2.2 各镜像表 |

**铁律**：headless 跑完后，**必须还原 `project.godot` 的 `main_scene` 回 `res://Main.tscn`**。
否则下次 F5 会进测试场景而非游戏。

---

## 1. 内容要求（叙事 / 红线 / 对应规则）

### 1.1 夜 D ↔ 夜 E 对应铁律（改任何一夜前先对这张表）

夜 D 是「闸门夜」（向内、邀请、揭晓自认），夜 E 是它的**镜像**（向外、切断、放手）。
二者必须成对出现，且只在对应维度上镜像，不互相抢戏。

| 维度 | 夜 D《背后楼梯》 | 夜 E《赶你出去的夜》 | 关系 |
|---|---|---|---|
| 门的方向 | 门**向内**开——「带你去我待的地方看看」 | 门**向外**推——「今晚你回去吧」 | 镜像：邀请 ↔ 切断 |
| 动作性质 | 邀请 + 揭晓 | 切断 + 放手 | 镜像：拉 ↔ 推 |
| 灯光 | 「灯还亮着，你回头能看见路」（他在内、他守） | 「灯在身后亮着」（他在内、他留，你在外） | 镜像：守 ↔ 留 |
| 双关句「有些书拖着不还对谁都不好」 | 夜 D **不用**（留给夜 E 收口） | 夜 E 用作双关：既指玩家不在场，也指他自身＝逾期最久、拖着不让你走的书 | 夜 E 收口，D 不抢 |
| reveal | 拼合三碎片 → **认自认**（c_draft/c_habit/c_borrow_card 门控） | **复用同一堆碎片**，新一层意义＝**接受放手** | 同一门控，不同落点 |
| 管理者状态 | 反常地「带你看」 | 反常地「赶你走」 | 二者都反常，都非冷酷、零说教 |
| 落点 | v6 原则（自认拼合） | v6 原则⑧陪伴非帮助 / ⑨感谢而非战胜；**不抢释放戏**（那是终章） | 分工不重叠 |

**红线**：
- 夜 E 可以写管理员主动切断「不急」回路（这是 BT 式「因爱放你走」），但**不得**写成道德说教、不得台词轰炸。
- 「赶」是**动作**（站在门里抵门、虚扶门把）不是台词。
- 夜 E 不点破教学（玩家已在夜 D 闸门自认），只做「放你走」的情感落点。

### 1.2 夜 E 三物证播种（为夜 F 合流锚定）

夜 E 在各自原本区域让管理员「一直收着」你的遗落物，跨夜携带进夜 F：

| 物证 | 区域 / 热点 | 解锁线索 | 来源夜 |
|---|---|---|---|
| ① 便签 | `service_desk.drawer_note` | `c_kept_note` | 夜 A《夹在书里的信》 |
| ② 相册书 | `reading_room.kept_album`「待你再来看」架 | `c_kept_album` | 夜 B《满员的书架》 |
| ③ 雨水盆边物 | `stacks_deep.kept_basin` | `c_kept_basin` | 夜 C《一屋子的雨》 |

外加：赶人 hook（`entry_porch.door_block`，选项 stay/go 均置 `c_letgo`＝因爱放手）；
留灯仪式 `study_zone.keep_lamp`→`c_lamp_kept`；反常信号 `service_desk.desk_empty`→`c_no_tea`（「不急」的茶不在）。
记忆 `m_letgo` 在 reveal 解锁。

### 1.3 夜 E reveal 门控（验证「夜与夜真正串联」）

夜 E `reveal.requiresClues = ["c_draft","c_habit","c_borrow_card"]` ——
**直接复用夜 D 的三门控线索**，靠跨夜携带触发。意义：玩家已在夜 D 拼过，
夜 E 的拼合是「同一堆碎片的新一层意义（接受放手）」。若夜 E 重建独立门控，则串联断、测试 E5-0 会 FAIL。

### 1.4 夜 F《三物证合流》· 预兆夜（已落地）

**落点铁律（v6 §五 line 208-212 + 原则 17）**：夜 F 只做一拍——**清醒地转**。
夜 D 已答「你是谁」、夜 E 已做「放手」；夜 F 落点＝「你知道自己在绕开，这件事本身成了新的重量。
循环不再是无知地转，是清醒地转」。三条红线：

1. **不抢终章**：终章才用三物证触发 A/B/C「正确做法」闪回（知≠行，v6 line 30/265/268）。
   夜 F **绝不**展开三夜正确做法回照，只到「承认自己在绕」为止。
2. **不重复夜 D 揭晓**：夜 F 可引用「我拼过了」，但落点是清醒重量，不是重新揭晓身份。
3. **不抢夜 E 放手**：夜 F 他在场（你又回来了），不再演一次放手；管理员零说教。

- `id=night_f`、`playerName:"阿迟"`、**无 `next`**（第三幕·最后的狂欢未做，收场落回重开）。
- `frame` 修正：管理员**在场**（v6 明确他把三物证摆出来，原脚手架误写「他不在」已改）。
- **核心互动＝Relief 消失**（v6 line 211）：`service_desk.three_things` 是 hook，
  选项 `take`（认领）/ `push_back`（推回「下次」）**都置 `c_knowing`**，但都不再有「下次再说」的轻松。
- 三物证呈现形态来自各夜状态钩子（便签＝揉皱又抚平／相册书＝折角停在空位页／盆边物盒＝标「雨天物」）。
- `reveal.requiresClues = ["c_kept_note","c_kept_album","c_kept_basin"]`（夜 E 携带而来）—— 验证 E→F 串联与合流门控。
- 记忆 `m_knowing` 在 reveal 解锁。区域收拢为 3 区 + void（预兆夜聚焦）：
  `service_desk`(three_things hook) / `entry_porch`(door_unlocked·你自己回来) / `reading_room`(empty_seat·清醒看自己) / `void_room`。

### 1.5 跨夜携带约定（引擎层）

- `_carry_forward()`：在 curtain「继续」点击时快照 `clues / memories / hookChosenLine / mailedLetter / revealSeen`。
- `_merge_cross_night()`：在 `load_night_by_id()` 末尾并入。
- 夜 D→E 携带：`c_draft / c_habit / c_borrow_card + m_self_left + revealSeen`。
- 夜 E→F 携带：上述全部 **+** `c_kept_note / c_kept_album / c_kept_basin + c_letgo`。

### 1.6 脊柱护栏（spine_check.py）

- `NIGHT_ORDER` 已含 `night_e / night_f / night_g / night_h / night_i / night_z`；`SPINE_BREAK_NIGHT = "night_d"`。
- night_e / f / g / h / i / z 在**豁免区**（夜序 ≥ night_d），spine_check 不扫泄漏；但夜 A/B/C 仍受护栏，
  改它们时若泄漏「其实是你／就是你自己」等词会 FAIL。
- 即便在豁免区，也**不要**在 night_e 抢终章释放戏、不要写进说教。

### 1.7 第三幕·最后的狂欢（夜 G/H/I）+ 终章·夜 Z（已落地 · 全链路绿灯）

第三幕是「贪恋被稳稳等着」的狂欢三夜——玩家已知『是我』，却仍贪恋，把续借的线拽回手里。
终章是单一必然 BE：玩家带序章续借本回来（夜 H 伏笔回收），callback 三物证知≠行闪回，
最后一句通知落空，收束句「灯还亮着。——你终于不用等我了。」

**统一红线（v6 §六 / §七）**：
1. 管理员非道德优胜者、零说教；陪伴非帮助；放手是「因爱放手」不是赶。
2. 灯的含义：灯不是他的，是**你自己不肯灭的光外化成他**（夜 G 点一丝；终章再点）。
3. 双侧逃避镜像（v6 升级）：玩家用旧痛逃现在，管理员用旧暖逃分离（夜 I 同框）。
4. callback 落在「知≠行」缝隙——**不写成『我终于做到了』**，写「我从来都知道要怎么做，只是懂了也还是难」。
5. 不抢夜 E 放手、不抢夜 D 揭晓；甲（短暂挣扎）压缩进乙（告别必然落点），不在此停。

| 夜 | 书题 | 核心 | 关键线索 / 门控 | 续接 |
|---|---|---|---|---|
| G | 《灯是谁装的》 | 狂欢①·点灯含义 | `c_lamp_g`/`c_lamp2_g`/`c_shelf_g`/`c_lamp_kept`；`archive_lamp.lamp_install`→closeup`see_lamp`→`c_lamp_meaning`（灯=你自己不肯灭的光） | `next=night_h` |
| H | 《档案室半开的门》 | 狂欢②·种序章本伏笔 | `c_claim_h`/`c_lamp2_h`/`c_shelf_h`；`archive_lamp.half_open_door`→closeup`read_card`→`c_prologue_book_waiting`（夜Z回收锚） | `next=night_i` |
| I | 《最后一盏灯前的玩笑》 | 狂欢③·双侧逃避同框 | `service_desk.hard_book` hook（defer/now 均→`c_stall_defer`/`c_stall_now`）；`c_reg_i`/`c_shelf_i`/`c_lamp_kept`/`c_lamp2_i` | `next=night_z` |
| Z | 《带书回来的人》 | 终章·单一必然BE | reveal `requiresClues=["c_kept_note","c_kept_album","c_kept_basin"]`（夜E携带）；`service_desk.prologue_book` 需 `requiresFlag:c_prologue_book_waiting`（夜H产）；closeup`choose_ending` 需 `requiresReveal`→ hook(stay/go)→`toExit`→收束句 | **无 next（终局）** |

终章关键节点（夜 Z）：
- `notice`：最后一天·无通知·你自己来；桌上已写好未寄出《你的归还期限·已到期》。
- `enter`：解释一切（他是你留下来的那部分；灯=你的光；门一直没锁）。
- `service_desk.unwritten_notice`→`c_unwritten`（最后一次通知落空·他爱你所以放手）+ settlement。
- `service_desk.prologue_book`（requiresFlag 满足才出现）→ closeup `choose_ending`（requiresReveal 满足才可点）。
- `reading_room.three_wall`（requiresReveal 门控在 closeup 子热点层生效，区域级不生效——见 §2.3 坑7）→`c_wall_z`。
- `archive_lamp.echo_heart`→closeup`hear_echo`→`c_echo_realized`（终章心脏瞬间：他的声音=你逃避回声；推力「我不能再爱你爱到把你变成我的样子」）。
- `entry_porch.door_unlocked`→`c_door_z`（最后一道不在场回收）。
- reveal 门控三物证→ callback 知≠行闪回；记忆 `m_final`/`m_echo_z` 解锁。
- `choose_ending`：甲 stay 压缩转 go（均置 `c_ending_go`，toExit）→ 出馆节点收束句；**终局 curtain 无「继续」**。

跨夜携带链（引擎 `_carry_forward` + `_merge_cross_night`，与既有一致）：
- H→I→Z：夜 H 产 `c_prologue_book_waiting`，终章 `prologue_book` 用它做 `requiresFlag` 门控（夜H→夜Z 串联验证点）。
- E→Z：三物证 `c_kept_note/album/basin` 跨夜携带进终章 reveal 门控（夜与夜真正串联）。

---

## 2. 实机要求（文件布局 / 调用 / 断言约定）

### 2.1 文件布局与接线清单

改完内容后，逐项确认：

- [ ] `content/night_e.json` 存在，顶层 `id:"night_e"`、`next:"night_f"`、`playerName:"阿迟"`。
- [ ] `content/night_f.json` 存在，顶层 `id:"night_f"`、`next:"night_g"`（第三幕已接通）、`reveal.requiresClues` 三物证、`service_desk.three_things` 为 hook。
- [ ] `content/night_g/h/i/z.json` 存在，顶层 `id` / `next`（G→H→I→Z，Z 无 next）/ `playerName:"阿迟"`；夜 Z reveal `requiresClues` 三物证、`service_desk.prologue_book` 带 `requiresFlag:c_prologue_book_waiting` 且 closeup `choose_ending` 带 `requiresReveal` + hook(stay/go)→`toExit`。
- [ ] `content/night_d.json` 顶层有 `"next": "night_e"`（D→E 续接声明）。
- [ ] `Main.gd` 第 46 行 `NIGHT_ORDER` 末尾含 `"night_e","night_f","night_g","night_h","night_i","night_z"`。
- [ ] `test_harness.gd` 含 E/F/G/H/I/Z 块，汇总行含「夜 G + 夜 H + 夜 I + 夜 Z + 跨夜携带」。
- [ ] `tools/spine_check.py` `NIGHT_ORDER` 含 `night_e / night_f / night_g / night_h / night_i / night_z`（已预置）。

### 2.2 区域出口数约定（§2.2 树边 / 镜像夜 D）

夜 E 八区出口数（引擎自动注入「回到服务台」，锁定区渲染为「（门锁着）」灰显、不计出口数）：

| 区域 | 出口数 | 备注 |
|---|---|---|
| `entry_porch` | 1 | 进馆·去服务台 |
| `service_desk` | 5 | 门廊 / 管理员区① / 管理员区② / 便民 / 阅览区 |
| `lounge_stairs` | 1 | 回服务台（管理员区①） |
| `archive_lamp` | 1 | 回服务台（管理员区②） |
| `utility_zone` | 1 | 回服务台 |
| `reading_room` | 3 | 服务台 / 书库深处 / 自习区 |
| `stacks_deep` | 1 | 回阅览区 |
| `study_zone` | 1 | 回阅览区 |
| `void_room` | 0 | **永不开启**（不计出口） |

断言：`test_harness.gd` 的 `e_expect` 字典 + `void_room 永不开启` + `八区均常驻「回到服务台」`。
改夜 E 区域拓扑时，**必须同步更新 `e_expect`**，否则 E5 断言 FAIL。

夜 F 区域出口数（**预兆夜·收拢为 3 区 + void**，聚焦「问出口→三物证合流→清醒地转」）：

| 区域 | 出口数 | 备注 |
|---|---|---|
| `entry_porch` | 1 | 进馆·去服务台 |
| `service_desk` | 2 | 去门廊 / 去阅览区 |
| `reading_room` | 1 | 回服务台 |
| `void_room` | 0 | **永不开启**（不计出口） |

断言：`test_harness.gd` 的 `f_expect` 字典 + `void_room 永不开启` + `三区均常驻「回到服务台」`。
改夜 F 区域拓扑时，**必须同步更新 `f_expect`**，否则 F6 断言 FAIL。

夜 G 区域出口数（狂欢①·5 区 + void）：

| 区域 | 出口数 |
|---|---|
| `service_desk` | 4（门廊 / 灯控室 / 阅览区 / 自习区） |
| `entry_porch` | 1（进馆·去服务台） |
| `reading_room` | 1（回服务台） |
| `study_zone` | 1（回服务台） |
| `archive_lamp` | 1（回服务台） |
| `void_room` | 0（永不开启） |

断言：`test_harness.gd` 的 `g_expect` 字典 + `void_room 永不开启` + `五区均常驻「回到服务台」`。

夜 H 区域出口数（狂欢②·4 区 + void）：

| 区域 | 出口数 |
|---|---|
| `service_desk` | 3（门廊 / 档案室 / 阅览区） |
| `archive_lamp` | 1（回服务台） |
| `entry_porch` | 1（进馆·去服务台） |
| `reading_room` | 1（回服务台） |
| `void_room` | 0（永不开启） |

断言：`test_harness.gd` 的 `h_expect` 字典 + `void_room 永不开启` + `四区均常驻「回到服务台」`。

夜 I 区域出口数（狂欢③·5 区 + void）：

| 区域 | 出口数 |
|---|---|
| `service_desk` | 4（门廊 / 阅览区 / 便民 / 自习区） |
| `reading_room` | 1（回服务台） |
| `utility_zone` | 1（回服务台） |
| `study_zone` | 1（回服务台） |
| `entry_porch` | 1（进馆·去服务台） |
| `void_room` | 0（永不开启） |

断言：`test_harness.gd` 的 `i_expect` 字典 + `void_room 永不开启` + `五区均常驻「回到服务台」`。

夜 Z 区域出口数（终章·4 区 + void）：

| 区域 | 出口数 |
|---|---|
| `service_desk` | 3（门廊 / 灯控室 / 阅览区） |
| `archive_lamp` | 1（回服务台） |
| `reading_room` | 1（回服务台） |
| `entry_porch` | 1（进馆·去服务台） |
| `void_room` | 0（永不开启） |

断言：`test_harness.gd` 的 `z_expect` 字典 + `void_room 永不开启` + `四区均常驻「回到服务台」`。

### 2.3 调用约定（与 harness 完全一致，手写测试照此）

```
入口链：  _on_node_action("read")  → enter
          _on_node_action("desk")  → hub + currentRegion=service_desk
区域切换：_on_goto(rid)
热点：    _on_hotspot(rid, hid)                        # 解锁 unlocks.clue
hook：    _on_hook_choice(rid, hid, hotspot_dict, option_id, "region", "")
揭示：    _refresh_region_controls()  →  _actions_has("拼合那一夜")  →  _on_enter_reveal()
出馆：    _on_node_action("to_exit")
收场：    _on_node_action("to_close")  →  curtain；含「继续」则 _carry_forward()→load_night_by_id(next)
```

注意：`_on_node_action` 仅处理硬编码 id（`read/toss/desk/door/to_utility/to_exit/to_close` 等），
**没有**通用 `to_<region>`；跨区任务必须放 `utility_zone` 复用 `to_utility`（夜 E 任务已落在本区或各自区域热点，未触发此约束）。

### 2.4 断言约定（写新测试块照此）

- `chk(id, cond, detail="")`：PASS/FAIL 计数，汇总打印 `PASS=N  FAIL=M`。
- `_stage()`：返回当前 `Stage` 文案，**子串匹配**关键句（如 `_stage().contains("灯还亮着")`）。
- `_actions_has(sub)`：**子串**匹配 action 文案。
  ⚠️ GDScript 的 `"x" in array` 是**精确成员匹配**，按钮文案常带后缀（如「（拼合）▶」），
  故必须用 `_actions_has()` 子串助手，不能用 `in`。
- `_portrait_visible()` / `_curator()`：馆员在场与台词（夜 E `entry_porch` 馆员在场，断言 `_portrait_visible()`）。
- 跨夜断言：先 `main.state = main._fresh_state()` 灌入上一夜 clues/memories，调 `_carry_forward()`，
  再 `load_night_by_id("night_e")`，断言 `c_xxx in main.state["clues"]`。

---

## 3. Runbook：如何自测（逐步命令）

### 3.1 前置 · 脊柱护栏

```bash
cd overdue-book/godot
python tools/spine_check.py
# 期望：EXIT=0，受护栏夜（night_a/b/c/prologue）全绿；night_d/e/f 标注「豁免」
```

### 3.2 实机 · Headless 点测

```bash
cd overdue-book/godot

# 1) 备份 + 翻转 main_scene 到测试场景
cp project.godot project.godot.bak
#   （用 Edit 工具把 run/main_scene="res://Main.tscn" 改为 "res://test_harness.tscn"）

# 2) 跑 Godot headless，stdout 重定向到文件（PowerShell 会吞 stdout）
"/d/godot/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe" \
  --headless --path . > /tmp/godot_harness.log 2>&1
echo "GODOT_EXIT=$?"

# 3) 解析日志
grep -E "PASS=|FAIL=|ALL GREEN|FAILED" /tmp/godot_harness.log
# 期望：PASS=N  FAIL=0   且出现 ALL GREEN；退出码 0

# 4) ⚠️ 必须还原（否则 F5 进测试场景）
#   （用 Edit 工具把 run/main_scene 改回 "res://Main.tscn"）
#   rm project.godot.bak   # 确认还原后删备份
```

退出码约定：ALL GREEN → `0`；任一 FAIL → `1`；harness 内置 120s 安全超时 → `2`。

### 3.3 已知坑（务必记牢）

1. **`project.godot` 测后必还原** `main_scene=res://Main.tscn`。最易忘，忘则下次 F5 进测试场景。
2. **stdout 被 shell 吞** → 必须 `> log 2>&1` 重定向到文件再 `grep`。
3. **Godot exe 是文件夹内含 console exe**：路径为
   `D:\godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe`（注意 `.exe` 夹在目录名里）。
4. **headless 安全超时 120s**：harness `_ready` 内置 `create_timer(120)` 强制 quit(2)，挂死也不会卡住。
5. **`add_child` 必须 `call_deferred` + 等 3 个 `process_frame`**：headless 下 root 正 busy，直接加子节点会被静默拒绝。
6. **spine_check 从自身路径解析 content/**：在 `godot/` 目录下跑即可，无需额外参数。
7. **`requiresReveal` 仅对 closeup 子热点 / 出口生效，区域级 hotspot 不生效**（引擎 `_refresh_region_controls` 只门控 `requiresFlag`，不门控 `requiresReveal`；schema 已声明）。
   终章 `reading_room.three_wall` 虽标 `requiresReveal:true`，但它是区域级热点，引擎不会灰显——它本就设计为「callback 触发物」，玩家到终章时三物证早已携带，门控在叙事上自然成立。
   真正硬门控的是 `service_desk.prologue_book` 的 closeup 子热点 `choose_ending`（`requiresReveal` 在 `_refresh_closeup_controls` / `_on_closeup_hotspot` 生效），
   故测试里「reveal 前 choose_ending 不可见」是真实引擎门控断言（Z2-3）。改终章时若把 `choose_ending` 误挪成区域级热点，门控会失效。
8. **`project.godot` 测后必还原** 同坑 1；夜 G/H/I/Z 验证同样需翻转 `main_scene`→`test_harness.tscn` 跑、跑完还原。
9. **`requiresFlag` 门控已支持 clue-id（引擎最小修复，守零改引擎纪律）**：原 `_refresh_region_controls`（530-532 行）只查顶层旗标，导致所有以 clue-id 作门控的热点（夜 C/D 的 `c_returned`、夜 B 的 `shelvedAlbum`、终章 Z 的 `c_prologue_book_waiting`）真实游戏里**不可达**、终章**不可通关**。已改为 `if rf_flag != "" and not (state.get(rf_flag, false) or state["clues"].has(rf_flag)): continue`。**改任何一夜时，若用 clue-id 做 `requiresFlag`，现在才能真正生效**；勿回退此改（它是让 clue 可作门控来源的唯一必要改动，未新增节点类型/新流程）。
10. **玩家向全流程试玩 = `playtest_dump.tscn`**：模拟真实玩家跑全 11 夜（序章 + 夜 A~I + 终章 Z），dump 出玩家实际读到的叙事文本供评测叙事通过性/剧情感。命令见 §3.5。同样需翻转 `main_scene`→`playtest_dump.tscn` 跑、跑完还原 `Main.tscn`。dumper 已含 `_reveal_ready()`（查 `requiresClues` 对 `state["clues"]` 满足）与 `_re_explore_after_reveal()`（reveal 后二次探勘 `requiresReveal` 近景子热点、置位前置旗标），绕开"区域字典序导致前置旗标未置位"的误报。
11. **G/H/I 出口缺失已修（真实 UI 阻塞）**：原三夜 JSON 有 `exit` 节点但全夜无 `toExit` 触发点 → 玩家走不到收场。已在三夜 `service_desk.hotspots` 各加 `leave_library`（`toExit:true` + `settlement` + 收尾"那明晚你还来还书吗？"）+ `companion` 对应行。改第三幕三夜时**勿删此热点**。
12. **headless 退出有 CanvasItem/ObjectDB 泄漏告警**：跑 `playtest_dump.tscn` 时日志末尾会出现 `12 CanvasItem leaked` + `24 ObjectDB leaked`，是测试场景卸载的对象清理告警，**非游戏内容缺陷**，不影响游玩与评测结论；`Main.tscn` 下不触发。

### 3.4 加一夜的最小改动清单（零改引擎）

1. 新建 `content/night_x.json`（含 `id` / `next` / `playerName` / `frame` / `regions` / `nodes` / `companion` / `memories`）。
2. `Main.gd` `NIGHT_ORDER` 追加 `"night_x"`。
3. 上一夜 json 顶层加 `"next":"night_x"`。
4. `tools/spine_check.py` `NIGHT_ORDER` 追加（若新夜 < night_d 则受护栏，需自查泄漏）。
5. `test_harness.gd` 加 X 块（加载 + 跨夜携带 + 关键断言 + 区域出口数），汇总行补名称。
6. 跑 §3.1 + §3.2 验证全绿。

---

### 3.5 玩家向全流程试玩（`playtest_dump.tscn`）

模拟真实玩家从序章一路玩到终章，逐夜 dump 出玩家实际读到的叙事文本（notice/enter/热点/钩子/近景/reveal/exit/curtain），用于评测**全局叙事流畅性、点击互动与自由探索、叙事通过性、叙事剧情感**四维度。

```bash
cd overdue-book/godot

# 1) 翻转 main_scene 到玩家试玩场景
#   （用 Edit 工具把 run/main_scene="res://Main.tscn" 改为 "res://playtest_dump.tscn"）

# 2) 跑 Godot headless，重定向 stdout
"/d/godot/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe" \
  --headless --path . > /tmp/godot_playtest.log 2>&1
echo "GODOT_EXIT=$?"

# 3) 解析：查每夜 [EXIT 出馆] 与最终 Exit Code
grep -E "\[EXIT 出馆\]|Exit Code|全部夜试玩结束" /tmp/godot_playtest.log
# 期望：序章 + 夜 A~I + 终章 Z 共 11 行 [EXIT 出馆]；Exit Code: 0；无 BLOCKER/阻断/不可达/卡死

# 4) ⚠️ 必须还原 main_scene 回 res://Main.tscn
```

**玩家向试玩断言清单（PASS）**：
- 11 夜每夜都出现 `[EXIT 出馆]`，出口路径符合 §2.2 各镜像表（g/h/i 走 `service_desk/leave_library`、Z 走 `service_desk/prologue_book/choose_ending`）。
- 全程无 BLOCKER / 阻断 / 不可达 / 卡死 / FAIL 标记；`void_room` 永不开启。
- 跨夜 `[本夜线索]` 列表逐夜增长（序章 ~15 → 终章 ~53），证明 clues/memories/revealSeen 整套跨夜链真实并入。
- 终章收束句命中 v6：「灯还亮着。——你终于不用等我了。……限度温柔，非致郁」。

**评测结论**：四维全达标（详见 `playtest_report.md`）。

## 4. 本次（夜 E + 夜 F）已落地的断言清单（备查）

**夜 E 块（E0-0 ~ E6-1）**
- E0-0 加载成功；E0-1~E0-5 跨夜携带（c_draft/c_habit/c_borrow_card/m_self_left/revealSeen 并入）；E0-6 `next=night_f`
- E1-0 notice「第六天·门里有人」；E1-2 read→enter「门从里面被抵住」；E1-3 desk→hub
- E2-0 反常 `c_no_tea`；E2-1 物证① `c_kept_note`
- E3-0 门廊馆员在场「没让你进」；E3-1 赶人 hook 提问上屏；E3-2 赶人→`c_letgo`「走吧」
- E4-0 物证② `c_kept_album`；E4-1 物证③ `c_kept_basin`；E4-2 留灯 `c_lamp_kept`
- E5-0 拼合按钮出现（跨夜线索满足）；E5-1 revealSeen 置位；E5-2「替我拖着不走」；E5-3「肯放/该放」
- E5-4 记忆 `m_letgo`；E6-0 出馆「灯还亮着」；E6-1 收场含「继续」
- E5 各区域出口数（§2.2 镜像表）；E5 `void_room` 永不开启；E5b 八区常驻「回到服务台」

**夜 F 块（F0-0 ~ F6b）**
- F0-0 加载成功；F0-1~F0-3 三边物证 `c_kept_note/c_kept_album/c_kept_basin` 并入
- F0-4 `c_letgo` 并入；F0-5 `c_draft/c_habit/c_borrow_card` 仍并入（证明 E→F 串联）；F0-6 无 `next`（收场落回重开）
- F1-0 notice「第七天·没通知·自己回来」；F1-1 read→enter「你到底是谁／我替你收着」；F1-2 desk→hub
- F2-0 门廊「门没锁·自己回来」；F2-1 阅览区「常坐空位·躲开自己那一本」
- F3-0 三物证 hook 提问上屏（认领/推回）；F3-1 推回「下次」→`c_knowing`；F3-2 **Relief 消失**（「那口松没来」）
- F4-0 reveal 解锁（三边物证满足）；F4-1 revealSeen 置位
- F4-2 落点·清醒地转「看见了还绕／睁着眼」；F4-3 落点·新重量「知道自己在绕开成了新的重量」
- F4-4 **红线**：不写成「现在都做到了」（仍是循环没停）；F4-5 记忆 `m_knowing`
- F5-0 出馆「灯还亮着·睁着眼走」；F5-1 收场 curtain（含「继续」→夜G）
- F6 各区域出口数（§2.2 收拢表）；F6 `void_room` 永不开启；F6b 三区常驻「回到服务台」

**夜 G 块（G0-0 ~ G5b）**
- G0-0 加载成功；G0-1 `next=night_h`；G0-2~G0-3 跨夜携带（三物证 / `c_letgo`+`m_letgo` 并入）
- G1-0 notice「第八天·灯是谁装的·逾期通知」；G1-1 read→enter「带你看看这馆」；G1-2 desk→hub
- G2-0 `c_lamp_g`；G2-1 `c_lamp2_g`（甜里带刺）；G2-2 `c_shelf_g`；G2-3 `c_lamp_kept`
- G3-0 进近景；G3-1 `c_lamp_meaning`（灯=你自己不肯灭的光）；G3-2 文案「灯不是他的／不肯灭」
- G4-0 收场 curtain（含「继续」→夜H）
- G5 各区域出口数（§2.2 狂欢①表）；G5 `void_room` 永不开启；G5b 五区常驻「回到服务台」

**夜 H 块（H0-0 ~ H5b）**
- H0-0 加载成功；H0-1 `next=night_i`；H0-2 跨夜携带（`c_lamp_meaning` 并入）
- H1-0 notice「第九天·档案室半开的门」；H1-1 read→enter「全是给你留的」；H1-2 desk→hub
- H2-0 `c_claim_h`（仍在逃分离）
- H3-0 进近景；H3-1 `c_prologue_book_waiting`（序章本伏笔·夜Z回收锚）；H3-2 文案「等你还」
- H3-3 `c_lamp2_h`；H3-4 `c_shelf_h`（每句炫耀底下藏『再多留一夜』）
- H4-0 收场 curtain（含「继续」→夜I）
- H5 各区域出口数（§2.2 狂欢②表）；H5 `void_room` 永不开启；H5b 四区常驻「回到服务台」

**夜 I 块（I0-0 ~ I5b）**
- I0-0 加载成功；I0-1 `next=night_z`；I0-2 跨夜携带（`c_prologue_book_waiting` 并入·夜H锚）
- I1-0 notice「第十天·最后一盏灯前的玩笑」；I1-1 read→enter「话最多·老友」；I1-2 desk→hub
- I2-0 `hard_book` hook 提问上屏（推到明天/今天就还）；I2-1 `c_stall_defer`（双侧逃避同框·结算「并肩拖着」）
- I3-0 `c_shelf_i`；I3-1 `c_reg_i`（登记册「压得最久」）；I3-2 `c_lamp_kept`；I3-3 `c_lamp2_i`
- I4-0 收场 curtain（含「继续」→夜Z）
- I5 各区域出口数（§2.2 狂欢③表）；I5 `void_room` 永不开启；I5b 五区常驻「回到服务台」

**夜 Z 块（Z0-0 ~ Z9b）·终章**
- Z0-0 加载成功；Z0-1 **无 next（单一必然BE）**；Z0-2~Z0-3 跨夜携带（三物证 + `c_prologue_book_waiting` 并入）
- Z1-0 notice「最后一天·没通知·自己来」；Z1-1 read→enter「你自己留下来的那部分／门一直没锁」；Z1-2 desk→hub
- Z2-0 `c_unwritten`（未寄出通知）；Z2-1 「你自己来了／放手」
- Z2-2 `prologue_book` 进入近景（requiresFlag 满足）；Z2-3 **门控：reveal 前 `choose_ending` 不可见**（closeup 子热点 requiresReveal 真门控）
- Z3-0 `c_wall_z`（三物证墙）
- Z4-0 进近景；Z4-1 `c_echo_realized`（他的声音=你的逃避回声）；Z4-2 推力「把你变成我的样子」
- Z5-0 `c_door_z`（门没锁）
- Z6-0 拼合按钮出现（三物证满足）；Z6-1 revealSeen 置位；Z6-2 callback 知≠行「我从来都知道要怎么做」；Z6-3 **红线**：不写成「我做到了」；Z6-4 记忆 `m_final`/`m_echo_z`
- Z7-0 reveal 后 `choose_ending` 可见；Z7-1 抉择 hook 上屏（放回架/真正还他）；Z7-2 `c_ending_go`（乙·告别必然落点）；Z7-3 抉择后→出馆节点（**收束句**「灯还亮着——你终于不用等我了」）
- Z8-0 **终局收场无「继续」**（单一必然BE）
- Z9 各区域出口数（§2.2 终章表）；Z9 `void_room` 永不开启；Z9b 四区常驻「回到服务台」

> 全量：**PASS=351 / FAIL=0 / ALL GREEN**（序章+夜A+夜B+夜C+夜D+夜E+夜F+夜G+夜H+夜I+夜Z+跨夜携带）。
> 注：夜G/H/I/Z 验证后，游戏已可从序章一路玩到终章完整结局（单一必然 BE）。
> 另：玩家向全流程试玩（`playtest_dump.tscn`，`playtest_dump_out.txt` 1517 行，`Exit Code: 0`）额外验证叙事流畅性/通过性/剧情感四维度全达标，零 BLOCKER；评测详见 `playtest_report.md`。
