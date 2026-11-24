/*
 * diagrams.js - part of the zero-to-expert course kit.
 *
 * Draws SVG diagrams from plain HTML lists when the page loads. Headless Chromium runs this script
 * before printing, so the PDF gets sharp vector diagrams without any other software.
 *
 *   <figure class="dg mindmap"><ul><li>Centre<ul><li>Branch<ul><li>Leaf</li></ul></li></ul></li></ul></figure>
 *   <figure class="dg roadmap"><ol><li><b>Step</b> short detail</li> ...</ol></figure>
 *   <figure class="dg flow"><ol><li><b>Step</b> short detail</li> ...</ol></figure>
 *   <figure class="dg cycle" data-center="Centre label"><ol><li><b>Phase</b> detail</li> ...</ol></figure>
 *   <figure class="dg layers" data-shape="pyramid"><ol><li><b>Top</b> detail</li> ... bottom</ol></figure>
 *   <figure class="dg timeline"><ol><li><b>1995</b> what happened</li> ...</ol></figure>
 *
 * Options: data-layout="auto|both|right" (mindmap), data-per-row="3" (roadmap, flow),
 *          data-colors="#2563eb,#0f766e" (any diagram, #rrggbb only; one colour = monochrome).
 * Also builds the table of contents ([data-toc]), chapter colours and progress bars (section.chapter),
 * the running page header (meta running-title or document title) and clickable bare URLs in td.url.
 * In French (<html lang="fr">) it adds the no-break spaces before ; : ! ? » % and after «.
 * Boxes taller than 40 % of a page may break across pages; the build log warns about layout problems.
 * Markup guide: references/diagrams.md
 */
(function () {
  'use strict';

  var NS = 'http://www.w3.org/2000/svg';
  var PALETTE = ['#2563eb', '#0f766e', '#c2410c', '#7c3aed', '#be123c', '#15803d', '#b45309', '#0e7490', '#4338ca', '#a21caf'];
  var INK = '#1e293b', SOFT = '#475569', LH = 1.24;
  var WORDS = {
    en: ['Start', 'Goal'], fr: ['Départ', 'Objectif'], es: ['Inicio', 'Meta'], de: ['Start', 'Ziel'],
    it: ['Partenza', 'Obiettivo'], pt: ['Início', 'Meta'], nl: ['Start', 'Doel'], ar: ['البداية', 'الهدف']
  };
  var lang = (document.documentElement.lang || 'en').slice(0, 2).toLowerCase();
  var T = WORDS[lang] || WORDS.en;
  var FONT = 'Segoe UI, Arial, sans-serif', P = PALETTE, uid = 0, probe = null;

  function f(v) { return Math.round(v * 10) / 10; }
  function pick(i) { return P[i % P.length]; }
  function each(list, fn) { Array.prototype.forEach.call(list, fn); }
  function wide(fig) { return !!(fig.closest('.wide') || fig.hasAttribute('data-wide')); }
  // Collapses ordinary whitespace only, so the no-break spaces of French typography survive.
  function squash(s) { return String(s == null ? '' : s).replace(/[ \t\r\n\f]+/g, ' ').trim(); }

  function el(name, attrs, parent) {
    var n = document.createElementNS(NS, name);
    for (var k in attrs) if (attrs[k] !== undefined && attrs[k] !== null) n.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(n);
    return n;
  }

  function tint(hex, k) {
    var n = parseInt(hex.replace('#', ''), 16), r = n >> 16, g = (n >> 8) & 255, b = n & 255;
    function m(c) { return Math.round(c + (255 - c) * k); }
    return 'rgb(' + m(r) + ',' + m(g) + ',' + m(b) + ')';
  }

  // Text is measured with the page font, so boxes fit their labels and nothing overlaps.
  function measure(s, size, weight) {
    if (!probe) {
      var svg = el('svg', { width: 10, height: 10, style: 'position:absolute;left:-10000px;top:0;visibility:hidden' }, document.body);
      probe = el('text', { x: 0, y: 0 }, svg);
    }
    probe.setAttribute('font-family', FONT);
    probe.setAttribute('font-size', size);
    probe.setAttribute('font-weight', weight || 400);
    probe.textContent = s;
    return probe.getComputedTextLength();
  }

  function wrap(s, size, weight, maxW) {
    var words = squash(s).split(' '), lines = [], line = '', width = 0;
    words.forEach(function (w) {
      if (!w) return;
      var t = line ? line + ' ' + w : w;
      if (line && measure(t, size, weight) > maxW) { lines.push(line); line = w; } else line = t;
    });
    if (line) lines.push(line);
    lines.forEach(function (l) { width = Math.max(width, measure(l, size, weight)); });
    return { lines: lines, width: width, height: lines.length * size * LH, size: size, weight: weight || 400 };
  }

  // Draws a wrapped block centred on (x, cy); anchor 'start' puts x at the left edge.
  function text(g, w, x, cy, fill, anchor) {
    var lh = w.size * LH, y0 = cy - (w.lines.length - 1) * lh / 2;
    w.lines.forEach(function (l, i) {
      el('text', { x: f(x), y: f(y0 + i * lh), fill: fill, 'font-size': w.size, 'font-weight': w.weight,
        'font-family': FONT, 'text-anchor': anchor || 'middle', 'dominant-baseline': 'central' }, g).textContent = l;
    });
  }
  function textTop(g, w, x, top, fill, anchor) { text(g, w, x, top + w.height / 2, fill, anchor); }

  // A list item gives a title (the <b>/<strong> part, or the text before " — ") and a detail (the rest).
  function own(li) {
    var c = li.cloneNode(true), b, title = '', detail, m;
    each(c.querySelectorAll('ul,ol'), function (n) { n.parentNode.removeChild(n); });
    each(c.querySelectorAll('br'), function (n) { n.parentNode.replaceChild(document.createTextNode(' '), n); });
    b = c.querySelector('b,strong');
    if (b) { title = squash(b.textContent); b.parentNode.removeChild(b); }
    detail = squash(c.textContent).replace(/^[—–:\-·]\s*/, '');
    if (!title) {
      m = detail.match(/^(.{1,90}?)\s+[—–]\s+(.+)$/);
      if (m) { title = m[1]; detail = m[2]; } else { title = detail; detail = ''; }
    }
    return { title: title, detail: detail };
  }

  function items(list) {
    var out = [];
    each(list.children, function (li) {
      if (li.tagName !== 'LI') return;
      var p = own(li), sub = null;
      each(li.children, function (k) { if (!sub && (k.tagName === 'UL' || k.tagName === 'OL')) sub = k; });
      p.children = sub ? items(sub) : [];
      out.push(p);
    });
    return out;
  }

  function svgFor(fig, W, H) {
    var cap = fig.querySelector('figcaption');
    var svg = el('svg', { viewBox: '0 0 ' + f(W) + ' ' + f(H), width: f(W), height: f(H), role: 'img', 'font-family': FONT });
    var label = fig.getAttribute('aria-label') || (cap ? squash(cap.textContent) : '');
    if (label) svg.setAttribute('aria-label', label);
    fig.insertBefore(svg, cap);
    return svg;
  }

  function arrowHead(svg, color) {
    var id = 'dg-arrow-' + (++uid), defs = el('defs', {}, svg);
    var m = el('marker', { id: id, viewBox: '0 0 10 10', refX: 8.5, refY: 5, markerWidth: 8, markerHeight: 8,
      markerUnits: 'userSpaceOnUse', orient: 'auto' }, defs);
    el('path', { d: 'M0,0 L10,5 L0,10 z', fill: color }, m);
    return 'url(#' + id + ')';
  }

  function star(g, cx, cy, r, fill) {
    var pts = [];
    for (var i = 0; i < 10; i++) {
      var a = -Math.PI / 2 + i * Math.PI / 5, rr = i % 2 ? r * 0.45 : r;
      pts.push(f(cx + rr * Math.cos(a)) + ',' + f(cy + rr * Math.sin(a)));
    }
    el('polygon', { points: pts.join(' '), fill: fill, stroke: '#ffffff', 'stroke-width': 1.5 }, g);
  }

  /* ---------- mindmap: centre + branches, on both sides (depth <= 2) or to the right ---------- */
  function mindmap(fig, list) {
    var top = items(list), nodes = [], k = wide(fig) ? 1.35 : 1;
    var root = top.length === 1 ? top[0] : { title: fig.getAttribute('data-title') || '', detail: '', children: top };
    var S = [
      { size: 15, weight: 700, maxW: 112 * k, px: 14, py: 9, rx: 12 },
      { size: 12.5, weight: 700, maxW: 96 * k, px: 10, py: 6, rx: 8 },
      { size: 11.5, weight: 400, maxW: 112 * k, px: 7, py: 4, rx: 5 },
      { size: 10.5, weight: 400, maxW: 108 * k, px: 6, py: 3, rx: 4 }
    ];
    var VG = [0, 14, 6, 4], HG = [0, 36, 22, 18];
    function st(d) { return S[Math.min(d, 3)]; }
    function gapV(d) { return VG[Math.min(d, 3)]; }

    (function prep(n, d, color) {
      var s = st(d);
      n.d = d; n.color = color;
      n.wr = wrap(n.detail ? n.title + ' — ' + n.detail : n.title, s.size, s.weight, s.maxW);
      n.w = n.wr.width + 2 * s.px; n.h = n.wr.height + 2 * s.py;
      nodes.push(n);
      n.children.forEach(function (c, i) { prep(c, d + 1, d === 0 ? pick(i) : color); });
    })(root, 0, INK);

    var maxD = 0;
    nodes.forEach(function (n) { maxD = Math.max(maxD, n.d); });
    var layout = fig.getAttribute('data-layout') || 'auto';
    var both = layout === 'both' || (layout === 'auto' && maxD <= 2 && root.children.length >= 3);

    (function span(n) {
      var s = 0;
      n.children.forEach(function (c, i) { s += span(c) + (i ? gapV(c.d) : 0); });
      return (n.span = Math.max(n.h, s));
    })(root);

    var kids = root.children, right = kids, left = [];
    if (both && kids.length > 1) {
      var total = 0, acc = 0, best = 1, bestDiff = Infinity;
      kids.forEach(function (c) { total += c.span; });
      for (var i = 1; i < kids.length; i++) {
        acc += kids[i - 1].span;
        if (Math.abs(acc - total / 2) < bestDiff) { bestDiff = Math.abs(acc - total / 2); best = i; }
      }
      right = kids.slice(0, best); left = kids.slice(best);
    }

    root.x = 0; root.y = -root.h / 2;
    function place(n, parent, dir, cy) {
      var g = HG[Math.min(n.d, 3)], tot = 0, y;
      n.dir = dir; n.y = cy - n.h / 2;
      n.x = dir > 0 ? parent.x + parent.w + g : parent.x - g - n.w;
      n.children.forEach(function (c, i) { tot += c.span + (i ? gapV(c.d) : 0); });
      y = cy - tot / 2;
      n.children.forEach(function (c) { place(c, n, dir, y + c.span / 2); y += c.span + gapV(c.d); });
    }
    function side(group, dir) {
      var tot = 0, y;
      group.forEach(function (c, i) { tot += c.span + (i ? gapV(1) : 0); });
      y = -tot / 2;
      group.forEach(function (c) { place(c, root, dir, y + c.span / 2); y += c.span + gapV(1); });
    }
    // Clockwise from the top right, as in classic mind maps: the left side is read bottom to top.
    side(right, 1); side(left.slice().reverse(), -1);

    var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity, M = 6;
    nodes.forEach(function (n) {
      minX = Math.min(minX, n.x); minY = Math.min(minY, n.y);
      maxX = Math.max(maxX, n.x + n.w); maxY = Math.max(maxY, n.y + n.h);
    });
    var svg = svgFor(fig, maxX - minX + 2 * M, maxY - minY + 2 * M);
    var g = el('g', { transform: 'translate(' + f(M - minX) + ',' + f(M - minY) + ')' }, svg);

    nodes.forEach(function (p) {
      p.children.forEach(function (c) {
        var y1 = p.y + p.h / 2, y2 = c.y + c.h / 2, x1, x2, mx;
        if (c.dir > 0) { x1 = p.x + p.w - (p.d === 0 ? 8 : 0); x2 = c.x; } else { x1 = p.x + (p.d === 0 ? 8 : 0); x2 = c.x + c.w; }
        mx = (x1 + x2) / 2;
        el('path', { d: 'M' + f(x1) + ',' + f(y1) + ' C' + f(mx) + ',' + f(y1) + ' ' + f(mx) + ',' + f(y2) + ' ' + f(x2) + ',' + f(y2),
          fill: 'none', stroke: c.color, 'stroke-width': c.d === 1 ? 2.6 : c.d === 2 ? 1.6 : 1.2, 'stroke-linecap': 'round' }, g);
      });
    });
    nodes.forEach(function (n) {
      var s = st(n.d), fill, stroke = 'none', ink = INK;
      if (n.d === 0) { fill = INK; ink = '#ffffff'; }
      else if (n.d === 1) { fill = n.color; ink = '#ffffff'; }
      else if (n.d === 2) { fill = tint(n.color, 0.9); stroke = n.color; }
      else { fill = '#ffffff'; stroke = tint(n.color, 0.5); }
      el('rect', { x: f(n.x), y: f(n.y), width: f(n.w), height: f(n.h), rx: s.rx, fill: fill, stroke: stroke, 'stroke-width': 1 }, g);
      text(g, n.wr, n.x + n.w / 2, n.y + n.h / 2, ink);
    });
  }

  /* ---------- roadmap: numbered milestones on a winding road, start flag to goal star ---------- */
  function roadmap(fig, list) {
    var steps = items(list), n = steps.length;
    if (!n) return;
    var W = wide(fig) ? 980 : 680, side = 34, R = 14;
    var per = +fig.getAttribute('data-per-row') || (n <= 4 ? n : n <= 6 ? 3 : 4);
    var colW = (W - 2 * side) / per, rows = Math.ceil(n / per), y = 30, rowCy = [], rowTop = [];
    steps.forEach(function (s) {
      s.t = wrap(s.title, 12, 700, colW - 12);
      s.dd = s.detail ? wrap(s.detail, 10.5, 400, colW - 12) : null;
      s.th = s.t.height + (s.dd ? 3 + s.dd.height : 0);
    });
    for (var r = 0; r < rows; r++) {
      var th = 0;
      for (var i = r * per; i < Math.min(n, (r + 1) * per); i++) th = Math.max(th, steps[i].th);
      rowCy.push(y + R); rowTop.push(y + 2 * R + 6);
      y += 2 * R + 6 + th + 24;
    }
    steps.forEach(function (s, i) {
      var r = Math.floor(i / per), j = i % per, col = r % 2 ? per - 1 - j : j;
      s.r = r; s.cx = side + colW * (col + 0.5); s.cy = rowCy[r];
    });
    var svg = svgFor(fig, W, y - 24 + 8), first = steps[0], last = steps[n - 1];
    var sx = first.cx - Math.min(colW / 2, 40) + 4, d = 'M' + f(sx) + ',' + f(first.cy);
    steps.forEach(function (s, i) {
      var nx = steps[i + 1];
      d += ' L' + f(s.cx) + ',' + f(s.cy);
      if (nx && nx.r !== s.r) {
        var ltr = s.r % 2 === 0, ex = ltr ? W - side / 2 : side / 2, sg = ltr ? 1 : -1, rr = Math.min(14, (nx.cy - s.cy) / 2);
        d += ' L' + f(ex - sg * rr) + ',' + f(s.cy) + ' Q' + f(ex) + ',' + f(s.cy) + ' ' + f(ex) + ',' + f(s.cy + rr) +
             ' L' + f(ex) + ',' + f(nx.cy - rr) + ' Q' + f(ex) + ',' + f(nx.cy) + ' ' + f(ex - sg * rr) + ',' + f(nx.cy);
      }
    });
    var gx = last.cx + (last.r % 2 === 0 ? 1 : -1) * Math.min(colW / 2, 40);
    d += ' L' + f(gx) + ',' + f(last.cy);
    el('path', { d: d, fill: 'none', stroke: '#cbd5e1', 'stroke-width': 12, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }, svg);
    el('path', { d: d, fill: 'none', stroke: '#ffffff', 'stroke-width': 1.6, 'stroke-dasharray': '5 6', 'stroke-linecap': 'round' }, svg);
    el('circle', { cx: f(sx), cy: f(first.cy), r: 7, fill: INK }, svg);
    text(svg, wrap(T[0], 10, 700, 200), sx, first.cy - 19, INK);
    star(svg, gx, last.cy, 10, '#f59e0b');
    text(svg, wrap(T[1], 10, 700, 200), gx, last.cy - 21, '#b45309');
    steps.forEach(function (s, i) {
      el('circle', { cx: f(s.cx), cy: f(s.cy), r: R, fill: pick(i), stroke: '#ffffff', 'stroke-width': 2.5 }, svg);
      text(svg, wrap(String(i + 1), 12, 700, 50), s.cx, s.cy, '#ffffff');
      textTop(svg, s.t, s.cx, rowTop[s.r], INK);
      if (s.dd) textTop(svg, s.dd, s.cx, rowTop[s.r] + s.t.height + 3, SOFT);
    });
  }

  /* ---------- flow: process boxes with arrows, wrapping to several rows ---------- */
  function flow(fig, list) {
    var steps = items(list), n = steps.length;
    if (!n) return;
    var W = wide(fig) ? 980 : 680, gap = 30, rowGap = 36, M = 2;
    var per = +fig.getAttribute('data-per-row') || (n <= 5 ? n : Math.ceil(n / Math.ceil(n / 4)));
    var bw = (W - gap * (per - 1)) / per, rows = Math.ceil(n / per), y = 12, rowY = [], rowH = [];
    steps.forEach(function (s) {
      s.t = wrap(s.title, 12, 700, bw - 18);
      s.dd = s.detail ? wrap(s.detail, 10.5, 400, bw - 16) : null;
      s.h = 15 + s.t.height + (s.dd ? 4 + s.dd.height : 0) + 10;
    });
    for (var r = 0; r < rows; r++) {
      var h = 0;
      for (var i = r * per; i < Math.min(n, (r + 1) * per); i++) h = Math.max(h, steps[i].h);
      rowY.push(y); rowH.push(h); y += h + rowGap;
    }
    var svg = svgFor(fig, W + 2 * M, y - rowGap + 4), mk = arrowHead(svg, SOFT);
    steps.forEach(function (s, i) {
      var r = Math.floor(i / per);
      s.r = r; s.x = M + (i % per) * (bw + gap); s.y = rowY[r]; s.hh = rowH[r];
    });
    steps.forEach(function (s, i) {
      var nx = steps[i + 1];
      if (!nx) return;
      if (nx.r === s.r) {
        el('path', { d: 'M' + f(s.x + bw + 3) + ',' + f(s.y + s.hh / 2) + ' L' + f(nx.x - 3) + ',' + f(s.y + s.hh / 2),
          stroke: SOFT, 'stroke-width': 2, fill: 'none', 'marker-end': mk }, svg);
      } else {
        var x1 = s.x + bw / 2, y1 = s.y + s.hh + 2, ym = s.y + s.hh + rowGap / 2, x2 = nx.x + bw / 2;
        el('path', { d: 'M' + f(x1) + ',' + f(y1) + ' L' + f(x1) + ',' + f(ym) + ' L' + f(x2) + ',' + f(ym) + ' L' + f(x2) + ',' + f(nx.y - 3),
          stroke: SOFT, 'stroke-width': 2, fill: 'none', 'stroke-linejoin': 'round', 'marker-end': mk }, svg);
      }
    });
    steps.forEach(function (s, i) {
      var c = pick(i), top = s.y + 15;
      el('rect', { x: f(s.x), y: f(s.y), width: f(bw), height: f(s.hh), rx: 8, fill: tint(c, 0.9), stroke: c, 'stroke-width': 1.3 }, svg);
      el('circle', { cx: f(s.x + 16), cy: f(s.y), r: 10, fill: c, stroke: '#ffffff', 'stroke-width': 2 }, svg);
      text(svg, wrap(String(i + 1), 10.5, 700, 30), s.x + 16, s.y, '#ffffff');
      textTop(svg, s.t, s.x + bw / 2, top, INK);
      if (s.dd) textTop(svg, s.dd, s.x + bw / 2, top + s.t.height + 4, SOFT);
    });
  }

  /* ---------- cycle: phases around an ellipse, arrows between them, optional centre label ---------- */
  function cycle(fig, list) {
    var steps = items(list), n = steps.length;
    if (n < 2) return;
    var W = 680, maxW = 132, bw = 0, bh = 0;
    steps.forEach(function (s) {
      s.t = wrap(s.title, 12, 700, maxW - 14);
      s.dd = s.detail ? wrap(s.detail, 10.3, 400, maxW - 12) : null;
      s.w = Math.max(s.t.width, s.dd ? s.dd.width : 0) + 18;
      s.h = s.t.height + (s.dd ? 3 + s.dd.height : 0) + 14;
      bw = Math.max(bw, s.w); bh = Math.max(bh, s.h);
    });
    var rx = Math.min((W - bw) / 2 - 6, 150 + 16 * n), ry = Math.min(170, 70 + 12 * n);
    var cx = W / 2, cy = ry + bh / 2 + 8;
    steps.forEach(function (s, i) {
      s.a = -Math.PI / 2 + 2 * Math.PI * i / n;
      s.cx = cx + rx * Math.cos(s.a); s.cy = cy + ry * Math.sin(s.a);
    });
    var svg = svgFor(fig, W, 2 * ry + bh + 16), mk = arrowHead(svg, SOFT), center = fig.getAttribute('data-center');
    if (center) {
      var cr = Math.min(rx, ry) * 0.42;
      el('circle', { cx: f(cx), cy: f(cy), r: f(cr), fill: '#f1f5f9', stroke: '#cbd5e1' }, svg);
      text(svg, wrap(center, 12.5, 700, cr * 1.55), cx, cy, INK);
    }
    function inside(s, x, y) { return Math.abs(x - s.cx) < s.w / 2 + 7 && Math.abs(y - s.cy) < s.h / 2 + 7; }
    steps.forEach(function (s, i) {
      var nx = steps[(i + 1) % n], a1 = i === n - 1 ? nx.a + 2 * Math.PI : nx.a, stp = (a1 - s.a) / 120, pts = [];
      for (var a = s.a; a <= a1 + 1e-9; a += stp) {
        var x = cx + rx * Math.cos(a), y = cy + ry * Math.sin(a);
        if (!inside(s, x, y) && !inside(nx, x, y)) pts.push(f(x) + ',' + f(y));
      }
      if (pts.length > 1) el('polyline', { points: pts.join(' '), fill: 'none', stroke: SOFT, 'stroke-width': 2, 'marker-end': mk }, svg);
    });
    steps.forEach(function (s, i) {
      var c = pick(i), top = s.cy - s.h / 2 + 7;
      el('rect', { x: f(s.cx - s.w / 2), y: f(s.cy - s.h / 2), width: f(s.w), height: f(s.h), rx: 9, fill: tint(c, 0.9), stroke: c, 'stroke-width': 1.4 }, svg);
      textTop(svg, s.t, s.cx, top, INK);
      if (s.dd) textTop(svg, s.dd, s.cx, top + s.t.height + 3, SOFT);
    });
  }

  /* ---------- layers: stacked bands (default) or a pyramid, first item on top ---------- */
  function layers(fig, list) {
    var steps = items(list), n = steps.length;
    if (!n) return;
    var W = 680, pyramid = fig.getAttribute('data-shape') === 'pyramid', minW = 210, gap = 4, H = 0, y = 1;
    steps.forEach(function (s, i) {
      var tw = (pyramid ? minW + (W - minW) * i / n : W) - 44;
      s.t = wrap(s.title, 13, 700, tw);
      s.dd = s.detail ? wrap(s.detail, 11, 400, tw) : null;
      s.inner = s.t.height + (s.dd ? 3 + s.dd.height : 0);
      s.h = Math.max(36, s.inner + 16);
      H += s.h + gap;
    });
    H = H - gap + 2;
    var svg = svgFor(fig, W, H);
    function widthAt(yy) { return pyramid ? minW + (W - minW) * yy / H : W; }
    steps.forEach(function (s, i) {
      var c = pick(i), top = y + (s.h - s.inner) / 2;
      if (pyramid) {
        var a = widthAt(y), b = widthAt(y + s.h);
        el('polygon', { points: [f((W - a) / 2) + ',' + f(y), f((W + a) / 2) + ',' + f(y), f((W + b) / 2) + ',' + f(y + s.h), f((W - b) / 2) + ',' + f(y + s.h)].join(' '), fill: c }, svg);
      } else {
        el('rect', { x: 0, y: f(y), width: W, height: f(s.h), rx: 7, fill: c }, svg);
      }
      textTop(svg, s.t, W / 2, top, '#ffffff');
      if (s.dd) textTop(svg, s.dd, W / 2, top + s.t.height + 3, 'rgba(255,255,255,0.93)');
      y += s.h + gap;
    });
  }

  /* ---------- timeline: dated events on an arrow, labels alternating above and below ---------- */
  function timeline(fig, list) {
    var ev = items(list), n = ev.length;
    if (!n) return;
    var W = wide(fig) ? 980 : 680, lw = 170, pad, step, up = 0, down = 0, stem = 16;
    for (var it = 0; it < 2; it++) {
      pad = lw / 2 + 6;
      step = n > 1 ? (W - 2 * pad) / (n - 1) : 0;
      lw = n > 2 ? Math.min(170, step * 2 - 12) : Math.min(260, W / 2 - 20);
    }
    ev.forEach(function (e, i) {
      e.x = n > 1 ? pad + step * i : W / 2;
      e.dt = wrap(e.title, 12, 700, lw);
      e.tx = e.detail ? wrap(e.detail, 10.5, 400, lw) : null;
      e.h = e.dt.height + (e.tx ? 3 + e.tx.height : 0);
      e.up = i % 2 === 0;
      if (e.up) up = Math.max(up, e.h); else down = Math.max(down, e.h);
    });
    var axisY = 8 + up + stem + 8, svg = svgFor(fig, W, axisY + 8 + stem + down + 8), mk = arrowHead(svg, INK);
    el('path', { d: 'M4,' + f(axisY) + ' L' + (W - 4) + ',' + f(axisY), stroke: INK, 'stroke-width': 2.5, fill: 'none', 'marker-end': mk }, svg);
    ev.forEach(function (e, i) {
      var c = pick(i), y1 = e.up ? axisY - 8 - stem : axisY + 8 + stem;
      el('line', { x1: f(e.x), y1: f(axisY), x2: f(e.x), y2: f(y1), stroke: c, 'stroke-width': 1.5 }, svg);
      el('circle', { cx: f(e.x), cy: f(axisY), r: 6.5, fill: c, stroke: '#ffffff', 'stroke-width': 2 }, svg);
      if (e.up) {
        textTop(svg, e.dt, e.x, y1 - e.dt.height - 2, c);
        if (e.tx) textTop(svg, e.tx, e.x, y1 - e.h - 2, SOFT);
      } else {
        textTop(svg, e.dt, e.x, y1 + 2, c);
        if (e.tx) textTop(svg, e.tx, e.x, y1 + 2 + e.dt.height + 3, SOFT);
      }
    });
  }

  /* ---------- page furniture ---------- */
  function header() {
    var m = document.querySelector('meta[name="running-title"]'), t = (m && m.content) || document.title, s;
    if (!t) return;
    s = document.createElement('style');
    s.textContent = '@page { @top-right { content: "' + t.replace(/["\\\n]/g, ' ') + '"; } }' +
      '@page :first { @top-right { content: none; } @bottom-right { content: none; } }';
    document.head.appendChild(s);
  }

  // Chapter i gets palette colour i: the same colour as its milestone on the course roadmap
  // and its branch on the final mindmap, so the learner can find their way by colour.
  function chapters() {
    var secs = document.querySelectorAll('section.chapter');
    each(secs, function (sec, i) {
      var c = sec.getAttribute('data-color') || PALETTE[i % PALETTE.length], h = sec.querySelector('h2'), bar;
      sec.style.setProperty('--c', c);
      sec.style.setProperty('--c-soft', tint(c, 0.92));
      sec.style.setProperty('--c-mid', tint(c, 0.7));
      if (!h || secs.length < 2) return;
      bar = document.createElement('div');
      bar.className = 'progress';
      for (var k = 0; k < secs.length; k++) {
        var sp = document.createElement('span');
        if (k < i) sp.className = 'done'; else if (k === i) sp.className = 'on';
        bar.appendChild(sp);
      }
      h.parentNode.insertBefore(bar, h.nextSibling);
    });
  }

  function toc() {
    each(document.querySelectorAll('[data-toc]'), function (box) {
      var ol = document.createElement('ol');
      each(document.querySelectorAll('section.chapter > h2, section.annex > h2'), function (h, i) {
        var c = h.cloneNode(true), li = document.createElement('li'), a = document.createElement('a'), lvl = h.querySelector('.lvl'), num = c.querySelector('.num'), s;
        if (!h.id) h.id = 'sec-' + (i + 1);
        each(c.querySelectorAll('.lvl, .sub'), function (x) { x.parentNode.removeChild(x); });
        if (num) {
          s = document.createElement('span'); s.className = 'tnum'; s.textContent = squash(num.textContent);
          li.appendChild(s); num.parentNode.removeChild(num);
        }
        a.href = '#' + h.id; a.textContent = squash(c.textContent);
        li.appendChild(a);
        if (lvl) { s = document.createElement('span'); s.className = 'lvl'; s.textContent = lvl.textContent; li.appendChild(s); }
        if (h.parentNode.classList.contains('annex')) li.className = 'annex';
        else li.style.setProperty('--c', h.parentNode.style.getPropertyValue('--c'));
        ol.appendChild(li);
      });
      box.appendChild(ol);
    });
  }

  function linkify() {
    each(document.querySelectorAll('td.url'), function (td) {
      var u = td.textContent.trim(), a;
      if (td.querySelector('a') || !/^https?:\/\//.test(u)) return;
      a = document.createElement('a'); a.href = u; a.textContent = u;
      td.textContent = ''; td.appendChild(a);
    });
  }

  // French typography: no-break spaces before ; : ! ? » % and after «, so these signs never start a line.
  // Only ordinary spaces typed by the author are replaced; code, URLs and scripts are left alone.
  function typo() {
    if (lang !== 'fr') return;
    var walk = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null), n, p, t;
    while ((n = walk.nextNode())) {
      for (p = n.parentNode; p && p !== document.body; p = p.parentNode) {
        if (/^(SCRIPT|STYLE|CODE|PRE|KBD|SAMP|TEXTAREA)$/.test(p.nodeName) || (p.classList && p.classList.contains('url'))) break;
      }
      if (p !== document.body) continue;
      t = n.nodeValue.replace(/ ([;!?»])/g, ' $1').replace(/« /g, '« ').replace(/ ([:%])/g, ' $1');
      if (t !== n.nodeValue) n.nodeValue = t;
    }
  }

  // Printed text height of an A4 page (297 mm minus the margins of course.css), in CSS pixels.
  var PAGE_H = (297 - 16 - 17) * 96 / 25.4;

  // A box taller than 40 % of a page may break across pages instead of leaving a big gap
  // at the bottom of the previous one. Short boxes stay whole (course.css: .split).
  function splitLong() {
    each(document.querySelectorAll('.tp, .quiz, .recap, .case, .box, .expert, .objectives, .hook, .analogy, .def, .tip, .pitfall, .warn'), function (b) {
      if (!b.closest('.cover') && b.getBoundingClientRect().height > 0.4 * PAGE_H) b.classList.add('split');
    });
  }

  // Warnings printed in the build log, so these problems show up without opening the PDF.
  // The screen layout (body 210 mm wide, see course.css) is close to the printed page.
  function checks() {
    var warn = [], left;
    each(document.querySelectorAll('.cover'), function (c) {
      if (c.scrollHeight > c.clientHeight + 4) warn.push('[layout] the cover overflows its page by ' + Math.round(c.scrollHeight - c.clientHeight) + ' px: shorten it');
    });
    each(document.querySelectorAll('figure svg[width]'), function (svg) {
      var w = +svg.getAttribute('width'), box = svg.getBoundingClientRect(), r = box.width, fig = svg.closest('figure');
      var name = squash(((fig && fig.querySelector('figcaption')) || svg).textContent).slice(0, 50);
      if (svg.closest('.wide')) return;
      if (w && r && r / w < 0.8) warn.push('[layout] diagram shrunk to ' + Math.round(100 * r / w) + ' % (' + name + '): text may be too small, shorten labels or split it');
      if (box.height > 0.9 * PAGE_H) warn.push('[layout] diagram too tall for one page (' + Math.round(box.height * 25.4 / 96) + ' mm, ' + name + '): use fewer items or split it');
    });
    left = document.body.innerText.match(/\[[A-Za-zÀ-ÿ][^\]\n]{2,60}\]/g) || [];
    if (left.length) warn.push('[template] ' + left.length + ' placeholder(s) left, e.g. ' + left.slice(0, 3).join(' '));
    warn.forEach(function (m) { console.warn(m); });
  }

  var KINDS = { mindmap: mindmap, roadmap: roadmap, flow: flow, cycle: cycle, layers: layers, timeline: timeline };

  function run() {
    var drawn = 0, failed = 0;
    FONT = getComputedStyle(document.body).fontFamily || FONT;
    typo(); header(); chapters(); toc(); linkify();
    each(document.querySelectorAll('figure.dg'), function (fig) {
      var list = null, kind = null, cols = fig.getAttribute('data-colors');
      each(fig.children, function (k) { if (!list && (k.tagName === 'UL' || k.tagName === 'OL')) list = k; });
      for (var k in KINDS) if (fig.classList.contains(k)) { kind = k; break; }
      if (!list || !kind) return;
      P = cols ? cols.split(',').map(function (x) { return x.trim(); }) : PALETTE;
      try { KINDS[kind](fig, list); list.style.display = 'none'; drawn++; }
      catch (e) { failed++; fig.classList.add('dg-error'); console.error('[diagrams] ' + kind + ' failed: ' + e.message); }
    });
    P = PALETTE;
    if (probe) { probe.parentNode.parentNode.removeChild(probe.parentNode); probe = null; }
    splitLong(); checks();
    document.documentElement.setAttribute('data-diagrams', drawn + ' drawn, ' + failed + ' failed');
    console.log('[diagrams] ' + drawn + ' drawn, ' + failed + ' failed');
  }

  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', run); else run();
})();
