package net.teamceleste.wiiulator;

import java.util.Arrays;

final class WiiUAudio {
    static final int SAMPLE_RATE = 48000;
    static final int CHANNELS = 2;
    static final int BLOCK_SAMPLES = 512;

    private short[] buffer = new short[BLOCK_SAMPLES * CHANNELS];
    private int writePosition;
    private boolean enabled = true;
    private float volume = 1.0f;

    void reset() {
        Arrays.fill(buffer, (short) 0);
        writePosition = 0;
    }

    void setEnabled(boolean value) { enabled = value; }
    boolean isEnabled() { return enabled; }

    void setVolume(float value) { volume = Math.max(0.0f, Math.min(1.0f, value)); }
    float volume() { return volume; }

    int queuedSamples() { return writePosition / CHANNELS; }

    void submit(short[] samples, int sampleCount) {
        if (!enabled || sampleCount <= 0) return;
        int frames = Math.min(sampleCount, buffer.length / CHANNELS);
        for (int i = 0; i < frames * CHANNELS; i++) {
            int scaled = Math.round(samples[i] * volume);
            buffer[i] = (short) Math.max(Short.MIN_VALUE, Math.min(Short.MAX_VALUE, scaled));
        }
        writePosition = frames * CHANNELS;
    }

    short[] consume() {
        short[] out = Arrays.copyOf(buffer, writePosition);
        writePosition = 0;
        return out;
    }
}
