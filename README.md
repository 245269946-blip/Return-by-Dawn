<div align="center">

# 📖 逾期之书 · Return by Dawn

**互动叙事 / 文字冒险 · Godot 4.7 · 锈湖式点击探索**

*一座深夜还亮着灯的图书馆，和一群逾期最久、迟迟没被归还的书。*

<br>

<span style="display:inline-block; padding:4px 12px; border:1px solid #d0d7de; border-radius:999px; margin:2px;">🎮 可直接运行</span>
<span style="display:inline-block; padding:4px 12px; border:1px solid #d0d7de; border-radius:999px; margin:2px;">📚 序章 + 夜A~I + 终章Z 全链路</span>
<span style="display:inline-block; padding:4px 12px; border:1px solid #d0d7de; border-radius:999px; margin:2px;">🧪 351 断言 ALL GREEN</span>
<span style="display:inline-block; padding:4px 12px; border:1px solid #d0d7de; border-radius:999px; margin:2px;">🛡️ 脊柱护栏</span>
<span style="display:inline-block; padding:4px 12px; border:1px solid #d0d7de; border-radius:999px; margin:2px;">🪶 加一夜 = 写一个 JSON</span>

</div>

---

## 📑 目录（点击卡片直达）

> 这是仓库首页的导航目录。每张卡片点一下就跳到对应文件/章节；下方是对应说明。
> **铁律**：叙事事实只认 [`story-draft-v6.md`](story-draft-v6.md)，数据字段只认 [`godot/CONTENT_SCHEMA.md`](godot/CONTENT_SCHEMA.md)；`archive/` 仅作历史参考，**不是现在该怎么写的依据**。

<div align="center">
<div style="display:flex; flex-wrap:wrap; justify-content:center; gap:10px; max-width:920px; margin:14px auto;">

<a href="#快速开始" style="flex:1 1 160px; min-width:150px; padding:14px 16px; border:1px solid #d0d7de; border-radius:12px; text-decoration:none; color:inherit; background:transparent;">
<div style="font-size:24px;">🚀</div><b>快速开始</b><br><small>装 Godot 跑起来</small></a>

<a href="story-draft-v6.md" style="flex:1 1 160px; min-width:150px; padding:14px 16px; border:1px solid #d0d7de; border-radius:12px; text-decoration:none; color:inherit; background:transparent;">
<div style="font-size:24px;">📜</div><b>叙事圣经</b><br><small>唯一事实源 v6</small></a>

<a href="godot/CONTENT_SCHEMA.md" style="flex:1 1 160px; min-width:150px; padding:14px 16px; border:1px solid #d0d7de; border-radius:12px; text-decoration:none; color:inherit; background:transparent;">
<div style="font-size:24px;">🧩</div><b>数据契约</b><br><small>JSON 字段权威</small></a>

<a href="godot/content/" style="flex:1 1 160px; min-width:150px; padding:14px 16px; border:1px solid #d0d7de; border-radius:12px; text-decoration:none; color:inherit; background:transparent;">
<div style="font-size:24px;">🎮</div><b>11 夜内容</b><br><small>全部夜 JSON</small></a>

<a href="godot/Main.gd" style="flex:1 1 160px; min-width:150px; padding:14px 16px; border:1px solid #d0d7de; border-radius:12px; text-decoration:none; color:inherit; background:transparent;">
<div style="font-size:24px;">⚙️</div><b>引擎代码</b><br><small>Main.gd 逻辑</small></a>

<a href="godot/TEST_FLOW.md" style="flex:1 1 160px; min-width:150px; padding:14px 16px; border:1px solid #d0d7de; border-radius:12px; text-decoration:none; color:inherit; background:transparent;">
<div style="font-size:24px;">🧪</div><b>自测 runbook</b><br><small>三套测试命令</small></a>

<a href="godot/playtest_report.md" style="flex:1 1 160px; min-width:150px; padding:14px 16px; border:1px solid #d0d7de; border-radius:12px; text-decoration:none; color:inherit; background:transparent;">
<div style="font-size:24px;">📊</div><b>试玩评测</b><br><small>四维全达标</small></a>

<a href="ending-three-tier-design-20260716.md" style="flex:1 1 160px; min-width:150px; padding:14px 16px; border:1px solid #d0d7de; border-radius:12px; text-decoration:none; color:inherit; background:transparent;">
<div style="font-size:24px;">🌅</div><b>终章设计</b><br><small>三态结局依据</small></a>

<a href="#历史存档" style="flex:1 1 160px; min-width:150px; padding:14px 16px; border:1px solid #d0d7de; border-radius:12px; text-decoration:none; color:inherit; background:transparent;">
<div style="font-size:24px;">📦</div><b>历史存档</b><br><small>折叠·只读参考</small></a>

</div>
</div>

---

## 快速开始

**这是什么**：互动叙事 / 点击探索（锈湖式节点推进 + 克制夜景 + 白噪音层）。核心是「一个人遗落的人生的故事」——表层是把送错的通知、逾期书籍「还回去」，里层慢慢收束到读者自己。当前**序章 + 夜 A~I + 终章 Z 已全部落地，从序章可一路玩到唯一必然 BE 结局**；自动化点测 **351/0 全绿**，玩家向全流程试玩 **11 夜零阻塞**。一句话：**加一夜 = 写一个 JSON，引擎零改动**。

### 1. 克隆仓库

```bash
git clone https://github.com/245269946-blip/Return-by-Dawn.git
```

### 2. 安装 Godot

- 安装 **Godot 4.7-stable（或最新的 Stable 4.x）**。
- 锁定依据见 [`godot/GODOT_VERSION`](godot/GODOT_VERSION)：**保持 Compatibility Renderer（gl_compatibility）**，不要切到 Forward+。
- 不需要额外插件；纯 GDScript。

### 3. 打开工程并运行

用 Godot 打开 **`Return-by-Dawn/godot/`** 目录（含 `project.godot` 的那一层），不是仓库根。

- **手动游玩**：按 **F5**（主场景已设为 `Main.tscn`）→ 从序章开始，点热点探索、看底部管理员反应、走抉择、出馆，逐夜推进到终章。
- **自动化点测 / 玩家试玩**：见下方「测试」一节。

---

## 游戏怎么玩（玩家视角）

每一夜节奏：**逾期通知进场 → 自由探索各区域（点热点 / 钩子 / 近景）→ 集齐线索触发「拼合那一夜」→ 出馆 / 收束句**。

- **区域**：馆分 8 区（门廊 / 服务台 / 阅览区 / 书库深处 / 自习区 / 便民配套 / 管理员休息室 / 灯控室）+ `void_room`（永不开启）。引擎自动注入「回到服务台」，锁定区渲染为「（门锁着）」灰显。
- **管理员**：会走动的场景人物（非无处不在的旁白）。主要锚在服务台，只在设计需要的场景 / 阶段出现、开口；出现即沉默陪伴、不主动说教。
- **脊柱（核心反转）**：图书管理员 = 逾期最久的那本书 = 玩家自己遗落的版本（莫比乌斯环）。此真相**只在夜 D 闸门、由玩家自己拼合认出**，前期只立馆员人设与还书循环，绝不提前说破。
- **无惩罚失败**：每夜都通向一个结果（归档 / 归还 / 私藏 / 隐秘），非通关 / 失败。

---

## 测试（改动后务必跑）

仓库内置三套测试。**推荐每次改动后至少跑 ① + ②**。详细命令与断言清单见 [`godot/TEST_FLOW.md`](godot/TEST_FLOW.md)。

### ① 脊柱护栏（防提前泄漏「其实是你」）

```bash
cd Return-by-Dawn/godot
python tools/spine_check.py
# 期望：EXIT=0，受护栏夜（序章 / 夜A / 夜B / 夜C）全绿；夜D 及之后为豁免区
```

### ② 自动化点测（headless，序章→终章全块断言）

需临时把 `project.godot` 的 `run/main_scene` 改为 `res://test_harness.tscn`，再用 Godot headless 跑，跑完**必须还原**回 `res://Main.tscn`：

```bash
cd Return-by-Dawn/godot
godot --headless --path . res://test_harness.tscn > /tmp/godot_harness.log 2>&1
grep -E "PASS=|FAIL=|ALL GREEN" /tmp/godot_harness.log
# 期望：PASS=N  FAIL=0  且出现 ALL GREEN；退出码 0
```

### ③ 玩家向全流程试玩（叙事通过性 / 剧情感评测）

模拟真实玩家跑全 11 夜，dump 出玩家实际读到的叙事文本供人工评测。同样需临时翻转 `main_scene`→`playtest_dump.tscn` 跑、跑完还原。最新结论见 [`godot/playtest_report.md`](godot/playtest_report.md)：**四维全达标（流畅性 / 点击互动 / 叙事通过性 / 叙事剧情感），11 夜零阻塞**。

---

## 内容创作：如何加一夜（引擎零改动）

**加一夜 = 加一个 `content/night_X.json` + 在 `Main.NIGHT_ORDER` 注册 id**，引擎逻辑完全不动。

最小步骤：

1. 新建 [`godot/content/night_x.json`](godot/content/)，顶层至少含 `id` / `title` / `regions` / `nodes`（`notice` `enter` `exit`）/ `companion`；跨夜续接靠上一夜的 `"next"`。
2. 在 [`godot/Main.gd`](godot/Main.gd) 的 `NIGHT_ORDER` 追加 `"night_x"`（保持夜序，闸门夜 `night_d` 之后为豁免区）。
3. 上一夜 json 顶层加 `"next":"night_x"` 接通幕链。
4. [`tools/spine_check.py`](godot/tools/spine_check.py) 的 `NIGHT_ORDER` 同步追加（若新夜夜序 < night_d 则受护栏，需自查泄漏）。
5. 跑 **① 脊柱护栏 + ② 自动化点测** 验证全绿。

> 完整字段语义、区域 / 热点 / 钩子 / 近景 / 出口门控写法，以 [`godot/CONTENT_SCHEMA.md`](godot/CONTENT_SCHEMA.md) 为权威契约；加完一夜的自测断言写法见 [`godot/TEST_FLOW.md`](godot/TEST_FLOW.md) §3.4。

### 红线（必须遵守）

- 夜 A / B / C **绝不点破「其实是你」**；自认只发生在夜 D 闸门，且由玩家自己合拢（拼图合拢，不是被告知）。任何一夜出现「这好像是我 / 你就是本人」式句子 = 违规打回。
- 管理员非道德优胜者、零说教；陪伴非帮助；放手是「因爱放手」不是赶。

---

## 架构约定

- **数据驱动**：每一夜内容是一个 `godot/content/night_X.json`；引擎（`Main.gd` + autoload）按 `CONTENT_SCHEMA.md` 契约渲染。
- **5 个 Autoload 单例**：`SaveManager`（存档）/ `AudioManager`（白噪音·占位）/ `PlatformService`（平台）/ `ContentLoader`（加载 JSON）/ `ProgressState`（跨夜进度：clues / memories / hookChosenLine / revealSeen 携带）。
- **界面分区（锈湖式）**：中间 `StageArea`（场景描述 + 可点热点 + 动作 + 线索/记忆）与底部 `DialogueBox`（管理员肖像 + 台词）严格分离；美术期把这两块替换为场景底图 / 带肖像对话框即可，节点路径不变。
- **零改引擎纪律**：加一夜、加一个区域、加一个热点都不需要改 `Main.gd` 逻辑，只改 / 加 JSON 与 `NIGHT_ORDER`。

---

## 协作（GitHub Desktop）

- 远程已配好 `origin` → `https://github.com/245269946-blip/Return-by-Dawn.git`，默认分支 `main`。
- 本机改完 → **Commit to main** → **Push origin** 即可。提交信息写清「改了哪一夜 / 修了什么 bug / 点测几/几」。
- 本仓库**不含**上层 `.workbuddy` 隐私目录；请勿把个人目录、`.godot/` 缓存、日志与生成式测试产物（`*_out.txt` 等，已在 `.gitignore` 排除）提交进来。

---

## 已知缺口（留给后续里程碑）

- 真实美术 / 音频未接入（当前为 ColorRect 占位 + 雨声占位）。
- Web 存档为 IndexedDB，易丢；真实进度以 Windows 端为准。
- headless 测试场景退出时有 CanvasItem / ObjectDB 泄漏告警（测试场景卸载产物，**非游戏内容缺陷**，`Main.tscn` 下不触发）。

---

## 历史存档

> ⚠️ 以下**全是历史稿 / 废弃原型，不是当前依据**。保留只为追溯「设计是怎么演进来的」。现在该怎么写，永远以顶部目录里的确认文件为准。

<details>
<summary>📦 点开查看历史存档（5 类主题 + 废弃原型，共 23 份）</summary>

**叙事稿旧版本** · [`archive/story-drafts/`](archive/story-drafts/)
> `story-draft-v1~v5.md` + `story-draft-v4-筛查.md`（6 份），已被 **v6** 取代。

**早期设计稿（按主题归类）** · [`archive/design-notes/`](archive/design-notes/)

| 主题 | 内容 |
|------|------|
| [`00-框架与骨架/`](archive/design-notes/00-框架与骨架/) | 框架地基 v1/v2、项目骨架方案、引擎小结、Godot 评审、设计规格（6 份） |
| [`01-逃避引擎与主题/`](archive/design-notes/01-逃避引擎与主题/) | 逃避引擎整合、沉浸与连续性（2 份） |
| [`02-认知冲击与结局/`](archive/design-notes/02-认知冲击与结局/) | 认知冲击密度 v1/v2、BE 结局冲击（3 份） |
| [`03-夜A专题/`](archive/design-notes/03-夜A专题/) | 夜A 地基、夜A 框架 v1/v2（3 份） |
| [`04-道具与灵感/`](archive/design-notes/04-道具与灵感/) | 道具清单、灵感与断裂原型（2 份） |

**废弃原型** · [`archive/prototypes/`](archive/prototypes/)
> `demo/`（Godot 之前的 HTML/JS 网页原型）+ `skeleton/`（更早的 engine.js 骨架原型），均已被 Godot 线取代。

**里程碑参考文档（当参考读，别当现状）**
> [`godot/README_M0.md`](godot/README_M0.md)（Godot 线早期里程碑说明）· [`godot/NIGHT_A_VERIFY.md`](godot/NIGHT_A_VERIFY.md)（夜 A 点测范式与验证记录）

</details>

---

> 💡 **一句话上手**：装 Godot 4.7（Compatibility）→ 打开 `godot/` 目录 → F5 从序章玩到终章；改完跑 `python tools/spine_check.py` + `godot --headless --path . res://test_harness.tscn` 确认全绿。
