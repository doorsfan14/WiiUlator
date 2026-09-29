package net.teamceleste.wiiulator;

final class CafeKernel {
    static final int SYS_CONSOLE_WRITE = 0x0000;
    static final int SYS_APP_EXIT = 0x1900;
    static final int SYS_PROC_YIELD_CORE = 0x2C00;
    static final int SYS_GET_ABSOLUTE_TIME = 0x3000;
    static final int SYS_ALLOC_VIRT_ADDR = 0x3800;
    static final int SYS_FREE_VIRT_ADDR = 0x3900;
    static final int SYS_MEMORY_BARRIER = 0x0101;

    boolean exited;
    int exitCode;
    private int heapCursor = 0x08000000;

    void reset() {
        exited = false;
        exitCode = 0;
        heapCursor = 0x08000000;
    }

    void dispatch(PowerPCCPU cpu, EmulatorMemory memory) {
        int number = cpu.syscall;
        cpu.syscall = 0;
        switch (number) {
            case SYS_CONSOLE_WRITE:
                consoleWrite(cpu, memory);
                break;
            case SYS_APP_EXIT:
                exited = true;
                exitCode = cpu.r[3];
                break;
            case SYS_PROC_YIELD_CORE:
                break;
            case SYS_GET_ABSOLUTE_TIME:
                cpu.r[3] = (int)(System.nanoTime() / 1000L);
                break;
            case SYS_ALLOC_VIRT_ADDR:
                int size = align4K(cpu.r[3]);
                if (size <= 0) {
                    cpu.r[3] = 0;
                } else {
                    int result = heapCursor;
                    long next = (long)heapCursor + size;
                    if (next > 0x0FFFFFFFL) {
                        cpu.r[3] = 0;
                    } else {
                        heapCursor = (int)next;
                        cpu.r[3] = result;
                    }
                }
                break;
            case SYS_FREE_VIRT_ADDR:
                cpu.r[3] = 0;
                break;
            case SYS_MEMORY_BARRIER:
                break;
            default:
                cpu.r[3] = -1;
                break;
        }
    }

    private void consoleWrite(PowerPCCPU cpu, EmulatorMemory memory) {
        int address = cpu.r[3];
        int length = cpu.r[4];
        if (length <= 0 || length > 4096) return;
        StringBuilder out = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            int c = memory.readU8(address + i);
            if (c == 0) break;
            out.append((char)c);
        }
        if (out.length() > 0) System.out.print(out.toString());
        cpu.r[3] = out.length();
    }

    private int align4K(int value) {
        if (value <= 0) return 0;
        long aligned = ((long)value + 0xFFF) & ~0xFFFL;
        return aligned > Integer.MAX_VALUE ? 0 : (int)aligned;
    }
}
