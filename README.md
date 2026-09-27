<p align="center">
  <img src="docs/wiiulator.png" alt="WiiUlator app icon" width="128">
</p>

<p align="center">
  <img src="docs/wordmark.png" alt="WiiUlator wordmark" width="140">
</p>

# WiiUlator

A Wii U emulator for iOS, iPadOS, and Android.

## Features

- PowerPC CPU emulation
- Memory and system emulation
- GPU rendering
- Audio
- Input and controller support
- Game library and importing
- JIT / dynamic recompilation

## Requirements

### iOS / iPadOS

- iOS 16.0+
- ARM64
- JIT

### Android

- Android 8.0+ (API 26)
- ARM64
- Vulkan or OpenGL ES

## Installation

### iOS / iPadOS

WiiUlator requires sideloading.

- [SideStore](https://sidestore.io/) — [installation guide](https://docs.sidestore.io/docs/installation/install)
- [AltStore](https://altstore.io/) — [guide](https://faq.altstore.io/)
- [SideStore GitHub](https://github.com/SideStore/SideStore)
- [StikDebug GitHub](https://github.com/StikDebug/StikDebug) — JIT
- [StikDebug Guide](https://github.com/StikDebug/StikDebug-Guide)
- [SideStore JIT Guide](https://docs.sidestore.io/docs/advanced/jit)

For jailbroken devices, use TrollStore if supported.

### Android

Install the APK and provide your own Wii U game and system files.

## Building

Builds are provided through GitHub Actions.

## Legal

WiiUlator does not distribute copyrighted Wii U games or proprietary system files.
