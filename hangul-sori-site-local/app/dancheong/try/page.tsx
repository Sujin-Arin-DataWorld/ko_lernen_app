import type {Metadata} from 'next';
import {VisitorStudio} from '../visitor-studio';
import {templateChoice,languageChoice} from '../public-contract';
export const metadata:Metadata={title:'Dancheong Studio',robots:{index:false,follow:false}};
export default async function Page({searchParams}:{searchParams:Promise<{template?:string;lang?:string}>}){
 const query=await searchParams;
 return <VisitorStudio initialTemplate={templateChoice(query.template)} language={languageChoice(query.lang)}/>;
}
