# 《逾期之书》内容契约（框架层）

> 本文件是夜内容的**数据契约**。每一夜 = 一个 `content/night_X.json` 纯数据文件；
> 引擎（`Main.gd` + autoload）按本契约渲染，**加一夜零改引擎**。
> 美术 / 音频 / 文案精修属内容层，不在此契约范围。

## 设计原则（来自《项目骨架与框架落地方案》）

1. **引擎与内容分离**：加一夜 = 加一个 `content/night_X.json`，引擎逻辑零改动（`Main.NIGHT_ORDER` 加 id 即可）。
2. **内容与视图分离**：`night_X.json` 导出**纯数据对象**（区域 / 热点 / 管理员钩子），引擎负责渲染成热点层 / 对话条 / 区域图。
3. **三件套即框架**：点击探索（热点）+ 区域切换 + 管理员常驻反应层；其余（背包 / 通知箱 / 回溯）属 meta 层，延后。

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

---

## `regions.<rid>`

```jsonc
{
  "name": "服务台",
  "metaphor": "程序性温柔的入口——所有处理都从这流过",
  "desc": "服务台后的灯拧得很低。",
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
  }
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
夜 A 当前 3 处泄漏（reveal.stage / read_front 结算标题 / trace_next 结算正文）属已知 P0 红线债，
待内容 red-line 重写清除；护栏的存在正是为了阻止其复现于后续夜。

---

## 校验清单（作者落一夜前自查）

- [ ] 顶层 `id` / `playerName` / `title` / `regions` / `nodes` / `companion` 齐全
- [ ] 每个区域有非空 `metaphor` 与至少一条 `exit`
- [ ] 每个热点 `once` 给事实不给结论；`curatorOnce` 克制（非说教）
- [ ] `reveal.requiresClues` 中的 id 都能从某热点 `unlocks.id` 产出
- [ ] `ending.endings` 覆盖 `defaultActions` 中所有 `end:<choice>`
- [ ] `companion` 键拼写 = `enter:<id>` / `hot:<rid>:<hid>` / `enter:<nid>`
- [ ] `python tools/spine_check.py` 绿灯（夜序 < night_d 无「点破词」泄漏）
