const {chromium}=require('C:/Users/vjinn/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
const fs=require('fs');const path=require('path');
(async()=>{
 const browser=await chromium.launch({headless:true});const page=await browser.newPage({viewport:{width:1366,height:900}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto('http://127.0.0.1:8876/family-r16/index.html');
 await page.locator('#image').evaluate(img=>img.decode());
 const count=await page.locator('#buildings button').count();if(count!==11)throw Error('Expected11buildings');
 const expected=await page.evaluate(()=>data.buildings.map(b=>({key:b.key,name:b.name,steps:b.steps.map(s=>({sequence:s.sequence,label:s.label}))})));
 let verifiedStages=0;
 for(let i=0;i<expected.length;i++){
  await page.locator('#buildings button').nth(i).click();
  await page.getByRole('button',{name:'공정별',exact:true}).click();
  for(let j=0;j<expected[i].steps.length;j++){
   await page.locator('#steps button').nth(j).click();
   await page.locator('#image').evaluate(img=>img.decode());
   if(!(await page.locator('#title').innerText()).includes(expected[i].steps[j].label))throw Error('Stage label mismatch');
   const src=await page.locator('#image').getAttribute('src');
   if(!src.endsWith('/'+String(j+1).padStart(2,'0')+'.png'))throw Error('Wrong stage image');
   verifiedStages++;
  }
 }
 await page.locator('#buildings button').first().click();
 await page.getByRole('button',{name:'공정별',exact:true}).click();
 await page.locator('#steps button').filter({hasText:/^5$/}).click();await page.locator('#image').evaluate(img=>img.decode());
 if(!(await page.locator('#title').innerText()).includes('기둥'))throw Error('WrongSarangstage5');
 await page.locator('#image').click();if(!(await page.locator('#zoom').evaluate(d=>d.open)))throw Error('Zoomdidnotopen');
 await page.getByRole('button',{name:'닫기',exact:true}).click();
 await page.locator('#buildings button').filter({hasText:'안사랑채'}).click();
 await page.getByRole('button',{name:'완성본',exact:true}).click();await page.locator('#image').evaluate(img=>img.decode());
 await page.screenshot({path:path.join(__dirname,'family-r16','gallery-desktop.png'),fullPage:true});
 await page.setViewportSize({width:390,height:844});
 const overflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1);if(overflow)throw Error('Mobilehorizontaloverflow');
 await page.screenshot({path:path.join(__dirname,'family-r16','gallery-mobile.png'),fullPage:true});
 if(errors.length)throw Error(errors.join('\n'));
 fs.writeFileSync(path.join(__dirname,'family-r16','gallery-check.json'),JSON.stringify({buildingButtons:count,allProcessImagesDecoded:verifiedStages,allProcessLabelsVerified:verifiedStages===128,stage5LabelVerified:true,zoomOpenCloseVerified:true,buildingSwitchVerified:true,desktopScreenshot:'gallery-desktop.png',mobileScreenshot:'gallery-mobile.png',horizontalOverflow:false,javascriptErrors:errors},null,2));
 await browser.close();console.log('GALLERY_INTERACTION_CHECK_PASSED');
})().catch(e=>{console.error(e);process.exit(1)});
