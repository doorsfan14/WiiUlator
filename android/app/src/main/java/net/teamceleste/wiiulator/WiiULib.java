package net.teamceleste.wiiulator;

import java.io.*;

final class WiiULib {
 final WiiUSystem system=new WiiUSystem();
 final EmulatorMemory memory=system.memory;
 final PowerPCCPU cpu=system.cpu;
 final CafeKernel kernel=system.kernel;
 WiiUAudio audio(){return system.audio;}
 long instructions;
 int entry;

 void reset(){system.reset();instructions=0;entry=0;}
 void load(byte[] data,int address,int entryPoint){reset();memory.load(data,address);entry=entryPoint;cpu.pc=entryPoint;}
 void run(int count){if(count<=0)return;for(int i=0;i<count;i++){cpu.step(memory);if(cpu.syscall>=0)kernel.dispatch(cpu,memory);instructions++;system.cycles++;if(cpu.unsupported!=0||kernel.exited)break;}}
 boolean isStopped(){return cpu.unsupported!=0;}
 int programCounter(){return cpu.pc;}
 static int u16(byte[]d,int o){return ((d[o]&255)<<8)|(d[o+1]&255);}
 static int u32(byte[]d,int o){return ((d[o]&255)<<24)|((d[o+1]&255)<<16)|((d[o+2]&255)<<8)|(d[o+3]&255);}

 void loadElf(byte[]d)throws IOException{
  reset();
  if(d.length<52||d[0]!=0x7f||d[1]!='E'||d[2]!='L'||d[3]!='F')throw new IOException("Not ELF");
  if(d[4]!=1||d[5]!=2)throw new IOException("Need 32-bit big-endian ELF");
  if(u16(d,18)!=20)throw new IOException("Need PowerPC ELF");
  entry=u32(d,24);
  int ph=u32(d,28),psz=u16(d,42),pc=u16(d,44);
  boolean loaded=false;
  if(psz>=32&&ph>=0&&pc>0&&ph<=d.length&&pc<=(d.length-ph)/psz){
   for(int i=0;i<pc;i++){
    int o=ph+i*psz;
    if(u32(d,o)!=1)continue;
    int off=u32(d,o+4),va=u32(d,o+8),fs=u32(d,o+16),ms=u32(d,o+20);
    if(off<0||fs<0||ms<fs||((long)off+fs)>d.length)throw new IOException("Invalid load segment");
    memory.load(java.util.Arrays.copyOfRange(d,off,off+fs),va);
    if(ms>fs)memory.zero(ms-fs,va+fs);
    loaded=true;
   }
  }
  if(!loaded){
   int sh=u32(d,32),ss=u16(d,46),sc=u16(d,48);
   if(ss<40||sc<=0||sh<0||sh>d.length||sc>(d.length-sh)/ss)throw new IOException("Invalid RPX sections");
   for(int i=0;i<sc;i++){
    int o=sh+i*ss,flags=u32(d,o+8),va=u32(d,o+12),off=u32(d,o+16),sz=u32(d,o+20),type=u32(d,o+4);
    if((flags&2)==0)continue;
    if(type!=8){if(((long)off+sz)>d.length)throw new IOException("Section out of bounds");memory.load(java.util.Arrays.copyOfRange(d,off,off+sz),va);}
    else memory.zero(sz,va);
    loaded=true;
   }
  }
  if(!loaded)throw new IOException("No loadable segments");
  cpu.pc=entry;instructions=0;
 }
}
