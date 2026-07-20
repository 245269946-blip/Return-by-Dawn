// ⚠️ 弃用文件（2026-07-10）
// 本文件是「demo 自行漂移」时期的旧内容逻辑（night.act / checkPuzzle / regionMapActions），
// 已被薄壳化废弃。
//
// 现在架构（见 skeleton/SCHEMA.md）：
//   - 唯一内容事实源 = godot/content/night_a.json（Godot 与 网页壳 共读）
//   - demo/engine.js 是薄壳，只读 night_a.json，不背任何内容逻辑
//   - index.html 通过 fetch('../godot/content/night_a.json') 加载同一份地基
//
// 不要再修改本文件。加一夜 = 加 godot/content/night_x.json + 薄壳加载器，零改引擎。
