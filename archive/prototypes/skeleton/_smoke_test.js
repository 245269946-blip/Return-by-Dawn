// 无头冒烟测试：验证三件套（点击探索 + 区域切换 + 对话系统）数据流转
const path = require('path');
require('./engine/engine.js');           // 设置 globalThis.Game
require('./content/nights/night_a.js');  // 设置 globalThis.NIGHT

const Game = globalThis.Game;
const NIGHT = globalThis.NIGHT;

let pass = 0, fail = 0;
function ok(cond, msg) { if (cond) { pass++; } else { fail++; console.log('  ✗ ' + msg); } }

Game.start(NIGHT);
const S = Game.state;
ok(S.node === 'notice', '启动在 notice');

// ① 通知 → 进入
Game.act('read');
ok(S.node === 'enter', '读通知后进入 enter');

// ② 进入 → 区域图
Game.act('desk');
ok(S.node === 'hub', '走近柜台后到 hub（区域图）');

// ③ 区域切换：点区域卡进入区域内
Game.act('goto:reading_room');
ok(S.node === 'region' && S.currentRegion === 'reading_room', '点区域卡进入阅览区');

// ④ 点击探索：旧灯 marquee + 管理员追问
Game.act('hot:reading_room:old_lamp');
ok(S.examining && S.examining.hot === 'old_lamp', '查看旧灯');
ok(S.curator === '「因为以前有人怕黑。」', '旧灯首次管理员反应正确');
ok(S.clues.c_lamp, '旧灯解锁线索 c_lamp');
Game.act('ask:reading_room:old_lamp');
ok(S.curator === '忘了。', '追问「谁？」→ 管理员「忘了。」');
ok(S.examining.asked === true, '追问后标记 asked');

// 再看一次旧灯应显示 again 文本与管理员 again 反应
// （浏览器中 render 会标记 examined；无头下手动模拟该标记）
S.examined['reading_room:old_lamp'] = true;
Game.act('hot:reading_room:old_lamp');
ok(S.curator === '「……忘了。」其实他说的是自己。', '旧灯 again 管理员反应');

// ⑤ 区域切换：去借阅台，做便签状态钩子
Game.act('goto:borrowing_desk');
Game.act('hot:borrowing_desk:drawer_note');
S._puzzleCtx = 'hook:borrowing_desk:drawer_note'; // 浏览器由 renderHook 设定
const r = Game.submitPuzzle('truth');
ok(r.ok && S.hookResult.drawer_note, '便签写真话 → 物证形态已记录');
ok(S.clues.c_note, '便签钩子解锁线索 c_note');
ok(S.curator.indexOf('替你收着') >= 0, '便签钩子管理员反应（收着真心）');

// ⑥ 书库深处：核心 decoy 信 + 墨团 + 伞
Game.act('goto:stacks_deep');
Game.act('hot:stacks_deep:letter');
ok(S.clues.c_letter, '信解锁线索 c_letter（decoy）');
Game.act('hot:stacks_deep:ink_blur');
ok(S.clues.c_next, '墨团「下次」解锁');
Game.act('hot:stacks_deep:umbrella_share');
ok(S.clues.c_umb2, '别人书里的伞解锁');

// ⑦ 借阅台：通知卡（解锁收束门槛）
Game.act('goto:borrowing_desk');
Game.act('hot:borrowing_desk:notice_card');
ok(S.clues.c_name, '通知卡解锁 c_name');

// ⑧ 区域图底部「走到灯下」应在线索齐备后可用
Game.act('hub');
const acts = NIGHT.regionMapActions(S);
const toReveal = acts.find(a => a.id === 'to_reveal');
ok(toReveal && !toReveal.disabled, '线索齐备后「走到灯下」可用');

// ⑨ 收束 → 结局三选一
Game.act('to_reveal');
ok(S.node === 'reveal' && S.memories.m_forgot, 'reveal 点亮记忆');
Game.act('to_ending');
ok(S.node === 'ending', '到 ending');
Game.act('end:return');
ok(S.choice === 'return' && S.endingText.indexOf('已归还') >= 0, '归还结局落地');

console.log('\n三件套冒烟测试结果：通过 ' + pass + ' / 失败 ' + fail);
process.exit(fail ? 1 : 0);
