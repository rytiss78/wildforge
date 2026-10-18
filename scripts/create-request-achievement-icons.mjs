import {mkdir,writeFile} from 'node:fs/promises';
import {deflateSync} from 'node:zlib';
import {resolve} from 'node:path';

const root=resolve('community/achievement-icons');
await mkdir(root,{recursive:true});
const badges=[
 ['wf_weapon_mastery',[246,214,124],0],['wf_formation_breaker',[255,186,114],1],['wf_biome_collector',[159,240,210],2],
 ['wf_party_pings',[255,233,143],3],['wf_ready_party',[182,214,255],4],['wf_welcome_back',[255,146,122],5],
 ['wf_build_scout',[183,235,255],6],['wf_after_action',[232,208,165],7],['wf_style_collection',[240,210,120],8]
];
const pngChunk=(type,data)=>{const name=Buffer.from(type);const length=Buffer.alloc(4);length.writeUInt32BE(data.length);const checksum=Buffer.alloc(4);checksum.writeUInt32BE(crc32(Buffer.concat([name,data])));return Buffer.concat([length,name,data,checksum]);};
function crc32(bytes){let crc=0xffffffff;for(const byte of bytes){crc^=byte;for(let bit=0;bit<8;bit++)crc=(crc>>>1)^((crc&1)?0xedb88320:0);}return (crc^0xffffffff)>>>0;}
function pixel([w,h,data],x,y,c){if(x<0||y<0||x>=w||y>=h)return;const n=(y*w+x)*4;data[n]=c[0];data[n+1]=c[1];data[n+2]=c[2];data[n+3]=255;}
function polygon(ctx,points,color){const [w,h]=ctx;const minX=Math.max(0,Math.floor(Math.min(...points.map(p=>p[0])))),maxX=Math.min(w-1,Math.ceil(Math.max(...points.map(p=>p[0]))));const minY=Math.max(0,Math.floor(Math.min(...points.map(p=>p[1])))),maxY=Math.min(h-1,Math.ceil(Math.max(...points.map(p=>p[1]))));for(let y=minY;y<=maxY;y++)for(let x=minX;x<=maxX;x++){let inside=false;for(let i=0,j=points.length-1;i<points.length;j=i++){const [xi,yi]=points[i],[xj,yj]=points[j];if((yi>y)!==(yj>y)&&x<(xj-xi)*(y-yi)/(yj-yi)+xi)inside=!inside;}if(inside)pixel(ctx,x,y,color);}}
function line(ctx,x0,y0,x1,y1,color,width=5){const steps=Math.ceil(Math.hypot(x1-x0,y1-y0)*1.5),r=width/2;for(let i=0;i<=steps;i++){const x=x0+(x1-x0)*i/steps,y=y0+(y1-y0)*i/steps;for(let py=Math.floor(y-r);py<=y+r;py++)for(let px=Math.floor(x-r);px<=x+r;px++)if((px-x)**2+(py-y)**2<=r*r)pixel(ctx,px,py,color);}}
function circle(ctx,cx,cy,r,color,fill=true,width=5){const [w,h]=ctx;for(let y=Math.max(0,cy-r-width);y<Math.min(h,cy+r+width);y++)for(let x=Math.max(0,cx-r-width);x<Math.min(w,cx+r+width);x++){const d=Math.hypot(x-cx,y-cy);if(fill?d<=r:Math.abs(d-r)<=width/2)pixel(ctx,x,y,color);}}
function make(accent,index,locked){const w=256,h=256,ctx=[w,h,Buffer.alloc(w*h*4)],ink=[10,19,30],edge=locked?[88,95,93]:[201,169,104],a=locked?[92,96,92]:accent;
 polygon(ctx,[[128,4],[235,62],[235,180],[128,252],[21,180],[21,62]],ink);const points=[[128,4],[235,62],[235,180],[128,252],[21,180],[21,62]];for(let i=0;i<6;i++)line(ctx,points[i][0],points[i][1],points[(i+1)%6][0],points[(i+1)%6][1],edge,4);
 if(index===0){const p=[];for(let i=0;i<10;i++){const r=i%2?28:70,ang=-Math.PI/2+i*Math.PI/5;p.push([128+Math.cos(ang)*r,118+Math.sin(ang)*r]);}polygon(ctx,p,a);}
 else if(index===1){circle(ctx,83,89,22,a);circle(ctx,173,89,22,a);polygon(ctx,[[75,189],[128,70],[181,189],[128,160]],a);line(ctx,45,205,90,169,[255,240,190],7);line(ctx,166,169,211,205,[255,240,190],7);}
 else if(index===2){polygon(ctx,[[128,40],[178,75],[160,160],[128,200],[96,160],[78,75]],a);line(ctx,128,40,128,200,ink,7);line(ctx,78,75,178,75,ink,7);line(ctx,96,160,160,160,ink,7);}
 else if(index===3){circle(ctx,128,125,58,a,false,8);circle(ctx,128,125,35,a,false,8);circle(ctx,128,125,12,a,true);}
 else if(index===4){line(ctx,67,126,108,168,a,14);line(ctx,108,168,190,78,a,14);}
 else if(index===5){circle(ctx,128,124,58,a,false,10);polygon(ctx,[[93,43],[61,55],[84,82]],a);line(ctx,73,54,116,54,a,10);}
 else if(index===6){polygon(ctx,[[45,119],[72,82],[128,65],[184,82],[211,119],[184,157],[128,174],[72,157]],a);circle(ctx,128,119,27,ink);circle(ctx,128,119,13,[255,240,190]);}
 else if(index===7){for(let i=0;i<3;i++)line(ctx,75,81+i*37,181-(i===2?35:0),81+i*37,a,9);}
 else {for(let i=0;i<3;i++)circle(ctx,82+i*46,147-i%2*20,23,a,false,9);polygon(ctx,[[128,35],[141,68],[177,71],[150,95],[158,130],[128,112],[98,130],[106,95],[79,71],[115,68]],a);}
 const raw=Buffer.alloc((w*4+1)*h);for(let y=0;y<h;y++)ctx[2].copy(raw,y*(w*4+1)+1,y*w*4,(y+1)*w*4);
 const header=Buffer.alloc(13);header.writeUInt32BE(w);header.writeUInt32BE(h,4);header[8]=8;header[9]=6;
 return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),pngChunk('IHDR',header),pngChunk('IDAT',deflateSync(raw)),pngChunk('IEND',Buffer.alloc(0))]);
}
for(const [id,color,index] of badges){await writeFile(resolve(root,id+'-unlocked.png'),make(color,index,false));await writeFile(resolve(root,id+'-locked.png'),make([106,112,108],index,true));}
console.log('Generated 18 distinct 256px achievement images.');
