// 用程序从原始地基 night_a.json 生成单文件 HTML，杜绝手写转义错误
const fs = require('fs');
const srcJson = 'C:\\Users\\Administrator\\WorkBuddy\\20260709093909\\overdue-book\\godot\\content\\night_a.json';
const out = 'C:\\Users\\Administrator\\WorkBuddy\\20260709093909\\overdue-book\\demo\\overdue-book-night-a.html';

const night = JSON.parse(fs.readFileSync(srcJson, 'utf8'));
// 用 JSON.stringify 得到合法转义字符串，嵌进 const NIGHT_DATA = <这里>;
const jsonLiteral = JSON.stringify(night); // 换行会变 \n，引号转义，安全

const style = `<style>
:root{
  --bg:#0d0f12; --panel:#16191f; --ink:#e9e3d6; --dim:#9a948a;
  --warm:#e8b06a; --line:#2a2f37; --paper:#cdbf9a;
}
*{box-sizing:border-box}
body{margin:0; background:var(--bg); color:var(--ink);
  font-family:"Noto Serif SC",serif; line-height:1.9; letter-spacing:.02em;}
.frame{max-width:880px; margin:40px auto; padding:0 20px}
.head{font-size:20px; color:var(--ink); border-bottom:1px solid var(--line); padding-bottom:14px; margin-bottom:22px}
.sub{color:var(--dim); font-size:14px; font-weight:400}
.layout{display:flex; gap:24px; align-items:flex-start}
.main{flex:1; min-width:0}
.side{width:210px; flex:none}
.stage{background:var(--panel); border:1px solid var(--line); border-radius:10px; padding:26px 28px; min-height:200px; font-size:16px;}
.narration{margin:0}
.scene-name{color:var(--warm); font-weight:600; font-size:15px; letter-spacing:.1em; margin:0 0 12px}
.hub-hint{color:var(--dim); font-style:italic; margin:0 0 16px}
.notice-card{background:#0a0c0f; border:1px dashed var(--paper); border-radius:8px; padding:22px; font-family:"SFMono-Regular",Consolas,monospace; color:var(--paper);}
.notice-top{font-size:12px; letter-spacing:.3em; color:var(--dim); margin-bottom:14px}
.notice-body{font-size:15px; line-height:2; white-space:pre-wrap}
.notice-foot{margin-top:16px; font-size:12px; color:var(--dim); text-align:right}
.puzzle{margin-top:16px; display:flex; flex-direction:column; gap:10px}
.pz{background:#11141a; border:1px solid var(--line); border-radius:8px; padding:16px 18px}
.pz-prompt{margin:0 0 12px; color:var(--ink); font-size:15px}
.pz-input{background:#0a0c0f; border:1px solid var(--line); color:var(--paper); border-radius:6px; padding:9px 12px; font-family:inherit; font-size:14px; min-width:200px;}
.pz-input:focus{outline:none; border-color:var(--warm)}
.pz-fb{margin:10px 0 0; color:var(--warm); font-style:italic; font-size:14px}
.pz-locked{color:var(--dim); font-style:italic; margin:0; font-size:14px}
.actions{margin-top:18px; display:flex; flex-wrap:wrap; gap:12px}
.btn{background:transparent; color:var(--ink); border:1px solid var(--line); border-radius:8px; padding:10px 18px; font-family:inherit; font-size:14px; cursor:pointer; transition:.2s;}
.btn:hover{border-color:var(--warm); color:var(--warm)}
.btn.primary{border-color:var(--warm); color:var(--warm)}
.btn.ghost{color:var(--dim)}
.btn:disabled{opacity:.4; cursor:default}
.catch{color:var(--warm); font-style:italic; margin-top:18px}
.curator{color:var(--dim); font-style:italic; margin:14px 0 0; font-size:14px}
.ending-line{color:var(--ink); font-size:17px; margin:0 0 10px}
.panel{background:var(--panel); border:1px solid var(--line); border-radius:10px; padding:16px; font-size:13px; margin-bottom:16px}
.panel-title{color:var(--dim); letter-spacing:.2em; margin-bottom:10px; font-size:11px}
.panel-item{color:var(--ink); padding:4px 0; border-top:1px solid var(--line); line-height:1.6}
.clock{color:var(--dim); font-size:12px; text-align:center; letter-spacing:.2em}
.title-bar{display:flex; align-items:center; gap:12px; min-height:20px; margin:-6px 0 16px; font-size:12px}
.btn.small{padding:6px 12px; font-size:12px}
.save-hint{color:var(--dim); font-style:italic}
.title-screen{padding:30px 4px; text-align:center}
.title-line{color:var(--warm); font-size:18px; letter-spacing:.08em; margin:0 0 10px}
.title-sub{color:var(--dim); font-size:14px; margin:0 0 22px}
.title-actions{display:flex; gap:14px; justify-content:center}
.companion{background:#11141a; border:1px solid var(--line); border-radius:8px; padding:12px 14px; font-size:14px; font-style:italic; color:var(--dim); margin-bottom:16px; min-height:18px}
.companion .companion-name{color:var(--warm); font-style:normal; margin-right:8px; font-size:12px; letter-spacing:.1em}
.companion .companion-line.dim{opacity:.7}
.region-grid{display:flex; flex-wrap:wrap; gap:12px}
.region-card{background:var(--panel); border:1px solid var(--line); border-radius:8px; padding:14px 16px; cursor:pointer; transition:.2s; min-width:150px}
.region-card:hover{border-color:var(--warm)}
.region-name{color:var(--warm); font-size:15px; margin-bottom:6px}
.region-meta{color:var(--dim); font-size:12px; font-style:italic}
.examine{margin-top:14px; background:#11141a; border:1px solid var(--line); border-radius:8px; padding:14px 16px}
.examine-line{color:var(--ink); font-size:15px; margin-bottom:10px}
.hotspot-row{display:flex; flex-wrap:wrap; gap:10px; margin-top:14px}
.btn.hot{text-align:left}
.btn.hot.hook{border-color:var(--paper); color:var(--paper)}
.seen-mark{color:var(--warm); margin-left:4px}
.exits{display:flex; flex-wrap:wrap; gap:10px; margin-top:14px}
.reveal-gate{margin-top:16px; padding-top:16px; border-top:1px dashed var(--line)}
</style>`;

const engine = `<script>
(function (global) {
  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
  const SAVE_KEY = 'overdue-book:save';
  const Game = {
    night: null, state: null, name: '阿迟', els: {},
    save() {
      if (typeof localStorage === 'undefined') return false;
      try {
        const s = this.state;
        const data = { night: this.night ? this.night.id : null, node: s.node,
          currentRegion: s.currentRegion, clues: s.clues, memories: s.memories,
          visitedHot: s.visitedHot, examined: s.examined, hookChosenLine: s.hookChosenLine,
          asking: s.asking, endingText: s.endingText, ts: Date.now() };
        localStorage.setItem(SAVE_KEY, JSON.stringify(data));
        return true;
      } catch (e) { console.warn('[save] 写入失败', e); return false; }
    },
    load() {
      if (typeof localStorage === 'undefined') return false;
      try {
        const raw = localStorage.getItem(SAVE_KEY);
        if (!raw) return false;
        const data = JSON.parse(raw);
        if (this.night && data.night && data.night !== this.night.id) return false;
        this.state = Object.assign(this._freshState(), data);
        return true;
      } catch (e) { return false; }
    },
    hasSave() {
      if (typeof localStorage === 'undefined') return false;
      try {
        const raw = localStorage.getItem(SAVE_KEY);
        if (!raw) return false;
        const data = JSON.parse(raw);
        if (this.night && data.night && data.night !== this.night.id) return false;
        return true;
      } catch (e) { return false; }
    },
    clearSave() {
      if (typeof localStorage === 'undefined') return;
      try { localStorage.removeItem(SAVE_KEY); } catch (e) {}
    },
    _freshState() {
      return { node:'notice', currentRegion:'', clues:{}, memories:{}, visitedHot:{},
        examined:{}, hookChosenLine:{}, asking:{}, curator:'', endingText:'' };
    },
    start(night, mode) {
      this.night = night; this.name = night.playerName || '阿迟';
      if (typeof document !== 'undefined') { this.cache(); this.bind(); }
      const canContinue = this.hasSave();
      if (mode === 'continue' && canContinue) { this.load(); }
      else if (mode === 'new') { this.state = this._freshState(); this.clearSave(); }
      else if (canContinue) { this.state = this._freshState(); this._showTitle(); return; }
      else { this.state = this._freshState(); }
      if (this.state.node !== 'hub' && this.state.node !== 'region') { this._companion('enter:' + this.state.node); }
      else if (this.state.node === 'region' && this.state.currentRegion) { this._companion('enter:' + this.state.currentRegion); }
      this.render();
    },
    _showTitle() {
      const el = this.els.stage; if (!el) return;
      el.innerHTML = '<div class="title-screen">' +
        '<p class="title-line">《逾期之书》· ' + esc(this.night.title || '夜 A') + '</p>' +
        '<p class="title-sub">检测到上次未走完的一夜。</p>' +
        '<div class="title-actions">' +
          '<button class="btn primary" data-act="__continue">继续上次 ▶</button>' +
          '<button class="btn" data-act="__newgame">从头开始 ↺</button>' +
        '</div></div>';
      this.els.actions.innerHTML = ''; this.els.puzzle.innerHTML = ''; this.els.regionMap.innerHTML = '';
      this.renderClues(); this.renderMemories(); this.renderCompanion(); this._renderTitleBar();
    },
    _renderTitleBar() {
      const el = this.els.titleBar; if (!el) return;
      el.innerHTML = '<button class="btn small ghost" data-act="__save">保存进度</button>' +
        '<span class="save-hint" id="save-hint"></span>';
    },
    cache() {
      this.els.stage = document.getElementById('stage');
      this.els.puzzle = document.getElementById('puzzle');
      this.els.actions = document.getElementById('actions');
      this.els.clues = document.getElementById('clues');
      this.els.memories = document.getElementById('memories');
      this.els.companion = document.getElementById('companion');
      this.els.regionMap = document.getElementById('region-map');
      this.els.titleBar = document.getElementById('title-bar');
    },
    bind() {
      document.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-act]');
        if (!btn || btn.disabled) return;
        const act = btn.getAttribute('data-act');
        if (act === '__continue') { this.start(this.night, 'continue'); return; }
        if (act === '__new_game') { this.clearSave(); this.start(this.night, 'new'); return; }
        if (act === '__save') { this._doSave(); return; }
        if (act.startsWith('pz:')) { this._onHookChoice(act.slice(3)); return; }
        this.act(act);
      });
    },
    _doSave() {
      const ok = this.save();
      const hint = document.getElementById('save-hint');
      if (hint) {
        hint.textContent = ok ? '（进度已存 · ' + new Date().toLocaleTimeString('zh-CN', {hour:'2-digit',minute:'2-digit'}) + '）' : '（当前环境无法存档）';
        setTimeout(() => { if (hint) hint.textContent = ''; }, 2500);
      }
      this._renderTitleBar();
    },
    _autoSave() {
      if (this.state.node === 'notice' && !this.state.currentRegion && Object.keys(this.state.clues).length === 0) return;
      this.save();
    },
    _companion(event) {
      const comp = this.night.companion; let text = null;
      if (comp && comp[event]) text = comp[event];
      if (text) { this.state.curator = text; this.state.curatorShown = true; }
    },
    companion(text) { if (text) { this.state.curator = text; this.state.curatorShown = true; } },
    act(id) {
      if (id.startsWith('goto:')) {
        const rid = id.slice(5); this.state.currentRegion = rid; this.state.node = 'region';
        this._companion('enter:' + rid); this.render(); return;
      }
      if (id.startsWith('hot:')) {
        const parts = id.slice(4).split(':');
        const rid = parts[0], hid = parts[1]; const key = rid + ':' + hid;
        const first = !this.state.examined[key];
        this.state.examining = { region: rid, hot: hid };
        const hot = this._hot(rid, hid);
        if (hot && hot.hook && this.state.hookChosenLine[hid]) { this.companion(this.state.hookChosenLine[hid]); this.render(); return; }
        if (hot && hot.unlocks) { const u = hot.unlocks; if (u.id) this.state.clues[u.id] = u.text; }
        if (hot && (hot.curatorOnce || hot.curatorAgain)) {
          const line = (first ? hot.curatorOnce : (hot.curatorAgain || hot.curatorOnce));
          if (line) this.companion(line);
        } else { this._companion('hot:' + rid + ':' + hid); }
        this.state.examined[key] = true; this.state.visitedHot[key] = true; this.render(); return;
      }
      if (id.startsWith('ask:')) {
        const ex = this.state.examining; const rid = ex ? ex.region : null; const hid = ex ? ex.hot : null;
        const hot = rid ? this._hot(rid, hid) : null;
        if (hot && hot.ask) { this.companion(hot.ask.then || '……'); this.state.asking[rid + ':' + hid] = true; }
        this.render(); return;
      }
      this._nodeAction(id); this._autoSave(); this.render();
    },
    _nodeAction(id) {
      const s = this.state;
      switch (id) {
        case 'read': case 'toss': s.node = 'enter'; break;
        case 'desk': case 'door': s.node = 'hub'; s.currentRegion = 'borrowing_desk'; break;
        case 'to_reveal': s.node = 'reveal'; this._unlockMemories(); break;
        case 'to_ending': s.node = 'ending'; break;
        case 'end:return': case 'end:take': case 'end:burn': {
          const key = id.slice(4); s.endingText = this.night.ending.endings[key] || ''; s.node = 'ending'; break;
        }
        case 'restart': this.clearSave(); this.start(this.night, 'new'); return;
      }
    },
    _unlockMemories() { const mem = this.night.memories; if (mem) for (const k in mem) this.state.memories[k] = mem[k]; },
    _hot(region, hotId) {
      const r = this.night.regions && this.night.regions[region];
      if (!r || !r.hotspots) return null; return r.hotspots[hotId] || null;
    },
    _onHookChoice(optId) {
      const ex = this.state.examining; if (!ex) return;
      const hot = this._hot(ex.region, ex.hot); if (!hot || !hot.hook) return;
      const res = hot.hookResults && hot.hookResults[optId]; if (!res) return;
      this.state.hookChosenLine[ex.hot] = res.line || '';
      if (res.clue && res.clue.id) this.state.clues[res.clue.id] = res.clue.text;
      this.companion(res.line || ''); this.state.node = 'region'; this._autoSave(); this.render();
    },
    render() {
      if (typeof document === 'undefined') return;
      const node = this.state.node;
      if (node === 'hub') return this.renderRegionMap();
      if (node === 'region') return this.renderRegionInterior();
      return this.renderContentNode(node);
    },
    renderContentNode(node) {
      const nodes = this.night.nodes; if (!nodes || !nodes[node]) return;
      const nd = nodes[node];
      const fill = (s) => (s == null ? '' : String(s).split('{name}').join(this.name));
      this.els.stage.innerHTML = '<div class="content-node">' + esc(fill(nd.stage)) + '</div>';
      this.els.actions.innerHTML = (nd.actions || []).map((b) =>
        '<button class="btn ' + (b.primary ? 'primary' : '') + '" data-act="' + esc(b.id) + '">' + esc(b.label) + '</button>').join('');
      this.els.puzzle.innerHTML = ''; this.els.regionMap.innerHTML = '';
      this._companion('enter:' + node);
      if (node === 'ending') this.companion('（这是你自己的事了。）');
      this.renderClues(); this.renderMemories(); this.renderCompanion();
    },
    renderRegionMap() {
      const regions = this.night.regions || {}; const self = this;
      const cards = Object.keys(regions).map((rid) => {
        const r = regions[rid];
        const meta = r.metaphor ? '<div class="region-meta">' + esc(r.metaphor) + '</div>' : '';
        return '<div class="region-card" data-act="goto:' + rid + '"><div class="region-name">' + esc(r.name) + '</div>' + meta + '</div>';
      }).join('');
      this.els.stage.innerHTML = '<p class="hub-hint">馆里很静。雨声贴着玻璃。你可以去各处看看——每一处都摊着一点关于这本书的线索，拼齐了，才知道它该回哪儿。</p><div class="region-grid">' + cards + '</div>';
      this.els.actions.innerHTML = '<button class="btn" data-act="goto:borrowing_desk">进入所选区域 ▶</button>';
      this.els.puzzle.innerHTML = ''; this.els.regionMap.innerHTML = '';
      this.renderClues(); this.renderMemories(); this.renderCompanion();
    },
    renderRegionInterior() {
      const rid = this.state.currentRegion; const r = this.night.regions[rid]; const self = this;
      if (!r) { this.els.stage.innerHTML = '<p class="narration">这里什么都没有。</p>'; return; }
      let html = '<h3 class="scene-name">' + esc(r.name) + '</h3>';
      if (r.metaphor) html += '<div class="region-meta">' + esc(r.metaphor) + '</div>';
      html += '<p class="narration">' + esc(r.desc || '') + '</p>';
      if (this.state.examining && this.state.examining.region === rid) {
        const hot = this._hot(rid, this.state.examining.hot);
        if (hot) {
          const key = rid + ':' + hot.id; const first = !this.state.examined[key];
          const line = (first ? hot.once : (hot.again || hot.once)) || '';
          html += '<div class="examine"><div class="examine-line">' + esc(line) + '</div>';
          if (hot.ask && !this.state.asking[key]) {
            html += '<button class="btn ghost small" data-act="ask:' + rid + ':' + hot.id + '">' + esc(hot.ask.prompt) + '</button>';
          }
          html += '<button class="btn ghost small" data-act="close">收起来</button></div>';
        }
      }
      const hots = Object.keys(r.hotspots || {}).map((hid) => {
        const h = r.hotspots[hid];
        const seen = self.state.visitedHot[rid + ':' + hid];
        const mark = seen ? ' <span class="seen-mark">✓</span>' : '';
        return '<button class="btn hot' + (h.hook ? ' hook' : '') + '" data-act="hot:' + rid + ':' + hid + '">' + esc(h.label) + mark + '</button>';
      }).join('');
      if (hots) html += '<div class="hotspot-row">' + hots + '</div>';
      const exits = (r.exits || []).map((e) => '<button class="btn exit" data-act="goto:' + e.to + '">' + esc(e.label) + ' →</button>').join('');
      if (exits) html += '<div class="exits">' + exits + '</div>';
      const revealBtn = this._revealButton();
      if (revealBtn) html += '<div class="reveal-gate">' + revealBtn + '</div>';
      this.els.stage.innerHTML = html;
      this.els.actions.innerHTML = '<button class="btn" data-act="hub">回到区域图 ▶</button>';
      const hot = this.state.examining ? this._hot(rid, this.state.examining.hot) : null;
      if (hot && hot.hook) { this.els.puzzle.innerHTML = this._renderHook(hot); } else { this.els.puzzle.innerHTML = ''; }
      this.renderClues(); this.renderMemories(); this.renderCompanion(); this.els.regionMap.innerHTML = '';
    },
    _revealButton() {
      const rv = this.night.reveal; if (!rv || !rv.requiresClues) return '';
      const ok = rv.requiresClues.every((cid) => this.state.clues[cid]);
      if (!ok) return '';
      return '<button class="btn primary" data-act="to_reveal">（碎片已凑齐）拼合那一夜 ▶</button>';
    },
    _renderHook(hot) {
      const prompt = hot.hookPrompt || '你要写点什么吗？';
      let html = '<div class="pz"><p class="pz-prompt">' + esc(prompt) + '</p>';
      html += (hot.options || []).map((o) => '<button class="btn" data-act="pz:' + esc(o.id) + '">' + esc(o.label) + '</button>').join('');
      html += '<button class="btn ghost small" data-act="goto:' + this.state.currentRegion + '">（什么都不写，退回去）</button></div>';
      return html;
    },
    renderClues() {
      const el = this.els.clues; if (!el) return;
      const ids = Object.keys(this.state.clues);
      if (!ids.length) { el.innerHTML = '<div class="panel-title">线索（空）</div>'; return; }
      el.innerHTML = '<div class="panel-title">线索</div>' + ids.map((id) => '<div class="panel-item">· ' + esc(this.state.clues[id]) + '</div>').join('');
    },
    renderMemories() {
      const el = this.els.memories; if (!el) return;
      const ids = Object.keys(this.state.memories);
      if (!ids.length) { el.innerHTML = '<div class="panel-title">记忆（空）</div>'; return; }
      el.innerHTML = '<div class="panel-title">记忆</div>' + ids.map((id) => '<div class="panel-item">· ' + esc(this.state.memories[id]) + '</div>').join('');
    },
    renderCompanion() {
      const el = this.els.companion; if (!el) return;
      const text = this.state.curator;
      if (!text) { el.innerHTML = '<span class="companion-name">管理员</span><span class="companion-line dim">（在柜台后，没抬头）</span>'; return; }
      el.innerHTML = '<span class="companion-name">管理员</span><span class="companion-line">' + esc(text) + '</span>';
    },
  };
  global.Game = Game;
  global.NIGHT_DATA = ${jsonLiteral};
  if (typeof window !== 'undefined') { Game.start(global.NIGHT_DATA); }
})(typeof window !== 'undefined' ? window : globalThis);
</script>`;

const html = `<!doctype html>
<html lang="zh">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>逾期之书 · 夜 A（单文件版）</title>
  ${style}
</head>
<body>
  <div class="frame">
    <div class="head">逾期之书 <span class="sub">· 夜 A《夹在书里的信》· 单文件验收壳（内联 Godot 同一份地基）</span></div>
    <div id="title-bar" class="title-bar"></div>
    <div class="layout">
      <div class="main">
        <div id="stage" class="stage"></div>
        <div id="puzzle" class="puzzle"></div>
        <div id="actions" class="actions"></div>
      </div>
      <aside class="side">
        <div id="clues" class="panel">线索（空）</div>
        <div id="memories" class="panel">记忆（空）</div>
        <div id="companion" class="companion"></div>
        <div class="clock">距天亮 · 还有很久</div>
      </aside>
    </div>
  </div>
  <script>const NIGHT_DATA = ${jsonLiteral};</script>
  ${engine}
</body>
</html>`;

fs.writeFileSync(out, html, 'utf8');
console.log('已生成单文件 HTML ->', out);
console.log('大小(bytes) =', Buffer.byteLength(html, 'utf8'));
console.log('含外部 fetch 依赖? ->', /fetch\(\s*['"]\.\./.test(html) ? '是(错误)' : '否(正确)');
