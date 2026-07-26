# 《逾期之书》视觉素材交付包

本目录是 `Return-by-Dawn` 仓库内独立维护的视觉资产包，不替代游戏代码，也不要求修改现有场景目录。

最新状态：147 个视觉资产组完成；29/29 热点有视觉来源；8 区横版与移动竖版齐全；96 个 @2x PNG 已导出；视觉缺项 0。

## 目录

```text
visual-assets-overdue-book/
├── art/                         # 可见素材与可编辑等价源
│   ├── locations/               # C01-C08、现实场景、M09 与 9:16 重构
│   ├── closeups/                # 故事检查近景
│   ├── objects/                 # 道具、状态图集与运行时补充
│   ├── characters/              # 管理员立绘、动作、手部与工牌
│   ├── ui/                      # UI、HUD、外壳、光标与无障碍 SVG
│   ├── fx/                      # 雨、灯、墨迹、翻页与转场
│   ├── branding/                # 中英 Logo 与标志
│   ├── platform/                # Windows、Web、Android 图标
│   ├── marketing/               # 主视觉、商店裁切与截图
│   ├── release/at2x/            # 高分辨率交付导出
│   └── reference/visual_audits/ # 接触表与视觉验收图
├── data/visual/                 # 机器清单、路径、状态与热点映射
└── docs/visual/                 # 视觉规范、生成记录与验收文档
```

## 首次使用

1. 先读 `data/visual/all_visual_assets_manifest_v3.json`；
2. 再读 `docs/visual/03_ART_SPEC_1增补视觉完成审计_2026-07-23.md`；
3. 热点接线以 `data/visual/art_spec1_hotspot_asset_map_v1.json` 为准；
4. 最终机器检查结果见 `data/visual/art_spec1_completion_audit_2026-07-23.json`；
5. 需要快速浏览时，打开：
   - `art/reference/visual_audits/art_spec1_new_assets_contact_sheet_v1.jpg`
   - `art/reference/visual_audits/mobile_9x16_background_contact_sheet_v1.jpg`

## Godot 接入建议

- 桌面横版使用 1920×1080 运行时图；
- 移动竖版使用 `art/locations/mobile_9x16/` 下 1080×1920 文件；
- 发行或高分屏构建使用 `art/release/at2x/`；
- 不带 `_source` 的 PNG 才是运行时候选；
- `*_source.png` 用于追溯、重新裁切和后续修订，不应直接进入运行时资源表；
- SVG 保持矢量导入，UI 正文、通知、日期、姓名和选项由引擎动态排版；
- 多状态 PNG 是图集，接入时按对应 JSON manifest 或热点映射拆分；
- 透明 Sprite 建议关闭有损压缩，保留 alpha；大背景可按目标平台开启纹理压缩和 mipmap；
- 首次接入后应在 Godot 内复核缩放、热点命中、遮挡、字体安全区和显存。

建议的 Godot 目标结构：

```text
res://art/overdue_book/
├── bg/
├── closeup/
├── prop/
├── character/
├── ui/
└── fx/
```

项目中的正式场景拓扑仍为 C01-C08。规格里的 `study_zone`、`utility_zone` 只映射为局部功能，不新增第九、第十大场景。

## 叙事与视觉限制

- 终章受控的不完整倒影之前，不出现玩家的手、身体、影子或完整反射；
- HD-01～05 玩家手部规格不采用；
- 夜 C 门槛积水只保留抽象光影，不出现可识别玩家脸；
- 不在图片里烘焙剧情正文和签名答案；
- 画风以项目的“当代记忆纸绘”为准，不回退到摄影写实或对既有作品的风格模仿；
- 夜 E/F/I 采用过渡夜方案，不为填充数量添加专属近景。

## 源文件规则

- 位图生成源：同目录 `*_source.png`；
- 透明运行时文件：同目录去掉 `_source` 的 RGBA PNG；
- UI、品牌和 FX：SVG；
- 版本、路径和状态：`data/visual/*.json`；
- 不提供只有空图层的伪 PSD。当前可编辑等价源由源 PNG、SVG 和 JSON 状态清单组成。

## Git LFS

本目录的 PNG、JPG 和 ICO 由 `.gitattributes` 交给 Git LFS 管理。GitHub Desktop 会自动安装和使用 Git LFS。

若通过命令行克隆，请确保本机已安装 Git LFS，并执行：

```bash
git lfs install
git lfs pull
```

不要删除 `.gitattributes`，否则后续二进制更新会直接进入普通 Git 历史。

## 范围边界

本包只负责视觉素材。以下内容不在本目录完成状态内：

- AU-01～AU-06 音频制作；
- F-01～F-05 字体授权与运行时字体选择；
- Godot 场景接线、动画时序、热点碰撞框和性能验证。

## 更新流程

1. 新资产先使用语义文件名并保留版本号；
2. 更新对应 `data/visual/*.json`；
3. 运行 JSON、SVG、尺寸、透明度和路径检查；
4. 更新完成审计；
5. 通过 GitHub Desktop 提交到独立分支，再合并到主分支。

