// 校验单文件 HTML：抽取 NIGHT_DATA 字面量做 JSON.parse，并确认无外部 fetch 依赖
const fs = require('fs');
const file = 'C:\\Users\\Administrator\\WorkBuddy\\20260709093909\\overdue-book\\demo\\overdue-book-night-a.html';
const html = fs.readFileSync(file, 'utf8');

// 取出 const NIGHT_DATA = 与下一个顶层 </script> 之间的内容
const start = html.indexOf('const NIGHT_DATA = ');
if (start < 0) { console.error('FAIL: 未找到 NIGHT_DATA'); process.exit(1); }
const after = html.slice(start + 'const NIGHT_DATA = '.length);
// 第一个 </script> 之前结束（字面量内不含 </script> 字符串）
const end = after.indexOf('</script>');
if (end < 0) { console.error('FAIL: 未找到闭合 script'); process.exit(1); }
let jsonText = after.slice(0, end).trim();
// 去掉末尾可能的分号
if (jsonText.endsWith(';')) jsonText = jsonText.slice(0, -1);

let data;
try { data = JSON.parse(jsonText); }
catch (e) { console.error('FAIL: JSON.parse 失败 ->', e.message); process.exit(1); }

console.log('OK: NIGHT_DATA 解析成功, id =', data.id, '| 区域数 =', Object.keys(data.regions).length);

// 无外部 fetch 依赖
if (/fetch\(\s*['"]\.\./.test(html)) { console.error('FAIL: 仍存在外部 fetch 依赖'); process.exit(1); }
console.log('OK: 无外部 fetch 依赖（真·单文件）');

// 关键字段
for (const k of ['reveal','ending','memories','companion','nodes']) {
  if (!(k in data)) { console.error('FAIL: 缺字段', k); process.exit(1); }
}
if (!data.reveal.requiresClues.includes('c_letter') || !data.reveal.requiresClues.includes('c_name')) {
  console.error('FAIL: reveal.requiresClues 不对'); process.exit(1);
}
console.log('OK: reveal 门控 requiresClues =', JSON.stringify(data.reveal.requiresClues));

// 便签钩子三分支
const hook = data.regions.borrowing_desk.hotspots.drawer_note;
for (const o of ['truth','safe','none']) {
  if (!hook.hookResults[o]) { console.error('FAIL: 缺钩子分支', o); process.exit(1); }
}
console.log('OK: 便签钩子三分支齐全（truth/safe/none）');

// 模拟玩家路径
const s = { node:'notice', currentRegion:'', clues:{}, memories:{}, visitedHot:{}, examined:{}, hookChosenLine:{}, asking:{}, curator:'', endingText:'' };
s.node='enter'; s.node='hub'; s.currentRegion='borrowing_desk';
const notice = data.regions.borrowing_desk.hotspots.notice_card;
s.clues[notice.unlocks.id] = notice.unlocks.text;
const res = hook.hookResults.truth; s.clues[res.clue.id]=res.clue.text; s.hookChosenLine['drawer_note']=res.line;
s.currentRegion='stacks_deep';
const letter = data.regions.stacks_deep.hotspots.letter;
s.clues[letter.unlocks.id]=letter.unlocks.text;
const ok = data.reveal.requiresClues.every(cid => s.clues[cid]);
if (!ok) { console.error('FAIL: reveal 门控未解锁'); process.exit(1); }
s.node='reveal'; for (const k in data.memories) s.memories[k]=data.memories[k];
s.node='ending'; s.endingText=data.ending.endings['return'];
console.log('OK: 玩家路径跑通 ->', JSON.stringify({clues:Object.keys(s.clues), hasMemo:Object.keys(s.memories).length>0, ending:s.endingText.slice(0,18)}));
console.log('\n=== 单文件校验全部通过，可交付 ===');
