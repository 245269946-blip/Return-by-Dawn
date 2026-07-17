# 逾期之书 / The Overdue Book

> 一座深夜还亮着灯的图书馆，和一群逾期最久、迟迟没被归还的书。
> 互动叙事 / 文字冒险游戏，Godot 4.7 制作，视觉走「亚洲城市夜生活 × 便利店灯光」的克制安静美学。

---

## 这是什么

- **类型**：互动叙事 / 点击探索（锈湖式节点推进 + 克制夜景 + 白噪音层）。
- **核心**：一个人遗落的人生的故事。表层是把送错的通知、逾期书籍「还回去」，里层慢慢收束到读者自己。
- **当前阶段**：**序章 + 夜 A~I + 终章 Z 已全部落地，从序章可一路玩到唯一必然 BE 结局**；自动化点测 **351/0 全绿**，玩家向全流程试玩 **11 夜零阻塞**。
- **发行规划**：Windows 独立主机优先，Web/HTML5 双端，TapTap 主发行；国内免费 + 海外买断双轨。
- **一句话**：数据驱动的文字游戏——**加一夜 = 写一个 JSON，引擎零改动**。

---

## 当前进度（截至 2026-07-17）

| 模块 | 状态 |
|------|------|
| Godot 工程骨架（点击探索 / 区域切换 / 管理员对话三件套） | ✅ 完成 |
| 内容数据契约 `CONTENT_SCHEMA.md` | ✅ 落地 |
| 序章 + 夜 A/B/C/D/E/F/G/H/I + 终章 Z（共 11 段，全链路可玩到结局） | ✅ 完成 |
| 跨夜携带引擎（clues / memories / hookChosenLine / revealSeen） | ✅ 完成 |
| headless 自动化点测（序章→终章全块） | ✅ **351 PASS / 0 FAIL / ALL GREEN** |
| 玩家向全流程试玩（11 夜叙事通过性 / 剧情感评测） | ✅ **11 夜全 EXIT、零 BLOCKER** |
| 真实美术 / 音频资产 | ⬜ 未接入（ColorRect 占位 + 雨声占位） |

---

## 仓库结构

```
Return-by-Dawn/                       ← 仓库根（对应本机 overdue-book/）
├── godot/                            ← ★ Godot 工程（用 Godot 打开这个目录）
│   ├── project.godot                 ← 工程配置：主场景 Main.tscn / Compatibility 渲染 / 5 个 Autoload
│   ├── Main.tscn / Main.gd           ← 主场景 + 逻辑（F5 即玩序章 → 夜 A）
│   ├── content/                      ← ★ 全部夜内容（纯数据 JSON，加一夜只改/加这里）
│   │   ├── prologue.json             ← 序章（教学夜：续借循环）
│   │   ├── night_a.json … night_i.json  ← 第一/二/三幕各夜
│   │   └── night_z.json              ← 终章《灯还亮着》
│   ├── autoload/                     ← SaveManager / AudioManager / PlatformService / ContentLoader / ProgressState
│   ├── test_harness.tscn / .gd       ← 自动化点测入口（序章→终章全块断言）
│   ├── playtest_dump.tscn / .gd      ← 玩家向全流程试玩 dump（逐夜输出玩家读到的叙事文本）
│   ├── CONTENT_SCHEMA.md             ← ★ 内容数据契约（写/改 JSON 前必读）
│   ├── TEST_FLOW.md                  ← ★ 自测 runbook（点测 + 玩家试玩命令与断言清单）
│   ├── playtest_report.md            ← 玩家向试玩四维评测报告
│   ├── NIGHT_A_VERIFY.md             ← 夜 A 验收清单（点测范式参考）
│   ├── README_M0.md                  ← 引擎层脚手架说明（更细）
│   ├── GODOT_VERSION                 ← 锁定的 Godot 版本
│   ├── tools/                        ← spine_check.py（脊柱泄漏护栏）/ pacing_estimate.py 等
│   └── art/                          ← 待用美术
├── story-draft-v6.md                 ← ★ 叙事圣经（19 条不可动摇原则 + 各夜框架，唯一事实源）
├── 设计讨论稿（story-draft-v1~v5、夜A框架、认知冲击密度 …）← 叙事设计演进史，参考用
└── .gitignore                        ← 已排除 .godot 缓存 / 日志 / 生成产物
```

> ⚠️ **叙事事实的唯一来源是 `story-draft-v6.md`**。动任何夜内容 / 框架前，必须先读它的第 12–35 行（19 条原则，含脊柱原则 1）与对应夜框架。

---

## 一、在另一台电脑上跑起来（3 步）

### 1. 克隆仓库

用 **GitHub Desktop**（已登录）：File → Clone repository → 选 `245269946-blip/Return-by-Dawn` → Clone。
或用命令行：

```bash
git clone https://github.com/245269946-blip/Return-by-Dawn.git
```

克隆下来的根目录 `Return-by-Dawn/` 即本仓库。

### 2. 安装 Godot

- 安装 **Godot 4.7-stable（或开发启动时最新的 Stable 4.x）**。
- 锁定依据见仓库内 `godot/GODOT_VERSION`：**保持 Compatibility Renderer（gl_compatibility）**，不要切到 Forward+，否则移动端 / 低配机可能跑不起来。
- 不需要额外插件；纯 GDScript。

### 3. 打开工程并运行

用 Godot 打开 **`Return-by-Dawn/godot/`** 这个目录（即包含 `project.godot` 的那一层），不是仓库根。
首次打开会重新导入（`.godot/` 缓存已被 git 忽略，正常，稍等片刻即可）。

> 若编辑器提示 `config/features` 版本不符，点「升级 / Keep」即可，不影响内容。

- **手动游玩**：直接按 **F5**（主场景已设为 `Main.tscn`）→ 从序章开始，点热点探索、看底部管理员反应、走抉择、出馆，逐夜推进到终章。
- **自动化点测**：见下文「三、测试」。

---

## 二、游戏怎么玩（玩家视角）

每一夜的节奏：**逾期通知进场 → 自由探索各区域（点热点 / 钩子 / 近景）→ 集齐线索触发「拼合那一夜」→ 出馆 / 收束句**。

- **区域**：馆分 8 区（门廊 / 服务台 / 阅览区 / 书库深处 / 自习区 / 便民配套 / 管理员休息室 / 灯控室）+ `void_room`（永不开启）。引擎自动注入「回到服务台」，锁定区渲染为「（门锁着）」灰显。
- **管理员**：一个会走动的场景人物（非无处不在的旁白）。他主要锚在服务台，只在设计需要的场景 / 阶段出现、开口；出现即沉默陪伴、不主动说教。
- **脊柱（核心反转）**：图书管理员 = 逾期最久的那本书 = 玩家自己遗落的版本（莫比乌斯环）。此真相**只在夜 D 闸门、由玩家自己拼合认出**，前期只立馆员人设与还书循环，绝不提前说破。
- **无惩罚失败**：每夜都通向一个结果（归档 / 归还 / 私藏 / 隐秘），非通关 / 失败。

---

## 三、测试（改动后务必跑）

仓库内置三套测试，覆盖不同粒度。**推荐每次改动后至少跑 ① + ②**。

### ① 脊柱护栏（防提前泄漏「其实是你」）

```bash
cd Return-by-Dawn/godot
python tools/spine_check.py
# 期望：EXIT=0，受护栏夜（序章 / 夜A / 夜B / 夜C）全绿；夜D 及之后为豁免区
```

> 需本地有 Python 3。脚本从自身路径解析 `content/`，在 `godot/` 下直接跑即可。

### ② 自动化点测（headless，序章→终章全块断言）

```bash
cd Return-by-Dawn/godot

# 1) 翻转主场景到测试场景（临时）
#    （用编辑器或 Edit 把 project.godot 的 run/main_scene 改为 "res://test_harness.tscn"）

# 2) 跑 Godot headless，stdout 重定向到文件（shell 会吞 stdout）
godot --headless --path . > /tmp/godot_harness.log 2>&1
echo "GODOT_EXIT=$?"

# 3) 解析
grep -E "PASS=|FAIL=|ALL GREEN" /tmp/godot_harness.log
# 期望：PASS=N  FAIL=0  且出现 ALL GREEN；退出码 0

# 4) ⚠️ 必须还原主场景回 "res://Main.tscn"（否则下次 F5 进测试场景）
```

⚠️ 必须显式传 `res://test_harness.tscn`：裸跑 `godot --headless --path .` 会启动游戏而非跑测试。
（本机路径示例见 `TEST_FLOW.md` §3.2；Godot 可执行文件换成你机器上的路径即可。）

### ③ 玩家向全流程试玩（叙事通过性 / 剧情感评测）

模拟真实玩家跑全 11 夜，dump 出玩家实际读到的叙事文本供人工评测。命令见 `TEST_FLOW.md` §3.5（同样需临时翻转 `main_scene`→`playtest_dump.tscn` 跑、跑完还原）。最新评测结论见 `playtest_report.md`：**四维全达标（流畅性 / 点击互动 / 叙事通过性 / 叙事剧情感），11 夜零阻塞**。

---

## 四、内容创作：如何加一夜（引擎零改动）

设计原则：**加一夜 = 加一个 `content/night_X.json` + 在 `Main.NIGHT_ORDER` 注册 id**，引擎逻辑完全不动。

### 最小步骤

1. **新建 `godot/content/night_x.json`**，顶层至少含：

   ```jsonc
   {
     "id": "night_x",
     "playerName": "阿迟",
     "title": "《新的一夜》",
     "next": "night_y",                 // 跨夜续接的下一夜 id；最后一夜省略
     "librarianHome": "service_desk",   // 管理员夜级初始位置（可选，缺省回退 service_desk）
     "regions": {
       "service_desk": {
         "name": "服务台",
         "metaphor": "程序性温柔的入口——所有处理都从这流过",
         "desc": "服务台后的灯拧得很低。",
         "exits": [ { "label": "去阅览区", "to": "reading_room" } ],
         "hotspots": {
           "some_hotspot": {
             "label": "可点的物件",
             "narrative": "你看见……",
             "unlocks": { "id": "c_some", "text": "一条线索" },   // 解锁线索
             "toExit": true,            // 可选：作为出馆触发点
             "settlement": { "title": "结算", "body": "……", "gained": "" }
           }
         }
       }
       // ... 其他区域
     },
     "nodes": {                         // 剧情节点全收在 nodes 下
       "notice":  { "stage": "逾期通知……", "actions": [{"id":"read","label":"拆开看"}] },
       "enter":   { "stage": "你推门进来……", "actions": [{"id":"desk","label":"去服务台"}] }
     },
     "reveal": {                        // 可选：拼合节点（多线索门控）
       "requiresClues": ["c_a","c_b","c_c"],
       "stage": "灯下，我把碎片一块块拼到一起……"
     },
     "companion": {                     // 管理员常驻反应
       "enter:service_desk": "「台面刚擦过。」"
     },
     "memories": {}                     // 可选：m_id -> text
   }
   ```

2. **`Main.gd` 的 `NIGHT_ORDER`** 追加 `"night_x"`（保持夜序，闸门夜 night_d 之后的为豁免区）。

3. **上一夜 json 顶层**加 `"next":"night_x"` 接通幕链。

4. **`tools/spine_check.py` 的 `NIGHT_ORDER`** 同步追加（若新夜夜序 < night_d 则受护栏，需自查泄漏）。

5. 跑 **① 脊柱护栏 + ② 自动化点测** 验证全绿。

> 完整的字段语义、区域 / 热点 / 钩子 / 近景 / 出口门控写法，以 **`godot/CONTENT_SCHEMA.md`** 为权威契约；加完一夜的自测断言写法见 **`godot/TEST_FLOW.md`** §3.4「加一夜的最小改动清单」。

### 红线（必须遵守）

- 夜 A / B / C **绝不点破「其实是你」**；自认只发生在夜 D 闸门，且由玩家自己合拢（拼图合拢，不是被告知）。任何一夜出现「这好像是我 / 你就是本人」式句子 = 违规打回。
- 管理员非道德优胜者、零说教；陪伴非帮助；放手是「因爱放手」不是赶。

---

## 五、架构约定

- **数据驱动**：每一夜的内容是 `godot/content/night_X.json` 这样一个 JSON。引擎（`Main.gd` + autoload）按 `CONTENT_SCHEMA.md` 契约渲染。
- **5 个 Autoload 单例**：
  - `SaveManager` — 存档（写 `user://`）
  - `AudioManager` — 白噪音 / 点击音（占位）
  - `PlatformService` — 平台相关（Windows / Web）
  - `ContentLoader` — 加载 `content/*.json`
  - `ProgressState` — 跨夜进度（`clues / memories / hookChosenLine / revealSeen` 携带）
- **界面分区（锈湖式）**：中间 `StageArea`（场景描述 + 可点热点 + 动作 + 线索/记忆）与底部 `DialogueBox`（管理员肖像 + 台词）严格分离；美术期把这两块替换为场景底图 / 带肖像对话框即可，节点路径不变。
- **零改引擎纪律**：加一夜、加一个区域、加一个热点都不需要改 `Main.gd` 逻辑，只改 / 加 JSON 与 `NIGHT_ORDER`。

---

## 六、用 GitHub Desktop 协作

- 远程已配好 `origin` → `https://github.com/245269946-blip/Return-by-Dawn.git`，默认分支 `main`。
- 本机改完 → GitHub Desktop 里 **Commit to main** → **Push origin** 即可。
- 提交信息建议写清「改了哪一夜 / 修了什么 bug / 点测几/几」。
- 本仓库**不含**上层 `.workbuddy` 隐私目录；请勿把个人目录、`.godot/` 缓存、日志与生成式测试产物（`*_out.txt` 等，已在 `.gitignore` 排除）提交进来。

---

## 七、已知缺口（留给后续里程碑）

- 真实美术 / 音频未接入（当前为 ColorRect 占位 + 雨声占位）。
- Web 存档为 IndexedDB，易丢；真实进度以 Windows 端为准。
- headless 测试场景退出时有 CanvasItem / ObjectDB 泄漏告警（测试场景卸载产物，**非游戏内容缺陷**，`Main.tscn` 下不触发）。

---

## 一句话上手

> 装 Godot 4.7（Compatibility）→ 打开 `godot/` 目录 → F5 从序章玩到终章；改完跑 `python tools/spine_check.py` + `godot --headless --path . res://test_harness.tscn` 确认全绿。
