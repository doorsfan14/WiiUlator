package net.teamceleste.wiiulator;

final class PowerPCCPU {
 final int[] r=new int[32]; int pc,cr,lr,ctr,xer,last,unsupported,syscall;
 void reset(){java.util.Arrays.fill(r,0);pc=cr=lr=ctr=xer=last=unsupported=syscall=0;}
 void step(EmulatorMemory m){int cur=pc;int ins=m.read32(cur);last=ins;unsupported=0;pc+=4;int op=ins>>>26;
  switch(op){
   case 7: {int d=ins>>>21&31,a=ins>>>16&31;r[d]=r[a]*(short)(ins&65535);break;}
   case 8: {int d=ins>>>21&31,a=ins>>>16&31;r[d]=(short)(ins&65535)-r[a];break;}
   case 14: {int d=ins>>>21&31,a=ins>>>16&31;r[d]=base(a)+sign16(ins);break;}
   case 15: {int d=ins>>>21&31,a=ins>>>16&31;r[d]=base(a)+(sign16(ins)<<16);break;}
   case 16: branchCond(ins,cur);break;
   case 17: syscall=r[0];break;
   case 18: {int li=ins&0x03fffffc;int t=((li&0x02000000)!=0?li|0xfc000000:li);if((ins&2)!=0)pc=t;if((ins&2)==0)pc=cur+t;if((ins&1)!=0)lr=cur+4;break;}
   case 24:{int s=ins>>>21&31,d=ins>>>16&31;r[d]=r[s]|(ins&65535);break;}
   case 25:{int s=ins>>>21&31,d=ins>>>16&31;r[d]=r[s]|((ins&65535)<<16);break;}
   case 26:{int s=ins>>>21&31,d=ins>>>16&31;r[d]=r[s]^(ins&65535);break;}
   case 28:{int s=ins>>>21&31,d=ins>>>16&31;int v=r[s]&(ins&65535);r[d]=v;cr=(cr&0x0fffffff)|((v==0?2:(v<0?8:4))<<28);break;}
   case 32:r[ins>>>21&31]=m.read32(ea(ins));break;
   case 33:{int a=ea(ins);r[ins>>>16&31]=a;r[ins>>>21&31]=m.read32(a);break;}
   case 34:r[ins>>>21&31]=m.readU8(ea(ins));break;
   case 36:m.write32(ea(ins),r[ins>>>21&31]);break;
   case 37:{int a=ea(ins);r[ins>>>16&31]=a;m.write32(a,r[ins>>>21&31]);break;}
   case 38:m.write8(ea(ins),r[ins>>>21&31]);break;
   case 40:r[ins>>>21&31]=m.read16(ea(ins));break;
   case 44:m.write16(ea(ins),r[ins>>>21&31]);break;
   case 46:{int a=ea(ins),d=ins>>>21&31;for(int i=d;i<32;i++){r[i]=m.read32(a);a+=4;}break;}
   case 47:{int a=ea(ins),s=ins>>>21&31;for(int i=s;i<32;i++){m.write32(a,r[i]);a+=4;}break;}
   case 31:op31(ins,m,cur);break;
   case 19:if((ins>>>1&1023)==16&&cond(ins)){pc=lr&~3;}break;
   default:unsupported=ins;break;
  }
 }
 int base(int a){return a==0?0:r[a];} int ea(int i){return base(i&31)+(short)i;}
 int sign16(int i){return (short)(i&65535);}
 boolean cond(int i){int bo=i>>>21&31,bi=i>>>16&31;boolean ctrOk;if((bo&4)!=0)ctrOk=true;else{ctr--;ctrOk=((ctr!=0)==((bo&2)!=0));}boolean crOk=(bo&16)!=0||(((cr>>>(31-bi))&1)!=0)==((bo&8)!=0);return ctrOk&&crOk;}
 void branchCond(int i,int cur){if(cond(i)){int bd=(short)(i&0xfffc);pc=((i&2)!=0?bd:cur+bd);}if((i&1)!=0)lr=cur+4;}
 void op31(int i,EmulatorMemory m,int cur){
  int xo=i>>>1&1023,s=i>>>21&31,a=i>>>16&31,b=i>>>11&31;
  switch(xo){
   case 19:r[a]=cr;break;
   case 24:r[a]=r[s]<<(r[b]&31);break;
   case 26:r[a]=Integer.numberOfLeadingZeros(r[s]);break;
   case 40:r[a]=r[b]-r[s];break;
   case 104:r[a]=-r[s];break;
   case 124:r[a]=~(r[s]|r[b]);break;
   case 235:r[a]=r[s]*r[b];break;
   case 476:r[a]=~(r[s]&r[b]);break;
   case 491:if(r[b]!=0 && !(r[s]==Integer.MIN_VALUE && r[b]==-1))r[a]=r[s]/r[b];break;
   case 266:r[a]=r[s]+r[b];break;
   case 444:r[a]=r[s]|r[b];break;
   case 316:r[a]=r[s]^r[b];break;
   case 28:r[a]=r[s]&r[b];break;
   case 536:r[a]=r[s]>>>(r[b]&31);break;
   case 534:{int ad=base(a)+r[b];r[s]=Integer.reverseBytes(m.read32(ad));break;}
   case 662:{int ad=base(a)+r[b];m.write32(ad,Integer.reverseBytes(r[s]));break;}
   case 16:if(cond(i))pc=lr&~3;if((i&1)!=0)lr=cur+4;break;
   case 528:if(cond(i))pc=ctr&~3;break;
   case 339:{int spr=((i>>>16)&31)|(((i>>>11)&31)<<5);r[a]=spr==1?xer:spr==8?lr:spr==9?ctr:0;break;}
   case 467:{int spr=((i>>>16)&31)|(((i>>>11)&31)<<5);if(spr==8)lr=r[s];else if(spr==9)ctr=r[s];else if(spr==1)xer=r[s];break;}
   default:unsupported=i;
  }
 }
}
