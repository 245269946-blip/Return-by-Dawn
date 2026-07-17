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
# 跨夜携带累加位（框架层 · F2/F3）：上一夜的可携带字段（线索/记忆/物证形态）在此累加，
# 由 Main._carry_forward() 写入、Main.load_night_by_id() 末尾并入下一夜的 state。
# 这是「夜与夜真正串联跑动」的地基——autoload 在 load_night_by_id 之间不被销毁，故可跨夜存活。
var cross_night: Dictionary = {}

func reset() -> void:
	night_index = 0
	unlocked_zones = []
	librarian = {}
	artifacts = []
	cross_night = {}
