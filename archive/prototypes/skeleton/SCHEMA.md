# 《逾期之书》夜内容 Schema 规范（唯一地基）

> **本文件是项目唯一内容契约。Godot 正式线 与 网页验收壳 都必须严格遵守同一份内容、同一套字段。**
> 任何一条线新增/修改内容，只能改 `content/*.json`，不得各自发明字段。
> 加一夜 = 加一个 `content/night_x.json` + 一个 `demo/nights/night_x.js` 薄壳加载器，**引擎/状态机零改动**。

---

## 0. 单一事实源（Single Source of Truth）

| 角色 | 路径 | 说明 |
|------|------|------|
| **内容契约（本文件）** | `skeleton/SCHEMA.md` | 字段定义唯一规范 |
| **内容数据（Godot 吃，demo 也吃）** | `godot/content/night_a.json` | 正式内容，双线共读 |
| **Godot 状态机（正式线）** | `godot/Main.gd` | 只认本 schema，不背逻辑 |
| **网页验收壳（薄壳）** | `demo/engine.js` + `demo/nights/night_a.js` | 只读同一份 JSON 做热点验收，**不实现 act/checkPuzzle 等漂移逻辑** |

⚠️ **禁止**：demo 自行定义 `night.act()` / `night.checkPuzzle()` / `night.regionMapActions()` 这类内容侧逻辑。所有规则必须落在 JSON 字段里，由引擎统一解释。

---

## 1. 顶层结构

```jsonc
{
  "id": "night_a",                 // 夜标识，存档按此区分
  "playerName": "阿迟",           // 默认玩家名，文案中 {name} 替换
  "title": "夜 A · 夹在书里的信",
  "meta": {                       // 叙事元信息（可选）
    "decoy": true,
    "note": "关系域 decoy，前期读成别人故事"
  },
  "regions": { ... },            // 区域图 + 可点物件（见 §2）
  "nodes": { ... },              // 剧情节点 notice/enter/reveal/ending（见 §3）
  "companion": { ... },          // 管理员常驻反应（见 §4）
  "reveal": { ... },             // 收束门控（见 §5，可选）
  "memories": { ... },           // 记忆字典（见 §6，可选）
  "ending": { ... }              // 结局三分支（见 §7）
}
```

---

## 2. regions（区域图 + 可点物件）

`regions` 是字典，`key` = 区域 id（如 `borrowing_desk`）。

```jsonc
"borrowing_desk": {
  "name": "借阅台",
  "metaphor": "程序性温柔的入口……",   // 区域隐喻，验收壳展示
  "desc": "服务台后的灯拧得很低……",     // 进入区域时的环境描述
  "exits": [                              // 出口通道（通往其他区域）
    { "label": "去阅览区", "to": "reading_room" }
  ],
  "hotspots": { ... }                     // 区域内可点物件（见 §2.1）
}
```

### 2.1 hotspots（可点物件）

`hotspots` 是字典，`key` = 物件 id（如 `notice_card`）。

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `label` | string | ✅ | 物件在验收壳里的按钮文字 |
| `once` | string | ✅ | **首次**查看时的一句话描述 |
| `again` | string | ⬜ | **再次**查看时的描述；缺则复用 `once` |
| `curatorOnce` | string | ⬜ | 首次查看时管理员的一句话反应 |
| `curatorAgain` | string | ⬜ | 再次查看时管理员反应；缺则用 `curatorOnce` |
| `unlocks` | object | ⬜ | 解锁线索：`{ "id": "c_xxx", "text": "线索正文" }` |
| `ask` | object | ⬜ | 追问钩子：`{ "prompt": "谁？", "then": "忘了。" }` |
| `hook` | bool | ⬜ | `true` 表示这是「便签钩子」物件（见 §2.2） |

### 2.2 便签钩子（hook = true 的物件）

```jsonc
"drawer_note": {
  "label": "抽屉里的空白便签（笔就在手边）",
  "hook": true,
  "hookPrompt": "服务台抽屉里有一张空白便签。你要写点什么吗？",
  "once": "服务台抽屉里压着一张空白便签……",
  "again": "便签还在原处。要不要写，你犹豫着。",
  "curatorOnce": "「要写吗？」他擦着台面，「不写也行。」",
  "options": [                               // 三选一（互斥）
    { "id": "truth", "label": "写一句真话" },
    { "id": "safe",  "label": "写一句安全的话" },
    { "id": "none",  "label": "什么都不写" }
  ],
  "hookResults": {                          // 每个选项的结果
    "truth": {
      "line": "「这句……我替你收着。」他把它压在抽屉最上层。",
      "clue": { "id": "c_note", "text": "便签写下一句真话……" }
    }
    // safe / none 同理，均产出同一 clue id（互斥不叠加）
  }
}
```

**规则**：钩子选择互斥——只记录唯一 `hookChosenLine[hotId]`，二次点击只复述，不叠加线索。

---

## 3. nodes（剧情节点）

`nodes` 是字典，固定四套：`notice` / `enter` / `reveal` / `ending`。

```jsonc
"notice": {
  "stage": "逾期通知 · 午夜送达\n\n{name}的《夏天》已逾期……",
  "actions": [
    { "id": "read", "label": "弯腰捡起，读完整张通知", "primary": true },
    { "id": "toss", "label": "先揉成一团——最后还是展平了" }
  ]
},
"enter": {
  "stage": "雨在馆外下……",
  "actions": [ { "id": "desk", "label": "走近柜台", "primary": true } ]
}
```

- `stage`：正文，`{name}` 由引擎替换为 `playerName`。
- `actions[].id`：引擎 `act(id)` 认的固定动作：
  - `read` / `toss` → 进入 `enter`
  - `desk` / `door` → 进入区域图 `hub`
  - `to_ending` → 进入 `ending`
  - `end:return` / `end:take` / `end:burn` → 结局分支（见 §7）

---

## 4. companion（管理员常驻反应）

字典，键为事件名：

```jsonc
"companion": {
  "enter:notice": "（通知单从门缝塞进来，像往常一样。）",
  "enter:borrowing_desk": "「台面刚擦过。」他指了指那摞书……",
  "hot:borrowing_desk:return_box": "「不急。」他隔着台面看你……"
}
```

事件命名：`enter:<node>` 或 `enter:<regionId>`，以及 `hot:<regionId>:<hotId>`。

---

## 5. reveal（收束门控，可选）

```jsonc
"reveal": {
  "requiresClues": ["c_letter", "c_name"],   // 集齐这些 clue 才解锁
  "stage": "灯下你把碎片拼完：信是你写的……",
  "actions": [ { "id": "to_ending", "label": "合上书，做最后的决定 ▶", "primary": true } ]
}
```

引擎在区域内自动检测：集齐 `requiresClues` 时，在出口区下方出现「拼合那一夜」按钮。

---

## 6. memories（记忆字典，可选）

```jsonc
"memories": {
  "m_forgot": "被遗忘的事：你写过一封没寄出的信……"
}
```

解锁后展示在「记忆」面板。

---

## 7. ending（结局三分支）

```jsonc
"ending": {
  "defaultStage": "现在你知道了：《夏天》该回到它那一格……",
  "defaultActions": [
    { "id": "end:return", "label": "归还 · 放回它该在的那一格", "primary": true },
    { "id": "end:take",   "label": "带走 · 悄悄塞进外套内袋" },
    { "id": "end:burn",   "label": "销毁 · 在灯下一页页撕碎" }
  ],
  "endings": {
    "return": "你把《夏天》放回它该在的那一格……",
    "take":   "你把它塞进外套内袋……",
    "burn":   "你在灯下把它一页页撕开……"
  }
}
```

`end:xxx` 动作的 `xxx` 部分即 `endings` 的键。

---

## 8. 状态字段（双线必须一致）

引擎内部状态 `state` 字段（Godot 与 demo 共用同名）：

| 字段 | 说明 |
|------|------|
| `node` | 当前节点 `notice｜enter｜hub｜region｜reveal｜ending` |
| `currentRegion` | 当前区域 id |
| `clues` | 线索字典 `id → text` |
| `memories` | 记忆字典 `id → text` |
| `visitedHot` | 已看热点 `"rid:hid" → true` |
| `examined` | 已展开热点 `"rid:hid" → true` |
| `hookChosenLine` | 便签已选复述 `"hid" → line` |
| `curator` | 管理员当前台词 |
| `asking` | 已追问过的热点 `"rid:hid" → true` |
| `endingText` | 结局正文（存档恢复用） |

**存档恢复**：重开后按上述字段还原区域、线索、便签选择、已看热点、阶段。

---

## 9. 验收清单（加一夜时自测）

- [ ] 新夜 JSON 严格符合本 schema，无引擎私有字段
- [ ] Godot 实跑：从 notice 走到 ending 三分支全通
- [ ] 网页壳加载同一份 JSON：热点点击 / 区域切换 / 便签钩子 / reveal 门控 全通
- [ ] 存档：走到中途退出再进，能恢复到同一阶段
- [ ] 两条线玩家视角一致（文案、线索、结局无差异）
