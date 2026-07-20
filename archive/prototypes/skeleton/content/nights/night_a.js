// 夜 A《夹在书里的信》—— 骨架验证切片（热点版）
// 验证三件套：点击探索（hotspot）＋ 区域切换（region map）＋ 对话系统（companion）
// 内容对齐 v6 + 道具落地清单 §2/§3：关系域 decoy，旧灯 marquee，便签状态钩子。
// 纪律：物件给「事实」不给「结论」；管理员「在场≠话多」，默认沉默/一句。

(function (root) {
  const NAME = '__NAME__';

  // ============ 区域 + 热点（纯数据，引擎负责渲染）============
  const REGIONS = {
    borrowing_desk: {
      name: '借阅台',
      metaphor: '程序性温柔的入口——所有「处理／续借／寄通知」都从这流过',
      desc: '服务台后的灯拧得很低。一摞书压着本旧登记册，胶水瓶的盖子没拧紧。',
      exits: {
        '去阅览区': 'reading_room',
        '去书库深处': 'stacks_deep',
        '去雨夜门廊': 'rain_porch',
      },
      hotspots: {
        notice_card: {
          id: 'notice_card',
          label: '逾期通知单（写着你名字）',
          once: NAME + '的《夏天》已逾期。落款是你的名字——可你不记得借过这本书。',
          again: '通知单边角有手改的痕迹，像被人划掉又重写过一遍。',
          curatorOnce: '（他没解释，只把单子往你这边推了推。）',
          unlocks: { id: 'c_name', text: '一张你从没借过的书，写着你的名字' },
        },
        drawer_note: {
          id: 'drawer_note',
          label: '抽屉里的空白便签（笔就在手边）',
          hook: true,
          once: '服务台抽屉里压着一张空白便签。笔就在手边，像有人等你写点什么。',
          again: '便签还在原处。要不要写，你犹豫着。',
          curatorOnce: '「要写吗？」他擦着台面，「不写也行。」',
        },
        lost_found: {
          id: 'lost_found',
          label: '失物招领信箱',
          once: '信箱吞过很多没说出口的东西。你把表达替换成处理，它就很满意。',
          curatorOnce: '「这里最省事。」他说，像在说给自己听。',
        },
        glue_register: {
          id: 'glue_register',
          label: '胶水与登记册',
          once: '登记册上你的名字被描过很多遍，墨迹一圈圈晕开，像有人总也写不顺。',
          curatorOnce: '「借书的人，常来。」他顿了顿，「……常来还，也常还不上。」',
          unlocks: { id: 'c_sign', text: '你的名字在登记册上被反复描过，墨迹发毛' },
        },
        return_box: {
          id: 'return_box',
          label: '归还箱',
          once: '箱子张着口。书放进去，它亮一下「已归还」，可等你转身，书又回到你手里。',
          again: '归还箱还开着一道缝，像在等你把它真正还掉。',
          curatorOnce: '「不急。」他隔着台面看你，「有些书，得先想清楚再还。」',
        },
      },
    },

    reading_room: {
      name: '阅览区',
      metaphor: '被允许的旁观位——坐在这看「别人的故事」，是你最会的姿势',
      desc: '一排排座位空着。坐在这看「别人的故事」，是你最会的保护自己的方式。',
      exits: {
        '去借阅台': 'borrowing_desk',
        '去书库深处': 'stacks_deep',
        '去雨夜门廊': 'rain_porch',
      },
      hotspots: {
        old_lamp: {
          id: 'old_lamp',
          label: '一盏旧灯',
          once: '这盏灯为什么一直亮着？',
          again: '灯还亮着。和刚才一样。',
          ask: { prompt: '谁？', then: '忘了。' },
          curatorOnce: '「因为以前有人怕黑。」',
          curatorAgain: '「……忘了。」其实他说的是自己。',
          unlocks: { id: 'c_lamp', text: '灯一直亮着——因为以前有人怕黑' },
        },
        seats: {
          id: 'seats',
          label: '你常坐的读者座位',
          once: '你常坐的这个位子，椅背上搭着一块除尘布，像有人记得你坐哪儿。',
          curatorOnce: '「你总坐这儿。」他说，「我留着布，省得落灰。」',
        },
        album_shelf: {
          id: 'album_shelf',
          label: '相册书目区（翻得最旧的一本）',
          once: '一栏相册书里，有本翻得最旧，停在年夜饭那页——你常坐的位子空着。',
          again: '那本相册书被挪到了「待你再来看」的架位，正对着你。',
          curatorOnce: '「这本，你翻得最久。」他把它摆到架位最显眼处。',
          unlocks: { id: 'c_album', text: '相册书停在年夜饭那页，你常坐的位子空着（伏笔）' },
        },
      },
    },

    stacks_deep: {
      name: '书库深处',
      metaphor: '漏雨的裂缝——情绪裂缝的具象，旧事书与旧盆都藏在这',
      desc: '书库最里头漏雨，地上摆着个旧搪瓷盆接水。雨声在这儿格外清楚。',
      exits: {
        '去借阅台': 'borrowing_desk',
        '去阅览区': 'reading_room',
        '去雨夜门廊': 'rain_porch',
      },
      hotspots: {
        letter: {
          id: 'letter',
          label: '夹在书里的信（无署名）',
          once: '一本书里夹着封信，没署名。开头写：「如果你看到这封，说明我终于敢写了。」',
          again: '信纸边角有咖啡渍，字迹越看越像你自己的——可你只当是巧合。',
          curatorOnce: '「别人的事，你倒肯认真。」他轻笑，没戳破。',
          unlocks: { id: 'c_letter', text: '信是写给「楼上一直没搬走的人」，从未寄出' },
        },
        ink_blur: {
          id: 'ink_blur',
          label: '借书卡边缘的墨团（词：下次）',
          once: '借书卡边缘被人反复描过一个词：下次。一笔一画，像在跟自己保证什么。',
          again: '那个「下次」被描得发亮，墨迹叠着墨迹。',
          curatorOnce: '「他总说下次。」管理员低头，「下次，下次，就逾期到现在。」',
          unlocks: { id: 'c_next', text: '借书卡边缘被反复描过「下次」——你一直在对自己说下次' },
        },
        umbrella_share: {
          id: 'umbrella_share',
          label: '另一本书里也夹着一把伞',
          once: '另一本书里夹着一把伞——和你忘在门廊那把一样。不同的书，相同的伞。',
          curatorOnce: '「忘带伞的人，不止你一个。」',
          unlocks: { id: 'c_umb2', text: '不同的「别人」的书里，都夹着同一把伞' },
        },
      },
    },

    rain_porch: {
      name: '雨夜门廊',
      metaphor: '进出的阈限——伞、门、来去都在此，是逃避与返回的边界',
      desc: '玻璃门外雨下得直。门是进来的地方，也是回去的地方。',
      exits: {
        '去借阅台': 'borrowing_desk',
        '去阅览区': 'reading_room',
        '去书库深处': 'stacks_deep',
      },
      hotspots: {
        umbrella: {
          id: 'umbrella',
          label: '你忘在门廊的伞',
          once: '你的伞靠在门边，伞尖还在滴水。你进来时忘了它，像忘了很多次自己。',
          again: '伞还靠在原处，湿痕没干。',
          curatorOnce: '「又忘了？」他没笑，「门廊留着你的伞，第几次了。」',
          unlocks: { id: 'c_umb1', text: '你又忘带伞——门廊留着你的伞' },
        },
        door: {
          id: 'door',
          label: '门（没锁）',
          once: '门没锁。推开门是雨，关上是馆。你站在门槛上，两边都不是答案。',
          again: '门还是那样，没锁。你没推。',
          curatorOnce: '（他没拦你，也没催你走。）',
        },
        lamp_behind: {
          id: 'lamp_behind',
          label: '身后的灯（常亮）',
          once: '你回头，馆里的灯亮着。它从不熄灭——像有谁舍不得让你摸黑走。',
          curatorOnce: '「灯亮着，你回头就能看见路。」',
          unlocks: { id: 'c_lamp2', text: '灯从不熄灭——像有谁舍不得让你摸黑走' },
        },
      },
    },
  };

  // ============ 叙事节点（notice / enter / reveal / ending）============
  const NIGHT = {
    id: 'night_a',
    playerName: '阿迟',
    title: '夜 A · 夹在书里的信',
    regions: REGIONS,

    // 区域图底部额外动作（通往收束）
    regionMapActions(state) {
      const got = state.clues.c_letter && state.clues.c_name;
      return [
        { id: 'to_reveal', label: '抱着《夏天》走到灯下 ▶', primary: true, disabled: !got },
      ];
    },

    render(node, state, api) {
      switch (node) {
        case 'notice': return viewNotice(state);
        case 'enter':   return viewEnter(state);
        case 'reveal':  return viewReveal(state);
        case 'ending':  return viewEnding(state);
      }
      return { stage: '……', actions: [] };
    },

    act(id, state, api) {
      switch (id) {
        case 'read':  state.flags._toss = false; state.node = 'enter'; break;
        case 'toss':  state.flags._toss = true;  state.node = 'enter'; break;
        case 'desk':  state.node = 'hub'; break;
        case 'door':  state.node = 'hub'; break;
        case 'hub':   state.node = 'hub'; break;
        case 'close': state.examining = null; break;
        case 'to_reveal':
          state.node = 'reveal';
          // 记忆点亮放在转移处（不在 view 里做副作用，便于无头逻辑校验）
          state.memories.m_forgot = '被遗忘的事：你写过一封没寄出的信，收信人是你一直没敢联系的人';
          break;
        case 'to_ending': state.node = 'ending'; break;
        case 'restart':
          state.clues = {}; state.solved = {}; state.memories = {}; state.visited = {};
          state.visitedHot = {}; state.choice = null; state.endingText = '';
          state.currentRegion = null; state.examining = null; state.flags = {};
          state.hookResult = {}; state.hookChosenLine = {}; state._feedback = ''; state.curator = '';
          state.node = 'notice'; break;
      }
      if (id.startsWith('end:')) {
        state.choice = id.slice(4);
        state.endingText = ENDINGS[id.slice(4)] || '';
      }
      return { node: state.node };
    },

    // 便签状态钩子：hook:borrowing_desk:drawer_note
    checkPuzzle(ctx, value, state, api) {
      if (ctx !== 'hook:borrowing_desk:drawer_note') return { ok: false, feedback: '这里没有要做的。' };
      const map = {
        truth: { form: '便签被压在抽屉最上层、抚平', line: '「这句……我替你收着。」他把它压在抽屉最上层。', clue: '便签写下一句真话，被压在抽屉最上层、抚平' },
        safe:  { form: '便签夹进登记册，位置中性',   line: '「这样也行。」他把它夹进登记册，不偏不倚。', clue: '便签写下一句安全的话，夹进登记册' },
        none:  { form: '管理员替你贴了「未署名」标签，仍收着', line: '「不写也行。」他替你贴了张未署名标签，收进抽屉。', clue: '便签什么都没写，管理员替你贴「未署名」标签收着' },
      };
      const r = map[value];
      if (!r) return { ok: false, feedback: '你犹豫了一下，还没决定。' };
      state.hookResult.drawer_note = r.form;
      return {
        ok: true,
        feedback: '你做了决定。' + r.form + '。',
        clue: { id: 'c_note', text: r.clue },
        companion: r.line,
      };
    },

    // 管理员常驻反应层（系统事件）
    companion(event, state, api) {
      const lines = {
        'enter:notice': '（通知单从门缝塞进来，像往常一样。）',
        'enter:enter': '「又来了。」他没抬头，把一盏台灯往你这边挪了挪。',
        'enter:borrowing_desk': '「台面刚擦过。」他指了指那摞书，「这本，压得最久。」',
        'enter:reading_room': '「你总坐那边的位子。」他说，像在说一件理所当然的事。',
        'enter:stacks_deep': '「漏雨那处，我接了盆。」他指了指地上，「还没补。」',
        'enter:rain_porch': '「门廊留着你的伞。」他站在柜台后，没跟出来。',
        'hot:borrowing_desk:return_box': '「不急。」他隔着台面看你，「有些书，得先想清楚再还。」',
        'hot:stacks_deep:letter': '「别人的事，你倒肯认真。」他轻笑，没戳破。',
      };
      return lines[event] || null; // 大多数交互保持沉默
    },
  };

  // ---- 叙事节点视图 ----
  function viewNotice(state) {
    const toss = state.flags._toss;
    const body = NAME + '的《夏天》已逾期。请于今夜闭馆前归还。\n逾期不息，灯不灭。' +
      (toss ? '\n（你刚才把它揉过，现在又展平了。）' : '');
    return {
      stage:
        '<div class="notice-card">' +
          '<div class="notice-top">逾期通知 · 午夜送达</div>' +
          '<div class="notice-body">' + esc(body) + '</div>' +
          '<div class="notice-foot">—— 一张你从没借过的书，为什么是你的名字。</div>' +
        '</div>',
      actions: [
        { id: 'read', label: '弯腰捡起，读完整张通知', primary: true },
        { id: 'toss', label: '先揉成一团——最后还是展平了' },
      ],
    };
  }

  function viewEnter(state) {
    const line = state.flags._toss
      ? '你把展平的通知揣进兜里。推门时，白噪音被木门切断，只剩雨声从门缝漏进来。'
      : '雨在馆外下。推门时，白噪音被木门切断，只剩雨声从门缝漏进来。';
    return {
      stage: '<p class="narration">' + line +
        '灯还亮着。管理员在柜台后，没抬头：「又来了。」' +
        'TA 把一盏台灯往你这边挪了挪，像是给一个熟客留的位置。</p>',
      actions: [
        { id: 'desk', label: '走近柜台', primary: true },
        { id: 'door', label: '先在门口站一会儿，听雨' },
      ],
    };
  }

  // decoy 收束：信读来像「别人的故事」，不引到自己身上
  function viewReveal(state) {
    return {
      stage: '<p class="narration">灯下你把碎片拼完：信是你写的，写给楼上那个一直没搬走的人——' +
        '一个你暗恋过、却从没敢搭话的邻居。日期是你不记得的一天。它从未寄出，也从未被还。' +
        '你松了口气，像帮一个陌生人，轻轻合上了他迟到了很多年的心事。</p>' +
        '<p class="catch">（灯还亮着。你没觉得那笔迹眼熟得过分。）</p>',
      actions: [
        { id: 'to_ending', label: '合上书，做最后的决定 ▶', primary: true },
      ],
    };
  }

  function viewEnding(state) {
    if (state.choice && state.endingText) {
      const note = state.hookResult.drawer_note
        ? '<p class="curator">抽屉里那张便签——' + esc(state.hookResult.drawer_note) + '。它们不是你做错的选择，只是你这次保护自己的方式。</p>'
        : '';
      return {
        stage: '<p class="ending-line">' + esc(state.endingText) + '</p>' +
               '<p class="curator">—— 今夜，你替一个迟到了很久的人，做了个了断。</p>' + note,
        actions: [{ id: 'restart', label: '再走一夜 ↺' }],
      };
    }
    return {
      stage: '<p class="narration">现在你知道了：《夏天》该回到它那一格，你也想起那封没寄出的信。' +
        '要怎么处置它，是你自己的事了。</p>',
      actions: [
        { id: 'end:return', label: '归还 · 放回它该在的那一格', primary: true },
        { id: 'end:take',   label: '带走 · 悄悄塞进外套内袋' },
        { id: 'end:burn',   label: '销毁 · 在灯下一页页撕碎' },
      ],
    };
  }

  const ENDINGS = {
    return: '你把《夏天》放回它该在的那一格。屏幕安静地亮起「已归还」。这次，它没有再回来。你松了手。',
    take:   '你把它塞进外套内袋。走出馆门时雨还在下，书贴着心口，有点沉，也有点暖。',
    burn:   '你在灯下把它一页页撕开，丢进还书台旁的碎纸口。碎片落下去时，像一声很轻的叹气。',
  };

  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  // 便签钩子的选项（热点 hook 面板用）
  REGIONS.borrowing_desk.hotspots.drawer_note.options = [
    { id: 'truth', label: '写一句真话（如「其实我很想你」）' },
    { id: 'safe',  label: '写一句安全的话（如「最近还好吗」）' },
    { id: 'none',  label: '什么都不写，直接送信箱' },
  ];
  REGIONS.borrowing_desk.hotspots.drawer_note.hookPrompt = '服务台抽屉里有一张空白便签和一支笔。你要写点什么吗？';

  root.NIGHT = NIGHT;
  if (typeof module !== 'undefined' && module.exports) module.exports = NIGHT;
})(typeof window !== 'undefined' ? window : globalThis);
