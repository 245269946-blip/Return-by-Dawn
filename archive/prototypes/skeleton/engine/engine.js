// 《逾期之书》通用引擎 v2 —— 骨架验证版（内容无关）
// 相较 M1 v0.9 新增三件套：
//   ① 点击探索（hotspot 层）：场景内多点可点，每件物件只给「一句话」，玩家脑补
//   ② 区域切换（region map）：把 hub 升级为「可点区域图 / 通道」，非按钮列表
//   ③ 对话系统（companion 层）：管理员常驻反应条——与锈湖最大区别，情绪核心是陪伴
// 内容模块只导出纯数据（regions / hotspots / narrative），引擎负责渲染成
// 热点层 / 区域图 / 对话条。加一夜 = 加一个 nights/*.js，零改引擎。
//
// 注：meta 层（背包 / 回溯 / 通知箱）本版只留接口（api.meta），不实现。

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

    // ---- 存档（B）：把当前进度写入 localStorage ----
    // 保留的字段 = 进程可见的全部状态（区域 / 线索 / 便签 / 热点 / 阶段 / 结局）
    save() {
      if (typeof localStorage === 'undefined') return false;
      try {
        const s = this.state;
        const data = {
          night: this.night ? this.night.id : null,
          node: s.node,
          clues: s.clues,
          solved: s.solved,
          memories: s.memories,
          visited: s.visited,
          visitedHot: s.visitedHot,
          examined: s.examined,
          choice: s.choice,
          endingText: s.endingText,
          currentRegion: s.currentRegion,
          examining: s.examining,
          curator: s.curator,
          hookResult: s.hookResult,
          flags: s.flags,
          ts: Date.now(),
        };
        localStorage.setItem(SAVE_KEY, JSON.stringify(data));
        return true;
      } catch (e) {
        console.warn('[save] 写入失败', e);
        return false;
      }
    },

    // ---- 读档：返回一个布尔，表示是否有可恢复的存档 ----
    load() {
      if (typeof localStorage === 'undefined') return false;
      try {
        const raw = localStorage.getItem(SAVE_KEY);
        if (!raw) return false;
        const data = JSON.parse(raw);
        // 只恢复同一夜的存档
        if (this.night && data.night && data.night !== this.night.id) return false;
        this.state = Object.assign(this._freshState(), data);
        return true;
      } catch (e) {
        console.warn('[load] 读取失败', e);
        return false;
      }
    },

    hasSave() {
      if (typeof localStorage === 'undefined') return false;
      try {
        const raw = localStorage.getItem(SAVE_KEY);
        if (!raw) return false;
        const data = JSON.parse(raw);
        if (this.night && data.night && data.night !== this.night.id) return false;
        // 已走到结局且做过选择，视为「一局已完」，不提示继续（但仍可重看）
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
        clues: {},
        solved: {},
        memories: {},
        visited: {},
        visitedHot: {},
        examined: {},
        choice: null,
        endingText: '',
        currentRegion: null,
        examining: null,
        curator: '',
        curatorShown: false,
        hookResult: {},
        hookChosenLine: {},     // 钩子已选后的复述文案：hotId -> line
        flags: {},
        _feedback: '',
      };
    },

    _newState() { return this._freshState(); },

    // ---- 启动 ----
    // mode: 'continue' | 'new' | undefined(自动判断)
    start(night, mode) {
      this.night = night;
      this.name = night.playerName || '阿迟';

      const canContinue = this.hasSave();
      if (typeof document !== 'undefined') {
        this.cache();
        this.bind();
      }

      if (mode === 'continue' && canContinue) {
        this.load();
      } else if (mode === 'new') {
        this.state = this._newState();
        this.clearSave();
      } else {
        // 自动：有存档先进标题（由 UI 决定）；无存档直接新开
        if (canContinue) {
          this.state = this._newState();     // 占位，等用户选继续/重开
          this._showTitle();
          return;
        }
        this.state = this._newState();
      }

      if (typeof night.init === 'function') night.init(this.state);
      if (typeof document !== 'undefined') this._renderTitleBar();
      // 进入当前节点时触发一次管理员反应（继续时也补一声）
      if (this.state.node !== 'hub' && this.state.node !== 'region') {
        this._companion('enter:' + this.state.node);
      } else if (this.state.node === 'region' && this.state.currentRegion) {
        this._companion('enter:' + this.state.currentRegion);
      }
      this.render();
    },

    // ---- 标题屏：有存档时给「继续 / 重新开始」----
    _showTitle() {
      const el = this.els.stage;
      if (!el) return;
      el.innerHTML =
        '<div class="title-screen">' +
          '<p class="title-line">《逾期之书》· 夜 A《夹在书里的信》</p>' +
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
      const root = document;
      root.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-act]');
        if (!btn || btn.disabled) return;
        const act = btn.getAttribute('data-act');
        // 标题屏 / 存档条 的特殊动作
        if (act === '__continue') { this.start(this.night, 'continue'); return; }
        if (act === '__new_game') { this.clearSave(); this.start(this.night, 'new'); return; }
        if (act === '__save') { this._doSave(); return; }
        this.act(act);
      });
      if (this.els.puzzle) {
        this.els.puzzle.addEventListener('keydown', (e) => {
          if (e.key === 'Enter' && e.target && e.target.id === 'pz-input') {
            this.submitPuzzle(e.target.value);
          }
        });
      }
    },

    // 手动存档 + 底部状态提示
    _doSave() {
      const ok = this.save();
      const hint = document.getElementById('save-hint');
      if (hint) {
        hint.textContent = ok ? '（进度已存 · ' + new Date().toLocaleTimeString('zh-CN', {hour:'2-digit',minute:'2-digit'}) + '）' : '（当前环境无法存档）';
        setTimeout(() => { if (hint) hint.textContent = ''; }, 2500);
      }
      this._renderTitleBar();
    },

    // 在每次状态变化后自动存档（B：退出再进能恢复）
    _autoSave() {
      if (this.state.node === 'notice' && !this.state.currentRegion && Object.keys(this.state.clues).length === 0) {
        // 还没真正开始，不写档
        return;
      }
      this.save();
    },

    // ---- 管理员常驻反应层 ----
    // 任何交互都过一遍：模块可返回一句话（或 null 表示沉默 / 一句都不说）
    _companion(event) {
      const fn = this.night && this.night.companion;
      let text = null;
      if (typeof fn === 'function') text = fn(event, this.state, this.api()) || null;
      if (text) {
        this.state.curator = text;
        this.state.curatorShown = true;
      }
    },

    companion(text) {
      if (text) {
        this.state.curator = text;
        this.state.curatorShown = true;
      }
    },

    api() {
      const self = this;
      return {
        name: self.name,
        state: self.state,
        companion: (t) => self.companion(t),
        meta: { stub: true },   // meta 层接口（后续实现）
      };
    },

    // ---- 动作分发 ----
    act(id) {
      // 区域图：点击区域卡
      if (id.startsWith('goto:')) {
        const rid = id.slice(5);
        this.state.currentRegion = rid;
        this.state.examining = null;
        this.state.node = 'region';
        if (!this.state.visited[rid]) this.state.visited[rid] = true;
        this._companion('enter:' + rid);
        this.render();
        return;
      }
      // 热点点击：hot:<region>:<hotId>
      if (id.startsWith('hot:')) {
        const parts = id.slice(4).split(':');
        const rid = parts[0], hid = parts[1];
        const key = rid + ':' + hid;
        const first = !this.state.examined[key];   // 首次查看 vs 再看一次
        this.state.examining = { region: rid, hot: hid };
        this.state._feedback = '';
        const hot = this._hot(rid, hid);

        // 钩子已选过：互斥，只复述不重提交（不叠加/不覆盖）
        if (hot && hot.hook && this.state.hookChosenLine[hid]) {
          this.companion(this.state.hookChosenLine[hid]);
          this.render();
          return;
        }

        // 解锁线索
        if (hot && hot.unlocks) {
          const u = hot.unlocks;
          if (typeof u === 'string') this.state.clues[u] = u;
          else if (u.id) this.state.clues[u.id] = u.text;
        }
        // 自定义行为（状态钩子等）
        if (hot && typeof hot.onHot === 'function') hot.onHot(this.state, this.api());
        // 管理员反应：优先 hotspot.curator，否则通用事件
        if (hot && (hot.curatorOnce || hot.curatorAgain)) {
          const line = (first ? hot.curatorOnce : (hot.curatorAgain || hot.curatorOnce));
          if (line) this.companion(line);
        } else {
          this._companion('hot:' + rid + ':' + hid);
        }
        // 状态钩子上下文（供 submitPuzzle 判定）
        if (hot && hot.hook) this.state._puzzleCtx = 'hook:' + rid + ':' + hid;
        this.render();
        return;
      }
      // 状态钩子：追问（如 旧灯「谁？」）
      if (id.startsWith('ask:')) {
        const parts = id.slice(4).split(':');
        const rid = this.state.examining ? this.state.examining.region : parts[0];
        const hid = this.state.examining ? this.state.examining.hot : parts[1];
        const hot = this._hot(rid, hid);
        if (hot && hot.ask) {
          this.companion(hot.ask.then || '……');
          this.state.examining = Object.assign({}, this.state.examining, { asked: true });
        }
        this.render();
        return;
      }
      // 通用动作交给内容模块
      if (typeof this.night.act === 'function') {
        const res = this.night.act(id, this.state, this.api()) || {};
        if (res.node) this.state.node = res.node;
        if (res.companion) this.companion(res.companion);
      }
      // 重新开始：清掉旧档
      if (id === 'restart') this.clearSave();
      this._autoSave();
      this.render();
    },

    _hot(region, hotId) {
      const r = this.night.regions && this.night.regions[region];
      if (!r || !r.hotspots) return null;
      return r.hotspots[hotId] || null;
    },

    // ---- 谜题 / 钩子提交 ----
    submitPuzzle(value) {
      const ctx = this.state._puzzleCtx || (this.state.currentScene || 'return');
      const res = (typeof this.night.checkPuzzle === 'function')
        ? this.night.checkPuzzle(ctx, value, this.state, this.api()) : { ok: false, feedback: '这里没有谜题。' };
      this.state._feedback = res.feedback || '';
      if (res.ok) {
        if (res.clue) this.state.clues[res.clue.id] = res.clue.text;
        if (res.proceedTo) this.state.node = res.proceedTo;
        if (res.companion) this.companion(res.companion);
        // 钩子上下文：记录已选 line，供二次点击复述（互斥不叠加）
        if (ctx.startsWith('hook:')) {
          const hid = ctx.slice(5).split(':')[1];
          if (hid && res.companion) this.state.hookChosenLine[hid] = res.companion;
        }
        this._autoSave();
      }
      this.render();
      return res;
    },

    // ---- 渲染调度 ----
    render() {
      if (typeof document === 'undefined') return;
      const node = this.state.node;

      // 引擎负责的两种节点：区域图 / 区域内
      if (node === 'hub') return this.renderRegionMap();
      if (node === 'region') return this.renderRegionInterior();

      // 其余交给内容模块
      const view = this.night.render(node, this.state, this.api());
      const fill = (s) => (s == null ? '' : String(s).split('__NAME__').join(this.name));

      this.els.stage.innerHTML = fill(view.stage || '');
      this.els.actions.innerHTML = (view.actions || []).map((b) =>
        '<button class="btn ' + (b.primary ? 'primary' : '') + (b.ghost ? ' ghost' : '') + '" data-act="' +
        esc(b.id) + '"' + (b.disabled ? ' disabled' : '') + '>' + esc(b.label) + '</button>'
      ).join('');

      const p = view.puzzle;
      this.els.puzzle.innerHTML = p ? this.renderPuzzle(p, fill) : '';

      this.renderClues();
      this.renderMemories();
      this.renderCompanion();
      this.els.regionMap.innerHTML = '';
    },

    // 区域图：可点区域卡（含隐喻），锁定的区呈暗态
    renderRegionMap() {
      const regions = this.night.regions || {};
      const self = this;
      const cards = Object.keys(regions).map((rid) => {
        const r = regions[rid];
        const unlocked = (typeof self.night.regionUnlocked === 'function')
          ? self.night.regionUnlocked(rid, self.state) : true;
        const seen = self.state.visited[rid];
        const cls = 'region-card' + (unlocked ? '' : ' locked') + (seen ? ' seen' : '');
        const meta = r.metaphor ? '<div class="region-meta">' + esc(r.metaphor) + '</div>' : '';
        if (!unlocked) {
          return '<div class="' + cls + '"><div class="region-name">' + esc(r.name) +
            '</div><div class="region-meta">（还推不开）</div></div>';
        }
        return '<div class="' + cls + '" data-act="goto:' + rid + '">' +
          '<div class="region-name">' + esc(r.name) + (seen ? ' <span class="dot">·</span>' : '') + '</div>' +
          meta + '</div>';
      }).join('');

      this.els.stage.innerHTML =
        '<p class="hub-hint">馆里很静。雨声贴着玻璃。你可以去各处看看——' +
        '每一处都摊着一点关于这本书的线索，拼齐了，才知道它该回哪儿。</p>' +
        '<div class="region-grid">' + cards + '</div>';
      // 区域图底部额外动作（内容模块提供，如「走到灯下收束」）
      const extra = (typeof this.night.regionMapActions === 'function')
        ? this.night.regionMapActions(this.state) : null;
      this.els.actions.innerHTML = (extra || []).map((b) =>
        '<button class="btn ' + (b.primary ? 'primary' : '') + (b.ghost ? ' ghost' : '') + '" data-act="' +
        esc(b.id) + '"' + (b.disabled ? ' disabled' : '') + '>' + esc(b.label) + '</button>'
      ).join('');
      this.els.puzzle.innerHTML = '';
      this.renderClues();
      this.renderMemories();
      this.renderCompanion();

      // 区域图本身也过一次管理员反应（空事件）
      this.els.regionMap.innerHTML = '';
    },

    // 区域内：描述 + 可点物件（hotspot） + 出口通道（通往其他区域）
    renderRegionInterior() {
      const rid = this.state.currentRegion;
      const r = this.night.regions[rid];
      const self = this;
      if (!r) { this.els.stage.innerHTML = '<p class="narration">这里什么都没有。</p>'; return; }

      let html = '<h3 class="scene-name">' + esc(r.name) + '</h3>';
      if (r.metaphor) html += '<div class="region-meta">' + esc(r.metaphor) + '</div>';
      html += '<p class="narration">' + esc(r.desc || '') + '</p>';

      // 正在查看的物件 → 焦点阅读（Florence 一句话）
      if (this.state.examining && this.state.examining.region === rid) {
        const hot = this._hot(rid, this.state.examining.hot);
        if (hot) {
          const key = rid + ':' + hot.id;
          const first = !this.state.examined[key];
          const line = (first ? hot.once : (hot.again || hot.once)) || '';
          html += '<div class="examine"><div class="examine-line">' + esc(line) + '</div>';
          if (hot.ask && !this.state.examining.asked) {
            html += '<button class="btn ghost small" data-act="ask:' + rid + ':' + hot.id + '">' + esc(hot.ask.prompt) + '</button>';
          }
          html += '<button class="btn ghost small" data-act="close">收起来</button></div>';
          // 首次展开后才标记「看过」，保证下一次显示 again
          this.state.examined[key] = true;
          this.state.visitedHot[key] = true;
        }
      }

      // 物件列表（可点）
      const hots = Object.keys(r.hotspots || {}).map((hid) => {
        const h = r.hotspots[hid];
        const seen = self.state.visitedHot[rid + ':' + hid];
        const mark = seen ? ' <span class="seen-mark">✓</span>' : '';
        return '<button class="btn hot' + (h.hook ? ' hook' : '') + '" data-act="hot:' + rid + ':' + hid + '">' +
          esc(h.label) + mark + '</button>';
      }).join('');

      if (hots) html += '<div class="hotspot-row">' + hots + '</div>';

      // 出口通道（可点门 / 通道 → 其他区域）
      const exits = Object.keys(r.exits || {}).map((label) => {
        const to = r.exits[label];
        const unlocked = (typeof self.night.regionUnlocked === 'function')
          ? self.night.regionUnlocked(to, self.state) : true;
        if (!unlocked) return '<span class="exit locked">' + esc(label) + '（锁着）</span>';
        return '<button class="btn exit" data-act="goto:' + to + '">' + esc(label) + ' →</button>';
      }).join('');
      if (exits) html += '<div class="exits">' + exits + '</div>';

      this.els.stage.innerHTML = html;
      this.els.actions.innerHTML = '<button class="btn" data-act="hub">回到区域图 ▶</button>';

      // 状态钩子面板（便签三选项等）
      const hot = this.state.examining ? this._hot(rid, this.state.examining.hot) : null;
      if (hot && hot.hook) {
        this.els.puzzle.innerHTML = this.renderHook(hot, rid);
      } else {
        this.els.puzzle.innerHTML = '';
      }

      this.renderClues();
      this.renderMemories();
      this.renderCompanion();
      this.els.regionMap.innerHTML = '';
    },

    renderHook(hot, rid) {
      const ctx = 'hook:' + rid + ':' + hot.id;
      const fb = this.state._feedback || '';
      let html = '<div class="pz"><p class="pz-prompt">' + esc(hot.hookPrompt || '你要怎么做？') + '</p>';
      html += (hot.options || []).map((o) =>
        '<button class="btn" data-pz="opt" data-val="' + esc(o.id) + '">' + esc(o.label) + '</button>'
      ).join('');
      if (fb) html += '<p class="pz-fb">' + esc(fb) + '</p>';
      html += '</div>';
      this.state._puzzleCtx = ctx;
      // 钩子选择经由 submitPuzzle → night.checkPuzzle(ctx,...)
      this._bindHook();
      return html;
    },

    _bindHook() {
      const el = this.els.puzzle;
      if (!el) return;
      el.onclick = (e) => {
        const b = e.target.closest('[data-pz="opt"]');
        if (!b) return;
        this.submitPuzzle(b.getAttribute('data-val'));
      };
    },

    renderPuzzle(p, fill) {
      const fb = this.state._feedback || '';
      if (p.locked) return '<p class="pz-locked">' + fill(p.locked) + '</p>';
      let html = '<div class="pz"><p class="pz-prompt">' + fill(p.prompt) + '</p>';
      if (p.type === 'input') {
        html += '<input id="pz-input" class="pz-input" placeholder="' + esc(p.placeholder || '') + '" />' +
                '<button class="btn primary" data-pz="submit">确定</button>';
      } else if (p.type === 'choice') {
        html += (p.options || []).map((o) =>
          '<button class="btn" data-pz="opt" data-val="' + esc(o.id) + '">' + esc(o.label) + '</button>'
        ).join('');
      }
      if (fb) html += '<p class="pz-fb">' + fill(fb) + '</p>';
      html += '</div>';
      this._bindPuzzle();
      return html;
    },

    _bindPuzzle() {
      const el = this.els.puzzle;
      if (!el) return;
      el.onclick = (e) => {
        const b = e.target.closest('[data-pz]');
        if (!b) return;
        const kind = b.getAttribute('data-pz');
        if (kind === 'submit') {
          const inp = document.getElementById('pz-input');
          this.submitPuzzle(inp ? inp.value : '');
        } else if (kind === 'opt') {
          this.submitPuzzle(b.getAttribute('data-val'));
        }
      };
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
        ids.map((id) => '<div class="panel-item">' + esc(this.state.memories[id]) + '</div>').join('');
    },

    renderCompanion() {
      const el = this.els.companion;
      if (!el) return;
      const text = this.state.curator;
      if (!text) { el.innerHTML = '<span class="companion-name">管理员</span><span class="companion-line dim">（在柜台后，没抬头）</span>'; return; }
      el.innerHTML = '<span class="companion-name">管理员</span><span class="companion-line">' + esc(text) + '</span>';
    },
  };

  Game._companion = Game._companion; // 暴露给内部

  global.Game = Game;
  if (typeof module !== 'undefined' && module.exports) module.exports = Game;
})(typeof window !== 'undefined' ? window : globalThis);
