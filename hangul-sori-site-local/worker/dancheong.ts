import { validShareId, publicSnapshot } from '../app/dancheong/public-contract';
const origin='https://europe-west3-ko-lernen-app.cloudfunctions.net/';
const headers={'Cache-Control':'private, no-store, max-age=0','X-Robots-Tag':'noindex, nofollow','X-Content-Type-Options':'nosniff'};
export async function handleDancheongProxy(request:Request):Promise<Response|null> {
 const url=new URL(request.url);
 const json=/^\/api\/dancheong\/art\/([^/]+)$/.exec(url.pathname);
 const image=/^\/art\/([^/]+)\/image\.png$/.exec(url.pathname);
 const match=json??image;if(!match){return null;}
 if(!['GET','HEAD'].includes(request.method)){return new Response(null,{status:405,headers});}
 if(!validShareId(match[1])){return new Response(null,{status:404,headers});}
 const target=new URL(image?'getDancheongShareImage':'getDancheongShare',origin);target.searchParams.set('shareId',match[1]);
 try {
  const response=await fetch(target,{method:'GET',redirect:'error',signal:AbortSignal.timeout(10000)});
  if(!response.ok){return new Response(null,{status:404,headers});}
  const limit=image?4*1024*1024:32768;
  const declared=Number(response.headers.get('content-length'));if(declared>limit){return new Response(null,{status:502,headers});}
  if(image && !response.headers.get('content-type')?.startsWith('image/png')){return new Response(null,{status:502,headers});}
  const reader=response.body?.getReader();if(!reader){return new Response(null,{status:502,headers});}
  const chunks:Uint8Array[]=[];let size=0;
  while(true){const {done,value}=await reader.read();if(done){break;}size+=value.length;if(size>limit){await reader.cancel();return new Response(null,{status:502,headers});}chunks.push(value);}
  const bytes=new Uint8Array(size);let offset=0;for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.length;}
  if(!image){const data=publicSnapshot(JSON.parse(new TextDecoder().decode(bytes)));if(!data||data.shareId!==match[1]){return new Response(null,{status:502,headers});}
   return new Response(request.method==='HEAD'?null:JSON.stringify(data),{headers:{...headers,'Content-Type':'application/json; charset=utf-8'}});}
  return new Response(request.method==='HEAD'?null:bytes,{headers:{...headers,'Content-Type':'image/png'}});
 }catch{return new Response(null,{status:503,headers});}
}
