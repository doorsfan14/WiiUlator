package net.teamceleste.wiiulator;

import static org.junit.Assert.assertEquals;
import org.junit.Test;

public class WiiULibTest {
    @Test public void addImmediateAndSharedSystemState() {
        WiiULib core = new WiiULib();
        int address = 0x1000;
        core.load(new byte[]{0x38,0x60,0x00,0x2A}, address, address);
        core.run(1);
        assertEquals(42, core.cpu.r[3]);
        assertEquals(address + 4, core.programCounter());
        assertEquals(1, core.instructions);
        assertEquals(1, core.system.cycles);
        assertEquals(core.memory, core.system.memory);
        assertEquals(core.cpu, core.system.cpu);
    }

    @Test public void branchAndLink() {
        WiiULib core = new WiiULib();
        int address = 0x2000;
        core.load(new byte[]{0x48,0x00,0x00,0x09,0x38,0x60,0x00,0x01,0x38,0x60,0x00,0x02}, address, address);
        core.run(1);
        assertEquals(address + 8, core.programCounter());
        assertEquals(address + 4, core.cpu.lr);
    }

    @Test public void bigEndianMemory() {
        EmulatorMemory memory = new EmulatorMemory();
        memory.write32(0x1FFE, 0x12345678);
        assertEquals(0x12345678, memory.read32(0x1FFE));
        memory.zero(4, 0x1FFE);
        assertEquals(0, memory.read32(0x1FFE));
    }
}
