package net.teamceleste.wiiulator;

import java.util.HashMap;
import java.util.Map;

final class EmulatorMemory {
    private static final int PAGE_SIZE=0x1000;
    private final Map<Integer,byte[]> pages=new HashMap<>();
    void reset(){pages.clear();}
    byte read8(int a){byte[] p=pages.get(a>>>12); return p==null?0:p[a&0xfff];}
    int readU8(int a){return read8(a)&255;}
    int read16(int a){byte[] p=pages.get(a>>>12); if(p!=null && (a&0xfff)!=0xfff)return ((p[a&0xfff]&255)<<8)|(p[(a&0xfff)+1]&255); return (readU8(a)<<8)|readU8(a+1);}
    int read32(int a){byte[] p=pages.get(a>>>12); int o=a&0xfff; if(p!=null && o<=0xffc)return ((p[o]&255)<<24)|((p[o+1]&255)<<16)|((p[o+2]&255)<<8)|(p[o+3]&255); return (readU8(a)<<24)|(readU8(a+1)<<16)|(readU8(a+2)<<8)|readU8(a+3);}
    void write8(int a,int v){int n=a>>>12; byte[] p=pages.get(n); if(p==null){p=new byte[PAGE_SIZE];pages.put(n,p);} p[a&0xfff]=(byte)v;}
    void write16(int a,int v){write8(a,v>>>8);write8(a+1,v);}
    void write32(int a,int v){write8(a,v>>>24);write8(a+1,v>>>16);write8(a+2,v>>>8);write8(a+3,v);}
    void load(byte[] d,int a){
        int source=0;
        while(source<d.length){
            int address=a+source, page=address>>>12, offset=address&0xfff, length=Math.min(PAGE_SIZE-offset,d.length-source);
            byte[] p=pages.get(page);
            if(p==null){p=new byte[PAGE_SIZE];pages.put(page,p);}
            System.arraycopy(d,source,p,offset,length);
            source+=length;
        }
    }
    void zero(int count,int a){
        while(count>0){
            int page=a>>>12, offset=a&0xfff, length=Math.min(PAGE_SIZE-offset,count);
            byte[] p=pages.get(page);
            if(p==null){p=new byte[PAGE_SIZE];pages.put(page,p);}
            java.util.Arrays.fill(p,offset,offset+length,(byte)0);
            a+=length; count-=length;
        }
    }
}
