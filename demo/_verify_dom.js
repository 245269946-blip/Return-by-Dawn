// 用极简 DOM 桩在 Node 里跑单文件 HTML 的引擎逻辑（不依赖浏览器）
const fs = require('fs');
const file = 'C:\\Users\\Administrator\\WorkBuddy\\20260709093909\\overdue-book\\demo\\overdue-book-night-a.html';
const html = fs.readFileSync(file, 'utf8');

// 抽取两个 script：NIGHT_DATA 字面量 + 引擎 IIFE
const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(m => m[1]);
if (scripts.length < 2) { console.error('FAIL: script 数量不足', scripts.length); process.exit(1); }

// 简易 DOM 桩
const store = {};
function mkEl() {
  return {
    _html: '', set innerHTML(v){ this._html = v; }, get innerHTML(){ return this._html; },
    textContent: '', disabled:false,
    getAttribute(){ return null; }, closest(){ return null; },
  };
}
const els = {}; ['stage','puzzle','actions','clues','memories','companion','region-map','title-bar']
  .forEach(id => els[id] = mkEl());

global.document = {
  getElementById: (id) => els[id] || (els[id] = mkEl()),
  addEventListener: () => {},
};
global.window = global;
global.localStorage = {
  _d:{}, getItem(k){ return this._d[k] ?? null; },
  setItem(k,v){ this._d[k]=v; }, removeItem(k){ delete this._d[k]; },
};

// 逐个执行 script（第一个是 NIGHT_DATA，第二个是引擎）
for (const s of scripts) {
  try { (0, eval)(s); }
  catch (e) { console.error('FAIL: 脚本执行抛错 ->', e.message); console.error(e.stack); process.exit(1); }
}

const G = global.Game, N = global.NIGHT_DATA;
if (!G || !N) { console.error('FAIL: Game 或 NIGHT_DATA 未定义'); process.exit(1); }
console.log('OK: 引擎与数据已加载, night id =', N.id);

// 模拟玩家路径：借台看通知单 -> 便签 truth -> 书库深处看信 -> reveal -> ending return
G.start(N, 'new');
G.act('read');                 // notice -> enter
G.act('desk');                // enter -> hub(借台)
G.act('hot:borrowing_desk:notice_card');  // 解锁 c_name
console.log('线索(通知单后):', Object.keys(G.state.clues));
G.act('pz:truth');          // 便签钩子 truth -> 解锁 c_note
console.log('线索(便签后):', Object.keys(G.state.clues));
G.act('goto:stacks_deep'); // 去书库深处
G.act('hot:stacks_deep:letter'); // 解锁 c_letter
console.log('线索(看信后):', Object.keys(G.state.clues));
// reveal 门控
const okGate = N.reveal.requiresClues.every(c => G.state.clues[c]);
if (!okGate) { console.error('FAIL: reveal 门控未解锁'); process.exit(1); }
G.act('to_reveal');          // 进入 reveal 并解锁记忆
console.log('记忆:', Object.keys(G.state.memories), '->', G.state.memories.m_forgot ? '已解锁' : '未解锁');
G.act('to_ending');         // reveal -> ending
G.act('end:return');        // 选归还结局
if (!G.state.endingText || !G.state.endingText.includes('已归还')) {
  console.error('FAIL: 结局文案未正确落位'); process.exit(1);
}
console.log('结局文案:', G.state.endingText.slice(0, 24), '...');
console.log('\n=== 单文件 HTML 在 Node 模拟 DOM 下完整跑通，可交付 ===');
