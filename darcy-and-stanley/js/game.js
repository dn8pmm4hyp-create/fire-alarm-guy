/* ============================================================
   DARCY & STANLEY — arcade brawler
   Level 1: city streets (on foot)
   Level 2: highway chase (car)
   Level 3: deep space (spaceship) + mothership boss
   ============================================================ */
(function(){
'use strict';

const cv = document.getElementById('game');
const ctx = cv.getContext('2d');
const W = cv.width, H = cv.height;

// ---------- input ----------
const keys = {};
const KMAP = {
  ArrowLeft:'left', KeyA:'left',
  ArrowRight:'right', KeyD:'right',
  ArrowUp:'jump', KeyW:'jump', Space:'jump',
  ArrowDown:'down', KeyS:'down',
  KeyJ:'attack', KeyF:'attack',
  KeyK:'weapon', KeyL:'weapon',
  KeyQ:'switch'
};
addEventListener('keydown', e=>{
  const a=KMAP[e.code]; if(!a) return;
  e.preventDefault();
  if(!keys[a]) press(a);
  keys[a]=true;
});
addEventListener('keyup', e=>{ const a=KMAP[e.code]; if(a){ keys[a]=false; e.preventDefault(); }});
function press(a){
  if(a==='attack') doAttack();
  if(a==='weapon') doWeapon();
  if(a==='jump') doJump();
  if(a==='switch') switchHero();
}

// touch
if(('ontouchstart' in window)|| navigator.maxTouchPoints>0){ document.body.classList.add('touch'); }
function bindTouch(id, action, hold){
  const el=document.getElementById(id); if(!el) return;
  const on=e=>{e.preventDefault(); if(hold) keys[action]=true; else press(action);};
  const off=e=>{e.preventDefault(); if(hold) keys[action]=false;};
  el.addEventListener('touchstart',on,{passive:false}); el.addEventListener('mousedown',on);
  el.addEventListener('touchend',off,{passive:false}); el.addEventListener('mouseup',off); el.addEventListener('mouseleave',off);
}
bindTouch('tc-left','left',true);
bindTouch('tc-right','right',true);
bindTouch('tc-jump','jump',false);
bindTouch('tc-attack','attack',false);
bindTouch('tc-weapon','weapon',false);
bindTouch('tc-switch','switch',false);

// ---------- game state ----------
const G = {
  mode:'menu',        // menu | playing | between
  level:1,
  hero:'darcy',
  hp:100, maxhp:100,
  score:0,
  killNeed:0, killHave:0,
  enemies:[], shots:[], parts:[], items:[], stars:[],
  t:0, shake:0,
  boss:null,
  spawnTimer:0
};
const player = { x:W*0.3, y:0, vx:0, vy:0, w:34, h:64, facing:1, onGround:false,
  spin:0, atkCd:0, wpnCd:0, invuln:0, mode:'foot' };

// signature weapon per hero
const WEAPONS = {
  darcy:   { name:'STAR BATON',  cd:80 },
  stanley: { name:'GOLDEN BOOT', cd:95 }
};

// physics tuning per mode
const GRAV = 0.9, GROUND_Y = H-70;

// ---------- level config ----------
const LEVELS = {
  1:{ name:'LEVEL 1 — CITY STREETS', mode:'foot', need:10,
      text:'The baddies have swarmed downtown. Brawl through the neon streets! Darcy spin-kicks up close — Stanley curls footballs from range. Clear 10 enemies.' },
  2:{ name:'LEVEL 2 — HIGHWAY CHASE', mode:'car', need:12,
      text:'You commandeer a turbo car. The enemy convoy is closing in from ahead. Blast or ram 12 hostiles. Mind the traffic!' },
  3:{ name:'LEVEL 3 — DEEP SPACE', mode:'ship', need:14,
      text:'Punch into orbit in a star-fighter. Free-fly with the arrows. Wipe out 14 alien craft — then take down the MOTHERSHIP.' }
};

// ---------- helpers ----------
const rand=(a,b)=>a+Math.random()*(b-a);
const clamp=(v,a,b)=>v<a?a:v>b?b:v;
function burst(x,y,color,n,spd){ for(let i=0;i<n;i++){const an=rand(0,Math.PI*2);G.parts.push({x,y,vx:Math.cos(an)*rand(1,spd),vy:Math.sin(an)*rand(1,spd),life:rand(18,40),color});} }
function rr(x,y,w,h,r){ctx.beginPath();ctx.moveTo(x+r,y);ctx.arcTo(x+w,y,x+w,y+h,r);ctx.arcTo(x+w,y+h,x,y+h,r);ctx.arcTo(x,y+h,x,y,r);ctx.arcTo(x,y,x+w,y,r);ctx.closePath();}

// init starfield (used in space + a few twinkles elsewhere)
for(let i=0;i<140;i++) G.stars.push({x:rand(0,W),y:rand(0,H),z:rand(.3,1.6),s:rand(.6,2.2)});

// ---------- DOM ----------
const el = id=>document.getElementById(id);
const hud=el('hud'), hpfill=el('hpfill'), levelBadge=el('levelBadge'),
      scoreBadge=el('scoreBadge'), enemyBadge=el('enemyBadge'), whoLabel=el('whoLabel'),
      wpnBadge=el('wpnBadge');
const startOverlay=el('startOverlay'), introOverlay=el('introOverlay'),
      endOverlay=el('endOverlay'), muteBtn=el('muteBtn');

// character select preview canvases
document.querySelectorAll('.pick').forEach(p=>{
  const k=p.dataset.pick, c=p.querySelector('canvas'), x=c.getContext('2d');
  let t=0;(function loop(){x.clearRect(0,0,120,150);if(window.DSChars)DSChars.draw(x,60,120+Math.sin(t/18)*5,k,t,1.3,1);t++;requestAnimationFrame(loop);})();
  p.addEventListener('click',()=>{ G.hero=k; document.querySelectorAll('.pick').forEach(z=>z.style.opacity=.5); p.style.opacity=1; });
});

el('startBtn').onclick = ()=>{ DSMusic.start(); if(window.DSFx) DSFx.setEnabled(true); muteBtn.style.display='block'; muteBtn.textContent='🔊 Sound'; startGame(); };
el('introBtn').onclick = ()=>{ introOverlay.classList.add('hidden'); G.mode='playing'; document.body.classList.add('playing'); };
el('retryBtn').onclick = ()=>{ endOverlay.classList.add('hidden'); startGame(); };
muteBtn.onclick = ()=>{ const on=DSMusic.toggle(); if(window.DSFx) DSFx.setEnabled(on); muteBtn.textContent = on?'🔊 Sound':'🔇 Muted'; };

function startGame(){
  G.level=1; G.score=0; G.hp=G.maxhp; G.hero=G.hero||'darcy';
  startOverlay.classList.add('hidden'); endOverlay.classList.add('hidden');
  hud.style.display='flex';
  loadLevel(1);
}
function loadLevel(n){
  G.level=n; const L=LEVELS[n];
  G.enemies=[]; G.shots=[]; G.parts=[]; G.items=[]; G.boss=null;
  G.killNeed=L.need; G.killHave=0; G.spawnTimer=60;
  player.mode=L.mode; player.x=W*0.28; player.vx=0; player.vy=0; player.invuln=60;
  player.spin=0; player.atkCd=0; player.wpnCd=0;
  player.y = L.mode==='ship' ? H/2 : GROUND_Y; player.onGround=(L.mode!=='ship');
  G.hp = Math.min(G.maxhp, G.hp+30); // small heal between levels
  levelBadge.textContent = 'LEVEL '+n;
  // intro card
  introOverlay.classList.remove('hidden');
  el('introTitle').textContent = L.name.split('—')[0].trim();
  el('introTitle').className = n===1?'o-pink':n===3?'o-cyan':'o-pink';
  el('introText').textContent = L.text;
  G.mode='between';
  document.body.classList.remove('playing');
}

// ---------- actions ----------
function switchHero(){ if(G.mode!=='playing')return; G.hero = G.hero==='darcy'?'stanley':'darcy';
  burst(player.x,player.y-30, G.hero==='darcy'?'#ff2e88':'#00f0ff',16,5); }
function doJump(){
  if(G.mode!=='playing')return;
  if(player.mode==='ship') return; // ship uses held thrust
  if(player.onGround){ player.vy = player.mode==='car'?-13:-15; player.onGround=false; }
}
function doAttack(){
  if(G.mode!=='playing'||player.atkCd>0)return;
  if(G.hero==='stanley'){
    // football projectile
    G.shots.push({x:player.x+player.facing*22, y:player.y-34, vx:player.facing*11, vy:-2, t:0, kind:'ball', friendly:true, dmg:34, r:10});
    player.atkCd=22;
  } else {
    // darcy spin — melee aura
    player.spin=18; player.atkCd=26;
    burst(player.x,player.y-30,'#ff2e88',10,4);
  }
}
function doWeapon(){
  if(G.mode!=='playing'||player.wpnCd>0)return;
  const f=player.facing, ox=player.x+f*22, oy=player.y-34;
  if(G.hero==='darcy'){
    // STAR BATON — a fan of three spinning, piercing batons
    for(const a of [-0.26,0,0.26]){
      G.shots.push({x:ox,y:oy,vx:f*12*Math.cos(a),vy:12*Math.sin(a),t:0,kind:'baton',friendly:true,dmg:28,r:11,pierce:1,spin:0});
    }
    burst(ox,oy,'#ffe600',16,5);
    player.wpnCd=WEAPONS.darcy.cd;
  } else {
    // GOLDEN BOOT — a flaming megaball that rips through a whole line of baddies
    G.shots.push({x:ox,y:oy,vx:f*14,vy:0,t:0,kind:'megaball',friendly:true,dmg:60,r:18,pierce:5,spin:0});
    burst(ox,oy,'#ff8a00',18,6); G.shake=8;
    player.wpnCd=WEAPONS.stanley.cd;
  }
}

// ---------- spawning ----------
function spawnEnemy(){
  const m=player.mode;
  const fromRight = Math.random()<(m==='foot'?0.55:0.85);
  const x = fromRight ? W+40 : -40;
  const dir = fromRight ? -1 : 1;
  if(m==='foot'){
    G.enemies.push({x,y:GROUND_Y, vx:dir*rand(1.4,2.4), vy:0, w:30,h:58, hp:34, type:'thug', dir, t:0, onGround:true});
  } else if(m==='car'){
    const lane = rand(GROUND_Y-90, GROUND_Y);
    G.enemies.push({x:W+50, y:lane, vx:-rand(3,5.5), vy:0, w:70,h:34, hp:40, type:'car', dir:-1, t:0, shootCd:rand(60,140)});
  } else { // ship
    const y=rand(50,H-60);
    G.enemies.push({x:W+50, y, vx:-rand(2.5,4.5), vy:rand(-1,1)*0, w:46,h:30, hp:40, type:'ufo', dir:-1, t:0, baseY:y, shootCd:rand(50,120)});
  }
}
function spawnBoss(){
  G.boss = { x:W+200, y:H/2, vx:-1.2, w:200, h:140, hp:600, maxhp:600, t:0, shootCd:60, entered:false };
}

// ---------- update ----------
function update(){
  G.t++;
  if(G.shake>0) G.shake*=0.86;
  if(G.mode!=='playing'){ updateParticles(); return; }

  // ----- player movement -----
  const speed = player.mode==='ship'?5.2 : player.mode==='car'?4.4 : 4.2;
  let mvx=0;
  if(keys.left) mvx-=1; if(keys.right) mvx+=1;
  if(mvx) player.facing = mvx>0?1:-1;

  if(player.mode==='ship'){
    let mvy=0; if(keys.jump||keys.up) mvy-=1; if(keys.down) mvy+=1;
    player.vx += mvx*1.2; player.vy += mvy*1.2;
    player.vx*=0.85; player.vy*=0.85;
    player.x = clamp(player.x+player.vx, 30, W-30);
    player.y = clamp(player.y+player.vy, 30, H-30);
  } else {
    player.vx = mvx*speed;
    player.x = clamp(player.x+player.vx, 20, W-20);
    player.vy += GRAV; player.y += player.vy;
    const gy = player.mode==='car'?GROUND_Y:GROUND_Y;
    if(player.y>=gy){ player.y=gy; player.vy=0; player.onGround=true; } else player.onGround=false;
  }

  if(player.atkCd>0) player.atkCd--;
  if(player.wpnCd>0) player.wpnCd--;
  if(player.spin>0) player.spin--;
  if(player.invuln>0) player.invuln--;

  // darcy spin hits enemies
  if(player.spin>0){
    const R=58;
    G.enemies.forEach(e=>{ if(dist(e,player)<R){ hurtEnemy(e,5); } });
    if(G.boss && dist(G.boss,player)<110) hurtBoss(6);
  }

  // ----- spawn logic -----
  if(!G.boss){
    G.spawnTimer--;
    const alive=G.enemies.length;
    const cap = player.mode==='foot'?4:6;
    if(G.spawnTimer<=0 && alive<cap && (G.killHave+alive)<G.killNeed){
      spawnEnemy(); G.spawnTimer = rand(40,90);
    }
    // level 3: once enough killed and no enemies, summon boss
    if(G.level===3 && G.killHave>=G.killNeed && G.enemies.length===0 && !G.boss){
      spawnBoss();
    } else if(G.level!==3 && G.killHave>=G.killNeed && G.enemies.length===0){
      levelComplete();
    }
  }

  updateEnemies();
  updateBoss();
  updateShots();
  updateParticles();
  updateStars();

  if(G.hp<=0){ gameOver(false); }
}

function dist(a,b){ const dx=a.x-b.x, dy=(a.y-30)-(b.y-30); return Math.hypot(dx,dy); }

function updateEnemies(){
  for(let i=G.enemies.length-1;i>=0;i--){
    const e=G.enemies[i]; e.t++;
    if(e.type==='thug'){
      // walk toward player
      const dir = player.x>e.x?1:-1; e.vx = dir*Math.abs(e.vx); e.dir=dir;
      e.x+=e.vx;
      // attack on contact
      if(Math.abs(e.x-player.x)<34 && Math.abs(e.y-player.y)<50){ damagePlayer(8); e.x-=dir*20; }
    } else if(e.type==='car'){
      e.x+=e.vx; e.y+=Math.sin(e.t/30)*0.6;
      e.shootCd--; if(e.shootCd<=0){ e.shootCd=rand(80,150);
        G.shots.push({x:e.x-30,y:e.y, vx:-7,vy:0,t:0,kind:'bolt',friendly:false,dmg:10,r:6}); }
      if(rectHit(e,player)){ damagePlayer(14); burst(e.x,e.y,'#ffae00',12,5); e.hp-=20; }
    } else if(e.type==='ufo'){
      e.x+=e.vx; e.y = e.baseY + Math.sin(e.t/22)*40;
      e.shootCd--; if(e.shootCd<=0){ e.shootCd=rand(70,140);
        const an=Math.atan2(player.y-e.y, player.x-e.x);
        G.shots.push({x:e.x,y:e.y,vx:Math.cos(an)*6,vy:Math.sin(an)*6,t:0,kind:'plasma',friendly:false,dmg:12,r:6}); }
      if(rectHit(e,player)){ damagePlayer(16); e.hp=0; burst(e.x,e.y,'#9b5cff',16,6); }
    }
    if(e.x<-80||e.x>W+90){ if(e.type==='thug'&&e.x<-80){/* escaped, respawn side */} G.enemies.splice(i,1); continue; }
    if(e.hp<=0){ killEnemy(e,i); }
  }
}

function updateBoss(){
  const B=G.boss; if(!B) return; B.t++;
  if(!B.entered){ B.x+=B.vx; if(B.x<=W-160){ B.entered=true; } }
  else { B.y = H/2 + Math.sin(B.t/40)*120; }
  B.shootCd--;
  if(B.shootCd<=0 && B.entered){ B.shootCd=34;
    for(let k=-1;k<=1;k++){ const an=Math.atan2((player.y-B.y), (player.x-B.x))+k*0.32;
      G.shots.push({x:B.x-60,y:B.y,vx:Math.cos(an)*5.5,vy:Math.sin(an)*5.5,t:0,kind:'plasma',friendly:false,dmg:10,r:7}); }
  }
  if(rectHit(B,player)) damagePlayer(2);
  if(B.hp<=0){ // win
    burst(B.x,B.y,'#00f0ff',60,9); burst(B.x,B.y,'#ffe600',40,7); G.shake=24; G.score+=500; G.boss=null;
    setTimeout(()=>levelComplete(), 600);
  }
}

function updateShots(){
  for(let i=G.shots.length-1;i>=0;i--){
    const s=G.shots[i]; s.t++;
    s.x+=s.vx; s.y+=s.vy;
    if(s.kind==='ball'){ s.vy+=0.25; s.spin=(s.spin||0)+0.4; } // football arcs
    if(s.kind==='baton'||s.kind==='megaball') s.spin=(s.spin||0)+0.6;
    if(s.friendly){
      let consumed=false;
      // hit enemies; piercing shots keep going and remember who they've struck
      for(const e of G.enemies){
        if(s.hit && s.hit.indexOf(e)>=0) continue;
        if(Math.abs(e.x-s.x)<e.w/2+s.r && Math.abs((e.y-25)-s.y)<e.h/2+s.r){
          hurtEnemy(e,s.dmg); (s.hit||(s.hit=[])).push(e);
          if(s.pierce>0) s.pierce--; else consumed=true;
          break;
        }
      }
      if(!consumed && G.boss && !s.bossHit && Math.abs(G.boss.x-s.x)<G.boss.w/2+s.r && Math.abs(G.boss.y-s.y)<G.boss.h/2+s.r){
        hurtBoss(s.dmg); s.bossHit=true; burst(s.x,s.y,'#fff',8,5);
        if(s.pierce>0) s.pierce--; else consumed=true;
      }
      if(consumed){ G.shots.splice(i,1); continue; }
    } else {
      if(player.invuln<=0 && Math.abs(player.x-s.x)<22 && Math.abs((player.y-30)-s.y)<34){ damagePlayer(s.dmg); G.shots.splice(i,1); continue; }
    }
    if(s.x<-30||s.x>W+30||s.y<-30||s.y>H+30){ G.shots.splice(i,1); }
  }
}
function updateParticles(){
  for(let i=G.parts.length-1;i>=0;i--){ const p=G.parts[i]; p.x+=p.vx;p.y+=p.vy;p.vy+=0.12;p.life--; if(p.life<=0)G.parts.splice(i,1); }
}
function updateStars(){ const sp=player.mode==='ship'?4:player.mode==='car'?6:1.2;
  G.stars.forEach(s=>{ s.x-=s.z*sp; if(s.x<0){s.x=W;s.y=rand(0,H);} }); }

function rectHit(e,p){ return Math.abs(e.x-p.x)<(e.w/2+p.w/2) && Math.abs(e.y-p.y)<(e.h/2+p.h/2); }
function hurtEnemy(e,d){ e.hp-=d; e.flash=6; burst(e.x,e.y-20,'#fff',4,4); }
function hurtBoss(d){ G.boss.hp-=d; G.boss.flash=5; }
function killEnemy(e,i){ burst(e.x,e.y-20, e.type==='thug'?'#ff5577':e.type==='car'?'#ffae00':'#9b5cff', 18,6);
  G.enemies.splice(i,1); G.killHave++; G.score += e.type==='thug'?50:80; G.shake=6;
  if(window.DSFx) DSFx.shout(G.hero); // "wey hey!" — Darcy high, Stanley deep
  if(Math.random()<0.16) G.items.push({x:e.x,y:e.type==='thug'?GROUND_Y:e.y, t:0, kind:'heart'});
}
function damagePlayer(d){ if(player.invuln>0)return; G.hp=clamp(G.hp-d,0,G.maxhp); player.invuln=40; G.shake=10; burst(player.x,player.y-30,'#ff2e88',8,4); }

function levelComplete(){
  if(G.level>=3){ gameOver(true); return; }
  loadLevel(G.level+1);
}
function gameOver(win){
  G.mode='menu';
  document.body.classList.remove('playing');
  endOverlay.classList.remove('hidden');
  el('endTitle').textContent = win?'YOU WIN!':'GAME OVER';
  el('endTitle').className = win?'o-cyan':'o-pink';
  el('endText').textContent = win
    ? `Darcy & Stanley saved the galaxy! Final score: ${G.score}. The baddies never stood a chance against a flip and a free-kick.`
    : `The baddies got the better of you this time. Final score: ${G.score}. Dust off and run it back!`;
}

// items pickup check (inside update loop via separate pass)
function updateItems(){
  for(let i=G.items.length-1;i>=0;i--){ const it=G.items[i]; it.t++;
    if(Math.abs(it.x-player.x)<30 && Math.abs(it.y-player.y)<50){ G.hp=clamp(G.hp+22,0,G.maxhp); burst(it.x,it.y-20,'#5cff8f',12,4); G.items.splice(i,1); continue; }
    if(it.t>600) G.items.splice(i,1);
  }
}

// ============================================================
//  RENDER
// ============================================================
function draw(){
  ctx.save();
  if(G.shake>0.5){ ctx.translate(rand(-G.shake,G.shake), rand(-G.shake,G.shake)); }

  if(player.mode==='foot') drawCity();
  else if(player.mode==='car') drawHighway();
  else drawSpace();

  // items
  G.items.forEach(it=>{ ctx.save(); ctx.translate(it.x,it.y-30+Math.sin(it.t/12)*4);
    ctx.fillStyle='#5cff8f'; ctx.font='24px sans-serif'; ctx.textAlign='center'; ctx.fillText('❤',0,0); ctx.restore(); });

  // enemies
  G.enemies.forEach(e=>drawEnemy(e));
  if(G.boss) drawBoss(G.boss);

  // shots
  G.shots.forEach(s=>drawShot(s));

  // player
  if(!(player.invuln>0 && Math.floor(G.t/4)%2)) drawPlayer();

  // particles
  G.parts.forEach(p=>{ ctx.globalAlpha=clamp(p.life/30,0,1); ctx.fillStyle=p.color; ctx.fillRect(p.x-2,p.y-2,4,4); });
  ctx.globalAlpha=1;

  ctx.restore();
  drawHUD();
}

function drawPlayer(){
  ctx.save();
  if(player.mode==='car'){ drawCar(player.x,player.y, true); ctx.restore(); /* hero peeks */
    if(window.DSChars) DSChars.draw(ctx, player.x-4, player.y-22, G.hero, G.t, 0.85, player.facing);
    return; }
  if(player.mode==='ship'){ drawShip(player.x,player.y, player.facing,true);
    if(window.DSChars) DSChars.draw(ctx, player.x, player.y+8, G.hero, G.t, 0.6, 1);
    ctx.restore(); return; }
  // foot
  const spinning = player.spin>0;
  if(spinning){
    ctx.save(); ctx.translate(player.x, player.y-30);
    ctx.rotate(G.t*0.9*player.facing);
    if(window.DSChars) DSChars.draw(ctx, 0, 30, G.hero, G.t*3, 1.1, player.facing);
    ctx.restore();
    // spin aura
    ctx.strokeStyle='rgba(255,46,136,.7)'; ctx.lineWidth=4;
    ctx.beginPath(); ctx.arc(player.x,player.y-30,52,0,Math.PI*2); ctx.stroke();
  } else {
    if(window.DSChars) DSChars.draw(ctx, player.x, player.y, G.hero, G.t* (Math.abs(player.vx)>1?1:0.25), 1.1, player.facing);
  }
  ctx.restore();
}

function drawEnemy(e){
  ctx.save();
  if(e.type==='thug'){
    const skin='#c98', cloth='#3a2f5c';
    if(e.flash){ctx.globalAlpha=1;} e.flash&&e.flash--;
    // shadow
    ctx.fillStyle='rgba(0,0,0,.3)'; ctx.beginPath(); ctx.ellipse(e.x,e.y+2,15,5,0,0,7); ctx.fill();
    // body
    ctx.fillStyle = e.flash? '#fff': cloth; rr(e.x-13,e.y-46,26,34,6); ctx.fill();
    // head
    ctx.fillStyle = e.flash?'#fff':skin; ctx.beginPath(); ctx.arc(e.x,e.y-54,9,0,7); ctx.fill();
    // angry mask eyes
    ctx.fillStyle='#ff2e2e'; ctx.fillRect(e.x-6,e.y-56,4,3); ctx.fillRect(e.x+2,e.y-56,4,3);
    // legs
    ctx.strokeStyle='#222'; ctx.lineWidth=5; ctx.lineCap='round';
    const sw=Math.sin(e.t/5)*5;
    ctx.beginPath(); ctx.moveTo(e.x,e.y-12); ctx.lineTo(e.x+sw,e.y); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(e.x,e.y-12); ctx.lineTo(e.x-sw,e.y); ctx.stroke();
  } else if(e.type==='car'){
    drawCar(e.x,e.y,false, e.flash); e.flash&&e.flash--;
  } else {
    // ufo
    ctx.fillStyle = e.flash?'#fff':'#6b2fb5'; e.flash&&e.flash--;
    ctx.beginPath(); ctx.ellipse(e.x,e.y,24,10,0,0,7); ctx.fill();
    ctx.fillStyle = e.flash?'#fff':'#b98cff';
    ctx.beginPath(); ctx.arc(e.x,e.y-6,11,Math.PI,0); ctx.fill();
    ctx.fillStyle='#00f0ff'; ctx.beginPath(); ctx.arc(e.x-9,e.y+1,2.5,0,7); ctx.arc(e.x,e.y+3,2.5,0,7); ctx.arc(e.x+9,e.y+1,2.5,0,7); ctx.fill();
  }
  ctx.restore();
}

function drawCar(x,y,isPlayer,flash){
  const body = flash?'#fff': isPlayer?'#ff2e88':'#444b6e';
  ctx.save();
  ctx.fillStyle='rgba(0,0,0,.3)'; ctx.beginPath(); ctx.ellipse(x,y+14,40,7,0,0,7); ctx.fill();
  ctx.fillStyle=body; rr(x-35,y-12,70,26,8); ctx.fill();
  ctx.fillStyle = isPlayer?'#7a0a3e':'#2a3050'; rr(x-18,y-26,36,16,6); ctx.fill();
  ctx.fillStyle='#9fd8ff'; rr(x-14,y-24,30,12,4); ctx.fill();
  // wheels
  ctx.fillStyle='#111'; ctx.beginPath(); ctx.arc(x-22,y+14,8,0,7); ctx.arc(x+22,y+14,8,0,7); ctx.fill();
  ctx.fillStyle='#888'; ctx.beginPath(); ctx.arc(x-22,y+14,3,0,7); ctx.arc(x+22,y+14,3,0,7); ctx.fill();
  // headlight glow
  ctx.fillStyle = isPlayer?'rgba(255,230,0,.8)':'rgba(255,80,80,.8)';
  const lx = isPlayer? x+34 : x-34; ctx.beginPath(); ctx.arc(lx,y,4,0,7); ctx.fill();
  ctx.restore();
}
function drawShip(x,y,face,isPlayer){
  ctx.save(); ctx.translate(x,y);
  // thruster
  ctx.fillStyle='rgba(255,180,0,.9)'; ctx.beginPath();
  ctx.moveTo(-22,0); ctx.lineTo(-34-Math.random()*8,-5); ctx.lineTo(-34-Math.random()*8,5); ctx.closePath(); ctx.fill();
  ctx.fillStyle=isPlayer?'#00f0ff':'#888'; ctx.beginPath();
  ctx.moveTo(26,0); ctx.lineTo(-18,-14); ctx.lineTo(-10,0); ctx.lineTo(-18,14); ctx.closePath(); ctx.fill();
  ctx.fillStyle='#ff2e88'; ctx.beginPath(); ctx.arc(4,0,5,0,7); ctx.fill();
  // wings
  ctx.fillStyle='#0a7d8c'; ctx.beginPath(); ctx.moveTo(-6,-8); ctx.lineTo(-20,-20); ctx.lineTo(-16,-6); ctx.closePath();
  ctx.moveTo(-6,8); ctx.lineTo(-20,20); ctx.lineTo(-16,6); ctx.closePath(); ctx.fill();
  ctx.restore();
}
function drawShip2(){}

function drawBoss(B){
  ctx.save(); ctx.translate(B.x,B.y);
  if(B.flash){ctx.globalAlpha=1;B.flash--;}
  // body
  const g=ctx.createLinearGradient(0,-70,0,70); g.addColorStop(0,'#5a2a8c'); g.addColorStop(1,'#2a1248');
  ctx.fillStyle=B.flash?'#fff':g; ctx.beginPath(); ctx.ellipse(0,0,100,60,0,0,7); ctx.fill();
  ctx.fillStyle=B.flash?'#fff':'#8a5cff'; ctx.beginPath(); ctx.ellipse(-10,-20,55,28,0,0,7); ctx.fill();
  // glow core
  ctx.fillStyle='#ff2e88'; ctx.beginPath(); ctx.arc(-10,-18,12+Math.sin(B.t/8)*3,0,7); ctx.fill();
  // turrets
  ctx.fillStyle='#1a0d33'; [-50,0,50].forEach(tx=>{ctx.beginPath();ctx.arc(tx,40,10,0,7);ctx.fill();});
  // lights
  for(let i=-4;i<=4;i++){ ctx.fillStyle = (i+Math.floor(B.t/10))%2? '#00f0ff':'#ffe600'; ctx.beginPath(); ctx.arc(i*18,28,2.5,0,7); ctx.fill(); }
  ctx.restore();
  // boss hp bar
  ctx.fillStyle='rgba(0,0,0,.5)'; ctx.fillRect(W/2-160,18,320,14);
  ctx.fillStyle='#ff2e88'; ctx.fillRect(W/2-158,20,316*(B.hp/B.maxhp),10);
  ctx.fillStyle='#fff'; ctx.font='bold 11px Russo One,sans-serif'; ctx.textAlign='center'; ctx.fillText('MOTHERSHIP',W/2,16);
}

function drawShot(s){
  ctx.save();
  if(s.kind==='ball'){ // football
    ctx.translate(s.x,s.y); ctx.rotate(s.spin||0);
    ctx.fillStyle='#fff'; ctx.beginPath(); ctx.arc(0,0,s.r,0,7); ctx.fill();
    ctx.fillStyle='#111'; ctx.beginPath(); ctx.moveTo(0,-5);ctx.lineTo(4,-2);ctx.lineTo(3,3);ctx.lineTo(-3,3);ctx.lineTo(-4,-2);ctx.closePath(); ctx.fill();
  } else if(s.kind==='bolt'){
    ctx.fillStyle='#ffae00'; ctx.fillRect(s.x-8,s.y-2,16,4);
  } else if(s.kind==='plasma'){
    ctx.fillStyle='#b98cff'; ctx.beginPath(); ctx.arc(s.x,s.y,s.r,0,7); ctx.fill();
    ctx.fillStyle='#fff'; ctx.beginPath(); ctx.arc(s.x,s.y,s.r*0.45,0,7); ctx.fill();
  } else if(s.kind==='baton'){ // Darcy's STAR BATON
    ctx.translate(s.x,s.y); ctx.rotate(s.spin||0);
    ctx.shadowColor='#ff2e88'; ctx.shadowBlur=12;
    ctx.fillStyle='#ffe600'; rr(-s.r,-3,s.r*2,6,3); ctx.fill();
    ctx.fillStyle='#ff2e88'; ctx.beginPath(); ctx.arc(-s.r,0,4,0,7); ctx.arc(s.r,0,4,0,7); ctx.fill();
    ctx.shadowBlur=0;
    ctx.fillStyle='#fff'; ctx.font='bold 12px sans-serif'; ctx.textAlign='center'; ctx.textBaseline='middle'; ctx.fillText('✦',0,0);
  } else if(s.kind==='megaball'){ // Stanley's GOLDEN BOOT power shot
    // fiery trail
    for(let k=1;k<=4;k++){ ctx.globalAlpha=0.32/k; ctx.fillStyle=k%2?'#ff8a00':'#ffd200';
      ctx.beginPath(); ctx.arc(s.x-Math.sign(s.vx)*k*9, s.y, s.r*(1-k*0.1), 0,7); ctx.fill(); }
    ctx.globalAlpha=1;
    ctx.translate(s.x,s.y); ctx.rotate(s.spin||0);
    ctx.shadowColor='#ff8a00'; ctx.shadowBlur=18;
    ctx.fillStyle='#ffd200'; ctx.beginPath(); ctx.arc(0,0,s.r,0,7); ctx.fill();
    ctx.shadowBlur=0;
    ctx.fillStyle='#111'; ctx.beginPath();
    ctx.moveTo(0,-7);ctx.lineTo(6,-2);ctx.lineTo(4,5);ctx.lineTo(-4,5);ctx.lineTo(-6,-2);ctx.closePath(); ctx.fill();
  }
  ctx.restore();
}

// ---------- backgrounds ----------
function drawCity(){
  const g=ctx.createLinearGradient(0,0,0,H); g.addColorStop(0,'#2a0b46'); g.addColorStop(.6,'#120626'); g.addColorStop(1,'#0a0418');
  ctx.fillStyle=g; ctx.fillRect(0,0,W,H);
  // moon
  ctx.fillStyle='#ffe6a0'; ctx.beginPath(); ctx.arc(W-120,90,46,0,7); ctx.fill();
  // stars
  ctx.fillStyle='#fff'; G.stars.forEach(s=>{ if(s.y<H*0.5){ctx.globalAlpha=s.z/1.6; ctx.fillRect(s.x,s.y,s.s,s.s);} }); ctx.globalAlpha=1;
  // skyline (parallax) two layers
  drawSkyline(0.4, '#1c0e3a', 150, 40);
  drawSkyline(1.0, '#2a1656', 110, 70);
  // ground
  ctx.fillStyle='#181028'; ctx.fillRect(0,GROUND_Y+6,W,H-GROUND_Y);
  ctx.strokeStyle='#ff2e88'; ctx.lineWidth=3; ctx.beginPath(); ctx.moveTo(0,GROUND_Y+8); ctx.lineTo(W,GROUND_Y+8); ctx.stroke();
  // road dashes scrolling
  ctx.fillStyle='rgba(0,240,255,.5)';
  for(let i=0;i<W/60+2;i++){ const x=((i*60 - (G.t*1.5)%60)); ctx.fillRect(x,GROUND_Y+30,30,4); }
}
function drawSkyline(par, color, baseH, varH){
  ctx.fillStyle=color;
  const off = (G.t*par)%80;
  for(let i=-1;i<W/80+1;i++){
    const seed=Math.sin(i*99.7+par)*0.5+0.5;
    const bw=60, bh=baseH+seed*varH;
    const x=i*80-off;
    ctx.fillRect(x,GROUND_Y-bh,bw,bh);
    // windows
    ctx.fillStyle='rgba(0,240,255,.18)';
    for(let wy=GROUND_Y-bh+12; wy<GROUND_Y-10; wy+=16) for(let wx=x+8;wx<x+bw-8;wx+=14){ if((Math.floor(wx+wy+i)%3)) ctx.fillRect(wx,wy,6,8); }
    ctx.fillStyle=color;
  }
}
function drawHighway(){
  const g=ctx.createLinearGradient(0,0,0,H); g.addColorStop(0,'#ff7a3d'); g.addColorStop(.4,'#b3308f'); g.addColorStop(.62,'#3a1a5c'); g.addColorStop(1,'#160a26');
  ctx.fillStyle=g; ctx.fillRect(0,0,W,H);
  // sun
  ctx.fillStyle='#ffe600'; ctx.beginPath(); ctx.arc(W/2,H*0.34,60,0,7); ctx.fill();
  // distant skyline silhouette
  drawSkyline(0.6,'#2a1240',90,50);
  // road
  ctx.fillStyle='#23202e'; ctx.beginPath(); ctx.moveTo(0,GROUND_Y-100); ctx.lineTo(W,GROUND_Y-100); ctx.lineTo(W,H); ctx.lineTo(0,H); ctx.closePath(); ctx.fill();
  // lane lines (3 lanes) scrolling fast
  ctx.fillStyle='#ffe600';
  for(let lane=0;lane<3;lane++){ const ly=GROUND_Y-70+lane*30;
    for(let i=0;i<W/70+2;i++){ const x=((i*70 - (G.t*9)%70)); ctx.fillRect(x,ly,40,4); }
  }
  // guardrail glow
  ctx.strokeStyle='#00f0ff'; ctx.lineWidth=3; ctx.beginPath(); ctx.moveTo(0,GROUND_Y-100); ctx.lineTo(W,GROUND_Y-100); ctx.stroke();
}
function drawSpace(){
  const g=ctx.createLinearGradient(0,0,0,H); g.addColorStop(0,'#0a0224'); g.addColorStop(1,'#1a0533');
  ctx.fillStyle=g; ctx.fillRect(0,0,W,H);
  // nebula blobs
  ctx.globalAlpha=.4;
  ctx.fillStyle='#3a1a6c'; ctx.beginPath(); ctx.arc(W*0.7,H*0.3,140,0,7); ctx.fill();
  ctx.fillStyle='#0a4a6c'; ctx.beginPath(); ctx.arc(W*0.2,H*0.7,120,0,7); ctx.fill();
  ctx.globalAlpha=1;
  // planet
  const pg=ctx.createRadialGradient(W*0.82-20,H*0.72-20,10,W*0.82,H*0.72,90);
  pg.addColorStop(0,'#ff9ad1'); pg.addColorStop(1,'#7a2ff7');
  ctx.fillStyle=pg; ctx.beginPath(); ctx.arc(W*0.82,H*0.72,80,0,7); ctx.fill();
  // stars
  ctx.fillStyle='#fff'; G.stars.forEach(s=>{ ctx.globalAlpha=s.z/1.6; ctx.fillRect(s.x,s.y,s.s,s.s); }); ctx.globalAlpha=1;
}

// ---------- HUD ----------
function drawHUD(){
  hpfill.style.width = (G.hp/G.maxhp*100)+'%';
  scoreBadge.textContent = 'SCORE '+G.score;
  whoLabel.textContent = G.hero==='darcy'?'DARCY · gymnast':'STANLEY · footballer';
  whoLabel.style.color = G.hero==='darcy'?'#ff2e88':'#00f0ff';
  if(G.boss){ enemyBadge.textContent='BOSS FIGHT'; }
  else enemyBadge.textContent = 'ENEMIES '+Math.max(0,G.killNeed-G.killHave);
  // weapon readiness
  if(wpnBadge){
    const wp=WEAPONS[G.hero];
    if(player.wpnCd>0){ const pct=Math.round((1-player.wpnCd/wp.cd)*100);
      wpnBadge.textContent='⚔ '+wp.name+' '+pct+'%'; wpnBadge.style.opacity=.55; }
    else { wpnBadge.textContent='⚔ '+wp.name+' ✦ READY'; wpnBadge.style.opacity=1; }
  }
}

// ---------- main loop ----------
function frame(){
  update();
  if(G.mode==='playing') updateItems();
  draw();
  requestAnimationFrame(frame);
}
// when not playing, still render menu backdrop
function boot(){
  // draw idle space behind menus
  player.mode='ship';
  requestAnimationFrame(function idle(){
    if(G.mode==='menu'){ updateStars(); updateParticles(); drawSpace();
      G.parts.forEach(p=>{ctx.globalAlpha=clamp(p.life/30,0,1);ctx.fillStyle=p.color;ctx.fillRect(p.x-2,p.y-2,4,4);}); ctx.globalAlpha=1;
      requestAnimationFrame(idle);
    } else { frame(); }
  });
}
boot();

})();
