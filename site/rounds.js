// Campaign rounds animation for #rounds in index.html. Expects #map, #range, #yr, #knows, #legend, #play, #tip, .mapcanvas.
// ---------- synthetic country: hex districts ----------
const TYPES = {
  measles:{name:'Measles‑rubella SIA',c:'var(--measles)'},
  polio:{name:'Polio round',c:'var(--polio)'},
  mda:{name:'NTD mass drug administration',c:'var(--mda)'},
  nets:{name:'Bed‑net distribution',c:'var(--nets)'},
  vita:{name:'Vitamin A',c:'var(--vita)'}
};
// axial hex coords forming a blob; names are invented
const CELLS = [
 [0,-3,'Kalu'],[1,-3,'Bemba'],[2,-3,'Oru'],
 [-1,-2,'Sena'],[0,-2,'Mira'],[1,-2,'Tolo'],[2,-2,'Adi'],[3,-2,'Weke'],
 [-2,-1,'Lomu'],[-1,-1,'Kiri'],[0,-1,'Nako'],[1,-1,'Sabu'],[2,-1,'Ende'],[3,-1,'Yala'],
 [-3,0,'Bori'],[-2,0,'Tami'],[-1,0,'Gora'],[0,0,'Central'],[1,0,'Mosi'],[2,0,'Rafa'],[3,0,'Duma'],
 [-3,1,'Ibe'],[-2,1,'Kanu'],[-1,1,'Pela'],[0,1,'Sori'],[1,1,'Nuru'],[2,1,'Wari'],
 [-2,2,'Ojo'],[-1,2,'Lira'],[0,2,'Bala'],[1,2,'Teso'],
 [-1,3,'Mbeya'],[0,3,'Zila']
];
const N = CELLS.length;
// campaigns in order, each: year, type, districts (indices), and what each round contributes
const ROUNDS = [
 {y:'2022',label:'Q1 2022',t:'measles',d:[3,4,5,9,10,11,16,17], hist:true, note:'Loaded from existing reports: district coverage and denominators only.'},
 {y:'2022',label:'Q3 2022',t:'mda',    d:[14,15,21,22,27,28,31], hist:true, note:'Loaded from existing reports. Most districts still have no record.'},
 {y:'2023',label:'Q1 2023',t:'nets',   d:[0,1,2,6,7,12,13,19], note:'First ICR‑native round: settlements registered, a household register started in the net‑distribution wards.'},
 {y:'2023',label:'Q3 2023',t:'vita',   d:[22,23,24,28,29,30,31,32], note:'Post‑based round: posts and teams recorded, few households added.'},
 {y:'2024',label:'Q1 2024',t:'polio',  d:[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32], note:'First nationwide round. Reused the 2023 settlement lists; enumeration skipped where a register already existed.'},
 {y:'2024',label:'Q3 2024',t:'mda',    d:[8,9,14,15,16,21,22,23,27,28,31], note:'Same posts and CDD teams as the polio round; household register grows in the MDA districts.'},
 {y:'2025',label:'Q1 2025',t:'measles',d:[3,4,5,9,10,11,16,17,18,23,24,25,29,30], note:'Three denominator sources per district for planning.'},
 {y:'2025',label:'Q3 2025',t:'nets',   d:[0,1,2,3,4,5,6,7,11,12,13,19,20,26], note:'Household revisit targeted from the 2023 register; new wards enumerated.'},
 {y:'2026',label:'Q1 2026',t:'vita',   d:[14,15,16,17,18,21,22,23,24,25,27,28,29,30,31,32], note:'Second vitamin A round on the same posts: coverage trend now available.'},
 {y:'2026',label:'Q3 2026',t:'polio',  d:[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32], note:'Every district now has a multi‑year coverage history.'}
];

const R=34, W=640, H=470, cx=W/2+10, cy=H/2+8;
function hexCenter(q,r){ return [cx + R*Math.sqrt(3)*(q + r/2), cy + R*1.5*r]; }
function hexPath(x,y){ const pts=[]; for(let i=0;i<6;i++){const a=Math.PI/180*(60*i-30); pts.push((x+R*Math.cos(a)).toFixed(1)+','+(y+R*Math.sin(a)).toFixed(1));} return 'M'+pts.join('L')+'Z'; }

const svg=document.getElementById('map'); const NS='http://www.w3.org/2000/svg';
const polys=[], labels=[], dotsG=[];
CELLS.forEach((c,i)=>{ const [x,y]=hexCenter(c[0],c[1]);
  const p=document.createElementNS(NS,'path'); p.setAttribute('d',hexPath(x,y)); p.setAttribute('class','district none'); p.dataset.i=i; svg.appendChild(p); polys.push(p);
  const g=document.createElementNS(NS,'g'); g.setAttribute('class','dots'); svg.appendChild(g); dotsG.push(g);
  const t=document.createElementNS(NS,'text'); t.setAttribute('x',x); t.setAttribute('y',y+13); t.setAttribute('class','dlabel'); t.textContent=c[2]; svg.appendChild(t); labels.push(t);
});

// legend
document.getElementById('legend').innerHTML = `<span><i style="background:linear-gradient(90deg,var(--paper-2),var(--reg))"></i>Fill = how much the registry knows (rounds recorded)</span>` + Object.values(TYPES).map(t=>`<span><i style="background:${t.c};border-radius:50%"></i>${t.name}</span>`).join('');

// per-district seeded numbers for tooltips
function seed(i){ let s=(i+1)*9301+49297; return ()=>{ s=(s*9301+49297)%233280; return s/233280; }; }
const meta = CELLS.map((c,i)=>{ const r=seed(i); const settle=40+Math.floor(r()*120), pop=18000+Math.floor(r()*60000); return {settle, pop, hh:Math.round(pop/5.2), teams:Math.round(settle/6), base: 0.62+r()*0.25}; });

// how much of a district each campaign type reaches, per round
// settle: share of unmapped settlements found; hh: share of unregistered households visited; team: share of the team pool engaged
const REACH = {
  polio:  {settle:0.55, hh:0.45, team:0.60},
  nets:   {settle:0.50, hh:0.60, team:0.40},
  mda:    {settle:0.45, hh:0.35, team:0.50},
  measles:{settle:0.35, hh:0.12, team:0.35},
  vita:   {settle:0.30, hh:0.10, team:0.30}
};
function stateAt(k){ // k = index of last round included
  const per = CELLS.map(()=>({rounds:[], types:new Set(), native:0, hist:0, settle:0, hh:0, teams:0}));
  let teams=0, hh=0, settlements=0, cov=0;
  for(let j=0;j<=k;j++){ const rd=ROUNDS[j];
    rd.d.forEach(i=>{ const p=per[i], m=meta[i]; p.rounds.push(rd); p.types.add(rd.t);
      if(rd.hist){ p.hist++; return; }
      p.native++;
      const r=REACH[rd.t];
      // each native round captures a share of what is still unknown, so counts climb quickly at first and then level off
      p.settle += (m.settle - p.settle)*r.settle;
      p.hh     += (m.hh     - p.hh)    *r.hh;
      p.teams  += (m.teams  - p.teams) *r.team;
    });
  }
  per.forEach(p=>{ cov+=p.rounds.length; settlements+=Math.round(p.settle); hh+=Math.round(p.hh); teams+=Math.round(p.teams); });
  const k2 = Math.min(k,ROUNDS.length-1);
  const included = ROUNDS.slice(0,k2+1);
  const hasNative = included.some(r=>!r.hist);
  const nSources = 1 + (hasNative?1:0) + (included.some(r=>r.t==='nets' || r.t==='polio')?1:0) + (k2>=6?1:0);
  return {per, settlements, teams, hh, nSources, cov, rounds:k2+1};
}

const knows=document.getElementById('knows'), yr=document.getElementById('yr'), range=document.getElementById('range'), tip=document.getElementById('tip');
function ramp(v){ const k=Math.min(v/9,1); const a=[238,241,235], b=[47,107,79]; return `rgb(${a.map((c,i)=>Math.round(c+(b[i]-c)*k)).join(',')})`; }
function fmt(n){ return n.toLocaleString('en-US'); }
let flashTimer=null;
function render(k){
  const st=stateAt(k); const rd=ROUNDS[k];
  yr.textContent=rd.label;
  if(flashTimer){ clearTimeout(flashTimer); flashTimer=null; }
  const inRound = new Set(rd.d);
  polys.forEach((p,i)=>{ const d=st.per[i]; const depth=d.rounds.length + d.native*0.5;
    if(!d.rounds.length){ p.setAttribute('class','district none'); p.style.fill=''; }
    else { p.setAttribute('class','district'); p.style.fill = inRound.has(i) ? TYPES[rd.t].c : ramp(depth); }
    labels[i].style.fill = (inRound.has(i) || depth > 5) ? '#fff' : 'var(--ink)';
    const g=dotsG[i]; while(g.firstChild) g.removeChild(g.firstChild);
    const [x,y]=hexCenter(CELLS[i][0],CELLS[i][1]); const n=Math.min(d.rounds.length,8);
    for(let m=0;m<n;m++){ const c=document.createElementNS(NS,'circle'); c.setAttribute('r',2.6); c.setAttribute('cx',x-(n-1)*3.4+m*6.8); c.setAttribute('cy',y-5); c.style.fill=TYPES[d.rounds[m].t].c; g.appendChild(c); }
  });
  // the round's districts show the campaign colour while its data lands, then settle into the registry shade
  flashTimer=setTimeout(()=>{ flashTimer=null;
    polys.forEach((p,i)=>{ if(!inRound.has(i)) return; const d=st.per[i]; const depth=d.rounds.length + d.native*0.5;
      p.style.fill=ramp(depth); labels[i].style.fill = depth > 5 ? '#fff' : 'var(--ink)'; });
  }, 650);
  const covered = st.per.filter(p=>p.rounds.length).length;
  knows.innerHTML = [
    ['Campaign rounds recorded', st.rounds],
    ['Districts with history', covered+' / '+N],
    ['Settlements with stable IDs', st.settlements? fmt(st.settlements):'—'],
    ['Denominator sources per district', st.nSources],
    ['Households in register', st.hh? fmt(st.hh):'—'],
    ['Teams with history', st.teams? fmt(st.teams):'—'],
    ['Coverage data points', fmt(st.cov)]
  ].map(([l,v])=>`<div class="k"><span>${l}</span><b>${v}</b></div>`).join('') + `<div class="k" style="border:0;padding-top:10px"><span style="font-size:13px;color:var(--ink-3)">${rd.hist?'Historical load · ':''}${rd.note}</span></div>`;
}
range.addEventListener('input',()=>{ stop(); render(+range.value); });
render(0);

// play
let timer=null; const play=document.getElementById('play');
function stop(){ if(timer){clearInterval(timer);timer=null;play.textContent='Play the rounds';} }
play.addEventListener('click',()=>{ if(timer){stop();return;} let k=+range.value; if(k>=ROUNDS.length-1) k=-1; play.textContent='Pause';
  timer=setInterval(()=>{ k++; if(k>=ROUNDS.length){stop();return;} range.value=k; render(k); },1500); });

// tooltip
const canvas=document.querySelector('.mapcanvas');
polys.forEach(p=>{
  p.addEventListener('mousemove',e=>{ const i=+p.dataset.i; const st=stateAt(+range.value); const d=st.per[i]; const m=meta[i];
    const rows = d.rounds.length? d.rounds.map((r,j)=>`<div class="row">${r.label} · ${TYPES[r.t].name}${r.hist?' (loaded)':''} · ${Math.round((m.base+j*0.035)*100)}%</div>`).join('') : '<div class="row">No campaign recorded yet</div>';
    tip.innerHTML=`<b>${CELLS[i][2]} District</b><div class="row">Pop. est. ${fmt(m.pop)} · ${d.native? Math.round(d.settle)+' of '+m.settle+' settlements mapped':'settlements not yet mapped'}</div>${rows}`;
    const r=canvas.getBoundingClientRect(); let x=e.clientX-r.left+14, y=e.clientY-r.top+14; const tw=tip.offsetWidth||340; if(x+tw+8>r.width) x=Math.max(4,x-tw-28); tip.style.left=x+'px'; tip.style.top=y+'px'; tip.classList.add('on'); });
  p.addEventListener('mouseleave',()=>tip.classList.remove('on'));
});
