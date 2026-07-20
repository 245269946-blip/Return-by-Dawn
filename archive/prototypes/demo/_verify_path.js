// 静态验收脚本：用与浏览器相同的 engine.js + night_a.json 跑完整路径
// 不依赖浏览器，Node 直接 require engine.js 并喂入 JSON
const fs = require('fs');
const path = require('path');

// 载入引擎（engine.js 末尾 module.exports = Game）
const Game = require('./engine.js');
const night = JSON.parse(fs.readFileSync('../godot/content/night_a.json', 'utf8'));

const log = [];
function step(label, fn) {
  fn();
  log.push('─ ' + label);
  log.push('  node=' + Game.state.node + ' region=' + (Game.state.currentRegion||'-'));
  log.push('  clues=[' + Object.keys(Game.state.clues).join(',') + ']');
  if (Object.keys(Game.state.memories).length)
    log.push('  memories=[' + Object.keys(Game.state.memories).join(',') + ']');
  if (Game.state.endingText) log.push('  endingText(len)=' + Game.state.endingText.length);
}

// 模拟 beforeunload 自动存档用不到，这里手动控制
Game.night = night;
Game.name = night.playerName || '阿迟';
Game.state = Game._freshState();

// 1. 开场
step('开场 notice', () => { Game.state.node = 'notice'; });
// 2. 读通知 → enter
step('读通知 read', () => Game.act('read'));
// 3. 走近柜台 → hub（借阅台）
step('走近柜台 desk', () => Game.act('desk'));
// 4. 借阅台热点：逾期单解锁 c_name，便签钩子
step('借阅台·逾期通知单', () => Game.act('hot:borrowing_desk:notice_card'));
step('借阅台·便签钩子(选 truth)', () => {
  // 先点开便签进入钩子面板
  Game.state.examining = { region:'borrowing_desk', hot:'drawer_note' };
  Game._onHookChoice('truth');
});
// 5. 去书库深处拿 c_letter
step('去书库深处', () => Game.act('goto:stacks_deep'));
step('书库·夹在书里的信', () => Game.act('hot:stacks_deep:letter'));
// 6. 现在 clues 应有 c_name + c_letter → reveal 按钮应出现
const revealOk = (function(){
  const rv = night.reveal;
  return rv.requiresClues.every(cid => Game.state.clues[cid]);
})();
log.push('─ reveal 门控检测: ' + (revealOk ? '通过（双 clue 齐）' : '未通过'));
// 7. 进入 reveal
step('拼合那一夜 to_reveal', () => Game.act('to_reveal'));
// 8. 到 ending
step('合上书 to_ending', () => Game.act('to_ending'));
// 9. 选 return 结局
step('结局·归还 end:return', () => Game.act('end:return'));

// 检查 reveal 按钮是否真被渲染（模拟 renderRegionInterior 内的 _revealButton）
const rvBtn = (function(){
  const rv = night.reveal;
  if (!rv || !rv.requiresClues) return '';
  const ok = rv.requiresClues.every(cid => Game.state.clues[cid]);
  return ok ? '<reveal button>' : '';
})();

console.log(log.join('\n'));
console.log('\n=== 最终校验 ===');
console.log('reveal 按钮渲染检测: ' + (rvBtn ? 'OK 出现' : '未出现（异常！）'));
console.log('endingText 内容首句: ' + (Game.state.endingText||'(空)').slice(0,40) + '…');
console.log('总线索数: ' + Object.keys(Game.state.clues).length);
console.log('记忆解锁: ' + (Object.keys(Game.state.memories).length ? '是' : '否'));
