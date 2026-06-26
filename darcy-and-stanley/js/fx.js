/* DSFx — voice sound effects via the Web Speech API.
   Shouts "wey hey!" (and friends) whenever you get a kill. No audio files needed. */
(function(){
  const SUPPORTED = 'speechSynthesis' in window;
  const PHRASES = ['wey hey!','wey hey!','wahey!','wey HEY!','oi wey hey!'];
  let enabled=true, last=0;
  let darcyVoice=null, stanleyVoice=null, anyEn=null;

  const FEMALE = /(female|woman|samantha|victoria|karen|moira|tessa|fiona|serena|allison|ava|susan|zira|catherine|kate|amelie|google uk english female|google us english.*female)/i;
  const MALE   = /(\bmale\b|\bman\b|daniel|alex|fred|oliver|arthur|gordon|david|mark|james|george|google uk english male|microsoft (david|mark|george))/i;

  function pickVoice(){
    if(!SUPPORTED) return;
    const vs = speechSynthesis.getVoices(); if(!vs.length) return;
    const en = vs.filter(v=>/^en/i.test(v.lang));
    const pool = en.length ? en : vs;
    anyEn = pool[0] || null;
    // Darcy: prefer a female English voice. Stanley: prefer a male English voice.
    darcyVoice   = pool.find(v=>FEMALE.test(v.name)) || anyEn;
    stanleyVoice = pool.find(v=>MALE.test(v.name))   || pool.find(v=>v!==darcyVoice) || anyEn;
  }
  if(SUPPORTED){ pickVoice(); speechSynthesis.onvoiceschanged = pickVoice; }

  // hero: 'darcy' (high & bright) or 'stanley' (deep & gruff)
  function shout(hero){
    if(!enabled || !SUPPORTED) return;
    const now = performance.now();
    if(now - last < 220) return;       // don't machine-gun on rapid multi-kills
    last = now;
    try{
      speechSynthesis.cancel();        // keep it snappy: latest kill wins
      const u = new SpeechSynthesisUtterance(PHRASES[(Math.random()*PHRASES.length)|0]);
      if(hero === 'stanley'){
        if(stanleyVoice) u.voice = stanleyVoice;
        u.pitch = 0.4 + Math.random()*0.2;   // deep man's voice
        u.rate  = 0.95 + Math.random()*0.15;
      } else {
        if(darcyVoice) u.voice = darcyVoice;
        u.pitch = 1.7 + Math.random()*0.3;    // high, bright
        u.rate  = 1.2 + Math.random()*0.2;
      }
      u.volume = 1.0;
      speechSynthesis.speak(u);
    }catch(e){/* ignore */}
  }

  function setEnabled(v){ enabled = !!v; if(!v && SUPPORTED) speechSynthesis.cancel(); }
  function isEnabled(){ return enabled; }

  window.DSFx = { shout, setEnabled, isEnabled };
})();
