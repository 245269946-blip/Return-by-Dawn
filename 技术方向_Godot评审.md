# 《逾期之书》技术方向评审（Godot 4.7 双端 / TapTap 主发行）

> 评审基线：用户 2026-07-10 提出生产载体从「网页 JS demo」改为 **Godot 4.7（仅 GDScript + Compatibility Renderer）**，目标 **Windows + Web/HTML5** 双端，**TapTap 为主发行平台**。
> 本文只做方向评审与补充，不推翻已锁的美学/机制事实。

---

## 0. 总体判断

方向成立，且与已确认的美学/机制**不冲突**。需要补的是三处**必须先定的关键决策**（平台错位、内容数据格式、存档脆弱性）和若干工程细则。下面分层给出。

---

## 1. 先澄清：这次 pivot 推翻了什么、没推翻什么

- **没推翻（仍锁死）**：锈湖式机制、克制夜景+便利店灯光调性、2D 固定场景点击探索、无自由移动角色、区域切换+物件点击+状态/对话推进、白噪音氛围层、管理员「在场不抢戏」纪律。
- **变了**：运行时栈从「网页 JS demo」改为 **Godot 4.7（仅 GDScript + Compatibility Renderer）**；载体从纯网页变成 **Windows + Web/HTML5 双端**；发行主平台 **TapTap**。
- **已有 JS 骨架（skeleton/engine v2 三系统）不是废稿**：它是 Godot 架构蓝图 + Web 传播/早期测试件。三系统在 Godot 里一一对应（见 §2）。

---

## 2. 现有 JS 骨架 → Godot 架构映射（证明不是推倒重来）

| JS 骨架 | Godot 对应 | 说明 |
|---|---|---|
| hotspot 层（物件只给一句话） | `Hotspot` Control / TextureButton + 数据 | 位置/文案/once-again 全从数据读 |
| region map（区域图+出口） | `RegionSwitcher` + `Region` 场景/资源 | 切换即换场景树，固定镜头 |
| companion 层（管理员常驻条） | `CuratorBar` UI 层（常驻 CanvasLayer） | 事件驱动，默认沉默 |
| night_a.js 数据 | `content/night_a.json`（或 .tres） | 直接搬运，结构 1:1 |
| 状态钩子（便签三选项） | `StateHook` + 物证形态数据 | 落 §3 程序化 |

---

## 3. 必须先定的三件事（关键决策）

### A. 目标平台与 TapTap 的错位（最重要）
- TapTap 的主场是 **Android 移动端 + PC 客户端**。当前目标是 Windows + Web，**没有 Android**。
- 一部「2D 固定场景点击」游戏，移植到触屏几乎零成本（点击→触摸，Godot 原生支持）。不补 Android = 主动放弃 TapTap 最大流量池。
- **建议**：要么明说「只做 Windows+Web、放弃移动端 TapTap 用户」（合法取舍），要么把 Android 加进目标（Godot 加 Android 导出很便宜，且「平台相关功能隔离」原则已留口子）。
- **待拍板：要不要 Android？**

### B. 内容数据格式（当前文档完全没写，但「全部数据化」是核心原则）
候选：
1. **JSON（推荐）**：人易读、diff 友好、能直接从 night_a.js 搬运、非程序员也能改；运行时读入 GDScript 类型包装。
2. **.tres 资源**：Godot 原生、类型安全、编辑器内可视化编辑；但改文案要开编辑器、不易 diff、不好外部分发。
3. **.gd 常量字典**：最差，改叙事要重编译、难协作。
- **强烈建议 JSON 作编写格式 + 启动时 schema 校验 + 运行时类型包装**。这样「§3 程序化」的状态钩子→物证形态也能纯数据表达。
- **待拍板：JSON 还是 .tres？（我推 JSON）**

### C. 存档与 Web 持久化脆弱性
- 跨夜累积（已还书目墙、常亮灯位、管理员引用前夜）是核心，必须有存档。
- PC 上 `user://` 是真实文件，稳。Web 上 `user://` 是 **IndexedDB**，浏览器清缓存/无痕模式会丢档——对「测试/传播」可接受，但**绝不能让 Web 成为唯一存档**。
- **建议**：存档 schema 带 `version` 字段（内容更新不破坏旧档）；Web 端加「导出/导入存档码」兜底；真实进度以 Windows 为准。内容数据（night/region）与玩家存档（save）必须**物理分离**两个目录。

---

## 4. 工程原则细化（补进原文档）

- **「不使用多线程」** 明确为「不使用自定义 Thread / BackgroundTask」，允许引擎托管的 `load_threaded_request`；Web 导出若不用线程，在导出项关掉线程支持以避免 COOP/COEP 头依赖。
- **平台隔离落地方式**：用 Autoload 单例做隔离层——`SaveManager` / `AudioManager` / `PlatformService` / `ContentLoader`，平台分支只在单例内部。新建 `platform/` 目录放平台相关实现，按运行平台选择。
- **导出自动化**：用 `godot --headless --export-release "Windows" ./build/win/...` 和 `"Web" ./build/web/...` 写脚本/CI，确保「每里程碑验双端」是强制而非口头。早期 Web 导出可只做冒烟（能加载、能点），不必每里程碑全量。
- **分辨率与美术管线**：定一个设计分辨率（建议 1920×1080）+ viewport stretch。固定场景 = 背景美术 PNG + 透明热点叠层（TextureButton/Control，`mouse_filter`）。Compatibility 下大单图注意尺寸（建议 ≤2048 或打 atlas）。
- **Web 音频手势门**：雨声白噪音必须在首次点击后启动（浏览器自动播放限制）。`AudioManager` 监听首次 `gui_input` 再 `resume()`。
- **Compatibility 渲染取舍**：无 Vulkan，部分 2D 后期（WorldEnvironment 的 glow/bloom）不可用；但「克制夜景」本就不需要炫光，**反而更干净**。若以后想做微光/雾，用 CanvasItem shader（Compatibility 支持）。
- **Godot 4.7**：以项目启动时「最新 Stable」为准；若 4.7 当时未发布，用最新 4.x 并避开 4.7-only API。

---

## 5. 发行相关（补进原文档）

- **TapTap 上架形态**：Windows 游戏走 TapTap **PC 客户端（电脑版）**分发；Web/HTML5 **不是 TapTap 商店渠道**，仅用于落地页/早期测试/传播（也可放 itch.io 或自建页）。
- **版号与评级**：若在国内 TapTap **付费/商业化**，依法需 **版号**（周期长，数月到年）。可走「免费首发 / 国际 TapTap / 抢先体验」规避或并行准备。**这是排期大项，现在就要定商业化路径。**
- **内容分级**：TapTap 需填内容评级（叙事/解谜/独立标签）。本作无敏感内容，评级轻松。

---

## 6. 内容管线（落 §3 程序化）

- **数据 schema 草图**（直接映射 night_a.js）：
  ```
  Night { id, regions: { id: Region }, start, reveal, ending }
  Region { id, name, metaphor, hotspots: { id: Hotspot }, exits: [regionId] }
  Hotspot {
    id, label, pos, size,
    once, again,                 # Florence 一句话
    curatorOnce, curatorAgain,   # 管理员反应
    unlocks: clueId | {id,text},
    hook?: { type, options:[{id,label,物证形态}] },
    ask?: { prompt, reply }
  }
  ```
- **内容校验工具**：复用现有 JS 原型当「内容预览器」，或写个 Godot debug walker，启动时扫数据抓「悬空 unlock / 缺 hotspot / 死路」，避免发破夜。
- **状态钩子→物证形态**：便签三选项（真话/安全话/不写）产出不同「物证形态」，终章 callback 复用——这条数据模型现在就能定，不必等美术。

---

## 7. 建议里程碑（对齐「每里程碑验双端」）

- **M0 引擎 spike**：Godot 空工程，搭好 4 个 Autoload 单例 + 一个测试夜（搬运夜 A 一个区域），验 Windows+Web 双导出能加载能点。
- **M1 夜 A 完整**：4 区域 + 旧灯 marquee + decoy 信 + 便签钩子 + 管理员条，双端验证。
- **M2 多夜 + meta 层**：通知箱/背包/回溯，跨夜累积可视状态。
- **M3 美术+音频 pass**：区域隐喻统一物件视觉，雨声+氛围床，白噪音门。
- **M4 TapTap 包装**：PC 客户端上架素材、Web 落地页、版号/评级路径。

---

## 8. 决策落定（2026-07-10 用户回执）

| # | 议题 | 用户决定 | 落地 |
|---|---|---|---|
| 1 | Android 是否加入目标 | **加**，但开发主线以 **Windows 独立主机优先**，Android 作为后期移植 | 单工程已留平台隔离口子；Android 导出后期补，不阻塞主线 |
| 2 | 内容数据格式 | **JSON**（采纳推荐） | 编写用 JSON + 启动 schema 校验 + 运行时类型包装；night_a.js 已搬为 `content/night_a.json` |
| 3 | 商业化 / 版号 | 不想等版号；买断制必须版号 → 走「国内免费 + 海外买断」双轨（见 §10） | 商业模式做成配置开关，开发按"免费可玩"默认；版号列为后续里程碑 |
| 4 | Godot 版本 | 交给我（4.7 仅为稳定性） | 锁 **最新 Stable 4.x**（若 4.7 为当时稳定版则用之），pin 到 `GODOT_VERSION`，保持 Compatibility |

> 四项已全部落定，M0 引擎 spike 脚手架已搭建（见 §9 与 `godot/`）。

## 9. M0 引擎 spike（已搭建脚手架）

`overdue-book/godot/` 已落地最小可运行骨架：
- `project.godot`：Compatibility 渲染、4 个 Autoload 单例、主场景 `Main.tscn`。
- `autoload/`：`SaveManager`（存档，Web/PC 同接口，user://）、`AudioManager`（白噪音占位 + 首次输入手势门）、`PlatformService`（is_web/is_mobile/is_desktop 平台判断）、`ContentLoader`（读 JSON + `{name}` 插值 + 缓存）。
- `content/night_a.json`：夜 A 全量数据（4 区域 + 节点 + 管理员反应层 + 便签钩子结果），由 `skeleton/night_a.js` 忠实搬运；`tools/gen_content.py` 生成、`tools/validate_content.js` 校验（已通过：10 条线索可达、出口无死路）。
- `Main.tscn` + `Main.gd`：M0 测试——加载夜 A、渲染借阅台区域、热点可点、管理员反应、区域切换、存档到 `user://`。
- `tools/export.ps1` + `export_presets.cfg`：Windows + Web 双端导出（需在编辑器内确认一次 preset）。
- `README_M0.md`：本地安装/运行/导出说明。

> ⚠️ 本机未安装 Godot，脚手架为"文件级"交付，未在此环境跑导出验证；需本地装 Godot 后打开 `godot/` 目录运行/导出（详见 `godot/README_M0.md`）。

## 10. 发行与版号专题（2026-07 调研）

**核心事实**（依据 TapTap 官方说明 + 律所解读 2025-2026）：
- **买断制（任何收费：买断 / 内购 / 抽卡）在国内发行必须版号**，无规避空间。周期数月到年。
- **免费 + 无内购**游戏：行业共识"暂时不需要版号"，但属**法规灰度**（已有处罚案例，非绝对安全港），且监管有收紧趋势。
- **不需要中国版号的路径**：TapTap **国际版**（海外）、**Steam 国际版**买断、itch.io / 自托管 Web 免费。

**决策：双轨发行，不等版号**
1. **国内 TapTap（电脑版）**：以**免费**上架攒口碑与测试（按灰度"暂时不需要版号"走；若后续监管收紧再议）。
2. **海外（TapTap 国际版 / Steam 国际版）**：做**买断制**收费，完全绕开中国版号，立刻能收钱。
3. **国内买断制**：列为**版号下来之后**的里程碑，届时再切商业模式开关。
4. **Android**：主线完成 Win 后移植（触屏零成本），同步走国际版买断。

> 内容全数据化 → 商业模式是配置开关，现在按"免费可玩"开发即可，不必现在定死。
