// 《逾期之书》内容自洽校验：检查 reveal 所需线索是否都能被产出、出口是否指向真实区域。
const fs = require('fs');
const path = require('path');
const file = path.join(__dirname, '..', 'content', 'night_a.json');
const data = JSON.parse(fs.readFileSync(file, 'utf8'));
let errors = [];

// 收集所有 hotspot.unlocks.id 与 hookResults.clue.id
const produced = new Set();
for (const rid in data.regions) {
  const region = data.regions[rid];
  for (const hid in region.hotspots) {
    const h = region.hotspots[hid];
    if (h.unlocks && h.unlocks.id) produced.add(h.unlocks.id);
    if (h.hookResults) {
      for (const k in h.hookResults) {
        const r = h.hookResults[k];
        if (r.clue && r.clue.id) produced.add(r.clue.id);
      }
    }
  }
}

// 检查 reveal.requiresClues 是否都能被产出
const reveal = data.nodes && data.nodes.reveal;
if (reveal && reveal.requiresClues) {
  for (const cid of reveal.requiresClues) {
    if (!produced.has(cid)) errors.push('reveal 需要线索 ' + cid + ' 但没有任何 hotspot 产出它');
  }
}

// 检查 exit.to 指向存在的区域
for (const rid in data.regions) {
  const region = data.regions[rid];
  for (const e of region.exits) {
    if (!data.regions[e.to]) errors.push('区域 ' + rid + ' 的出口指向不存在的区域 ' + e.to);
  }
}

if (errors.length) {
  console.error('内容校验失败：');
  errors.forEach(e => console.error('  - ' + e));
  process.exit(1);
} else {
  console.log('内容校验通过：夜 A 数据自洽（' + produced.size + ' 条线索可达，出口无死路）');
}
