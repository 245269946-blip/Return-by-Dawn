# 《逾期之书》M0 引擎 Spike 脚手架

## 状态
- **本机已安装 Godot 4.7-stable**（路径见 MEMORY），工程可直接 F5 运行 / headless 校验。
- 引擎已从 M0 三件套升级到 **M0.5**：`hook`（便签三选一）/ `reveal`（双 clue 门控）/ `ending`（三分支）均已实装，非占位。
- 已落定：Android 加入目标（主线 Windows 独立主机优先，Android 后期移植）；内容用 JSON；
  双轨发行（国内免费 + 海外买断，不等版号）；Godot 锁最新 Stable 4.x（4.7 仅为稳定性）。

## 目录
- `project.godot` — 工程配置（Compatibility 渲染 + 4 个 Autoload 单例 + 主场景）
- `autoload/` — SaveManager / AudioManager / PlatformService / ContentLoader
- `content/night_a.json` — 夜 A 全量数据（由 skeleton/night_a.js 忠实搬运）
- `Main.tscn` / `Main.gd` — M0 测试场景
- `tools/gen_content.py` — 内容生成（重跑以刷新 night_a.json）
- `tools/validate_content.js` — 内容自洽校验
- `tools/export.ps1` — Windows + Web 双端导出

## 本地运行
1. 已装好 Godot 4.7-stable，直接用导入本目录 `project.godot`（或双击工程目录）。
2. 按 F5 运行；应能看到「借阅台」区域、若干可点热点、底部管理员反应、出口按钮可切换区域、
   点「保存进度」写 user://。
3. 若编辑器提示 `config/features` 版本不符，点「升级」即可（不影响内容）。
4. **两种运行入口（当前 `run/main_scene = Main.tscn`）**：
   - **F5 直接玩夜 A**：按 F5（或 `godot --path .` 不带场景参数）即启动 `Main.tscn`，进入「借阅台」区域、可点热点、
     底部管理员反应、出口切换区域、点「保存进度」写 `user://`。这是你手动点测夜 A 的入口。
   - **自动化点测（headless）**：在 `godot/` 目录下执行
     `godot --headless --path . res://test_harness.tscn`
     会实例化 `Main.tscn`、按 `NIGHT_A_VERIFY.md` 清单逐条驱动并断言，输出 PASS/FAIL 汇总（同时写 `test_out.txt`/`test_err.txt`）；
     全部 PASS 退出码 0，任一 FAIL 退出码 1（详见 `test_harness.gd` 头注释）。务必带 `--path .`，否则读不到工程与 `res://`。
     ⚠️ **必须显式传 `res://test_harness.tscn`**：主场景现在是 `Main.tscn`，裸跑 `godot --headless --path .` 会启动游戏而非跑测试。
   - ⚠️ 旧的 `tools/headless_test.gd --script` 路径**已废弃**：Autoload 单例（`SaveManager` 等）不在 `--script` 场景树作用域内，
     会报 `Identifier not found: SaveManager`；请以 `test_harness.tscn` 主场景路径为准。

## 导出双端
- 编辑器内：Project → Export → Add → Windows Desktop / Web，各导出一次
  （生成 export_presets.cfg 后 `godot --headless --export-release` 即可自动化）。
- 或运行 `powershell -ExecutionPolicy Bypass -File tools/export.ps1`
  （先把脚本里的 `$godot` 改成你的 Godot 可执行文件路径）。

## 已知缺口（留给后续里程碑）
- 真实美术 / 音频未接入（ColorRect 占位 + 雨声占位）。
- Web 存档为 IndexedDB，易丢；真实进度以 Windows 为准。
- 存档恢复目前只回写 `region`+`clues`（及 `visitedHot`/`examined`/`hookChosenLine`/`endingText`），
  回进时热点重新渲染、clue 数保留；完整"恢复阅读状态"留 M1 装载流程。
