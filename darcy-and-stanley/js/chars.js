/* Shared vector character art for Darcy (gymnast) & Stanley (footballer).
   Drawn procedurally on a 2D canvas so no image assets are needed. */
(function(){
  function rr(x,c,y,w,h,r){c.beginPath();c.moveTo(x+r,y);c.arcTo(x+w,y,x+w,y+h,r);c.arcTo(x+w,y+h,x,y+h,r);c.arcTo(x,y+h,x,y,r);c.arcTo(x,y,x+w,y,r);c.closePath();}

  // draw character centered at feet point (px,py). s = scale. t = time, face = 1 right / -1 left
  function draw(ctx, px, py, kind, t, s, face){
    s = s || 1; face = face || 1;
    ctx.save();
    ctx.translate(px, py);
    ctx.scale(s*face, s);
    const sw = Math.sin(t/6); // limb swing

    if(kind==='darcy'){
      const skin='#ffd9b8', hair='#ff2e88', suit='#b3008f', suit2='#ff2e88';
      // shadow
      ctx.fillStyle='rgba(0,0,0,.25)'; ctx.beginPath(); ctx.ellipse(0,2,16,5,0,0,7); ctx.fill();
      // back leg
      ctx.strokeStyle=skin; ctx.lineWidth=5; ctx.lineCap='round';
      ctx.beginPath(); ctx.moveTo(0,-26); ctx.lineTo(6+sw*5,-2); ctx.stroke();
      // front leg
      ctx.beginPath(); ctx.moveTo(0,-26); ctx.lineTo(-6-sw*5,-2); ctx.stroke();
      // body leotard
      ctx.fillStyle=suit; rr(-7,ctx,-50,14,26,6); ctx.fill();
      ctx.fillStyle=suit2; rr(-7,ctx,-36,14,12,5); ctx.fill();
      // arms (raised, acrobatic)
      ctx.strokeStyle=skin;
      ctx.beginPath(); ctx.moveTo(-2,-46); ctx.lineTo(-12,-58-Math.abs(sw)*4); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(2,-46); ctx.lineTo(12,-58-Math.abs(sw)*4); ctx.stroke();
      // head
      ctx.fillStyle=skin; ctx.beginPath(); ctx.arc(0,-58,8,0,7); ctx.fill();
      // hair ponytail
      ctx.fillStyle=hair; ctx.beginPath(); ctx.arc(0,-62,8.5,Math.PI,0); ctx.fill();
      ctx.beginPath(); ctx.moveTo(6,-60); ctx.quadraticCurveTo(20,-58,16+sw*4,-42); ctx.quadraticCurveTo(10,-50,4,-56); ctx.fill();
      // face dot eyes
      ctx.fillStyle='#222'; ctx.beginPath(); ctx.arc(-3,-58,1.3,0,7); ctx.arc(3,-58,1.3,0,7); ctx.fill();
    } else {
      const skin='#f1c197', hair='#3a2a1a', jersey='#00bcd4', jersey2='#fff', shorts='#0a3d4a';
      ctx.fillStyle='rgba(0,0,0,.25)'; ctx.beginPath(); ctx.ellipse(0,2,16,5,0,0,7); ctx.fill();
      // legs
      ctx.strokeStyle=shorts; ctx.lineWidth=6; ctx.lineCap='round';
      ctx.beginPath(); ctx.moveTo(0,-24); ctx.lineTo(7+sw*5,-12); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(0,-24); ctx.lineTo(-7-sw*5,-12); ctx.stroke();
      ctx.strokeStyle=skin; ctx.lineWidth=5;
      ctx.beginPath(); ctx.moveTo(7+sw*5,-12); ctx.lineTo(8+sw*6,-2); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(-7-sw*5,-12); ctx.lineTo(-8-sw*6,-2); ctx.stroke();
      // boots
      ctx.fillStyle='#fff'; ctx.beginPath(); ctx.ellipse(9+sw*6,-1,4,2.5,0,0,7); ctx.ellipse(-9-sw*6,-1,4,2.5,0,0,7); ctx.fill();
      // jersey
      ctx.fillStyle=jersey; rr(-9,ctx,-48,18,26,6); ctx.fill();
      ctx.fillStyle=jersey2; ctx.fillRect(-2,-48,4,24);
      // arms
      ctx.strokeStyle=skin; ctx.lineWidth=5;
      ctx.beginPath(); ctx.moveTo(-6,-44); ctx.lineTo(-14-sw*4,-30); ctx.stroke();
      ctx.beginPath(); ctx.moveTo(6,-44); ctx.lineTo(14+sw*4,-30); ctx.stroke();
      // head
      ctx.fillStyle=skin; ctx.beginPath(); ctx.arc(0,-56,8.5,0,7); ctx.fill();
      // hair
      ctx.fillStyle=hair; ctx.beginPath(); ctx.arc(0,-58,8.7,Math.PI,0); ctx.fill();
      ctx.fillRect(-9,-59,18,4);
      // eyes
      ctx.fillStyle='#222'; ctx.beginPath(); ctx.arc(-3,-56,1.3,0,7); ctx.arc(3,-56,1.3,0,7); ctx.fill();
    }
    ctx.restore();
  }

  window.DSChars = { draw };
})();
