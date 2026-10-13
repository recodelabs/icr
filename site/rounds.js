/* Campaign rounds diagram for #rounds in index.html: the living map. Each round sweeps across the
   district. Where a ward has not been counted yet, the round lists its
   households (a pre-census) and its population appears. Where it has, the
   round starts from that number and updates it. The markup is the final
   frame. */
(() => {
  const svg = document.querySelector('[data-living-map]');
  if (!svg) return;
  const ORANGE = '#2B5A8A', INK = '#17211C', INK2 = '#4A554F', GREY = '#8A948E', OFF = '#D5DAD3';
  const KNOWN = '#E3EAF2', NEW = '#C7D8EA';
  const ROUNDS = 4, T0 = 0.5, RD = 2.8, SWEEP = 1.7, TOTAL = T0 + ROUNDS * RD + 0.2;
  const X0 = 30, X1 = 820;
  const clamp = v => Math.min(1, Math.max(0, v));
  const ease = t => 1 - Math.pow(1 - t, 3);
  const fmt = n => Math.round(n).toLocaleString('en-US');
  const roundStart = r => T0 + (r - 1) * RD;
  const sweepAt = (r, x) => roundStart(r) + SWEEP * (x - X0) / (X1 - X0);

  const households = [...svg.querySelectorAll('[data-households] rect')].map(el => ({
    el, r: +el.dataset.r, x: +el.getAttribute('x') + 1.6,
  }));
  const wards = [...svg.querySelectorAll('[data-wards] > g')].map((g, i) => {
    const label = svg.querySelectorAll('[data-labels] > g')[i];
    return {
      r: +g.dataset.r, x: +g.dataset.cx,
      fill: g.querySelector('[data-fill]'), edge: g.querySelector('[data-edge]'),
      label, num: label.querySelector('[data-num]'), unknown: label.querySelector('[data-unknown]'),
      known: [...label.querySelectorAll('text')].filter(el => !el.hasAttribute('data-unknown')).slice(1),
      hh: label.dataset.hh.split(',').map(Number),
      pop: label.querySelector('[data-pop]'),
      square: svg.querySelector(`[data-ward-square="${i}"] [data-fill]`),
    };
  });
  const rows = [...svg.querySelectorAll('[data-round]')].map(g => ({
    r: +g.dataset.round, marker: g.querySelector('[data-marker]'),
    texts: [...g.querySelectorAll('text')], note: g.querySelector('[data-note]'),
  }));
  const knownCount = svg.querySelector('[data-known-count]');
  const total = svg.querySelector('[data-total]');
  const totalPop = svg.querySelector('[data-total-pop]');
  const sweep = svg.querySelector('[data-sweep]');

  // population shown for a ward at time t: 0 before counted, counts up when
  // first counted, then eases from one round's figure to the next
  // households registered in a ward at time t: none before it is reached,
  // counts up as it is listed, then eases from one round's figure to the next
  function wardState(w, t, done) {
    if (done) return { p: 1, hh: w.hh[ROUNDS - 1], counting: false };
    const first = sweepAt(w.r, w.x);
    if (t < first) return { p: 0, hh: 0, counting: false };
    let hh = w.hh[w.r - 1] * ease(clamp((t - first) / 0.9));
    for (let k = w.r + 1; k <= ROUNDS; k++) {
      const at = sweepAt(k, w.x);
      if (t >= at) hh = w.hh[k - 2] + (w.hh[k - 1] - w.hh[k - 2]) * ease(clamp((t - at) / 0.6));
    }
    const counting = t < roundStart(w.r) + RD;
    return { p: ease(clamp((t - first) / 0.4)), hh, counting };
  }
  const estimate = hh => Math.round(hh * 5.2 / 10) * 10;

  function render(t) {
    const done = t >= TOTAL;
    const cur = done ? ROUNDS : Math.min(ROUNDS, Math.max(1, Math.floor((t - T0) / RD) + 1));
    const isNew = r => r === ROUNDS || t < roundStart(r) + RD;

    households.forEach(h => {
      h.el.style.opacity = done ? 1 : ease(clamp((t - sweepAt(h.r, h.x)) / 0.25));
      h.el.setAttribute('fill', isNew(h.r) && !(done && h.r < ROUNDS) ? ORANGE : INK);
    });

    let known = 0, sum = 0, sumPop = 0;
    wards.forEach(w => {
      const s = wardState(w, t, done);
      w.fill.style.opacity = s.p;
      w.fill.setAttribute('fill', s.counting ? NEW : KNOWN);
      w.square.style.opacity = s.p;
      w.square.setAttribute('fill', s.counting ? NEW : KNOWN);
      w.square.setAttribute('stroke', s.counting ? ORANGE : INK2);
      w.edge.setAttribute('stroke', s.counting && s.p > 0 ? ORANGE : INK2);
      w.edge.setAttribute('opacity', s.counting && s.p > 0 ? 1 : 0.6);
      w.unknown.setAttribute('opacity', s.p > 0 ? 0 : 1);
      w.known.forEach(el => { el.style.opacity = s.p; });
      w.num.textContent = fmt(s.hh);
      w.pop.textContent = fmt(estimate(s.hh));
      if (s.p > 0) { known += 1; sum += s.hh; sumPop += estimate(s.hh); }
    });
    knownCount.textContent = known;
    total.textContent = fmt(sum);
    totalPop.textContent = fmt(sumPop);

    rows.forEach(row => {
      const reached = done || t >= roundStart(row.r);
      const active = row.r === cur && reached && !done;
      row.marker.setAttribute('fill', reached ? row.marker.dataset.c : OFF);
      row.marker.setAttribute('width', active ? 11 : 9);
      row.marker.setAttribute('height', active ? 11 : 9);
      row.texts.forEach((el, i) => {
        if (el === row.note) { el.style.opacity = reached ? 1 : 0; return; }
        el.setAttribute('fill', reached ? (i === 1 ? INK : i === 0 ? INK2 : GREY) : OFF);
      });
    });

    const local = t - roundStart(cur);
    const sweeping = !done && local >= 0 && local <= SWEEP;
    sweep.setAttribute('opacity', sweeping ? 1 : 0);
    if (sweeping) sweep.setAttribute('transform', `translate(${X0 + (X1 - X0) * local / SWEEP} 0)`);
  }

  let raf = 0;
  function play() {
    cancelAnimationFrame(raf);
    const start = performance.now();
    const tick = now => {
      const t = (now - start) / 1000;
      render(t);
      if (t < TOTAL) raf = requestAnimationFrame(tick);
    };
    render(0);
    raf = requestAnimationFrame(tick);
  }

  document.querySelector('#rounds .replay').addEventListener('click', play);
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches || !('IntersectionObserver' in window)) return;
  render(0);
  const io = new IntersectionObserver(entries => {
    if (entries.some(e => e.isIntersecting)) { io.disconnect(); play(); }
  }, { threshold: 0.4 });
  io.observe(svg);
})();
