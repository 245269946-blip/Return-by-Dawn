# 📑 仓库目录 · REPO_GUIDE

> 本文件是仓库的**导航目录**：点任意链接直接跳到对应文件。
> 想区分「哪些是现在生效的、哪些是历史」→ 看下面的【速判表】；想翻具体某份旧稿 → 直接点【历史存档】里的链接。
> 想完整上手（装 Godot / 运行 / 加一夜 / 跑测试）→ 看 [`README.md`](README.md)。

---

## 🔗 目录（点击跳转到对应章节）
- [一、30 秒速判表](#一30-秒速判表)
- [二、确认内容（现在生效，照这个写）](#二确认内容现在生效照这个写)
- [三、历史存档（只读参考，别当依据）](#三历史存档只读参考别当依据)
  - [3.1 叙事稿旧版本](#31-叙事稿旧版本-archivestory-drafts)
  - [3.2 早期设计稿（按主题归类）](#32-早期设计稿按主题归类-archivedesign-notes)
  - [3.3 废弃原型](#33-废弃原型-archiveprototypes)
- [四、两份 Godot 里程碑参考文档](#四两份-godot-里程碑参考文档)
- [五、生成产物（不入库）](#五生成产物不入库)

---

## 一、30 秒速判表

| 你想做什么 | 直接点这里 |
|-----------|-----------|
| 把游戏跑起来 / 装 Godot / F5 | [`README.md`](README.md) 第一节 |
| 改剧情、加一夜、写 JSON | [`story-draft-v6.md`](story-draft-v6.md)（叙事事实源）+ [`godot/CONTENT_SCHEMA.md`](godot/CONTENT_SCHEMA.md)（数据契约）|
| 改完怎么测 | [`godot/TEST_FLOW.md`](godot/TEST_FLOW.md) |
| 终章三态结局设计依据 | [`ending-three-tier-design-20260716.md`](ending-three-tier-design-20260716.md) |
| 看玩家试玩评测报告 | [`godot/playtest_report.md`](godot/playtest_report.md) |
| 想翻旧设计怎么演进来的 | 直接点下面【历史存档】里的链接 |

**一句话铁律**：叙事事实只认 [`story-draft-v6.md`](story-draft-v6.md)；数据字段只认 [`godot/CONTENT_SCHEMA.md`](godot/CONTENT_SCHEMA.md)。`archive/` 里的任何文件都**不能**作为「现在该怎么写」的依据。

---

## 二、确认内容（现在生效，照这个写）

| 路径 | 是什么 | 定位 |
|------|--------|------|
| [`README.md`](README.md) | 项目总说明 / 运行 / 测试 / 加一夜 / 架构 / 红线 | **总入口** |
| [`story-draft-v6.md`](story-draft-v6.md) | 19 条不可动摇原则 + 各夜框架 + 自认机制 | **叙事圣经·唯一事实源** |
| [`ending-three-tier-design-20260716.md`](ending-three-tier-design-20260716.md) | 终章三态谱系（逃避 / 抹去 / 面对）设计 | v6 的终章补充，仍生效 |
| [`godot/`](godot/) | 正在跑的 Godot 4.7 工程（引擎 + 11 段内容 + 测试） | **生产线** |

### `godot/` 里的关键件（直接点链接）

| 路径 | 是什么 |
|------|--------|
| [`godot/project.godot`](godot/project.godot) · [`godot/Main.tscn`](godot/Main.tscn) · [`godot/Main.gd`](godot/Main.gd) | 工程配置 + 主场景 + 引擎逻辑（F5 即玩） |
| [`godot/content/`](godot/content/) | ★ 全部夜内容（prologue + night_a…i + night_z），**加一夜只动这里** |
| [`godot/autoload/`](godot/autoload/) | 单例：Save / Audio / Platform / Content / Progress |
| [`godot/CONTENT_SCHEMA.md`](godot/CONTENT_SCHEMA.md) | ★ 内容数据契约（写/改 JSON 前必读） |
| [`godot/TEST_FLOW.md`](godot/TEST_FLOW.md) | ★ 自测 runbook（点测 + 玩家试玩命令与断言清单） |
| [`godot/playtest_report.md`](godot/playtest_report.md) | 玩家向全流程试玩四维评测报告 |
| [`godot/test_harness.tscn`](godot/test_harness.tscn) · [`godot/test_harness.gd`](godot/test_harness.gd) | 自动化点测入口（序章→终章全块断言） |
| [`godot/playtest_dump.tscn`](godot/playtest_dump.tscn) · [`godot/playtest_dump.gd`](godot/playtest_dump.gd) | 玩家向试玩 dump（逐夜输出玩家读到的文本） |
| [`godot/tools/spine_check.py`](godot/tools/spine_check.py) | 脊柱泄漏护栏（防提前点破「其实是你」） |
| [`godot/tools/pacing_estimate.py`](godot/tools/pacing_estimate.py) | 单夜时长估算 |
| [`godot/GODOT_VERSION`](godot/GODOT_VERSION) | 锁定的 Godot 版本 |

---

## 三、历史存档（只读参考，别当依据）

> 这些是项目演进过程中的旧稿 / 废弃原型。**保留是为了追溯「为什么这样设计」，不是给你照着写的。** 当前该怎么写，永远以上面【二、确认内容】为准。

### 3.1 叙事稿旧版本 · [`archive/story-drafts/`](archive/story-drafts/)

> 叙事稿旧版本，已被 **v6** 取代。看叙事演进点这里。

| 链接 | 说明 |
|------|------|
| [`story-draft-v1.md`](archive/story-drafts/story-draft-v1.md) | 最早的叙事框架初稿 |
| [`story-draft-v2.md`](archive/story-drafts/story-draft-v2.md) | 第二版 |
| [`story-draft-v3.md`](archive/story-drafts/story-draft-v3.md) | 第三版 |
| [`story-draft-v4.md`](archive/story-drafts/story-draft-v4.md) | 第四版 |
| [`story-draft-v4-筛查.md`](archive/story-drafts/story-draft-v4-筛查.md) | v4 阶段的筛查记录 |
| [`story-draft-v5.md`](archive/story-drafts/story-draft-v5.md) | 第五版（v6 前身） |

### 3.2 早期设计稿（按主题归类） · [`archive/design-notes/`](archive/design-notes/)

> 16 份早期中文设计稿，结论已吸收进 v6 与 `godot/`。按主题分了 5 类，找同类直接点。

#### 📁 框架与骨架 · [`00-框架与骨架/`](archive/design-notes/00-框架与骨架/)
| 链接 | 说明 |
|------|------|
| [`框架地基设计-v1.md`](archive/design-notes/00-框架与骨架/框架地基设计-v1.md) | 内容框架地基第一版 |
| [`框架地基设计-v2.md`](archive/design-notes/00-框架与骨架/框架地基设计-v2.md) | 内容框架地基第二版 |
| [`项目骨架与框架落地方案.md`](archive/design-notes/00-框架与骨架/项目骨架与框架落地方案.md) | 项目整体骨架落地方案 |
| [`引擎地基落地小结.md`](archive/design-notes/00-框架与骨架/引擎地基落地小结.md) | 引擎地基落地小结 |
| [`技术方向_Godot评审.md`](archive/design-notes/00-框架与骨架/技术方向_Godot评审.md) | 选用 Godot 的技术评审 |
| [`设计规格.md`](archive/design-notes/00-框架与骨架/设计规格.md) | 早期设计规格 |

#### 📁 逃避引擎与主题 · [`01-逃避引擎与主题/`](archive/design-notes/01-逃避引擎与主题/)
| 链接 | 说明 |
|------|------|
| [`主题整合-逃避引擎.md`](archive/design-notes/01-逃避引擎与主题/主题整合-逃避引擎.md) | 「逃避引擎」核心机制整合 |
| [`沉浸与连续性设计.md`](archive/design-notes/01-逃避引擎与主题/沉浸与连续性设计.md) | 沉浸感与跨夜连续性设计 |

#### 📁 认知冲击与结局 · [`02-认知冲击与结局/`](archive/design-notes/02-认知冲击与结局/)
| 链接 | 说明 |
|------|------|
| [`认知冲击密度设计.md`](archive/design-notes/02-认知冲击与结局/认知冲击密度设计.md) | 认知冲击密度设计（第一版） |
| [`认知冲击密度设计-v2.md`](archive/design-notes/02-认知冲击与结局/认知冲击密度设计-v2.md) | 认知冲击密度设计（第二版） |
| [`BE结局实感冲击设计.md`](archive/design-notes/02-认知冲击与结局/BE结局实感冲击设计.md) | BE 结局实感冲击设计 |

#### 📁 夜 A 专题 · [`03-夜A专题/`](archive/design-notes/03-夜A专题/)
| 链接 | 说明 |
|------|------|
| [`夜A叙事地基梳理.md`](archive/design-notes/03-夜A专题/夜A叙事地基梳理.md) | 夜 A 叙事地基梳理 |
| [`夜A框架v1.md`](archive/design-notes/03-夜A专题/夜A框架v1.md) | 夜 A 框架第一版 |
| [`夜A框架v2.md`](archive/design-notes/03-夜A专题/夜A框架v2.md) | 夜 A 框架第二版 |

#### 📁 道具与灵感 · [`04-道具与灵感/`](archive/design-notes/04-道具与灵感/)
| 链接 | 说明 |
|------|------|
| [`道具落地清单.md`](archive/design-notes/04-道具与灵感/道具落地清单.md) | 道具落地清单 |
| [`灵感参考与断裂原型.md`](archive/design-notes/04-道具与灵感/灵感参考与断裂原型.md) | 灵感参考与断裂原型记录 |

### 3.3 废弃原型 · [`archive/prototypes/`](archive/prototypes/)

> Godot 之前的验证性原型，已被 Godot 线取代，仅存历史。

| 链接 | 说明 |
|------|------|
| [`prototypes/demo/`](archive/prototypes/demo/) | Godot 之前的 HTML/JS 网页原型（夜 A 可跑 demo） |
| [`prototypes/skeleton/`](archive/prototypes/skeleton/) | 更早的引擎骨架原型（engine.js + 单夜数据） |

---

## 四、两份 Godot 里程碑参考文档

> `godot/README_M0.md`、`godot/NIGHT_A_VERIFY.md` 属**早期里程碑文档**：运行/导出细节与夜 A 点测范式仍可参考，但状态描述（「M0.5」「三件套」）已被当前进度覆盖——当参考读，别当现状读。

| 链接 | 说明 |
|------|------|
| [`godot/README_M0.md`](godot/README_M0.md) | Godot 线早期里程碑说明（M0 阶段） |
| [`godot/NIGHT_A_VERIFY.md`](godot/NIGHT_A_VERIFY.md) | 夜 A 点测范式与验证记录 |

---

## 五、生成产物（不入库）

`.gitignore` 已排除本地重跑即可再生的产物，不应提交：
`*_out.txt`（harness / playtest / test 输出）、`spine_out.txt`、`_spine_baseline.txt`、`.godot/` 缓存、`*.log`。
若发现它们被误跟踪，用 `git rm --cached <file>` 移出即可。

---

## 仓库结构速览

```
Return-by-Dawn/
├── README.md                         ✅ 怎么用（总入口）
├── REPO_GUIDE.md                     ✅ 本文件（导航目录·带跳转）
├── story-draft-v6.md                 ✅ 叙事唯一事实源
├── ending-three-tier-design-…16.md  ✅ 终章设计（生效）
├── godot/                            ✅ 生产线（引擎 + 内容 + 测试）
└── archive/                         📦 历史存档（只读，非依据）
    ├── story-drafts/                v1~v5 + 筛查（6 份）
    ├── design-notes/                16 份早期设计稿，按 5 主题归类
    │   ├── 00-框架与骨架/           框架/骨架/引擎/技术评审/规格（6）
    │   ├── 01-逃避引擎与主题/       逃避引擎/沉浸连续性（2）
    │   ├── 02-认知冲击与结局/       认知冲击 v1/v2 / BE 冲击（3）
    │   ├── 03-夜A专题/             夜A 地基/框架 v1/v2（3）
    │   └── 04-道具与灵感/          道具清单/灵感原型（2）
    └── prototypes/                  demo/(网页原型) + skeleton/(旧骨架)
```
