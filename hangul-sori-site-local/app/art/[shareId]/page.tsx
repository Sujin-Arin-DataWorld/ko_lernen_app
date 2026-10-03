import type {Metadata} from 'next';
import {PublicArtwork} from '../../dancheong/public-artwork';
import {validShareId} from '../../dancheong/public-contract';
export async function generateMetadata({params}:{params:Promise<{shareId:string}>}):Promise<Metadata>{
 const {shareId}=await params;
 return {title:'Dancheong artwork · Hangul Sori',robots:{index:false,follow:false},
  ...(validShareId(shareId)?{openGraph:{title:'Dancheong artwork · Hangul Sori',images:[`https://hangul-sori.com/art/${shareId}/image.png`]}}:{})};
}
export default async function Page({params,searchParams}:{params:Promise<{shareId:string}>;searchParams:Promise<{lang?:string}>}){
 const {shareId}=await params;const {lang}=await searchParams;
 return <PublicArtwork shareId={shareId} language={lang==='en'?'en':'de'}/>;
}
