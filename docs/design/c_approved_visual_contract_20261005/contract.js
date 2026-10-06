'use strict';
const ui = Object.fromEntries(['screen','width','overlay','whole','workspace','load-state','visual-title','original','art','reference','lines','viewport-note','bounds','gaps','proof','tokens'].map(id=>[id,document.getElementById(id)]));
let contract, manifest, showOverlay=true, showWhole=false, selectedBound=-1;
function el(tag, text, className) {
  const element=document.createElement(tag);
  if(text!==undefined) element.textContent=text;
  if(className) element.className=className;
  return element;
}
function render() {
  const screen=contract.screens.find(s=>s.id===ui.screen.value);
  const reference=manifest.references.find(r=>r.id===screen.reference);
  const view=showWhole?[0,0,reference.width,reference.height]:screen.viewport;
  const width=ui.width.value==='original'?view[2]:Number(ui.width.value);
  ui.art.style.width=`${width}px`;
  ui.art.style.aspectRatio=`${view[2]} / ${view[3]}`;
  ui.reference.src=reference.path;
  ui.reference.alt=`최종 승인 ${screen.title} 원본. 상세 배치는 오른쪽 경계 표에 표시됩니다.`;
  ui.reference.style.width=`${reference.width/view[2]*100}%`;
  ui.reference.style.left=`${-view[0]/view[2]*100}%`;
  ui.reference.style.top=`${-view[1]/view[3]*100}%`;
  ui.original.href=reference.path;
  ui['visual-title'].textContent=screen.title;
  ui['viewport-note'].textContent=`비교 영역 ${view[2]}×${view[3]} 원본 px · ${ui.width.value==='original'?'원본 너비':`${width} 너비 비례 비교`} · dp 추출값이 아닙니다.`;
  ui.lines.replaceChildren();
  ui.lines.hidden=!showOverlay;
  ui.bounds.replaceChildren();
  screen.boxes.forEach((bound,i)=>{
    const [x,y,w,h]=bound.rect;
    const mark=el('div',undefined,`mark ${bound.kind}${selectedBound===i?' selected':''}`);
    mark.style.left=`${(x-view[0])/view[2]*100}%`;
    mark.style.top=`${(y-view[1])/view[3]*100}%`;
    mark.style.width=`${w/view[2]*100}%`;
    mark.style.height=`${h/view[3]*100}%`;
    mark.append(el('span',`${i+1} · ${bound.label}`));
    ui.lines.append(mark);
    const button=el('button',undefined,'bound');
    button.type='button';button.setAttribute('aria-pressed',String(selectedBound===i));
    button.append(el('strong',`${i+1}. ${bound.label}`),el('span',`x ${x} · y ${y} · ${w}×${h}px`));
    button.addEventListener('click',()=>{
      selectedBound=selectedBound===i?-1:i;
      [...ui.lines.children].forEach((line,j)=>line.classList.toggle('selected',j===selectedBound));
      [...ui.bounds.children].forEach((item,j)=>item.setAttribute('aria-pressed',String(j===selectedBound)));
    });
    ui.bounds.append(button);
  });
  ui.gaps.replaceChildren();
  if(!screen.gaps.length) ui.gaps.append(el('p','이 페이지는 장면 전체의 원본 비율을 유지합니다. CTA와 뒤로 간격은 별도 표시했습니다.','small'));
  screen.gaps.forEach(g=>{
    const row=el('div',undefined,'gap-row');
    row.append(el('span',g.label),el('b',`${g.px}px ±3`));ui.gaps.append(row);
  });
  ui.proof.replaceChildren(el('p',`승인 원본: ${reference.width}×${reference.height}px`),el('p',reference.path),el('code',reference.sha256));
  ui.proof.append(el('p',reference.generatedOriginal?'생성 이미지 원본과 파일 해시 일치':'사용자가 첨부한 최신 원본을 바이트 그대로 보존'));
  if(reference.existingIntroSourceId) ui.proof.append(el('p',`기존 전달본 연결: ${reference.existingIntroSourceId}`));
}
async function boot() {
  try {
    const responses=await Promise.all([fetch('geometry.json'),fetch('manifest.json')]);
    for(const response of responses) if(!response.ok) throw new Error(`자료 조회 실패: ${response.status}`);
    [contract,manifest]=await Promise.all(responses.map(r=>r.json()));
    ui.screen.replaceChildren(...contract.screens.map(s=>{
      const option=el('option',s.title);option.value=s.id;return option;
    }));
    const requested=new URLSearchParams(location.search).get('screen');
    ui.screen.value=contract.screens.some(s=>s.id===requested)?requested:'learn';
    contract.tokens.forEach(token=>{
      const row=el('tr');
      row.append(el('td',token.name),el('td',`${token.value}${token.unit}`),el('td',`${token.source}:${token.line}`));
      ui.tokens.append(row);
    });
    ui.screen.disabled=false;ui.workspace.hidden=false;ui['load-state'].hidden=true;
    ui.screen.addEventListener('change',()=>{selectedBound=-1;render();});
    ui.width.addEventListener('change',render);
    ui.overlay.addEventListener('click',()=>{showOverlay=!showOverlay;ui.overlay.setAttribute('aria-pressed',String(showOverlay));ui.lines.hidden=!showOverlay;});
    ui.whole.addEventListener('click',()=>{showWhole=!showWhole;ui.whole.setAttribute('aria-pressed',String(showWhole));render();});
    render();
  } catch(error) {
    ui['load-state'].replaceChildren(el('p',error.message));
    const retry=el('button','다시 불러오기');retry.type='button';retry.addEventListener('click',()=>location.reload());ui['load-state'].append(retry);
  }
}
boot();
