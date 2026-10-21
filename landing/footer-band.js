// Footer band: New York's things in a row (the tower mark, the Flatiron, a water tower, a taxi, a Brooklyn Bridge tower, a
// subway token), cut like a line engraving in plain 2D canvas. Faint rules run across the band; inside the glyphs they
// thicken, and thicken again on the edge facing away from the light, so the glyphs look cut into the page. Drawn once per size and theme.
// Same band as the Hermes landing (static, no WebGL: it rendered as a black box on iPhone).
(function () {
  var band = document.querySelector('.word-band'), canvas = band && band.querySelector('canvas');
  if (!canvas) return;

  var mark = new Image(), tints = {};
  mark.src = 'mark.svg';

  // Each glyph is drawn white on a 100 unit square.
  function cut(c, fn) { c.globalCompositeOperation = 'destination-out'; fn(); c.globalCompositeOperation = 'source-over'; }
  var GLYPHS = [
    function (c) { // tower: the brand mark itself
      if (!mark.complete || !mark.naturalWidth) return;
      var key = c.fillStyle;
      if (!tints[key]) {
        var t = document.createElement('canvas'); t.width = t.height = 400;
        var tc = t.getContext('2d'); tc.drawImage(mark, 0, 0, 400, 400);
        tc.globalCompositeOperation = 'source-in'; tc.fillStyle = key; tc.fillRect(0, 0, 400, 400);
        tints[key] = t;
      }
      c.drawImage(tints[key], -6, -6, 112, 112);
    },
    function (c) { // Flatiron: a tall wedge with the prow cut by window columns
      c.beginPath(); c.moveTo(16, 94); c.lineTo(16, 30); c.lineTo(58, 6); c.lineTo(84, 94); c.closePath(); c.fill();
      cut(c, function () {
        c.lineWidth = 3.5;
        [27, 38, 49].forEach(function (x) { c.beginPath(); c.moveTo(x, 34); c.lineTo(x, 94); c.stroke(); });
        c.beginPath(); c.moveTo(58, 10); c.lineTo(58, 94); c.stroke();
        c.beginPath(); c.moveTo(16, 36); c.lineTo(58, 36); c.stroke();
      });
    },
    function (c) { // water tower on its legs
      c.beginPath(); c.moveTo(26, 22); c.lineTo(50, 4); c.lineTo(74, 22); c.closePath(); c.fill();
      c.fillRect(28, 22, 44, 34);
      cut(c, function () { c.fillRect(28, 32, 44, 3); c.fillRect(28, 44, 44, 3); });
      c.lineWidth = 5; c.lineCap = 'round';
      c.beginPath(); c.moveTo(34, 56); c.lineTo(28, 94); c.moveTo(66, 56); c.lineTo(72, 94); c.moveTo(34, 56); c.lineTo(66, 94); c.moveTo(66, 56); c.lineTo(34, 94); c.stroke();
    },
    function (c) { // taxi
      c.beginPath(); c.roundRect(6, 52, 88, 24, 9); c.fill();
      c.beginPath(); c.roundRect(26, 32, 48, 24, 8); c.fill();
      c.fillRect(42, 22, 16, 9);
      cut(c, function () { c.fillRect(32, 38, 15, 13); c.fillRect(53, 38, 15, 13); c.beginPath(); c.arc(28, 78, 14, 0, 7); c.arc(72, 78, 14, 0, 7); c.fill(); });
      [28, 72].forEach(function (x) { c.beginPath(); c.arc(x, 78, 10, 0, 7); c.fill(); });
      cut(c, function () { [28, 72].forEach(function (x) { c.beginPath(); c.arc(x, 78, 4, 0, 7); c.fill(); }); });
    },
    function (c) { // Brooklyn Bridge tower: a block with pointed arches, cables running off it
      c.fillRect(24, 14, 52, 80);
      cut(c, function () {
        function arch(x0, x1, base, spring, tip) { c.beginPath(); c.moveTo(x0, base); c.lineTo(x0, spring); c.quadraticCurveTo(x0, spring - (spring - tip) * 0.5, (x0 + x1) / 2, tip); c.quadraticCurveTo(x1, spring - (spring - tip) * 0.5, x1, spring); c.lineTo(x1, base); c.closePath(); c.fill(); }
        arch(34, 66, 94, 66, 44);
        arch(40, 60, 36, 28, 18);
      });
      c.lineWidth = 3; c.lineCap = 'round';
      c.beginPath(); c.moveTo(24, 16); c.lineTo(0, 74); c.moveTo(76, 16); c.lineTo(100, 74); c.moveTo(24, 24); c.lineTo(0, 80); c.moveTo(76, 24); c.lineTo(100, 80); c.stroke();
    },
    function (c) { // subway token
      c.beginPath(); c.arc(50, 52, 42, 0, 7); c.fill();
      cut(c, function () { c.beginPath(); c.arc(50, 52, 33, 0, 7); c.fill(); });
      c.beginPath(); c.arc(50, 52, 27, 0, 7); c.fill();
      cut(c, function () {
        c.lineWidth = 8; c.lineCap = 'round'; c.lineJoin = 'round';
        c.beginPath(); c.moveTo(36, 38); c.lineTo(50, 54); c.lineTo(64, 38); c.moveTo(50, 54); c.lineTo(50, 70); c.stroke();
      });
    }
  ];
  // Lays the glyphs out evenly across a w by h 2D context, in the given colour: one row, or two on a narrow band.
  function grid(w, h) {
    var n = GLYPHS.length, rows = w < h * 3 ? 2 : 1, per = Math.ceil(n / rows);
    return { rows: rows, per: per, cell: Math.min(h / rows * 0.86, w / per) };
  }
  function paint(c, w, h, colour) {
    var g = grid(w, h), gap = (w - g.cell * g.per) / g.per, rowH = h / g.rows;
    GLYPHS.forEach(function (draw, i) {
      var col = i % g.per, row = Math.floor(i / g.per);
      c.save(); c.translate(gap / 2 + col * (g.cell + gap), row * rowH + (rowH - g.cell) / 2 + rowH * 0.04); c.scale(g.cell / 100, g.cell / 100);
      c.fillStyle = c.strokeStyle = colour; draw(c); c.restore();
    });
  }

  var ctx = canvas.getContext('2d');
  if (!ctx) return;
  function layer(w, h) { var c = document.createElement('canvas'); c.width = w; c.height = h; return c; }
  // Horizontal rules `t` px thick, one every `pitch` px, kept only where `mask` is drawn (everywhere when null).
  function rules(w, h, pitch, t, colour, mask) {
    var c = layer(w, h), x = c.getContext('2d');
    x.fillStyle = colour;
    for (var y = 0; y < h; y += pitch) x.fillRect(0, Math.round(y + (pitch - t) / 2), w, Math.max(1, Math.round(t)));
    if (mask) { x.globalCompositeOperation = 'destination-in'; x.drawImage(mask, 0, 0); }
    return c;
  }
  var drawnW = 0;
  function draw() {
    var dpr = Math.min(window.devicePixelRatio || 1, 2), w = Math.round(canvas.clientWidth * dpr), h = Math.round(canvas.clientHeight * dpr);
    if (!w || !h) return;
    drawnW = w; canvas.width = w; canvas.height = h;
    var colour = getComputedStyle(band).color, pitch = Math.min(5 * dpr, Math.max(3 * dpr, grid(w, h).cell / 22)), s = Math.max(2, h * 0.014);
    var glyphs = layer(w, h); paint(glyphs.getContext('2d'), w, h, '#fff');
    // the shadow side: glyph pixels whose neighbour down and right is outside the glyph (light from the top left)
    var shade = layer(w, h), sc = shade.getContext('2d');
    sc.drawImage(glyphs, 0, 0); sc.globalCompositeOperation = 'destination-out'; sc.drawImage(glyphs, -s, -s);
    ctx.globalAlpha = 0.28; ctx.drawImage(rules(w, h, pitch, dpr * 0.75, colour, null), 0, 0);
    ctx.globalAlpha = 1; ctx.drawImage(rules(w, h, pitch, pitch * 0.32, colour, glyphs), 0, 0);
    ctx.drawImage(rules(w, h, pitch, pitch * 0.6, colour, shade), 0, 0);
    // fade out toward the legal line
    var g = ctx.createLinearGradient(0, h * 0.88, 0, h);
    g.addColorStop(0, '#000'); g.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.globalCompositeOperation = 'destination-in'; ctx.fillStyle = g; ctx.fillRect(0, 0, w, h);
    ctx.globalCompositeOperation = 'source-over';
  }
  band.classList.add('live');
  draw();
  mark.addEventListener('load', draw);
  // iOS fires resize as the toolbar slides; only a width change needs a redraw
  window.addEventListener('resize', function () { if (Math.round(canvas.clientWidth * Math.min(window.devicePixelRatio || 1, 2)) !== drawnW) draw(); });
  matchMedia('(prefers-color-scheme: dark)').addEventListener('change', draw);
})();
