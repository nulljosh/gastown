// Landing behaviour: fade-up on scroll, and parallax. Nothing here is needed to read the page.
(function () {
  document.documentElement.classList.add('js');
  var still = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;
  var items = Array.prototype.slice.call(document.querySelectorAll('.reveal'));
  if (still || !('IntersectionObserver' in window)) { items.forEach(function (e) { e.classList.add('in'); }); }
  else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) { if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); } });
    }, { rootMargin: '0px 0px -8% 0px' });
    items.forEach(function (e) { io.observe(e); });
  }
  if (still) return;

  // Parallax. data-parallax="s": the element moves by s of its distance from the viewport centre
  // (positive lags behind the page, negative runs ahead); with data-fade it is measured from the top. data-parallax-art="s" does the same to a
  // halftone art layer through --ty. data-fade also fades the element out as it leaves the top.
  var layers = Array.prototype.slice.call(document.querySelectorAll('[data-parallax], [data-parallax-art]'));
  var queued = false;
  function frame() {
    queued = false;
    var vh = window.innerHeight;
    layers.forEach(function (el) {
      var box = el.parentElement.getBoundingClientRect();
      if (box.bottom < -200 || box.top > vh + 200) return;
      var off = (box.top + box.height / 2 - vh / 2);
      var art = el.getAttribute('data-parallax-art');
      if (art !== null) { el.style.setProperty('--ty', (-off * parseFloat(art)).toFixed(1) + 'px'); return; }
      var s = parseFloat(el.getAttribute('data-parallax'));
      var y = el.hasAttribute('data-fade') ? Math.max(0, -box.top) : -off;
      el.style.transform = 'translate3d(0,' + (y * s).toFixed(1) + 'px,0)';
      if (el.hasAttribute('data-fade')) el.style.opacity = String(Math.max(0, 1 - Math.max(0, -box.top) / (vh * 0.6)));
    });
  }
  function ask() { if (!queued) { queued = true; requestAnimationFrame(frame); } }
  window.addEventListener('scroll', ask, { passive: true });
  window.addEventListener('resize', ask);
  ask();
})();
