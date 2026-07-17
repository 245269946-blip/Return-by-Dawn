# 《逾期之书》内容契约（框架层）

> 本文件是夜内容的**数据契约**。每一夜 = 一个 `content/night_X.json` 纯数据文件；
> 引擎（`Main.gd` + autoload）按本契约渲染，**加一夜零改引擎**。
> 美术 / 音频 / 文案精修属内容层，不在此契约范围。

## 设计原则（来自《项目骨架与框架落地方案》）

1. **引擎与内容分离**：加一夜 = 加一个 `content/night_X.json`，引擎逻辑零改动（`Main.NIGHT_ORDER` 加 id 即可）。
2. **内容与视图分离**：`night_X.json` 导出**纯数据对象**（区域 / 热点 / 管理员钩子），引擎负责渲染成热点层 / 对话条 / 区域图。
3. **三件套即框架**：点击探索（热点）+ 区域切换 + 管理员常驻反应层；其余（背包 / 通知箱 / 回溯）属 meta 层，延后。

---

## 界面分区（锈湖式 · 2026-07-16 重排）

引擎渲染为上下双区，点击互动与对话严格分离：

| 区域 | 节点路径 | 承载内容 |
|---|---|---|
| **中间画面 `StageArea`** | `Panel/StageArea/*` | 场景描述（`Stage`）+ 可点物件（`Hotspots`）+ 动作（`Actions`）+ 线索/记忆（`Clues`/`Memories`）。**所有点击互动都在这块。** |
| **底部对话框 `DialogueBox`** | `Panel/DialogueBox/*` | 管理员肖像位（`Portrait`，在场才显示）+ 台词（`Curator`）。**对话只在这块。** |

> 内容层只产数据；美术期把 `StageArea` 替换为场景底图 + 热点层，`DialogueBox` 替换为带肖像的对话框即可，节点路径不变。

## 管理员在场模型（非「无处不在」 · 2026-07-16）

管理员是一个**会走动的场景人物**，不是无处不在的旁白声。原则⑧（零说教／非道德优胜者）与「在场≠话多」要求他只在被放置在场时出现、开口。

- 每个区域用 `regions.<rid>.librarian` 声明他的在场与点位：
  - **省略** → 在场（兼容旧内容；点位 = 区域 id）。
  - `false` / `null` → **不在场**：底部肖像隐藏，该区域的 `enter:<rid>` / `hot:<rid>:<hid>` 反应**沉默**。
  - `"<spot>"`（字符串）→ 在场，点位 = 该字符串（美术落位提示，如 `"desk"` `"by_window"`）。
  - `{ "spot": "<spot>", "requiresFlag": "<flag>" }` → **仅当 `state[flag]` 为真时在场**（表达「某个阶段他才走到这里」）。
- 剧情节点反应 `enter:<nodeId>`（notice/enter/reveal/ending）非空间锚定，**恒定触发**（叙事节拍，不计入在场门控）。
- **走动**：热点或 hook 结果可带 `"moveLibrarian": "<rid>"`，把他移到另一区（置位 `librarianArrived:<rid>`，配合目标区的 `requiresFlag` 表达「他走了过来」）。引擎不在场时自动隐藏肖像。
- 夜级初始位置：顶层 `"librarianHome": "<rid>"`（缺省回退 `service_desk`）。

> 作者纪律：先把管理员放进「他在哪、站哪」再写反应；不要把「进每个区域都开口」当默认。他主要锚在服务台（互动点），只在设计需要的场景/阶段出现。

---

## 出口门控（场景切换的限制与引导 · 2026-07-16）

为落实「每夜约 10 分钟」的节奏约束，场景切换本身也要受引导，而非自由乱窜。出口（`regions.<rid>.exits[]`）支持与热点一致的前置门控：

- `requiresFlag`: "<flag>" → 仅当 `state[flag]` 为真时可走；否则灰显不可点。
- `requiresReveal`: true → 仅当已拼合（`revealSeen`）后可走；否则灰显不可点。
- `lockedLabel`: "…" → 未满足时的灰显文案（默认「（还去不了）」）。
- 门控出口**不计入**可走出口；与区域级 `locked`（夜D 解锁区）同样处理。

```jsonc
"exits": [
  { "label": "去书库深处", "to": "stacks_deep", "requiresFlag": "c_letter", "lockedLabel": "去书库深处（还差线索）" },
  { "label": "去便民配套区", "to": "utility_zone", "requiresReveal": true, "lockedLabel": "去便民配套区（先把信读完）" }
]
```

> 用途：把「必须按线索顺序推进」显式化——玩家在没集齐线索前，看不到通往下一阶段的出口，从而被自然引导走完设计路径，节奏被框在 ~10 分钟。

---

## 顶层字段

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `id` | string | 是 | 夜 id，与文件名一致（如 `"night_a"`） |
| `playerName` | string | 是 | 主角称呼，`{name}` 在全文插值 |
| `title` | string | 是 | 夜标题 |
| `meta` | object | 否 | `{ decoy: bool, note: string }` 作者备注，不参与渲染 |
| `next` | string | 否 | 跨夜续接：声明下一夜 id（须在 `Main.NIGHT_ORDER` 中且夜序靠后）；收场 curtain 提供「继续」入口。最后一夜省略 |
| `regions` | object | 是 | 区域图，键 = 区域 id |
| `nodes` | object | 是 | 剧情节点（`notice` / `enter` / 可扩展），键 = 节点 id |
| `reveal` | object | 否 | 拼合节点（多线索门控） |
| `ending` | object | 否 | 结局分支 |
| `companion` | object | 是 | 管理员常驻反应，键见下 |
| `memories` | object | 否 | 记忆字典 `m_id -> text` |
| `librarianHome` | string | 否 | 管理员夜级初始位置（区域 id）；省略回退 `service_desk` |

---

## `regions.<rid>`

```jsonc
{
  "name": "服务台",
  "metaphor": "程序性温柔的入口——所有处理都从这流过",
  "desc": "服务台后的灯拧得很低。",
  "librarian": "desk",   // 可选：管理员在场点位（字符串）；省略=在场，false/null=不在场
  "exits": [ { "label": "去阅览区", "to": "reading_room" } ],
  "hotspots": { "<hid>": { /* Hotspot */ } }
}
```

- `metaphor`：区域展示隐喻（叙事层，**不可空**）。
- `exits`：区域间通道，`to` 指向其它区域 id；单夜内构成区域图。

## Hotspot（点击探索 · 三件套之一）

```jsonc
{
  "label": "逾期通知单（写着你名字）",   // 物件名（按钮文案）
  "once": "首次点击的一句话（事实，不解释）",
  "again": "再次点击（可选）",
  "curatorOnce": "首次的管理员反应（可选）",
  "curatorAgain": "再次的管理员反应（可选）",
  "ask": { "prompt": "谁？", "then": "忘了。" },        // 追问链（可选）
  "unlocks": { "id": "c_name", "text": "线索文本" },    // 点击解锁的线索（可选）
  "hook": true,                                          // 是否为三选项钩子（可选）
  "hookPrompt": "你要写点什么吗？",
  "options": [ { "id": "truth", "label": "写一句真话" } ],
  "hookResults": {
    "truth": {
      "form": "便签被压在抽屉最上层、抚平",
      "line": "「这句……我替你收着。」",
      "clue": { "id": "c_note", "text": "线索文本" },
      "settlement": { "title": "你写下了那句话", "body": "…", "gained": "线索：…" }
    }
  },
  "closeup": {                                            // 近景（可选，递归同结构）
    "stage": "你把书摊开。…",
    "hotspots": { "<subhid>": { /* Hotspot */ } }
  },
  "moveLibrarian": "reading_room"   // 可选：触发后把管理员移到该区（走动）
}
```

**写作纪律（对齐骨架 §2.1 / §3.2）**：
- 物件给**事实**，不给**结论**；不写「主角因为…所以…」。
- 一句话呈现，留白高，让玩家自己脑补。
- 管理员默认沉默；只在特定物件 / 钩子开口（在场 ≠ 话多）。

## `nodes.<nid>`（剧情节点）

```jsonc
{ "stage": "节点正文", "actions": [ { "id": "read", "label": "弯腰捡起", "primary": true } ] }
```

- `stage`：节点正文；`actions`：选项按钮，`primary: true` 高亮主选项。
- 引擎内置节点名：`notice`（开场通知）/ `enter`（进门）/ `reveal`（拼合）/ `ending`（结局）。

## `reveal`（拼合节点 · 门控）

```jsonc
{ "requiresClues": ["c_letter", "c_name"], "stage": "…", "actions": [ … ] }
```

- 仅当 `state.clues` 含全部 `requiresClues` 时，由区域热点触发进入。

## `ending`（结局分支）

```jsonc
{
  "defaultStage": "未触发 reveal 时的默认正文",
  "defaultActions": [ { "id": "end:return", "label": "归还", "primary": true }, … ],
  "endings": { "return": "该选择的正文", "take": "…", "burn": "…" }
}
```

- 选项 id 形如 `end:<choice>`；`endings[choice]` 为该选择的正文。

## `companion`（管理员常驻反应层 · 三件套之二）

键格式：

| 键 | 触发时机 |
|---|---|
| `enter:<regionId>` | 进入区域 |
| `hot:<regionId>:<hotspotId>` | 点击热点 |
| `enter:<nodeId>` | 进入剧情节点 |

值 = 一句话。引擎在对应时机调用 `_companion(key)`；**缺键则沉默**。

> **在场门控**：`enter:<regionId>` 与 `hot:<regionId>:<hotspotId>` 仅在管理员**当前位于该区域**时触发（见「管理员在场模型」）；区域声明 `librarian: false` 则这两条反应恒沉默。`enter:<nodeId>`（notice/enter/reveal/ending）非空间锚定，恒定触发。

---

## 脊柱护栏（自认红线 · 原则13）

> 来自 v6 原则13：夜 A / 夜 B / 夜 C **绝不点破「其实是你」**；自认只发生在夜 D 闸门，
> 且由**玩家自己拼合**（拼图合拢，不是被告知）。任何一夜出现「这好像是我／你就是本人」式
> 点破句＝违规打回。

**护栏工具**：`tools/spine_check.py`（F4）

- 扫描所有 `content/night_*.json`，对夜序 `< night_d` 的夜递归检查全部故事文案；
- 命中「点破词」（如 `是你写的` / `是你自己` / `其实是你` / `信是你` …）即报错退出（CI 拦截）；
- 点破词含负向先行断言，已排除领属用法「是你自己的事／决定」（玩家自主权，非自认）；
- 夜序 `>= night_d` 的夜豁免（闸门与终章允许自认）。

**作者纪律**：落一夜前先跑 `python tools/spine_check.py`，受约束的夜必须为绿灯（退出码 0）。
夜 A 早期版本曾在 reveal.stage / read_front 结算标题 / trace_next 结算正文 三处出现点破表述，
经 red-line 重写后已清除；当前 `spine_check` 对 night_a/b/c/prologue 全部绿灯（2026-07-16 复核）。
护栏的存在正是为了阻止点破词复现于后续夜。

---

## 每夜节奏预算（约 10 分钟 · 2026-07-16）

用户硬性约束：**夜 A / 夜 B / 夜 C 各自约 10 分钟**（非三夜合计）。靠「限制 + 引导」框定节奏，而非靠自由探索：

- **场景切换**：出口门控（见上）把可走路径限制在「当前阶段该去的地方」；服务台恒为家（`⌂ 回到服务台` 常驻）。
- **点击道具**：每个区域 2–3 个策展热点（不堆 sandbox）；关键道具用 `requiresFlag`/`requiresReveal` 门控出现。
- **故事探索**：`reveal.requiresClues` 把线索拼合门控住，未集齐不进拼合/不进高潮。
- **结构模板（约 10 分钟体量）**：
  - 4 个剧情节点：notice / enter / reveal / exit（阅读 ~2–3 min）
  - 5–6 个区域，每区 2–3 热点，其中 1–2 区含 closeup（2 子热点）（点击+阅读 ~5–6 min）
  - 1 个管理员事件（study_zone 留灯走动，机制④）（~1 min）
  - 1–2 个决策钩子（便签 / 投信）（~1 min）
- 夜 A / 夜 B 已按此体量落地（内容单夜即 ~10 min）；夜 C 起的新夜须按此模板建。

---

## 校验清单（作者落一夜前自查）

- [ ] 顶层 `id` / `playerName` / `title` / `regions` / `nodes` / `companion` 齐全
- [ ] 每个区域有非空 `metaphor` 与至少一条 `exit`
- [ ] 每个热点 `once` 给事实不给结论；`curatorOnce` 克制（非说教）
- [ ] `reveal.requiresClues` 中的 id 都能从某热点 `unlocks.id` 产出
- [ ] `ending.endings` 覆盖 `defaultActions` 中所有 `end:<choice>`
- [ ] `companion` 键拼写 = `enter:<id>` / `hot:<rid>:<hid>` / `enter:<nid>`
- [ ] `python tools/spine_check.py` 绿灯（夜序 < night_d 无「点破词」泄漏）
