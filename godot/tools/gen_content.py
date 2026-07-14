# -*- coding: utf-8 -*-
# 《逾期之书》内容生成器：把夜 A 数据写成 content/night_a.json。
# 重跑即可刷新（非程序员改叙事也走这里，或手改 JSON 后跑 validate_content.js）。
#
# 拓扑对齐：v2.2 §2.2 楼层树（2026-07-14 锁死）
#   - borrowing_desk -> service_desk（服务台，5 出口）
#   - rain_porch     -> entry_porch（雨夜门廊，1 出口）
#   - 新增 study_zone / utility_zone / lounge_stairs / archive_lamp / void_room
#   - 删除 return_box（其叙事已由失物招领信箱 + 结算近景承担）
#   - 邻接为严格树（禁止跨区乱飞），locked/void 由引擎层灰显/拦截
import json, os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BASE, "content", "night_a.json")

data = {
  "id": "night_a",
  "playerName": "阿迟",
  "title": "夜 A · 夹在书里的信",
  "meta": {
    "decoy": True,
    "note": "关系域 decoy，前期读成别人故事，不引到自己身上"
  },
  "regions": {
    "service_desk": {
      "name": "服务台",
      "metaphor": "程序性温柔的入口——所有「处理／续借／寄通知」都从这流过",
      "desc": "服务台后的灯拧得很低。一摞书压着本旧登记册，胶水瓶的盖子没拧紧。",
      "exits": [
        {"label": "去雨夜门廊", "to": "entry_porch"},
        {"label": "去管理员区①·休息室", "to": "lounge_stairs"},
        {"label": "去管理员区②·灯控室", "to": "archive_lamp"},
        {"label": "去便民配套区", "to": "utility_zone"},
        {"label": "去阅览区", "to": "reading_room"}
      ],
      "hotspots": {
        "notice_card": {
          "label": "逾期通知单（写着你名字）",
          "once": "{name}的《夏天》已逾期。落款是你的名字——可你不记得借过这本书。",
          "again": "通知单边角有手改的痕迹，像被人划掉又重写过一遍。",
          "curatorOnce": "（他没解释，只把单子往你这边推了推。）",
          "unlocks": {"id": "c_name", "text": "一张你从没借过的书，写着你的名字"}
        },
        "drawer_note": {
          "label": "抽屉里的空白便签（笔就在手边）",
          "hook": True,
          "hookPrompt": "服务台抽屉里有一张空白便签和一支笔。你要写点什么吗？",
          "once": "服务台抽屉里压着一张空白便签。笔就在手边，像有人等你写点什么。",
          "again": "便签还在原处。要不要写，你犹豫着。",
          "curatorOnce": "「要写吗？」他擦着台面，「不写也行。」",
          "options": [
            {"id": "truth", "label": "写一句真话（如「其实我很想你」）"},
            {"id": "safe", "label": "写一句安全的话（如「最近还好吗」）"},
            {"id": "none", "label": "什么都不写，直接送信箱"}
          ],
          "hookResults": {
            "truth": {"form": "便签被压在抽屉最上层、抚平", "line": "「这句……我替你收着。」他把它压在抽屉最上层。", "clue": {"id": "c_note", "text": "便签写下一句真话，被压在抽屉最上层、抚平"}, "settlement": {"title": "你写下了那句话", "body": "便签被压在抽屉最上层、抚平。有些话，第一次被认真收着。", "gained": "线索：便签写下一句真话"}},
            "safe": {"form": "便签夹进登记册，位置中性", "line": "「这样也行。」他把它夹进登记册，不偏不倚。", "clue": {"id": "c_note", "text": "便签写下一句安全的话，夹进登记册"}, "settlement": {"title": "你写下一句安全的话", "body": "便签夹进登记册，位置不偏不倚。也是一种选择。", "gained": "线索：便签写下一句安全的话"}},
            "none": {"form": "管理员替你贴了「未署名」标签，仍收着", "line": "「不写也行。」他替你贴了张未署名标签，收进抽屉。", "clue": {"id": "c_note", "text": "便签什么都没写，管理员替你贴「未署名」标签收着"}, "settlement": {"title": "你什么都没写", "body": "便签空着，被收进抽屉。有些话，留到下次也行。", "gained": "线索：便签什么都没写"}}
          }
        },
        "lost_found": {
          "label": "失物招领信箱",
          "once": "信箱吞过很多没说出口的东西。你把表达替换成处理，它就很满意。",
          "curatorOnce": "「这里最省事。」他说，像在说给自己听。"
        },
        "glue_register": {
          "label": "胶水与登记册",
          "once": "登记册上你的名字被描过很多遍，墨迹一圈圈晕开，像有人总也写不顺。",
          "curatorOnce": "「借书的人，常来。」他顿了顿，「……常来还，也常还不上。」",
          "unlocks": {"id": "c_sign", "text": "你的名字在登记册上被反复描过，墨迹发毛"}
        }
      }
    },
    "entry_porch": {
      "name": "雨夜门廊",
      "metaphor": "进出的阈限——伞、门、来去都在此，是逃避与返回的边界",
      "desc": "玻璃门外雨下得直。门是进来的地方，也是回去的地方。",
      "exits": [
        {"label": "进馆·去服务台", "to": "service_desk"}
      ],
      "hotspots": {
        "umbrella": {
          "label": "你忘在门廊的伞",
          "once": "你的伞靠在门边，伞尖还在滴水。你进来时忘了它，像忘了很多次自己。",
          "again": "伞还靠在原处，湿痕没干。",
          "curatorOnce": "「又忘了？」他没笑，「门廊留着你的伞，第几次了。」",
          "unlocks": {"id": "c_umb1", "text": "你又忘带伞——门廊留着你的伞"}
        },
        "door": {
          "label": "门（没锁）",
          "once": "门没锁。推开门是雨，关上是馆。你站在门槛上，两边都不是答案。",
          "again": "门还是那样，没锁。你没推。",
          "curatorOnce": "（他没拦你，也没催你走。）"
        },
        "lamp_behind": {
          "label": "身后的灯（常亮）",
          "once": "你回头，馆里的灯亮着。它从不熄灭——像有谁舍不得让你摸黑走。",
          "curatorOnce": "「灯亮着，你回头就能看见路。」",
          "unlocks": {"id": "c_lamp2", "text": "灯从不熄灭——像有谁舍不得让你摸黑走"}
        }
      }
    },
    "reading_room": {
      "name": "阅览区",
      "metaphor": "被允许的旁观位——坐在这看「别人的故事」，是你最会的姿势",
      "desc": "一排排座位空着。坐在这看「别人的故事」，是你最会的保护自己的方式。",
      "exits": [
        {"label": "回服务台", "to": "service_desk"},
        {"label": "去书库深处", "to": "stacks_deep"},
        {"label": "去自习学习区", "to": "study_zone"}
      ],
      "hotspots": {
        "old_lamp": {
          "label": "一盏旧灯",
          "once": "这盏灯为什么一直亮着？",
          "again": "灯还亮着。和刚才一样。",
          "ask": {"prompt": "谁？", "then": "忘了。"},
          "curatorOnce": "「因为以前有人怕黑。」",
          "curatorAgain": "「……忘了。」其实他说的是自己。",
          "unlocks": {"id": "c_lamp", "text": "灯一直亮着——因为以前有人怕黑"}
        },
        "seats": {
          "label": "你常坐的读者座位",
          "once": "你常坐的这个位子，椅背上搭着一块除尘布，像有人记得你坐哪儿。",
          "curatorOnce": "「你总坐这儿。」他说，「我留着布，省得落灰。」"
        },
        "album_shelf": {
          "label": "相册书目区（翻得最旧的一本）",
          "once": "一栏相册书里，有本翻得最旧，停在年夜饭那页——你常坐的位子空着。",
          "again": "那本相册书被挪到了「待你再来看」的架位，正对着你。",
          "curatorOnce": "「这本，你翻得最久。」他把它摆到架位最显眼处。",
          "unlocks": {"id": "c_album", "text": "相册书停在年夜饭那页，你常坐的位子空着（伏笔）"}
        }
      }
    },
    "stacks_deep": {
      "name": "书库深处",
      "metaphor": "漏雨的裂缝——情绪裂缝的具象，旧事书与旧盆都藏在这",
      "desc": "书库最里头漏雨，地上摆着个旧搪瓷盆接水。雨声在这儿格外清楚。",
      "exits": [
        {"label": "回阅览区", "to": "reading_room"}
      ],
      "hotspots": {
        "letter": {
          "label": "夹在书里的信（无署名）",
          "once": "一本书里夹着封信，没署名。你想凑近看看。",
          "again": "信还在原处。你想凑近看看。",
          "closeup": {
            "stage": "你把书摊开。信夹在第 37 页，没署名。雨声贴着书页。可以凑近读——",
            "hotspots": {
              "read_front": {
                "label": "读信的正面",
                "once": "开头写：「如果你看到这封，说明我终于敢写了。」落款空着，可那句话你越读越耳熟。",
                "again": "还是那句话。你假装那是别人的心事。",
                "curatorOnce": "「别人的事，你倒肯认真。」他轻笑，没戳破。",
                "unlocks": {"id": "c_letter", "text": "信是写给「楼上一直没搬走的人」，从未寄出"},
                "settlement": {"title": "信，是你写的", "body": "你把信读完，落款没有名字，但那句开头的话，像你犹豫了很久没说出口的。", "gained": "线索：信是写给「楼上一直没搬走的人」，从未寄出"}
              },
              "back_stain": {
                "label": "翻到背面：咖啡渍下压着一行极小的字",
                "once": "翻到背面，咖啡渍晕开处压着一行极小的字：「别怕，是我。」——你以为是别人写的。",
                "again": "那行字还在。你假装没看见。",
                "unlocks": {"id": "c_stain", "text": "信背面极小的字：别怕，是我（伏笔）"},
                "settlement": {"title": "一行没署名的字", "body": "你发现了信背面的字，但没深想。有些温柔，总是迟到又匿名。", "gained": "线索：信背面极小的字「别怕，是我」"}
              }
            }
          }
        },
        "ink_blur": {
          "label": "借书卡边缘的墨团（词：下次）",
          "once": "借书卡边缘被人反复描过一个词：下次。你想凑近看看。",
          "again": "那个「下次」还在。你想凑近看看。",
          "closeup": {
            "stage": "借书卡从书里滑出来。边缘被人反复描过一个词，墨迹一圈圈发亮。",
            "hotspots": {
              "trace_next": {
                "label": "用手指描那个「下次」",
                "once": "你跟着那道墨迹描了一遍「下次」。一笔一画，像在跟自己保证什么。",
                "again": "你又描了一遍。墨迹叠着墨迹。",
                "curatorOnce": "「他总说下次。」管理员低头，「下次，下次，就逾期到现在。」",
                "unlocks": {"id": "c_next", "text": "借书卡边缘被反复描过「下次」——你一直在对自己说下次"},
                "settlement": {"title": "你描了一遍「下次」", "body": "那个词被你描得发亮。你忽然意识到，说「下次」的人，是你自己。", "gained": "线索：借书卡边缘被反复描过「下次」"}
              },
              "card_back": {
                "label": "翻到借书卡背面",
                "once": "背面是一串还书记录，最后一栏空着，墨迹还没干。",
                "again": "最后一栏还是空的。",
                "unlocks": {"id": "c_cardback", "text": "借书卡背面最后一栏空着，墨迹未干（伏笔）"}
              }
            }
          }
        },
        "umbrella_share": {
          "label": "另一本书里也夹着一把伞",
          "once": "另一本书里夹着一把伞——和你忘在门廊那把一样。不同的书，相同的伞。",
          "curatorOnce": "「忘带伞的人，不止你一个。」",
          "unlocks": {"id": "c_umb2", "text": "不同的「别人」的书里，都夹着同一把伞"}
        }
      }
    },
    "study_zone": {
      "name": "自习学习区",
      "metaphor": "静音自习位——管理员留灯仪式的落点（机制④）",
      "desc": "一排自习桌空着。有一盏灯的位置，像一直有人替你留着。",
      "exits": [
        {"label": "回阅览区", "to": "reading_room"}
      ],
      "hotspots": {}
    },
    "utility_zone": {
      "name": "便民配套区",
      "metaphor": "别人遗落物的集散地——失物招领/储物柜/打印复印（decoy 容器）",
      "desc": "门厅旁的配套区。失物招领箱、储物柜、打印复印机都在这。很多别人忘带的东西。",
      "exits": [
        {"label": "回服务台", "to": "service_desk"}
      ],
      "hotspots": {}
    },
    "lounge_stairs": {
      "name": "管理员区①·休息室/背后楼梯",
      "metaphor": "管理员的来处（夜D 解锁）",
      "desc": "门半掩着。楼梯通向馆员休息室，还不到时候进去。",
      "locked": True,
      "exits": [
        {"label": "回服务台", "to": "service_desk"}
      ],
      "hotspots": {}
    },
    "archive_lamp": {
      "name": "管理员区②·档案室/灯控室",
      "metaphor": "灯光与档案的源头（夜D/H 解锁）",
      "desc": "灯控室。整座馆的灯从这来。门锁着。",
      "locked": True,
      "exits": [
        {"label": "回服务台", "to": "service_desk"}
      ],
      "hotspots": {}
    },
    "void_room": {
      "name": "（第9空间）",
      "metaphor": "管理员的来处 / 灯光的源头——永不开启",
      "desc": "门虚掩着，推不开。",
      "void": True,
      "exits": [],
      "hotspots": {}
    }
  },
  "nodes": {
    "notice": {
      "stage": "逾期通知 · 午夜送达\n\n{name}的《夏天》已逾期。请于今夜闭馆前归还。\n逾期不息，灯不灭。\n\n—— 一张你从没借过的书，为什么是你的名字。",
      "actions": [
        {"id": "read", "label": "弯腰捡起，读完整张通知", "primary": True},
        {"id": "toss", "label": "先揉成一团——最后还是展平了"}
      ]
    },
    "enter": {
      "stage": "雨在馆外下。推门时，白噪音被木门切断，只剩雨声从门缝漏进来。灯还亮着。管理员在柜台后，没抬头：「又来了。」TA 把一盏台灯往你这边挪了挪，像是给一个熟客留的位置。",
      "actions": [
        {"id": "desk", "label": "走近柜台", "primary": True},
        {"id": "door", "label": "先在门口站一会儿，听雨"}
      ]
    }
  },
  "reveal": {
    "requiresClues": [
      "c_letter",
      "c_name"
    ],
    "stage": "灯下你把碎片拼完：信是你写的，写给楼上那个一直没搬走的人——一个你暗恋过、却从没敢搭话的邻居。日期是你不记得的一天。它从未寄出，也从未被还。你松了口气，像帮一个陌生人，轻轻合上了他迟到了很多年的心事。\n\n（灯还亮着。你没觉得那笔迹眼熟得过分。）",
    "actions": [
      {
        "id": "to_ending",
        "label": "合上书，做最后的决定 ▶",
        "primary": True
      }
    ]
  },
  "ending": {
    "defaultStage": "现在你知道了：《夏天》该回到它那一格，你也想起那封没寄出的信。要怎么处置它，是你自己的事了。",
    "defaultActions": [
      {"id": "end:return", "label": "归还 · 放回它该在的那一格", "primary": True},
      {"id": "end:take", "label": "带走 · 悄悄塞进外套内袋"},
      {"id": "end:burn", "label": "销毁 · 在灯下一页页撕碎"}
    ],
    "endings": {
      "return": "你把《夏天》放回它该在的那一格。屏幕安静地亮起「已归还」。这次，它没有再回来。你松了手。",
      "take": "你把它塞进外套内袋。走出馆门时雨还在下，书贴着心口，有点沉，也有点暖。",
      "burn": "你在灯下把它一页页撕开，丢进还书台旁的碎纸口。碎片落下去时，像一声很轻的叹气。"
    }
  },
  "companion": {
    "enter:notice": "（通知单从门缝塞进来，像往常一样。）",
    "enter:enter": "「又来了。」他没抬头，把一盏台灯往你这边挪了挪。",
    "enter:service_desk": "「台面刚擦过。」他指了指那摞书，「这本，压得最久。」",
    "enter:reading_room": "「你总坐那边的位子。」他说，像在说一件理所当然的事。",
    "enter:stacks_deep": "「漏雨那处，我接了盆。」他指了指地上，「还没补。」",
    "enter:entry_porch": "「门廊留着你的伞。」他站在柜台后，没跟出来。",
    "hot:stacks_deep:letter": "「别人的事，你倒肯认真。」他轻笑，没戳破。"
  },
  "memories": {
    "m_forgot": "被遗忘的事：你写过一封没寄出的信，收信人是你一直没敢联系的人"
  }
}

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print("wrote", OUT)
