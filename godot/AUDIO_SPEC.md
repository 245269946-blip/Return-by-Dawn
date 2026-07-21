# 《逾期之书》音频资产规格书 · AUDIO_SPEC

> 目的：把**每个场景（每个夜 / 每个区域）需要的音乐素材逐一拉出来**，逐项标记
> `✅已做` / `🟡我能做(未做)` / `🔴需外部(作曲)`。确保全面覆盖、不漏项。
> 数据来源：`godot/content/*.json` 全部 11 段真实锚点（脚本抽取，非举例）。

---

## 0. 能力边界速查（先读这段，避免误判）

| 类型 | 我能否在仓库内闭环合成 | 状态 |
|---|---|---|
| 环境床（雨声 / 室内底噪 / 白噪音） | ✅ 能 | ✅ 已做（10 个 wav） |
| 交互音效 SFX（点击/翻书/投递/灯/抽屉/门/水/呼吸/提示音/过场） | ✅ 能（程序化合成） | 🟡 已做 4 个，待补 6 个 |
| 章节色调 Pad（每夜一段无旋律的情绪底噪 drone） | ✅ 能（叠加谐波+缓动 LFO） | 🟡 未做，11 段 |
| 叙事转场 Sting（通知到达/进场/揭示/收束/过场帧） | ✅ 能（包络控制的环境 swell） | 🟡 未做，5 类 |
| 管理员 presence 提示音 | ✅ 能（极轻的木鱼/钟片质感） | 🟡 未做 |
| **章节主题旋律**（To the Moon 式可记忆钢琴曲） | 🔴 不能（我合成不出"打动人的旋律"） | 🔴 需外部作曲 |

**一句话结论**：除"可记忆主题旋律"外，本作**全部音频（环境 + 所有 Pad + 所有 Sting + 所有 SFX）我都能在仓库内合成闭环**。当前缺口只是"还没合成"，不是"做不了"。

---

## 1. 完整音频资产库（按类型，全量）

### A. 环境床 Ambient Beds（区域循环）　✅ 已做
| 资产 | 内容 | 映射区域 |
|---|---|---|
| `amb_noise.wav` | 白噪音/空气底 | 全局常驻低电平 |
| `rain_heavy.wav` | 大雨 | entry_porch / stacks_deep |
| `rain_fine.wav` | 细雨 | service_desk / study_zone / archive_lamp |
| `rain_indoor.wav` | 室内闷雨 | reading_room / utility_zone |
| `rain_eaves.wav` | 檐沟流水 | lounge_stairs |
| `room_tone.wav` | 室内低频底噪 | 全局叠加 |
> void_room 永不开启 = 结构性静默（不放音，靠逻辑控制）。

### B. 章节色调 Pad（每夜一段情绪 drone，无旋律）　🟡 我能做
| 资产 | 对应夜 | 情绪方向 | 合成手法 |
|---|---|---|---|
| `pad_prologue.wav` | 序章·续借 | 冷 / 系统感 / 未了结 | 低频小调，远、薄 |
| `pad_nightA.wav` | 夜A·信 | 重 / 未说出口的话悬着 | 中频悬停和声，轻微拍频 |
| `pad_nightB.wav` | 夜B·书架 | 暖但空 / 用尽责替代在场 | 暖色三和弦，缺底色 |
| `pad_nightC.wav` | 夜C·雨 | 麻木 / 浸在水里 | 低通水声 drone，淹没感 |
| `pad_nightD.wav` | 夜D·背后楼梯 | 真相拼合 / 紧张→释然 | 上行半音逼近后落定 |
| `pad_nightE.wav` | 夜E·赶你出去 | 被推开 / 疏离 | 高频空洞，抽离 |
| `pad_nightF.wav` | 夜F·三物证 | 知≠行 / 苦甜 | 多声部缓缓合流 |
| `pad_nightG.wav` | 夜G·灯是谁装的 | 暖 / 被发现 | 柔和大三和弦 |
| `pad_nightH.wav` | 夜H·半开的门 | 试探 / 靠近 | 单音犹豫颤动 |
| `pad_nightI.wav` | 夜I·最后一盏灯 | 玩笑 / 告别前 | 轻、眷恋 |
| `pad_nightZ.wav` | 夜Z·带书回来 | 限度温柔 / 落定 | 温暖解决，留气口 |

### C. 叙事转场 Sting（全屏节点情绪标点）　🟡 我能做
| 资产 | 触发点 | 音色 | 现状 |
|---|---|---|---|
| `sting_notice.wav` | 逾期通知到达（每夜 notice） | 极轻钟片/纸面提示 | 🟡 未做 |
| `sting_enter.wav` | 进场淡入（enter） | pad 缓起 swell | 🟡 未做（由 B 类 pad 承担） |
| `sting_reveal.wav` | 碎片拼合（reveal） | 上行 swell，情绪峰 | 🟡 未做（旋律层需外部） |
| `sting_exit.wav` | 收束句（exit） | 软解决/留白 | 🟡 未做 |
| `sting_curtain.wav` | 过场帧夜→夜（curtain） | 极短 whoosh/滤波扫 | 🟡 未做 |

### D. 交互音效 SFX　🟡 部分已做
| 资产 | 事件 | 状态 |
|---|---|---|
| `sfx_click.wav` | 轻点击/选项 | ✅ 已做 |
| `sfx_page.wav` | 翻书/近景/纸质 | ✅ 已做 |
| `sfx_slot.wav` | 信箱投递口合上 | ✅ 已做 |
| `sfx_lamp.wav` | 灯偏移/开关 | ✅ 已做 |
| `sfx_drawer.wav` | 抽屉开合（服务台/楼梯/灯控室） | 🟡 待补 |
| `sfx_door.wav` | 门开合/门廊进出 | 🟡 待补 |
| `sfx_water.wav` | 水滴/漏雨/接水（门廊/书库/便民/夜C） | 🟡 待补 |
| `sfx_breath.wav` | 呼吸（夜D 灯控室） | 🟡 待补 |
| `sfx_notice_chime.wav` | 通知到达提示（同 C.sting_notice，可复用） | 🟡 待补 |
| `sfx_curtain.wav` | 过场帧扫过（同 C.sting_curtain） | 🟡 待补 |

### E. 管理员 Presence 提示　🟡 我能做
| 资产 | 触发 | 状态 |
|---|---|---|
| `sfx_companion.wav` | 管理员出现/走到身边（事件触发式） | 🟡 未做（极轻木质提示，不抢戏） |

### F. 章节主题旋律（可记忆）　🔴 需外部
| 资产 | 对应 | 说明 |
|---|---|---|
| `theme_main` | 全局主旋律（To the Moon 式钢琴） | 外包/曲库，我无法合成 |
| `theme_reveal` | 揭示夜（夜D）高潮旋律 | 外包 |
| `theme_ending` | 终章（夜Z）收束旋律 | 外包 |

---

## 2. 逐场景覆盖矩阵（11 夜 × 区域 → 触发素材 + 状态）

> 表中「音频触发」= 该区域实际会响的声音；标注色同 §0。
> 区域缩写：门廊=entry_porch，台=service_desk，阅=reading_room，库=stacks_deep，
> 习=study_zone，便=utility_zone，梯=lounge_stairs，灯=archive_lamp，空=void_room(永不开)。

### 📕 序章 · 续借（3 区）
| 区域 | 环境床 | 该区 SFX | Pad | 节点 Sting |
|---|---|---|---|---|
| 门廊 | heavy rain ✅ | 水/滴🟡 门🟡 灯✅ | pad_prologue🟡 | notice✅→sting_notice🟡 / enter✅ / exit✅ |
| 台 | fine rain ✅ | 门🟡 灯✅（续借钩子） | pad_prologue🟡 | — |
| 阅 | indoor rain ✅ | 门🟡 灯✅ | pad_prologue🟡 | — |
> 管理员出现位 13 处 → `sfx_companion`🟡

### 🌙 夜 A · 夹在书里的信（9 区）
| 区域 | 环境床 | 该区 SFX | Pad | 节点 Sting |
|---|---|---|---|---|
| 门廊 | heavy ✅ | 水/滴🟡 门🟡 灯✅ | pad_nightA🟡 | notice🟡/enter✅/reveal✅(翻🟡)/exit✅ |
| 台 | fine ✅ | 抽屉🟡 灯✅ 翻🟡 门🟡 | pad_nightA🟡 | — |
| 阅 | indoor ✅ | 灯✅ 门🟡 | pad_nightA🟡 | — |
| 库 | heavy ✅ | 声/水🟡 翻🟡 门🟡（近景×2） | pad_nightA🟡 | — |
| 习 | fine ✅ | 灯✅（留灯仪式，静） | pad_nightA🟡 | — |
| 便 | indoor ✅ | 信箱✅ 投递✅ 抽屉🟡 水🟡 门🟡（近景×1） | pad_nightA🟡 | — |
| 梯/灯/空 | 各自环境✅ | 门🟡（锁区灰显，不计触发） | — | — |
> 管理员出现位 21 处 → `sfx_companion`🟡；reveal 需 `sting_reveal`🟡 + 旋律层🔴

### 🌙 夜 B · 满员的书架（9 区）
| 区域 | 环境床 | 该区 SFX | Pad | 节点 Sting |
|---|---|---|---|---|
| 门廊 | heavy ✅ | 水/滴🟡 门🟡 灯✅ | pad_nightB🟡 | notice🟡/enter✅/reveal✅/exit✅ |
| 台 | fine ✅ | 灯✅ 翻🟡 门🟡 | pad_nightB🟡 | — |
| 阅 | indoor ✅ | 灯✅ 翻🟡 门🟡（近景×1） | pad_nightB🟡 | — |
| 库 | heavy ✅ | 声/水🟡 翻🟡 门🟡 | pad_nightB🟡 | — |
| 习 | fine ✅ | 灯✅（静） | pad_nightB🟡 | — |
| 便 | indoor ✅ | 信箱✅ 声/投递✅ 水🟡 灯✅ 翻🟡 门🟡（近景×1） | pad_nightB🟡 | — |
| 梯/灯/空 | ✅ | 门🟡 | — | — |
> 管理员 22 处 → companion🟡；相册/折角热点的"翻"用 sfx_page✅

### 🌙 夜 C · 一屋子的雨（9 区）
| 区域 | 环境床 | 该区 SFX | Pad | 节点 Sting |
|---|---|---|---|---|
| 门廊 | heavy ✅ | 水/滴🟡 门🟡 灯✅ | pad_nightC🟡 | notice🟡/enter✅/reveal✅(水🟡)/exit✅ |
| 台 | fine ✅ | 灯✅ 翻🟡 门🟡 | pad_nightC🟡 | — |
| 阅 | indoor ✅ | 灯✅ 门🟡 | pad_nightC🟡 | — |
| 库 | heavy ✅ | 声/水🟡 翻🟡 门🟡（近景×2） | pad_nightC🟡 | — |
| 习 | fine ✅ | 灯✅（静） | pad_nightC🟡 | — |
| 便 | indoor ✅ | 信箱✅ 声/投递✅ 水🟡 灯✅ 门🟡（近景×1，搪瓷盆接水→water🟡） | pad_nightC🟡 | — |
> **重点**：夜C 的"漏水/接水"是核心隐喻，water SFX🟡 必须做；reveal 三态（ evade/erase/face ）各需一次 sting_reveal🟡

### 🌙 夜 D · 背后楼梯（9 区，揭示夜）　⭐ 最重
| 区域 | 环境床 | 该区 SFX | Pad | 节点 Sting |
|---|---|---|---|---|
| 门廊 | heavy ✅ | 水/滴🟡 门🟡 灯✅ | pad_nightD🟡 | notice🟡/enter✅/reveal✅(抽屉🟡)/exit✅ |
| 台 | fine ✅ | 灯✅ 门🟡 | pad_nightD🟡 | — |
| 阅 | indoor ✅ | 声/灯✅ 翻🟡 门🟡 | pad_nightD🟡 | — |
| 库 | heavy ✅ | 声/水🟡 门🟡 | pad_nightD🟡 | — |
| 习 | fine ✅ | 灯✅（静） | pad_nightD🟡 | — |
| 便 | indoor ✅ | 信箱✅ 声/门🟡 | pad_nightD🟡 | — |
| 梯 | eaves ✅ | 抽屉🟡 翻🟡 门🟡（近景×1，废稿划痕通知） | pad_nightD🟡 | — |
| 灯 | fine ✅ | **呼吸🟡** 抽屉🟡 灯✅ 门🟡（近景×1） | pad_nightD🟡 | — |
> **呼吸 SFX🟡 全游戏唯一出现点**（灯控室）；reveal"拼合那一夜"= 情绪峰，需 sting_reveal🟡 + 旋律🔴

### 🌙 夜 E · 赶你出去的夜（9 区）
| 区域 | 环境床 | 该区 SFX | Pad | 节点 Sting |
|---|---|---|---|---|
| 门廊 | heavy ✅ | 声/灯✅ 门🟡（钩子） | pad_nightE🟡 | notice🟡/enter✅/reveal✅/exit✅ |
| 台 | fine ✅ | 抽屉🟡 灯✅ 门🟡 | pad_nightE🟡 | — |
| 阅 | indoor ✅ | 声/灯✅ 翻🟡 门🟡 | pad_nightE🟡 | — |
| 库 | heavy ✅ | 声/水🟡 | pad_nightE🟡 | — |
| 习 | fine ✅ | 灯✅（静） | pad_nightE🟡 | — |
| 便 | indoor ✅ | 信箱✅ 翻🟡 门🟡 | pad_nightE🟡 | — |
| 梯/灯 | ✅ | 门🟡 / 抽屉🟡 灯✅ | pad_nightE🟡 | — |
> 情绪=被推开，pad_nightE🟡 用抽离高频；管理员 22 处 companion🟡

### 🌙 夜 F · 三物证合流（4 区，桥段）
| 区域 | 环境床 | 该区 SFX | Pad | 节点 Sting |
|---|---|---|---|---|
| 台 | fine ✅ | 声/灯✅ 翻🟡 门🟡（钩子，三物证合流） | pad_nightF🟡 | notice🟡(抽屉🟡)/enter✅(静)/reveal✅(翻🟡)/exit✅ |
| 门廊 | heavy ✅ | 灯✅ 门🟡 | pad_nightF🟡 | — |
| 阅 | indoor ✅ | 声/翻🟡 门🟡 | pad_nightF🟡 | — |
| 空 | — | — | — | — |
> 三物证 callback 的"知≠行"→ pad_nightF🟡 多声部合流；reveal 需 sting_reveal🟡 + 旋律🔴

### 🌙 夜 G · 灯是谁装的（6 区）
| 区域 | 环境床 | 该区 SFX | Pad | 节点 Sting |
|---|---|---|---|---|
| 门廊 | heavy ✅ | 灯✅ 门🟡 | pad_nightG🟡 | notice🟡/enter✅/exit✅ |
| 台 | fine ✅ | 灯✅ 门🟡 | pad_nightG🟡 | — |
| 阅 | indoor ✅ | — | pad_nightG🟡 | — |
| 习 | fine ✅ | 灯✅（静） | pad_nightG🟡 | — |
| 灯 | fine ✅ | 灯✅ 门🟡（近景×1） | pad_nightG🟡 | — |
> 无 reveal（狂欢夜）；暖色 pad_nightG🟡；管理员 14 处 companion🟡

### 🌙 夜 H · 档案室半开的门（5 区）
| 区域 | 环境床 | 该区 SFX | Pad | 节点 Sting |
|---|---|---|---|---|
| 门廊 | heavy ✅ | 灯✅ 门🟡（静） | pad_nightH🟡 | notice🟡/enter✅/exit✅ |
| 台 | fine ✅ | 灯✅ 门🟡 | pad_nightH🟡 | — |
| 阅 | indoor ✅ | — | pad_nightH🟡 | — |
| 灯 | fine ✅ | 灯✅ 门🟡（近景×1，半开门旧书） | pad_nightH🟡 | — |
> 试探情绪 → pad_nightH🟡 单音犹豫；管理员 12 处 companion🟡

### 🌙 夜 I · 最后一盏灯前的玩笑（6 区）
| 区域 | 环境床 | 该区 SFX | Pad | 节点 Sting |
|---|---|---|---|---|
| 门廊 | heavy ✅ | 灯✅ 门🟡（静） | pad_nightI🟡 | notice🟡/enter✅/exit✅ |
| 台 | fine ✅ | 灯✅ 翻🟡 门🟡（钩子） | pad_nightI🟡 | — |
| 阅 | indoor ✅ | — | pad_nightI🟡 | — |
| 便 | indoor ✅ | 翻🟡 门🟡 | pad_nightI🟡 | — |
| 习 | fine ✅ | 灯✅（静） | pad_nightI🟡 | — |
> 告别前玩笑 → pad_nightI🟡 轻、眷恋；管理员 14 处 companion🟡

### 🌅 夜 Z · 带书回来的人（5 区，终章）　⭐ 收束
| 区域 | 环境床 | 该区 SFX | Pad | 节点 Sting |
|---|---|---|---|---|
| 门廊 | heavy ✅ | 门🟡（静） | pad_nightZ🟡 | notice🟡/enter✅/reveal✅(信箱✅ 水🟡)/exit✅ |
| 台 | fine ✅ | 灯✅ 翻🟡 门🟡（近景×1） | pad_nightZ🟡 | — |
| 阅 | indoor ✅ | 水🟡 雨 | pad_nightZ🟡 | — |
| 灯 | fine ✅ | 声/灯✅（近景×1） | pad_nightZ🟡 | — |
> 收束句"灯还亮着"= 全作终点 → sting_exit🟡 + 旋律 theme_ending🔴；pad_nightZ🟡 温暖解决留气口

---

## 3. 待补清单（🟡 我能做，尚未合成）—— 按优先级

**P0（交互必备，不补则音效断层）：**
1. `sfx_drawer.wav` — 抽屉（服务台/楼梯/灯控室，多夜触发）
2. `sfx_door.wav` — 门开合（全区域进出，高频触发）
3. `sfx_water.wav` — 水滴/漏雨/接水（门廊/书库/便民/夜C 核心隐喻）

**P1（氛围与情绪完整度）：**
4. `sfx_breath.wav` — 呼吸（仅夜D 灯控室，但不可省）
5. `sfx_notice_chime.wav` — 通知到达提示（= sting_notice 复用）
6. `sfx_curtain.wav` — 过场帧扫过（= sting_curtain 复用）
7. `sfx_companion.wav` — 管理员出现提示

**P2（章节音乐层，无旋律 drone）：**
8. `pad_prologue` ~ `pad_nightZ` 共 **11 段** 章节 Pad
9. `sting_reveal` / `sting_exit` 两段情绪 swell（reveal 旋律层仍🔴）

> 以上 P0+P1 共 **10 个文件**、P2 共 **13 个文件**，全部我可程序化合成，落 `godot/audio/`，并在 `AudioManager.gd` 接线（已有 `play_sfx` / `set_mood` 守卫，扩展成本低）。

## 4. 需外部清单（🔴 甩给作曲 / 曲库）
| 资产 | 用途 | 建议 |
|---|---|---|
| `theme_main` | 全局主旋律（钢琴，To the Moon 式） | 外包 or Epidemic Sound 等授权库 |
| `theme_reveal` | 揭示夜（夜D）高潮 | 外包 |
| `theme_ending` | 终章（夜Z）收束 | 外包 |
> 我会另写一份《章节配乐需求单》（每章情绪/时长/乐器/参考曲）方便你直接甩给作曲人。

## 5. 命名规范 & 接入点
- 文件：`godot/audio/<类型>_<名称>.wav`（16-bit PCM，Godot 原生支持）
- 环境床由 `AudioManager.set_mood(rid)` 按区域映射循环播放并交叉淡入淡出（✅ 已通）
- SFX 由 `AudioManager.play_sfx(id)` 在各交互点触发（已挂 热点/近景/导航/投递口，需补 drawer/door/water/breath/companion 的调用点）
- Pad/Sting 由 `AudioManager.set_chapter(night_id)` + `play_sting(kind)` 在节点切换时触发（待写）
- 旋律层（🔴）由独立 `MusicManager` 在 reveal/exit 高峰淡入，留接口待外部素材就位

---
*生成依据：11 段内容 JSON 全量抽取（区域/节点/近景/钩子/管理员出现位）。已做项以 `godot/audio/` 现有 10 个 wav + `AudioManager.gd` 实测 351/0 ALL GREEN 为准。*
