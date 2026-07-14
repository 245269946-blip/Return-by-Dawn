extends Node
# 《逾期之书》跨夜持久进度（框架地基 · F2）
#
# 这是夜 A 单夜时的结构占位；多夜顺序 / 跨夜选择 / 三物证累计在此落地。
# 字段（与 v2.2 §五 F2 对齐）：
#   night_index    : 当前夜在 NIGHT_ORDER 中的下标（0 = 夜 A）
#   unlocked_zones : 当前已解锁可进的区域 id 列表（排除 locked / void）
#   librarian      : 管理员羁绊档案（跨夜熟悉度 / 手作痕迹 / 往复仪式等）
#   artifacts      : 三物证存放位（夜 Z 终归 / 夜D 合流的实物锚点）
#
# 注：夜 A 单夜下仅作框架占位，由 Main._ready 在每局开场写入 night_index / unlocked_zones。
# 真正的跨夜持久化（写入 user://、多夜累加）在后续框架层扩展，不在本轮范围。

var night_index := 0
var unlocked_zones: Array = []
var librarian: Dictionary = {}
var artifacts: Array = []

func reset() -> void:
	night_index = 0
	unlocked_zones = []
	librarian = {}
	artifacts = []
