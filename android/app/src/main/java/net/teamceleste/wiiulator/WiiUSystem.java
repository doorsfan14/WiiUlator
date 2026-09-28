package net.teamceleste.wiiulator;

final class WiiUSystem {
    static final int MAIN_RAM_BASE = 0x10000000;
    static final int MAIN_RAM_SIZE = 0x10000000;
    static final int MMIO_BASE = 0x0C000000;
    static final int MMIO_SIZE = 0x01000000;

    final EmulatorMemory memory = new EmulatorMemory();
    final PowerPCCPU cpu = new PowerPCCPU();
    final WiiUAudio audio = new WiiUAudio();
    long cycles;

    void reset() {
        memory.reset();
        cpu.reset();
        audio.reset();
        cycles = 0;
    }

    void loadProgram(byte[] data, int address, int entryPoint) {
        reset();
        memory.load(data, address);
        cpu.pc = entryPoint;
    }

    void run(int instructions) {
        if (instructions <= 0) return;
        for (int i = 0; i < instructions; i++) {
            cpu.step(memory);
            cycles++;
            if (cpu.unsupported != 0) break;
        }
    }

    boolean isStopped() {
        return cpu.unsupported != 0;
    }
}
