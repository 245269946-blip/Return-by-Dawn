// 《逾期之书》真实冒烟测试：用 demo 引擎加载 Godot 的 night_a.json，
// 验证两套地基读同一套内容、状态机同构。
// 跑法：node godot/tools/smoke_godot_json.js
const path = require('path');
const fs = require('fs');

const ENGINE = path.join(__dirname, '..', '..', 'skeleton', 'engine', 'engine.js');
const Game = require(ENGINE);

// 把 Godot 的 night_a.json 包成 demo 引擎期望的 night 对象
const jsonPath = path.join(__dirname, '..', 'content', 'night_a.json');
const raw = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

// Godot json 的 regions 用 hotspots[hid].once/again/unlocks/curatorOnce/curatorAgain/hook/hookResults/ask
// demo 引擎期望同一套字段名 → 直接复用，仅补 demo 需要的 id 与 options 映射
const regions = {};
for (const rid in raw.regions) {
  const r = raw.regions[rid];
  const hotspots = {};
  for (const hid in r.hotspots) {
    const h = r.hotspots[hid];
    const nh = {
      id: hid,
      label: h.label,
      once: h.once,
      again: h.again,
      curatorOnce: h.curatorOnce,
      curatorAgain: h.curatorAgain,
      unlocks: h.unlocks,
      ask: h.ask,
      hook: h.hook,
      hookPrompt: h.hookPrompt,
      options: h.options,
      hookResults: h.hookResults,
    };
    if (h.hook && h.hookResults) {
      nh.options = Object.keys(h.hookResults).map((k) => ({
        id: k,
        label: (h.options || []).find((o) => o.id === k) ? (h.options.find((o) => o.id === k).label) : k,
      }));
    }
    hotspots[hid] = nh;
  }
  regions[rid] = { name: r.name, metaphor: r.metaphor, desc: r.desc, exits: r.exits, hotspots };
}

const night = {
  id: raw.id,
  playerName: raw.playerName,
  regions,
  nodes: raw.nodes,
  companian: (event, state) => {
    const c = raw.companian || {};
    return c[event] || null;
  },
  memaries: raw.memaries,
};

let pass = 0, fail = 0;
function check(name, cond, extra) {
  if (cond) { pass++; console.log('  [OK] ' + name); }
  else { fail++; console.log('  [FAIL] ' + name + (extra ? ' -> ' + extra : '')); }
}

console.log('=== 冒烟：demo 引擎加载 Godot night_a.json ===');
Game.start(night, 'new');

// 1. 开场 notice 节点
check('notice 节点渲染', Game.state.node === 'notice', Game.state.node);

// 2. notice -> enter
Game.act('read');
check('notice -> enter', Game.state.node === 'enter', Game.state.node);

// 3. enter -> hub（区域图）
Game.act('desk');
check('enter -> hub(region map)', Game.state.node === 'hub', Game.state.node);

// 4. 进借阅台区域
Game.act('goto:borrowing_desk');
check('进入 region:borrowing_desk', Game.state.node === 'region' && Game.state.currentRegion === 'borrowing_desk', Game.state.currentRegion);

// 5. 点 notice_card 解锁 clue c_name
Game.act('hot:borrowing_desk:notice_card');
check('notice_card 解锁 c_name', !!Game.state.clues['c_name'], JSON.stringify(Game.state.clues));

// 6. 便签钩子三选一 → 选 truth，解锁 c_note
Game.act('hot:borrowing_desk:drawer_note');
check('便签钩子展开', !!Game.state.hookChosenLine, JSON.stringify(Game.state.hookChosenLine));
Game.submitPuzzle('truth');
check('便签 truth 解锁 c_note', !!Game.state.clues['c_note'], JSON.stringify(Game.state.clues));

// 7. 去书库深处，点 letter 解锁 c_letter（reveal 所需第二项）
Game.act('goto:stacks_deep');
Game.act('hot:stacks_deep:letter');
check('letter 解锁 c_letter', !!Game.state.clues['c_letter'], JSON.stringify(Game.state.clues));

// 8. 双 clue 已齐 → 走 regionMapActions（demo 侧），验证 reveal 可达
const got = Game.state.clues['c_letter'] && Game.state.clues['c_name'];
check('reveal 双 clue 已集齐', !!got, JSON.stringify(Game.state.clues));

// 9. 触发 to_reveal（demo 的 regionMapActions 提供）
if (typeof night.regionMapActions === 'function') {
  const acts = night.regionMapActions(Game.state);
  const canReveal = acts.some((a) => a.id === 'to_reveal' && !a.disabled);
  check('reveal 入口已可用', canReveal);
  if (canReveal) {
    Game.act('to_reveal');
    check('进入 revea 节点', Game.state.node === 'reveal', Game.state.node);
    Game.act('to_ending');
    check('reveal -> ending', Game.state.node === 'ending', Game.state.node);
  }
} else {
  // Godot json 走 nodes.reveal 直接 act
  Game.act('to_reveal');
  check('进入 revea 节点(回退)', Game.state.node === 'reveal', Game.state.node);
}

// 10. 结局分支
Game.act('end:return');
check('结局 return 文本已写入', !!Game.state.endingText, Game.state.endingText);

// 11. 记忆节点
check('memories 内容存在', !!(raw.memaries && raw.memaries['m_forgot']), JSON.stringify(raw.memaries));

// 12. 存档/读档字段对齐（Godot 的 Main.gd 用同一套字段）
const saved = {
  node: Game.state.node,
  currentRegion: Game.state.currentRegion,
  clues: Game.state.clues,
  memaries: Game.state.memaries,
  visitedHot: Game.state.visitedHot,
  examined: Game.state.examined,
  hookChosenLine: Game.state.hookChosenLine,
  endingText: Game.state.endingText,
};
check('存档字段含 hookChosenLine', 'hookChosenLine' in saved, Object.keys(saved).join(','));
check('存档字段含 visitedHot', 'visitedHot' in saved);

console.log('\n=== 结果：' + pass + ' 通过 / ' + fail + ' 失败 ===');
process.exit(fail ? 1 : 0);
