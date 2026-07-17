#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
《逾期之书》第一幕每夜节奏估算器（数据驱动，无 GUI）。

模型假设：
- 路径 = "尽量多点击"的完整通关：每个区域都进、每个 hotspot 都点、每个 closeup 都展开、
  每个 hook 选一条最长分支（最保守上界）。
- 文案阅读速度两档：
    慢速(沉浸)  = 200 字/分钟  ≈ 3.33 字/秒   （情绪叙事、逐字体会）
    正常(流畅)  = 320 字/分钟  ≈ 5.33 字/秒
- UI 按钮/选项/出口标签：快扫 600 字/分钟 ≈ 10 字/秒
- 每次点击决策（读选项+决定）：+2 秒
- 每次区域移动（走过去）：+2 秒
- 最终选择处停留：+10 秒（用户指定）

只统计 first-visit（once）文本；re-click（again）文本不计入（可选增量，另注）。
hook 三选一/二选一只取最长分支（上界），避免把三条分支都算进去。
"""
import json
import os
import glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONTENT = os.path.join(ROOT, "content")

# 会被玩家"读"的文案键（白名单）
READING_KEYS = {
    "frame", "stage", "desc", "once", "curatorOnce", "curatorAgain",
    "hookPrompt", "line", "body", "prompt", "then", "text", "title",
}
# 不应计入玩家阅读的键
EXCLUDE = {"again", "metaphor", "note", "label", "name", "id", "next",
           "requiresFlag", "setFlag", "requiresReveal", "lockedLabel",
           "lockedHint", "form", "gained", "meta", "playerName", "frame_note"}


def collect(node, out):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == "hookResults" and isinstance(v, dict):
                best = 0
                for bk, bv in v.items():
                    if isinstance(bv, dict):
                        s = sum(len(bv[f]) for f in ("line", "body")
                                if f in bv and isinstance(bv[f], str))
                        best = max(best, s)
                out["hook_branch_chars"] += best
                continue
            if k in EXCLUDE:
                continue
            if k in READING_KEYS and isinstance(v, str):
                out["reading"].append(v)
            elif k == "options" and isinstance(v, list):
                for o in v:
                    if isinstance(o, dict) and isinstance(o.get("label"), str):
                        out["ui_chars"] += len(o["label"])
                        out["clicks"] += 1
            elif k == "actions" and isinstance(v, list):
                for a in v:
                    if isinstance(a, dict) and isinstance(a.get("label"), str):
                        out["ui_chars"] += len(a["label"])
                        out["clicks"] += 1
            elif k == "exits" and isinstance(v, list):
                for e in v:
                    if isinstance(e, dict) and isinstance(e.get("label"), str):
                        out["ui_chars"] += len(e["label"])
                        out["exits"] += 1
            elif k == "hotspots" and isinstance(v, dict):
                out["hotspots"] += len(v)
                for hk, hv in v.items():
                    collect(hv, out)
            elif k == "regions" and isinstance(v, dict):
                out["regions"] += len(v)
                for rk, rv in v.items():
                    collect(rv, out)
            elif k in ("companion", "memories") and isinstance(v, dict):
                for ck, cv in v.items():
                    if isinstance(cv, str):
                        out["reading"].append(cv)
            else:
                collect(v, out)
    elif isinstance(node, list):
        for item in node:
            collect(item, out)


def analyze(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    out = {
        "reading": [], "ui_chars": 0, "clicks": 0, "exits": 0,
        "hotspots": 0, "regions": 0, "hook_branch_chars": 0,
    }
    collect(data, out)
    reading_chars = sum(len(t) for t in out["reading"]) + out["hook_branch_chars"]

    # 阅读时间（秒）
    slow = reading_chars / (200 / 60.0)
    normal = reading_chars / (320 / 60.0)
    ui_time = out["ui_chars"] / (600 / 60.0)
    decision = out["clicks"] * 2.0
    nav = out["regions"] * 2.0
    final_pause = 10.0

    low = normal + ui_time + decision + nav + final_pause
    high = slow + ui_time + decision + nav + final_pause

    return {
        "id": data.get("id"),
        "title": data.get("title"),
        "reading_chars": reading_chars,
        "ui_chars": out["ui_chars"],
        "hotspots": out["hotspots"],
        "regions": out["regions"],
        "clicks": out["clicks"],
        "exits": out["exits"],
        "slow_s": slow, "normal_s": normal,
        "ui_time": ui_time, "decision": decision, "nav": nav,
        "low_s": low, "high_s": high,
    }


def fmt(sec):
    m = int(sec // 60)
    s = int(sec % 60)
    return f"{m}分{s:02d}秒" if m else f"{s}秒"


def main():
    files = sorted(glob.glob(os.path.join(CONTENT, "*.json")))
    print("=" * 78)
    print("《逾期之书》第一幕 · 每夜节奏估算（完整通关 / 慢速~正常）")
    print("=" * 78)
    print(f"{'夜':<10}{'文案字数':>8}{'UI字':>6}{'热点':>5}{'区域':>5}"
          f"{'点击':>5} | {'慢速':>9}{'正常':>9}{'预估区间':>16}")
    print("-" * 78)
    grand_low = grand_high = 0
    for fp in files:
        r = analyze(fp)
        print(f"{r['title']:<10}{r['reading_chars']:>8}{r['ui_chars']:>6}"
              f"{r['hotspots']:>5}{r['regions']:>5}{r['clicks']:>5} | "
              f"{fmt(r['high_s']):>9}{fmt(r['low_s']):>9}"
              f"  {fmt(r['low_s'])+'~'+fmt(r['high_s']):>16}")
        grand_low += r["low_s"]
        grand_high += r["high_s"]
    print("-" * 78)
    print(f"{'第一幕合计':<10}{'':>8}{'':>6}{'':>5}{'':>5}{'':>5} | "
          f"{fmt(grand_high):>9}{fmt(grand_low):>9}"
          f"  {fmt(grand_low)+'~'+fmt(grand_high):>16}")
    print("=" * 78)
    print("说明：")
    print(" - 慢速=200字/分（沉浸逐字），正常=320字/分；UI按钮快扫600字/分。")
    print(" - 每次点击+2s决策，每次区域移动+2s，最终选择+10s。")
    print(" - 仅计首访(once)；re-click(again)为可选增量，未计入。")
    print(" - hook 三/二选一只取最长分支上界；不同选择会让区间小幅浮动。")
    print(" - 目标每夜≈10分钟(600s)。区间若显著低于600s=偏瘦，高于=偏胖。")


if __name__ == "__main__":
    main()
