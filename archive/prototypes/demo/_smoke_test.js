// 无头冒烟测试（薄壳 v3 + Godot 同一份 night_a.json）
// 直接用 fs 读 Godot 的 content/night_a.json，验证：
//   主链 notice→enter→hub→region→reveal→ending 全通
//   热点 / 追问 / 便签钩子互斥 / reveal 门控（引擎层）
//   存档：退出再进能恢复区域、线索、便签选择、已看热点
//
// 运行：node _smoke_test.js   （在 demo/ 目录下）

const fs = require('fs');
const path = require('path');

// 内存版 localStorage（无头环境）
const store = {};
global.localStorage = {
  getItem: (k) => (k in store ? store[k] : null),
  setItem: (k, v) => { store[k] = String(v); },
  removeItem: (k) => { delete store[k]; },
};

require('./engine.js'); // 设置 globalThis.Game

// 直接读 Godot 正式线同一份地基
const jsonPath = path.join(__dirname, '..', 'godot', 'content', 'night_a.json');
const NIGHT = JSON.parse(fs.readFileSync(jsonPath, 'utf-8'));

const Game = globalThis.Game;

let pass = 0, fail = 0;
function ok(cond, msg) { if (cond) { pass++; } else { fail++; console.log('  ✗ ' + msg); } }

// ---- 启动 ----
Game.start(NIGHT);
const S = Game.state;
ok(S.node === 'notice', '启动在 notice');

// ---- notice → enter ----
Game.act('read');
ok(S.node === 'enter', '读通知后进入 enter');

// ---- enter → hub（区域图）----
Game.act('desk');
ok(S.node === 'hub', '走近柜台后到 hub（区域图）');

// ---- 进入阅览区 ----
Game.act('goto:reading_room');
ok(S.node === 'region' && S.currentRegion === 'reading_room', '点区域卡进入阅览区');

// ---- 旧灯：首次 + 解锁 + 追问 ----
Game.act('hot:reading_room:old_lamp');
ok(S.examining && S.examining.hot === 'old_lamp', '查看旧灯');
ok(S.curator === '「因为以前有人怕黑。」', '旧灯首次管理员反应');
ok(S.clues.c_lamp, '旧灯解锁 c_lamp');
Game.act('ask:reading_room:old_lamp');
ok(S.curator === '忘了。', '追问「谁？」→ 管理员「忘了。」');
ok(S.asking['reading_room:old_lamp'] === true, '追问后标记 asking');

// ---- 便签钩子（三选一互斥）----
Game.act('goto:borrowing_desk');
Game.act('hot:borrowing_desk:drawer_note');
ok(S.examining && S.examining.hot === 'drawer_note', '打开便签钩子');
Game._onHookChoice('truth');
ok(S.clues.c_note, '便签写真话解锁 c_note');
ok(S.curator.indexOf('替你收着') >= 0, '便签钩子管理员反应（收着真心）');

// 二次点击便签：互斥，只复述不重提交
Game.act('hot:borrowing_desk:drawer_note');
const noteKeys = Object.keys(S.clues).filter(k => k === 'c_note');
ok(noteKeys.length === 1, '便签二次点击被互斥拦截（仍只有一条 c_note）');
ok(S.hookChosenLine['drawer_note'] && S.hookChosenLine['drawer_note'].indexOf('抽屉最上层') >= 0, '便签复述保持首次选择（truth）');

// ---- 书库深处：核心 decoy 信 + 墨团 + 伞 ----
Game.act('goto:stacks_deep');
Game.act('hot:stacks_deep:letter');
ok(S.clues.c_letter, '信解锁 c_letter（主链关键）');
Game.act('hot:stacks_deep:ink_blur');
ok(S.clues.c_next, '墨团「下次」解锁');
Game.act('hot:stacks_deep:umbrella_share');
ok(S.clues.c_umb2, '别人书里的伞解锁');

// ---- 借阅台：通知卡（主链另一关键）----
Game.act('goto:borrowing_desk');
Game.act('hot:borrowing_desk:notice_card');
ok(S.clues.c_name, '通知卡解锁 c_name（主链关键）');

// ---- reveal 门控（引擎层自动检测 requiresClues）----
Game.act('hub');
ok(Game._revealButton().indexOf('拼合那一夜') >= 0, '双线索齐备后引擎出现「拼合那一夜」');
// 缺一个关键 clue 时不应出现
delete S.clues.c_letter;
Game.act('hub');
ok(Game._revealButton() === '', '缺 c_letter 时引擎不出现 reveal 按钮（门控）');
S.clues.c_letter = '信是写给「楼上一直没搬走的人」，从未寄出'; // 复原

// ---- reveal → ending 三选一 ----
Game.act('goto:stacks_deep'); // 任意回区域再回 hub 以刷新按钮
Game.act('hub');
Game.act('to_reveal');
ok(S.node === 'reveal' && S.memories.m_forgot, 'reveal 点亮记忆');
Game.act('to_ending');
ok(S.node === 'ending', '到 ending');
Game.act('end:return');
ok(S.endingText && S.endingText.indexOf('已归还') >= 0, '归还结局落地');
Game.act('end:take');
ok(S.endingText.indexOf('外套内袋') >= 0, '带走结局落地');
Game.act('end:burn');
ok(S.endingText.indexOf('撕开') >= 0, '销毁结局落地');

// ---- 存档 B 验证 ----
console.log('\n[存档 B] 主链跑通，开始验证存档恢复……');
Game.start(NIGHT, 'new'); // 清档重开
const S2 = Game.state;
S2.node = 'region';
S2.currentRegion = 'stacks_deep';
S2.clues = { c_letter: 'X', c_name: 'Y' };
S2.visitedHot = { 'stacks_deep:letter': true, 'borrowing_desk:notice_card': true };
S2.examined = { 'stacks_deep:letter': true };
S2.hookChosenLine = { drawer_note: '「这句……我替你收着。」他把它压在抽屉最上层。' };
S2.endingText = '';
Game.save();
ok(Game.hasSave(), 'save 后 hasSave() 为真');

// 模拟「退出再进」：重新 start（自动模式应进标题屏）
Game.start(NIGHT);
ok(Game.state.node === 'notice' && !Game.state.currentRegion, '有存档时自动停在标题屏（等用户选继续）');

Game.start(NIGHT, 'continue');
const R = Game.state;
ok(R.node === 'region' && R.currentRegion === 'stacks_deep', '继续后恢复区域位置');
ok(R.clues.c_letter === 'X' && R.clues.c_name === 'Y', '继续后恢复线索');
ok(R.visitedHot['stacks_deep:letter'] === true, '继续后恢复已看热点');
ok(R.examined['stacks_deep:letter'] === true, '继续后恢复 examined（once/again 不重置）');
ok(R.hookChosenLine['drawer_note'] && R.hookChosenLine['drawer_note'].indexOf('抽屉最上层') >= 0, '继续后恢复便签选择文案');

console.log('\n主链 + 存档 B 测试结果：通过 ' + pass + ' / 失败 ' + fail);
process.exit(fail ? 1 : 0);
