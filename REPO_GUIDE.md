# REPO_GUIDE（纯文本镜像）

> ⚠️ **本仓库的可视化导航目录已整合进 [`README.md`](README.md)（仓库首页）。**
> README 即是「可点击目录卡 + 下方说明」的入口页，**看那个就行**。
> 本文件仅保留为**纯文本镜像**，方便复制 / 搜索 / 不支持 HTML 渲染的场景使用。

---

## 确认内容（现在生效，照这个写）

| 用途 | 文件 |
|------|------|
| 怎么用（总入口 · 可视化目录） | [`README.md`](README.md) |
| 叙事圣经 · 唯一事实源 | [`story-draft-v6.md`](story-draft-v6.md) |
| 终章三态结局设计（v6 补充，生效） | [`ending-three-tier-design-20260716.md`](ending-three-tier-design-20260716.md) |
| 生产线（引擎 + 内容 + 测试） | [`godot/`](godot/) |
| 内容数据契约（写 JSON 前必读） | [`godot/CONTENT_SCHEMA.md`](godot/CONTENT_SCHEMA.md) |
| 自测 runbook（三套测试命令） | [`godot/TEST_FLOW.md`](godot/TEST_FLOW.md) |
| 玩家向试玩四维评测 | [`godot/playtest_report.md`](godot/playtest_report.md) |
| 引擎逻辑（F5 即玩） | [`godot/Main.gd`](godot/Main.gd) · [`godot/project.godot`](godot/project.godot) |
| 全部夜内容 JSON（加一夜只动这里） | [`godot/content/`](godot/content/) |
| 脊柱泄漏护栏 | [`godot/tools/spine_check.py`](godot/tools/spine_check.py) |

**铁律**：叙事事实只认 `story-draft-v6.md`；数据字段只认 `godot/CONTENT_SCHEMA.md`。

## 历史存档（只读，非依据）

- 叙事稿旧版本： [`archive/story-drafts/`](archive/story-drafts/)
- 早期设计稿（5 主题归类）： [`archive/design-notes/`](archive/design-notes/)
  - `00-框架与骨架/` · `01-逃避引擎与主题/` · `02-认知冲击与结局/` · `03-夜A专题/` · `04-道具与灵感/`
- 废弃原型： [`archive/prototypes/`](archive/prototypes/)（`demo/` + `skeleton/`）
- 里程碑参考（当参考读）： [`godot/README_M0.md`](godot/README_M0.md) · [`godot/NIGHT_A_VERIFY.md`](godot/NIGHT_A_VERIFY.md)
