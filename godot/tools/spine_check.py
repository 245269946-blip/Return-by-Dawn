# -*- coding: utf-8 -*-
# 《逾期之书》脊柱护栏扫描器（F4）
#
# 作用：防止「自认红线」（v6 原则13）被提前点破。
#   夜 A / 夜 B / 夜 C（夜序 < 夜D）绝不允许出现直接把「主角 = 自己」说破的文案；
#   自认只在夜 D 闸门由玩家自行拼合。
#
# 本脚本扫描所有 content/night_*.json，对夜序 < SPINE_BREAK_NIGHT 的夜，
# 递归检查全部故事文案中是否出现「点破词」（见 LEAK_PATTERNS，正则）。
#   命中 -> 报告 文件路径 + JSON 路径 + 点破词 + 上下文，进程退出码 1（护栏拦截）。
#   未命中 -> 退出码 0。
#
# 用法：python tools/spine_check.py
import json, os, re, sys

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT_DIR = os.path.join(BASE, "content")

# 夜程表（顺序即夜序）。新增一夜在此追加即可，引擎侧 Main.NIGHT_ORDER 同步。
# prologue 为序章（教学关，玩家自己的逾期书），夜序最前，受护栏约束（< 夜D 不得点破自认）。
NIGHT_ORDER = ["prologue", "night_a", "night_b", "night_c", "night_d", "night_e", "night_f"]
# 第一夜允许自认揭晓的闸门（夜序 >= 此夜 不再受本护栏约束）。
SPINE_BREAK_NIGHT = "night_d"

# 点破词（正则）。只收「游戏直接把『是你』说破」的高信噪片段，避免误伤：
#   - 「是你写的/寄的/本人」：恒为身份断言，直接匹配。
#   - 「是你自己」：须排除领属用法「是你自己的事/决定」（那是玩家自主权，非自认），
#     故用负向先行断言 (?!的) 只匹配身份断言语境。
#   - 「其实是你 / 就是你自己 / 信是你 / 这信是你」：恒为身份断言。
LEAK_PATTERNS = [
    "是你写的", "是你寄的", "是你本人", r"是你自己(?!的)",
    "其实是你", "就是你自己", "信是你", "这信是你",
]


def _scan_strings(node, path, leaks):
    """递归遍历 JSON 树，对每一个字符串值做点破词检测，按位置去重。"""
    if isinstance(node, dict):
        for k, v in node.items():
            _scan_strings(v, path + [k], leaks)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            _scan_strings(v, path + [str(i)], leaks)
    elif isinstance(node, str):
        for pat in LEAK_PATTERNS:
            m = re.search(pat, node)
            if m:
                key = tuple(path)
                entry = leaks.setdefault(key, {"pats": set(), "snippet": ""})
                entry["pats"].add(pat)
                if not entry["snippet"]:
                    s, e = m.start(), m.end()
                    entry["snippet"] = node[max(0, s - 8): e + 8]


def main():
    if not os.path.isdir(CONTENT_DIR):
        print("content 目录不存在：", CONTENT_DIR)
        return 0

    break_idx = NIGHT_ORDER.index(SPINE_BREAK_NIGHT)
    total_leaks = 0

    for fn in sorted(os.listdir(CONTENT_DIR)):
        if not (fn.startswith("night_") or fn.startswith("prologue")) or not fn.endswith(".json"):
            continue
        night_id = fn[:-5]
        if night_id not in NIGHT_ORDER:
            order_idx = 0
            guarded = True
        else:
            order_idx = NIGHT_ORDER.index(night_id)
            guarded = order_idx < break_idx

        path = os.path.join(CONTENT_DIR, fn)
        with open(path, encoding="utf-8") as f:
            data = json.load(f)

        print("[%s] 夜序=%d %s" % (
            night_id, order_idx,
            "（受护栏约束）" if guarded else "（夜D及之后，豁免）"))

        if not guarded:
            continue

        leaks = {}
        _scan_strings(data, [], leaks)
        if leaks:
            total_leaks += len(leaks)
            for p in sorted(leaks.keys(), key=lambda x: ".".join(x)):
                jp = "$." + ".".join(p)
                pats = " / ".join(sorted(leaks[p]["pats"]))
                print("  [LEAK] 脊柱泄漏 @ %s" % jp)
                print("         点破词[%s]" % pats)
                print("         上下文：...%s..." % leaks[p]["snippet"])
        else:
            print("  [OK] 未发现脊柱泄漏")

    print("-" * 48)
    if total_leaks:
        print("拦截：发现 %d 处脊柱泄漏（夜序 < %s 不应点破自认）" % (total_leaks, SPINE_BREAK_NIGHT))
        return 1
    print("通过：所有受护栏约束的夜均未提前点破自认。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
