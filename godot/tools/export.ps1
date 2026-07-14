# 《逾期之书》双端导出脚本
# 用法：powershell -ExecutionPolicy Bypass -File tools/export.ps1
# 前提：本机已安装 Godot，并把下方 $godot 改为你的 Godot 可执行文件全路径。
#       首次导出前，请在 Godot 编辑器里 Project -> Export -> Add 添加
#       "Windows Desktop" 与 "Web" 两个 preset（与 export_presets.cfg 同名），
#       之后即可用此脚本自动化（--headless --export-release）。

$godot = "godot"   # 例如 "C:\godot\Godot_v4.7-stable_win64.exe"
$root = Resolve-Path $PSScriptRoot\..
Push-Location $root

& $godot --headless --export-release "Windows Desktop" "build/win/逾期之书.exe"
& $godot --headless --export-release "Web" "build/web/index.html"

Pop-Location
