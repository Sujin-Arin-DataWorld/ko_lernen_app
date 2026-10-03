import type {Border, Template} from './public-contract';
export const frameSources:Record<Exclude<Border,'none'>,string> = {
 brocadeFlow:'brocade_flow_frame.png',colorRibbon:'color_ribbon_frame.png',lotusScroll:'lotus_frame.png',
};
const segmenter=new Intl.Segmenter('ko',{granularity:'grapheme'});
function image(name:string):Promise<HTMLImageElement>{return new Promise((resolve,reject)=>{
 const img=new Image();img.onload=()=>resolve(img);img.onerror=reject;img.src=`/dancheong/starter/${name}`;
});}
export async function renderVisitor(target:HTMLCanvasElement, draft:{template:Template;border:Border;motif:string;text:string;signature:string},current:()=>boolean){
 const [motif,frame,flower]=await Promise.all([image(`${draft.motif}.png`),draft.border==='none'?null:image(frameSources[draft.border]),draft.template==='flower'&&draft.border!=='none'?image('flower.png'):null]);
 await document.fonts.ready;if(!current()){return;}
 const ctx=target.getContext('2d');if(!ctx){throw new Error('Canvas unavailable');}
 ctx.fillStyle='#faf6ec';ctx.fillRect(0,0,1080,1350);
 const scale=1080/1122;const top=(1350-1402*scale)/2;
 const safe=draft.border==='brocadeFlow'?[320,300,1060,1060]:draft.border==='colorRibbon'?[244,304,876,1082]:draft.border==='lotusScroll'?[232,256,887,1142]:[92/scale,92/scale,988/scale,1258/scale];
 let [left,y,right,bottom]=safe.map((v,i)=>v*scale+(i%2===1?top:0));
 const richFlow=draft.border==='brocadeFlow'&&draft.template==='flower'&&draft.text.length+draft.signature.length<=100&&!draft.text.includes('\n');
 if(richFlow){[left,y,right,bottom]=[285*scale,270*scale+top,1060*scale,1000*scale+top];ctx.fillStyle='#125844';ctx.beginPath();ctx.moveTo(0,top);ctx.lineTo(1080,top);ctx.lineTo(1080,top+930*scale);ctx.bezierCurveTo(650*scale,top+960*scale,300*scale,top+800*scale,0,top+780*scale);ctx.closePath();ctx.fill();}
 const width=right-left-16;const height=bottom-y-16;const x=left+8;const start=y+8;
 const hasText=draft.text.trim()||draft.signature.trim();const artBottom=hasText&&!richFlow?start+height*.58:bottom-8;const centerX=x+width/2;const centerY=(start+artBottom)/2;
 function stamp(img:HTMLImageElement,cx:number,cy:number,size:number){const side=Math.min(size,img.naturalWidth,img.naturalHeight);const ratio=img.naturalWidth/img.naturalHeight;const w=ratio>=1?side:side*ratio;const h=ratio>=1?side/ratio:side;ctx!.drawImage(img,cx-w/2,cy-h/2,w,h);}
 ctx.save();ctx.beginPath();ctx.rect(x,start,width,artBottom-start);ctx.clip();
 if(draft.template==='flower'&&flower){stamp(flower,centerX,centerY-28,Math.min(width,artBottom-start-64));stamp(motif,centerX,artBottom-35,70);}
 else if(draft.template==='flower'){const radius=Math.min(width*.36,(artBottom-start)*.34);for(let i=0;i<8;i++){const angle=i*Math.PI/4;stamp(motif,centerX+Math.cos(angle)*radius,centerY+Math.sin(angle)*radius,Math.min(164,radius*.48));}stamp(motif,centerX,centerY,Math.min(540,radius*1.7));}
 else if(draft.template==='brocade'){const cell=Math.min(270,width/3);let row=0;for(let sy=start+cell*.5;sy<artBottom-cell*.4;sy+=cell){for(let col=0;col<3;col++){stamp(motif,x+cell*(col+.5)+(row%2?cell*.08:-cell*.08),sy,cell*.84);}row++;}}
 else{stamp(motif,centerX,centerY,Math.min(width*.82,(artBottom-start)*.82));}
 ctx.restore();
 if(hasText){
  let font=64;let lines:string[]=[];const textX=richFlow?805*scale:centerX;const textWidth=richFlow?470*scale:width-16;const textY=richFlow?1000*scale+top:artBottom+16;const available=richFlow?210*scale:bottom-20-artBottom-16;
  function wrap(){lines=[];ctx!.font=`${font}px "Gowun Dodum", sans-serif`;for(const paragraph of draft.text.split('\n')){let line='';for(const part of segmenter.segment(paragraph)){if(ctx!.measureText(line+part.segment).width>textWidth&&line){lines.push(line);line='';}line+=part.segment;}if(line){lines.push(line);}}}
  wrap();while((lines.length+(draft.signature?1.2:0))*font*1.35>available&&font>24){font-=2;wrap();}
  if((lines.length+(draft.signature?1.2:0))*font*1.35>available){throw new Error('Text does not fit');}
  ctx.fillStyle='#243b33';ctx.textAlign='center';const textTop=textY+(available-(lines.length+(draft.signature?1.2:0))*font*1.35)/2;
  lines.forEach((line,i)=>ctx.fillText(line,textX,textTop+(i+1)*font*1.35));
  if(draft.signature){ctx.font=`${font*.56}px "Gowun Dodum", sans-serif`;ctx.fillText(draft.signature,textX,textTop+(lines.length+1.1)*font*1.35);}
 }
 if(frame){ctx.drawImage(frame,0,top,1080,1402*scale);}
}
