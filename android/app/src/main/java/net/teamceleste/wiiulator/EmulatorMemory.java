package net.teamceleste.wiiulator;

import java.util.HashMap;
import java.util.Map;

final class EmulatorMemory {
    private static final int PAGE_SIZE=0x1000;
    private final Map<Integer,byte[]> pages=new HashMap<>();
    void reset(){pages.clear();}
    byte read8(int a){byte[] p=pages.get(a>>>12); return p==null?0:p[a&0xfff];}
    int readU8(int a){return read8(a)&255;}
    int read16(int a){return (readU8(a)<<8)|readU8(a+1);}
    int read32(int a){return (readU8(a)<<24)|(readU8(a+1)<<16)|(readU8(a+2)<<8)|readU8(a+3);}
    void write8(int a,int v){int n=a>>>12; byte[] p=pages.get(n); if(p==null){p=new byte[PAGE_SIZE];pages.put(n,p);} p[a&0xfff]=(byte)v;}
    void write16(int a,int v){write8(a,v>>>8);write8(a+1,v);}
    void write32(int a,int v){write8(a,v>>>24);write8(a+1,v>>>16);write8(a+2,v>>>8);write8(a+3,v);}
    void load(byte[] d,int a){for(int i=0;i<d.length;i++)write8(a+i,d[i]);}
    void zero(int count,int a){for(int i=0;i<count;i++)write8(a+i,0);}
}
