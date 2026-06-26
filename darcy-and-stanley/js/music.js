/* DSMusic — an original "Oliver Tree style" theme.
   The whole loop is rendered ONCE into an AudioBuffer with OfflineAudioContext,
   then played back on a looping source node. Because nothing is scheduled on the
   main thread while it plays, the game's render loop can never make it stutter. */
(function(){
  let ctx, master, src, started=false, bufferCache=null;
  const BPM = 104, STEP = 60/BPM/2;       // 8th notes
  const BARS = 2, TOTAL = BARS*16;         // steps in the rendered loop
  const SR = 44100;

  // F-minor-ish — moody but bouncy
  const NOTES={f2:87.31,af2:103.83,c3:130.81,ef3:155.56,f3:174.61,af3:207.65,c4:261.63,ef4:311.13,f4:349.23,af4:415.30};
  const BASS=['f2','f2',null,'af2','c3',null,'ef3','c3', 'f2','f2',null,'af2','c3','c3',null,'af2'];
  const LEAD=[null,'f4',null,null,'ef4',null,'c4','af3', null,'f4','af4',null,'c4',null,'af3',null];

  // ---- synth voices (write into an arbitrary context `ac` -> `dest`) ----
  function env(g,t,a,d,peak){ g.gain.setValueAtTime(0,t); g.gain.linearRampToValueAtTime(peak,t+a); g.gain.linearRampToValueAtTime(0,t+a+d); }

  function kick(ac,dest,t){
    const o=ac.createOscillator(), g=ac.createGain();
    o.frequency.setValueAtTime(150,t); o.frequency.exponentialRampToValueAtTime(45,t+.12);
    g.gain.setValueAtTime(1,t); g.gain.exponentialRampToValueAtTime(.001,t+.28);
    o.connect(g).connect(dest); o.start(t); o.stop(t+.3);
  }
  function noiseBuf(ac,len,shape){
    const n=Math.max(1,Math.floor(ac.sampleRate*len));
    const b=ac.createBuffer(1,n,ac.sampleRate), d=b.getChannelData(0);
    for(let i=0;i<n;i++) d[i]=(Math.random()*2-1)*(shape?Math.pow(1-i/n,shape):1);
    return b;
  }
  function snare(ac,dest,t){
    const s=ac.createBufferSource(); s.buffer=noiseBuf(ac,.2,2);
    const bp=ac.createBiquadFilter(); bp.type='bandpass'; bp.frequency.value=1700; bp.Q.value=1.1;
    const lp=ac.createBiquadFilter(); lp.type='lowpass'; lp.frequency.value=6000;
    const g=ac.createGain(); g.gain.setValueAtTime(.42,t); g.gain.exponentialRampToValueAtTime(.001,t+.16);
    s.connect(bp).connect(lp).connect(g).connect(dest); s.start(t); s.stop(t+.2);
  }
  function hat(ac,dest,t,open){
    const len=open?.075:.028;
    const s=ac.createBufferSource(); s.buffer=noiseBuf(ac,len,0);
    const bp=ac.createBiquadFilter(); bp.type='bandpass'; bp.frequency.value=9500; bp.Q.value=1.4;
    const hp=ac.createBiquadFilter(); hp.type='highpass'; hp.frequency.value=6500;
    const g=ac.createGain(); g.gain.setValueAtTime(open?.045:.05,t); g.gain.exponentialRampToValueAtTime(.0006,t+len);
    s.connect(bp).connect(hp).connect(g).connect(dest); s.start(t); s.stop(t+len);
  }
  function bassNote(ac,dest,freq,t){
    const g=ac.createGain();
    const f=ac.createBiquadFilter(); f.type='lowpass'; f.frequency.value=520; f.Q.value=6;
    [0,-7,7].forEach(det=>{ const o=ac.createOscillator(); o.type='sawtooth'; o.frequency.value=freq; o.detune.value=det; o.connect(f); o.start(t); o.stop(t+STEP*1.05); });
    env(g,t,.01,STEP*0.98,.34); f.connect(g).connect(dest);
  }
  function leadNote(ac,dest,freq,t){
    const g=ac.createGain();
    const dist=ac.createWaveShaper(); dist.curve=curve(8);
    const tone=ac.createBiquadFilter(); tone.type='lowpass'; tone.frequency.value=3200;
    const o=ac.createOscillator(); o.type='square'; o.frequency.value=freq;
    const lfo=ac.createOscillator(), lg=ac.createGain(); lfo.frequency.value=5.5; lg.gain.value=6;
    lfo.connect(lg).connect(o.frequency); lfo.start(t); lfo.stop(t+STEP*1.9);
    o.connect(dist).connect(tone).connect(g); env(g,t,.015,STEP*1.5,.15); g.connect(dest);
    o.start(t); o.stop(t+STEP*1.9);
  }
  function curve(amt){ const n=256,c=new Float32Array(n); for(let i=0;i<n;i++){const x=i/n*2-1; c[i]=(Math.PI+amt)*x/(Math.PI+amt*Math.abs(x));} return c; }

  // ---- render the full loop into a buffer (once) ----
  function buildLoop(){
    if(bufferCache) return Promise.resolve(bufferCache);
    const len = Math.round(TOTAL*STEP*SR);          // exact loop length = seamless
    const oac = new OfflineAudioContext(2, len, SR);
    const comp = oac.createDynamicsCompressor();
    const bus = oac.createGain(); bus.gain.value=1; bus.connect(comp).connect(oac.destination);
    for(let step=0; step<TOTAL; step++){
      const t = step*STEP, s = step%16;
      if(s===0||s===6||s===10) kick(oac,bus,t);
      if(s===4||s===12) snare(oac,bus,t);
      if(s%2===1) hat(oac,bus,t+STEP*0.32,false);
      if(s===7||s===15) hat(oac,bus,t,true);
      if(BASS[s]) bassNote(oac,bus,NOTES[BASS[s]],t);
      if(LEAD[s]) leadNote(oac,bus,NOTES[LEAD[s]],t);
    }
    return oac.startRendering().then(b=>{ bufferCache=b; return b; });
  }

  function start(){
    if(started) return; started=true;
    ctx = new (window.AudioContext||window.webkitAudioContext)();
    master = ctx.createGain(); master.gain.value=0;
    master.connect(ctx.destination);
    if(ctx.state==='suspended') ctx.resume().catch(()=>{});
    buildLoop().then(buf=>{
      if(!started || !ctx) return;                  // stopped before render finished
      src = ctx.createBufferSource(); src.buffer=buf; src.loop=true;
      src.connect(master); src.start();
      const now=ctx.currentTime;
      master.gain.cancelScheduledValues(now);
      master.gain.setValueAtTime(0,now);
      master.gain.linearRampToValueAtTime(0.32, now+0.5);  // fade in
    }).catch(()=>{});
  }
  function stop(){
    if(!started) return; started=false;
    const c=ctx, s=src;
    if(c && master){ const now=c.currentTime; master.gain.cancelScheduledValues(now); master.gain.linearRampToValueAtTime(0, now+0.25); }
    setTimeout(()=>{ try{ if(s) s.stop(); }catch(e){} try{ if(c) c.close(); }catch(e){} }, 320);
    src=null; ctx=null; master=null;
  }
  function toggle(){ started?stop():start(); return started; }
  function isOn(){ return started; }
  function setVolume(v){ if(started && master) master.gain.value=v; }

  window.DSMusic = { start, stop, toggle, isOn, setVolume };
})();
