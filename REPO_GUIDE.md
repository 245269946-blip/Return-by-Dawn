# 仓库导览 · REPO_GUIDE

> 一页看清这个仓库：**怎么用 / 哪些是确认内容（唯一事实源）/ 哪些是历史存档（只作参考、别当依据）**。
> 想直接上手运行 / 加一夜 / 跑测试 —— 看 **`README.md`**。本文件只负责「分清文件性质」。

---

## 30 秒速判

| 你想做什么 | 看哪个 |
|-----------|--------|
| 把游戏跑起来 / 装 Godot / F5 | `README.md` 第一节 |
| 改剧情、加一夜、写 JSON | `story-draft-v6.md`（叙事事实源）+ `godot/CONTENT_SCHEMA.md`（数据契约）|
| 改完怎么测 | `godot/TEST_FLOW.md` |
| 终章三态结局设计依据 | `ending-three-tier-design-20260716.md` |
| 想翻旧设计怎么演进来的 | `archive/`（**只读历史，不是当前依据**）|

**一句话铁律**：叙事事实只认 `story-draft-v6.md`；数据字段只认 `godot/CONTENT_SCHEMA.md`。`archive/` 里的任何文件都**不能**作为「现在该怎么写」的依据。

---

## ✅ 确认 · 当前（唯一事实源，动手前看这些）

| 路径 | 是什么 | 定位 |
|------|--------|------|
| `README.md` | 项目总说明 / 运行 / 测试 / 加一夜 / 架构 / 红线 | **总入口** |
| `story-draft-v6.md` | 19 条不可动摇原则 + 各夜框架 + 自认机制 | **叙事圣经·唯一事实源** |
| `ending-three-tier-design-20260716.md` | 终章三态谱系（逃避 / 抹去 / 面对）设计 | v6 的终章补充，仍生效 |
| `godot/` | 正在跑的 Godot 4.7 工程（引擎 + 11 段内容 + 测试） | **生产线** |

### `godot/` 里的关键件

| 路径 | 是什么 |
|------|--------|
| `godot/project.godot` `Main.tscn` `Main.gd` | 工程配置 + 主场景 + 引擎逻辑（F5 即玩） |
| `godot/content/*.json` | ★ 全部夜内容（prologue + night_a…i + night_z），**加一夜只动这里** |
| `godot/autoload/*.gd` | 5 个单例：Save / Audio / Platform / Content / Progress |
| `godot/CONTENT_SCHEMA.md` | ★ 内容数据契约（写/改 JSON 前必读） |
| `godot/TEST_FLOW.md` | ★ 自测 runbook（点测 + 玩家试玩命令与断言清单） |
| `godot/playtest_report.md` | 玩家向全流程试玩四维评测报告 |
| `godot/test_harness.tscn/.gd` | 自动化点测入口（序章→终章全块断言） |
| `godot/playtest_dump.tscn/.gd` | 玩家向试玩 dump（逐夜输出玩家读到的文本） |
| `godot/tools/spine_check.py` | 脊柱泄漏护栏（防提前点破「其实是你」） |
| `godot/tools/pacing_estimate.py` | 单夜时长估算 |
| `godot/GODOT_VERSION` | 锁定的 Godot 版本 |
| `godot/art/` | 待用美术素材（未接入引擎） |

> `godot/README_M0.md`、`godot/NIGHT_A_VERIFY.md` 属**早期里程碑文档**：运行/导出细节与夜 A 点测范式仍可参考，但状态描述（「M0.5」「三件套」）已被当前进度覆盖——当参考读，别当现状读。

---

## 📦 历史 · 存档（`archive/`，只读参考）

> 这些是项目演进过程中的旧稿 / 废弃原型。**保留是为了追溯「为什么这样设计」，不是给你照着写的。** 当前该怎么写，永远以上面「✅ 确认」区为准。

| 路径 | 是什么 | 为什么进存档 |
|------|--------|-------------|
| `archive/story-drafts/` | `story-draft-v1~v5.md` + `story-draft-v4-筛查.md`（6 份） | 叙事稿旧版本，已被 **v6** 取代 |
| `archive/design-notes/` | 16 份早期中文设计稿（框架 v1/v2、认知冲击 v1/v2、夜A框架 v1/v2、逃避引擎、BE 冲击、道具清单…） | 早期设计思考，结论已吸收进 v6 与 `godot/` |
| `archive/prototypes/demo/` | Godot 之前的 HTML/JS 网页原型（夜 A 可跑 demo） | 技术选型阶段的验证，已被 Godot 线取代 |
| `archive/prototypes/skeleton/` | 更早的引擎骨架原型（engine.js + 单夜数据） | 同上，仅存历史 |

---

## 🔧 生成产物（不入库）

`.gitignore` 已排除本地重跑即可再生的产物，不应提交：
`*_out.txt`（harness / playtest / test 输出）、`spine_out.txt`、`_spine_baseline.txt`、`.godot/` 缓存、`*.log`。
若发现它们被误跟踪，用 `git rm --cached <file>` 移出即可。

---

## 分类图示

```
Return-by-Dawn/
├── README.md                          ✅ 怎么用（总入口）
├── REPO_GUIDE.md                      ✅ 本文件（怎么分清文件）
├── story-draft-v6.md                  ✅ 叙事唯一事实源
├── ending-three-tier-design-…16.md   ✅ 终章设计（生效）
├── godot/                             ✅ 生产线（引擎 + 内容 + 测试）
└── archive/                          📦 历史存档（只读，非依据）
    ├── story-drafts/     v1~v5 + 筛查
    ├── design-notes/     16 份早期设计稿
    └── prototypes/       demo/(网页原型) + skeleton/(旧骨架)
```
