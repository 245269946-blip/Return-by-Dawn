# 逾期之书 / The Overdue Book

> 一座深夜还亮着灯的图书馆，和一群逾期最久、迟迟没被归还的书。
> 互动叙事 / 文字冒险游戏，Godot 4.7 制作，视觉走「亚洲城市夜生活 × 便利店灯光」的克制安静美学。

---

## 这是什么

- **类型**：互动叙事 / 点击探索（锈湖式节点推进 + 克制夜景 + 白噪音层）。
- **核心**：一个人遗落的人生的故事。表层是把送错的通知、逾期书籍「还回去」，里层慢慢收束到读者自己。
- **当前阶段**：**夜 A（第一夜《夹在书里的信》）已完整可玩**；自动化点测 **55/0 全绿**。
- **发行规划**：Windows 独立主机优先，Web/HTML5 双端，TapTap 主发行；国内免费 + 海外买断双轨。

---

## 当前进度（截至 2026-07-14）

| 模块 | 状态 |
|------|------|
| Godot 工程骨架（点击探索 / 区域切换 / 管理员对话三件套） | ✅ 完成 |
| 夜 A 全流程（进门 → 探索 → 知被遗忘 → 投信抉择 → 出馆） | ✅ 可玩 |
| 内容数据契约 `CONTENT_SCHEMA.md` | ✅ 落地 |
| headless 自动化点测 | ✅ 55 PASS / 0 FAIL |
| 真实美术 / 音频资产 | ⬜ 未接入（ColorRect 占位 + 雨声占位） |
| 夜 B / 夜 C / 终章 | ⬜ 待推进 |

---

## 仓库结构（精简）

```
Return-by-Dawn/                     ← 仓库根（对应本机 overdue-book/）
├── godot/                          ← ★ Godot 工程（用 Godot 打开这个目录）
│   ├── project.godot               ← 工程配置：主场景 Main.tscn / Compatibility 渲染 / 5 个 Autoload
│   ├── Main.tscn / Main.gd         ← 主场景 + 逻辑（F5 即玩夜 A）
│   ├── content/
│   │   └── night_a.json            ← 夜 A 全量内容数据（加一夜只改/加这个 JSON）
│   ├── autoload/                   ← SaveManager / AudioManager / PlatformService / ContentLoader / ProgressState
│   ├── test_harness.tscn / .gd     ← 自动化点测入口
│   ├── CONTENT_SCHEMA.md           ← 内容数据契约（写/改 JSON 前必读）
│   ├── NIGHT_A_VERIFY.md           ← 夜 A 验收清单
│   ├── GODOT_VERSION               ← 锁定的 Godot 版本（见下）
│   ├── README_M0.md                ← 引擎层脚手架说明（更细）
│   └── art/ tools/                 ← 待用美术 / 导出脚本
├── story-draft-v6.md               ← ★ 叙事圣经（19 条不可动摇原则 + 各夜框架）
├── 夜A框架v1.md 夜A叙事地基梳理.md  …  ← 设计讨论稿与框架文档
└── demo/                           ← 早期 Web 骨架（非 Godot 主线，参考用）
```

> ⚠️ **叙事事实的唯一来源是 `story-draft-v6.md`**。动任何夜内容 / 框架前，必须先读它的第 12–35 行（19 条原则，含脊柱原则 1）与对应夜框架。

---

## 在另一台电脑上跑起来

### 1. 克隆仓库

用 **GitHub Desktop**（你已登录）：File → Clone repository → 选 `245269946-blip/Return-by-Dawn` → Clone。
或用命令行：

```bash
git clone https://github.com/245269946-blip/Return-by-Dawn.git
```

克隆下来的根目录 `Return-by-Dawn/` 即本仓库。

### 2. 安装 Godot

- 安装 **Godot 4.7-stable（或开发启动时最新的 Stable 4.x）**。
- 版本锁定依据见仓库内 `godot/GODOT_VERSION`：**保持 Compatibility Renderer（gl_compatibility）**，不要切到 Forward+，否则移动端 / 低配机可能跑不起来。
- 不需要额外插件；纯 GDScript。

### 3. 打开工程

用 Godot 打开 **`Return-by-Dawn/godot/`** 这个目录（即包含 `project.godot` 的那一层），不是仓库根。
首次打开会重新导入（`.godot/` 缓存已被 git 忽略，正常，稍等片刻即可）。

> 若编辑器提示 `config/features` 版本不符，点「升级 / Keep」即可，不影响内容。

### 4. 运行

- **手动玩夜 A**：直接按 **F5**（主场景已设为 `Main.tscn`）→ 进入「借阅台」区域，点热点探索、看底部管理员反应、走投信抉择、出馆。
- **自动化点测（headless，推荐每次改动后跑）**：在 `godot/` 目录下执行
  ```bash
  godot --headless --path . res://test_harness.tscn
  ```
  会按 `NIGHT_A_VERIFY.md` 清单逐条驱动并断言，输出 PASS/FAIL 汇总（同时写 `test_out.txt` / `test_err.txt`）；**全 PASS 退出码 0，任一 FAIL 退出码 1**。
  - ⚠️ 必须显式传 `res://test_harness.tscn`：裸跑 `godot --headless --path .` 会启动游戏而非跑测试。
  - ⚠️ 旧的 `tools/headless_test.gd --script` 路径已废弃（Autoload 不在 `--script` 作用域内）。

---

## 内容 / 架构约定

- **内容即数据**：每一夜的内容是 `godot/content/night_a.json` 这样一个 JSON。加一夜内容 = 写一个新的 `night_a.json` 风格文件并在 `Main.NIGHT_ORDER` 注册，**引擎零改动**。
- **数据契约**：写 / 改 JSON 前读 `godot/CONTENT_SCHEMA.md`；节点 `notice/enter/reveal/exit` 全部收在 `content["nodes"]` 下（曾因读错顶层 `content["reveal"]` 出过真 bug）。
- **引擎三件套**：点击探索 / 区域切换 / 管理员对话。Autoload 单例提供存档、音频、平台服务、内容加载、跨夜进度。
- **红线（必须遵守）**：夜 A / B / C **绝不点破「其实是你」**；自认只发生在夜 D 闸门，且由玩家自己合拢（拼图合拢，不是被告知）。任何一夜出现「这好像是我 / 你就是本人」式句子 = 违规打回。

---

## 用 GitHub Desktop 协作

- 远程已配好 `origin` → `https://github.com/245269946-blip/Return-by-Dawn.git`，默认分支 `main`。
- 你在本机改完 → GitHub Desktop 里 **Commit to main** → **Push origin** 即可。
- 提交信息建议写清「改了哪一夜 / 修了什么 bug / 点测几/几」。
- 本仓库**不含**上层 `.workbuddy` 隐私目录；请勿把个人目录、`.godot/` 缓存、`*.log` 提交进来（已在 `.gitignore` 排除）。

---

## 已知缺口（留给后续里程碑）

- 真实美术 / 音频未接入（当前为 ColorRect 占位 + 雨声占位）。
- Web 存档为 IndexedDB，易丢；真实进度以 Windows 端为准。
- 跨夜记忆（管理员羁绊机制 1+2+4+6）目前尚无存放位，留 M1。
- 夜 B / 夜 C / 终章 / 夜 D 闸门尚未落地。

---

## 一句话上手

> 装 Godot 4.7（Compatibility）→ 打开 `godot/` 目录 → F5 玩夜 A；改完跑一遍 `godot --headless --path . res://test_harness.tscn` 确认 55/0。
