'use strict';
// Visual response only; business actions remain on the existing click handlers.
const touched=new Map();
const reducedMotion=()=>document.body.classList.contains('reduced')||matchMedia('(prefers-reduced-motion:reduce)').matches;
const interactive='button.practice-tile,button.play-button,button.primary,button.secondary,.mission-mini button';
function clearContact(contact,release=false){
  contact.button.classList.remove('is-pressing');
  if(release&&!reducedMotion()){
    contact.button.classList.add('is-releasing');
    setTimeout(()=>contact.button.classList.remove('is-releasing'),300);
  }
}
function resetContacts(){for(const contact of touched.values())clearContact(contact);touched.clear();}
document.addEventListener('pointerdown',event=>{
  const button=event.target.closest(interactive);
  if(!button||button.disabled||event.button!==0)return;
  const bounds=button.getBoundingClientRect();
  button.style.setProperty('--touch-x',`${Math.round((event.clientX-bounds.left)/bounds.width*100)}%`);
  button.style.setProperty('--touch-y',`${Math.round((event.clientY-bounds.top)/bounds.height*100)}%`);
  button.classList.remove('is-releasing');
  button.classList.add('is-pressing');
  touched.set(event.pointerId,{button,x:event.clientX,y:event.clientY,bounds});
},{passive:true});
document.addEventListener('pointermove',event=>{
  const contact=touched.get(event.pointerId);
  if(!contact)return;
  if(Math.hypot(event.clientX-contact.x,event.clientY-contact.y)>12){
    clearContact(contact);touched.delete(event.pointerId);
  }
},{passive:true});
document.addEventListener('pointerup',event=>{
  const contact=touched.get(event.pointerId);
  if(!contact)return;
  touched.delete(event.pointerId);
  const {left,right,top,bottom}=contact.bounds;
  const inside=event.clientX>=left&&event.clientX<=right&&event.clientY>=top&&event.clientY<=bottom;
  clearContact(contact,inside);
  const phone=document.querySelector('#phone');
  if(inside&&phone&&phone.contains(contact.button)&&!reducedMotion()){
    const rect=phone.getBoundingClientRect(),trace=document.createElement('span');
    trace.className='touch-trace';trace.setAttribute('aria-hidden','true');
    trace.style.left=`${event.clientX-rect.left}px`;trace.style.top=`${event.clientY-rect.top}px`;
    phone.append(trace);trace.addEventListener('animationend',()=>trace.remove(),{once:true});
    setTimeout(()=>trace.remove(),350);
  }
},{passive:true});
document.addEventListener('pointercancel',event=>{const contact=touched.get(event.pointerId);if(contact)clearContact(contact);touched.delete(event.pointerId);},{passive:true});
window.addEventListener('pagehide',resetContacts);
document.addEventListener('visibilitychange',()=>{if(document.hidden)resetContacts();});
document.addEventListener('change',event=>{if(event.target.id==='reduce')resetContacts();});
