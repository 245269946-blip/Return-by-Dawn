// 《逾期之书》网页验收壳 —— 薄壳引擎（v3，JSON 驱动）
// 设计纪律（见 skeleton/SCHEMA.md）：
//   ① 本文件不背任何内容逻辑，只解释同一份 night_a.json（与 Godot Main.gd 共读）
//   ② 禁止 night.act() / night.checkPuzzle() / night.regionMapActions() 这类内容侧漂移
//   ③ 所有规则（区域图 / 热点 / 便签钩子 / reveal 门控）都由引擎按 JSON 字段解释
//   ④ 状态字段名与 Godot Main.gd 完全一致（见 SChEMA §8）
// 用途：浏览器开 index.html，验收「框架与功能完整度」，不挑机器。

(function (global) {
  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  const SAVE_KEY = 'overdue-book:save';

  const Game = {
    night: null,
    state: null,
    name: '阿迟',
    els: {},

    // ---- 存档（与 Godot _on_save 字段一一对应）----
    save() {
      if (typeof localStorage === 'undefined') return false;
      try {
        const s = this.state;
        const data = {
          night: this.night ? this.night.id : null,
          node: s.node,
          currentRegion: s.currentRegion,
          clues: s.clues,
          memories: s.memories,
          visitedHot: s.visitedHot,
          examined: s.examined,
          hookChosenLine: s.hookChosenLine,
          asking: s.asking,
          endingText: s.endingText,
          ts: Date.now(),
        };
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
      return {
        node: 'notice',
        currentRegion: '',
        clues: {},
        memories: {},
        visitedHot: {},
        examined: {},
        hookChosenLine: {},
        asking: {},
        curator: '',
        endingText: '',
      };
    },

    // ---- 启动：mode 'continue' | 'new' | undefined(自动) ----
    start(night, mode) {
      this.night = night;
      this.name = night.playerName || '阿迟';
      if (typeof document !== 'undefined') {
        this.cache();
        this.bind();
      }
      const canContinue = this.hasSave();
      if (mode === 'continue' && canContinue) {
        this.load();
      } else if (mode === 'new') {
        this.state = this._freshState();
        this.clearSave();
      } else if (canContinue) {
        this.state = this._freshState();
        this._showTitle();
        return;
      } else {
        this.state = this._freshState();
      }
      // 进入节点时触发一次管理员反应
      if (this.state.node !== 'hub' && this.state.node !== 'region') {
        this._companion('enter:' + this.state.node);
      } else if (this.state.node === 'region' && this.state.currentRegion) {
        this._companion('enter:' + this.state.currentRegion);
      }
      this.render();
    },

    _showTitle() {
      const el = this.els.stage;
      if (!el) return;
      el.innerHTML =
        '<div class="title-screen">' +
          '<p class="title-line">《逾期之书》· ' + esc(this.night.title || '夜 A') + '</p>' +
          '<p class="title-sub">检测到上次未走完的一夜。</p>' +
          '<div class="title-actions">' +
            '<button class="btn primary" data-act="__continue">继续上次 ▶</button>' +
            '<button class="btn" data-act="__newgame">从头开始 ↺</button>' +
          '</div>' +
        '</div>';
      this.els.actions.innerHTML = '';
      this.els.puzzle.innerHTML = '';
      this.els.regionMap.innerHTML = '';
      this.renderClues();
      this.renderMemories();
      this.renderCompanion();
      this._renderTitleBar();
    },

    _renderTitleBar() {
      const el = this.els.titleBar;
      if (!el) return;
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
        hint.textContent = ok
          ? '（进度已存 · ' + new Date().toLocaleTimeString('zh-CN', {hour:'2-digit',minute:'2-digit'}) + '）'
          : '（当前环境无法存档）';
        setTimeout(() => { if (hint) hint.textContent = ''; }, 2500);
      }
      this._renderTitleBar();
    },

    _autoSave() {
      if (this.state.node === 'notice' && !this.state.currentRegion && Object.keys(this.state.clues).length === 0) return;
      this.save();
    },

    // ---- 管理员常驻反应层（系统事件，纯 JSON 驱动）----
    _companion(event) {
      const comp = this.night.companion;
      let text = null;
      if (comp && comp[event]) text = comp[event];
      if (text) {
        this.state.curator = text;
        this.state.curatorShown = true;
      }
    },

    companion(text) {
      if (text) { this.state.curator = text; this.state.curatorShown = true; }
    },

    // ---- 动作分发（只认 JSON 字段，不调 night.act）----
    act(id) {
      if (id.startsWith('goto:')) {
        const rid = id.slice(5);
        this.state.currentRegion = rid;
        this.state.node = 'region';
        this._companion('enter:' + rid);
        this.render();
        return;
      }
      if (id.startsWith('hot:')) {
        const parts = id.slice(4).split(':');
        const rid = parts[0], hid = parts[1];
        const key = rid + ':' + hid;
        const first = !this.state.examined[key];
        this.state.examining = { region: rid, hot: hid };
        const hot = this._hot(rid, hid);

        // 钩子已选过：互斥，只复述不重提交
        if (hot && hot.hook && this.state.hookChosenLine[hid]) {
          this.companion(this.state.hookChosenLine[hid]);
          this.render();
          return;
        }

        // 解锁线索
        if (hot && hot.unlocks) {
          const u = hot.unlocks;
          if (u.id) this.state.clues[u.id] = u.text;
        }
        // 管理员反应
        if (hot && (hot.curatorOnce || hot.curatorAgain)) {
          const line = (first ? hot.curatorOnce : (hot.curatorAgain || hot.curatorOnce));
          if (line) this.companion(line);
        } else {
          this._companion('hot:' + rid + ':' + hid);
        }
        this.state.examined[key] = true;
        this.state.visitedHot[key] = true;
        this.render();
        return;
      }
      if (id.startsWith('ask:')) {
        const ex = this.state.examining;
        const rid = ex ? ex.region : null;
        const hid = ex ? ex.hot : null;
        const hot = rid ? this._hot(rid, hid) : null;
        if (hot && hot.ask) {
          this.companion(hot.ask.then || '……');
          this.state.asking[rid + ':' + hid] = true;
        }
        this.render();
        return;
      }
      // 内容节点动作（notice/enter/reveal/ending 的 actions[].id）
      this._nodeAction(id);
      this._autoSave();
      this.render();
    },

    _nodeAction(id) {
      const s = this.state;
      switch (id) {
        case 'read':
        case 'toss':
          s.node = 'enter'; break;
        case 'desk':
        case 'door':
          s.node = 'hub'; s.currentRegion = 'borrowing_desk'; break;
        case 'to_reveal':
          s.node = 'reveal'; this._unlockMemories(); break;
        case 'to_ending':
          s.node = 'ending'; break;
        case 'end:return':
        case 'end:take':
        case 'end:burn': {
          const key = id.slice(4);
          s.endingText = this.night.ending.endings[key] || '';
          s.node = 'ending';
          break;
        }
        case 'restart':
          this.clearSave();
          this.start(this.night, 'new');
          return;
      }
    },

    _unlockMemories() {
      const mem = this.night.memories;
      if (mem) for (const k in mem) this.state.memories[k] = mem[k];
    },

    _hot(region, hotId) {
      const r = this.night.regions && this.night.regions[region];
      if (!r || !r.hotspots) return null;
      return r.hotspots[hotId] || null;
    },

    // ---- 便签钩子三选一（互斥，只产一个 clue）----
    _onHookChoice(optId) {
      const ex = this.state.examining;
      if (!ex) return;
      const hot = this._hot(ex.region, ex.hot);
      if (!hot || !hot.hook) return;
      const res = hot.hookResults && hot.hookResults[optId];
      if (!res) return;
      this.state.hookChosenLine[ex.hot] = res.line || '';
      if (res.clue && res.clue.id) this.state.clues[res.clue.id] = res.clue.text;
      this.companion(res.line || '');
      this.state.node = 'region';
      this._autoSave();
      this.render();
    },

    // ---- 渲染调度 ----
    render() {
      if (typeof document === 'undefined') return;
      const node = this.state.node;
      if (node === 'hub') return this.renderRegionMap();
      if (node === 'region') return this.renderRegionInterior();
      return this.renderContentNode(node);
    },

    renderContentNode(node) {
      const nodes = this.night.nodes;
      if (!nodes || !nodes[node]) return;
      const nd = nodes[node];
      const fill = (s) => (s == null ? '' : String(s).split('{name}').join(this.name));
      this.els.stage.innerHTML = '<div class="content-node">' + esc(fill(nd.stage)) + '</div>';
      this.els.actions.innerHTML = (nd.actions || []).map((b) =>
        '<button class="btn ' + (b.primary ? 'primary' : '') + '" data-act="' + esc(b.id) + '">' + esc(b.label) + '</button>'
      ).join('');
      this.els.puzzle.innerHTML = '';
      this.els.regionMap.innerHTML = '';
      this._companion('enter:' + node);
      if (node === 'ending') this.companion('（这是你自己的事了。）');
      this.renderClues();
      this.renderMemories();
      this.renderCompanion();
    },

    renderRegionMap() {
      const regions = this.night.regions || {};
      const self = this;
      const cards = Object.keys(regions).map((rid) => {
        const r = regions[rid];
        const meta = r.metaphor ? '<div class="region-meta">' + esc(r.metaphor) + '</div>' : '';
        return '<div class="region-card" data-act="goto:' + rid + '">' +
          '<div class="region-name">' + esc(r.name) + '</div>' + meta + '</div>';
      }).join('');
      this.els.stage.innerHTML =
        '<p class="hub-hint">馆里很静。雨声贴着玻璃。你可以去各处看看——' +
        '每一处都摊着一点关于这本书的线索，拼齐了，才知道它该回哪儿。</p>' +
        '<div class="region-grid">' + cards + '</div>';
      this.els.actions.innerHTML = '<button class="btn" data-act="goto:borrowing_desk">进入所选区域 ▶</button>';
      this.els.puzzle.innerHTML = '';
      this.els.regionMap.innerHTML = '';
      this.renderClues();
      this.renderMemories();
      this.renderCompanion();
    },

    renderRegionInterior() {
      const rid = this.state.currentRegion;
      const r = this.night.regions[rid];
      const self = this;
      if (!r) { this.els.stage.innerHTML = '<p class="narration">这里什么都没有。</p>'; return; }

      let html = '<h3 class="scene-name">' + esc(r.name) + '</h3>';
      if (r.metaphor) html += '<div class="region-meta">' + esc(r.metaphor) + '</div>';
      html += '<p class="narration">' + esc(r.desc || '') + '</p>';

      // 正在查看的物件 → 焦点阅读
      if (this.state.examining && this.state.examining.region === rid) {
        const hot = this._hot(rid, this.state.examining.hot);
        if (hot) {
          const key = rid + ':' + hot.id;
          const first = !this.state.examined[key];
          const line = (first ? hot.once : (hot.again || hot.once)) || '';
          html += '<div class="examine"><div class="examine-line">' + esc(line) + '</div>';
          if (hot.ask && !this.state.asking[key]) {
            html += '<button class="btn ghost small" data-act="ask:' + rid + ':' + hot.id + '">' + esc(hot.ask.prompt) + '</button>';
          }
          html += '<button class="btn ghost small" data-act="close">收起来</button></div>';
        }
      }

      // 物件列表
      const hots = Object.keys(r.hotspots || {}).map((hid) => {
        const h = r.hotspots[hid];
        const seen = self.state.visitedHot[rid + ':' + hid];
        const mark = seen ? ' <span class="seen-mark">✓</span>' : '';
        return '<button class="btn hot' + (h.hook ? ' hook' : '') + '" data-act="hot:' + rid + ':' + hid + '">' +
          esc(h.label) + mark + '</button>';
      }).join('');
      if (hots) html += '<div class="hotspot-row">' + hots + '</div>';

      // 出口通道
      const exits = (r.exits || []).map((e) =>
        '<button class="btn exit" data-act="goto:' + e.to + '">' + esc(e.label) + ' →</button>'
      ).join('');
      if (exits) html += '<div class="exits">' + exits + '</div>';

      // reveal 门控（引擎按 requiresClues 自动检测，回归引擎层）
      const revealBtn = this._revealButton();
      if (revealBtn) html += '<div class="reveal-gate">' + revealBtn + '</div>';

      this.els.stage.innerHTML = html;
      this.els.actions.innerHTML = '<button class="btn" data-act="hub">回到区域图 ▶</button>';

      // 便签钩子面板
      const hot = this.state.examining ? this._hot(rid, this.state.examining.hot) : null;
      if (hot && hot.hook) {
        this.els.puzzle.innerHTML = this._renderHook(hot);
      } else {
        this.els.puzzle.innerHTML = '';
      }

      this.renderClues();
      this.renderMemories();
      this.renderCompanion();
      this.els.regionMap.innerHTML = '';
    },

    _revealButton() {
      const rv = this.night.reveal;
      if (!rv || !rv.requiresClues) return '';
      const ok = rv.requiresClues.every((cid) => this.state.clues[cid]);
      if (!ok) return '';
      return '<button class="btn primary" data-act="to_reveal">（碎片已凑齐）拼合那一夜 ▶</button>';
    },

    _renderHook(hot) {
      const prompt = hot.hookPrompt || '你要写点什么吗？';
      let html = '<div class="pz"><p class="pz-prompt">' + esc(prompt) + '</p>';
      html += (hot.options || []).map((o) =>
        '<button class="btn" data-act="pz:' + esc(o.id) + '">' + esc(o.label) + '</button>'
      ).join('');
      html += '<button class="btn ghost small" data-act="goto:' + this.state.currentRegion + '">（什么都不写，退回去）</button>';
      html += '</div>';
      return html;
    },

    renderClues() {
      const el = this.els.clues;
      if (!el) return;
      const ids = Object.keys(this.state.clues);
      if (!ids.length) { el.innerHTML = '<div class="panel-title">线索（空）</div>'; return; }
      el.innerHTML = '<div class="panel-title">线索</div>' +
        ids.map((id) => '<div class="panel-item">· ' + esc(this.state.clues[id]) + '</div>').join('');
    },

    renderMemories() {
      const el = this.els.memories;
      if (!el) return;
      const ids = Object.keys(this.state.memories);
      if (!ids.length) { el.innerHTML = '<div class="panel-title">记忆（空）</div>'; return; }
      el.innerHTML = '<div class="panel-title">记忆</div>' +
        ids.map((id) => '<div class="panel-item">· ' + esc(this.state.memories[id]) + '</div>').join('');
    },

    renderCompanion() {
      const el = this.els.companion;
      if (!el) return;
      const text = this.state.curator;
      if (!text) { el.innerHTML = '<span class="companion-name">管理员</span><span class="companion-line dim">（在柜台后，没抬头）</span>'; return; }
      el.innerHTML = '<span class="companion-name">管理员</span><span class="companion-line">' + esc(text) + '</span>';
    },
  };

  global.Game = Game;
  if (typeof module !== 'undefined' && module.exports) module.exports = Game;
})(typeof window !== 'undefined' ? window : globalThis);
