// Reuse the existing C CTA renderer; source pixels stay unchanged.
let ctaId=0;
function paintCta(button){
 const art=button.querySelector('.cta-art');if(!art)return;
 const {width:w,height:h}=button.getBoundingClientRect(),primary=art.dataset.primary==='true',base=primary?54:48,u=base/232,top=primary?101:397,expanded=h>base+.1;
 const sx=[14,244,1101,1241],sy=[top,top+64,top+80,top+232],dx=[0,230*u,w-140*u,w],dy=[0,64*u,h-152*u,h];
 const slice=(x,y,width,height,r)=>`<svg x="${x}" y="${y}" width="${width}" height="${height}" viewBox="${r.join(' ')}" preserveAspectRatio="none"><image href="../../../assets/cta_atlas.png" width="1254" height="1254"/></svg>`;
 const id='cta-'+(++ctaId),b=26*u;
 let face='',frame='';
 for(let row=0;row<3;row++)for(let col=0;col<3;col++){
  if(row===1&&col===1)continue;
  frame+=slice(dx[col],dy[row],dx[col+1]-dx[col],dy[row+1]-dy[row],[sx[col],sy[row],sx[col+1]-sx[col],sy[row+1]-sy[row]]);
 }
 {
  face=slice(0,0,w,h,[254,top+44,836,144]);
  const ring=`M12 0H${w-12}Q${w} 0 ${w} 12V${h-12}Q${w} ${h} ${w-12} ${h}H12Q0 ${h} 0 ${h-12}V12Q0 0 12 0Z M${12} ${b}H${w-12}Q${w-b} ${b} ${w-b} 12V${h-12}Q${w-b} ${h-b} ${w-12} ${h-b}H12Q${b} ${h-b} ${b} ${h-12}V12Q${b} ${b} 12 ${b}Z`;
  const cloud='M24 209L24 161C15 149 22 127 41 127C36 108 52 94 73 96C89 91 104 103 111 115C129 113 145 126 143 140C160 138 177 145 180 162C195 171 192 192 170 199L195 209Z';
  face=`<defs><clipPath id="${id}-outer"><rect width="${w}" height="${h}" rx="12"/></clipPath><clipPath id="${id}-frame"><path d="${ring}" clip-rule="evenodd"/><path d="${cloud}" transform="translate(0 ${h-base}) scale(${u})"/></clipPath></defs><g clip-path="url(#${id}-outer)">${face}<g clip-path="url(#${id}-frame)">${frame}</g></g>`;
 }
 art.setAttribute('viewBox',`0 0 ${w} ${h}`);art.dataset.expanded=String(expanded);art.innerHTML=face;
}

const observer = new ResizeObserver(entries => entries.forEach(entry => paintCta(entry.target)));
export function refreshCtaSurfaces() {
  observer.disconnect();
  document.querySelectorAll('button:has(.cta-art)').forEach(button => {
    paintCta(button);
    observer.observe(button);
  });
}
