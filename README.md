<p align="center">
  <img src="docs/wiiulator.png" alt="WiiUlator app icon" width="128">
</p>

<p align="center">
  <img src="docs/wordmark.png" alt="WiiUlator wordmark" width="140">
</p>

# WiiUlator

WiiUlator is an open-source Wii U emulator for iOS, iPadOS, and Android, developed by Team Celeste.

The project has separate native frontends for each platform and a portable emulator core. The Android frontend uses native Android UI, while the iOS/iPadOS frontend uses SwiftUI.

## Emulator

WiiUlator is being developed around the main components required to run Wii U software:

- PowerPC CPU emulation
- Memory and system emulation
- GPU and graphics rendering
- Audio
- Input and controller handling
- Game library and game importing
- JIT / dynamic recompilation

The emulator is currently in development and is not presented as a finished compatibility layer.

## iOS / iPadOS

### Requirements

- iOS 16.0 or later
- ARM64 device
- JIT required for practical emulation

### Sideloading

Install the WiiUlator IPA with:

- [SideStore](https://sidestore.io/) — [installation guide](https://docs.sidestore.io/docs/installation/install)
- [AltStore](https://altstore.io/) — [official guide](https://faq.altstore.io/)

Repositories and documentation:

- [SideStore repository](https://github.com/SideStore/SideStore)
- [SideStore documentation](https://github.com/SideStore/SideStore-Docs)

### JIT

WiiUlator requires JIT for emulation.

- [StikDebug](https://github.com/StikDebug/StikDebug) — JIT/debugging tool
- [StikDebug Guide](https://github.com/StikDebug/StikDebug-Guide) — setup documentation
- [StikJIT](https://github.com/StikDebug/StikJIT) — JIT-related project
- [SideStore JIT guide](https://docs.sidestore.io/docs/advanced/jit)

For jailbroken devices, TrollStore can be used where it is already installed and supported.

## Android

### Requirements

- Android 8.0 or later (API 26+)
- ARM64 device
- Vulkan or OpenGL ES support

The Android frontend is built with native Android components and is separate from the iOS/iPadOS UI.

## Game Files

WiiUlator does not distribute Wii U games or proprietary Wii U system files. Users are responsible for providing compatible files they are legally entitled to use.

## Building

Development builds are provided through GitHub Actions. Platform-specific signing and JIT configuration may be required for development and testing.
