<p align="center">
  <img src="docs/wiiulator.png" alt="WiiUlator app icon" width="128">
</p>

<p align="center">
  <img src="docs/wordmark.png" alt="WiiUlator wordmark" width="140">
</p>

# WiiUlator

A Wii U emulator for iOS, iPadOS, and Android.

## Requirements

### iOS / iPadOS

- iOS 16.0 or later
- ARM64 device
- JIT required for emulation

### Android

- Android 8.0 or later (API 26+)
- ARM64 device
- Vulkan or OpenGL ES

## iOS Setup

### Sideloading

Use one of these methods to install the WiiUlator IPA:

- [SideStore](https://sidestore.io/) — [installation guide](https://docs.sidestore.io/docs/installation/install)
- [AltStore](https://altstore.io/) — [official guide](https://faq.altstore.io/)

SideStore's [official GitHub repository](https://github.com/SideStore/SideStore) and [documentation repository](https://github.com/SideStore/SideStore-Docs) are also available.

### JIT

WiiUlator requires JIT for emulation.

- **iOS 17.4+ / iOS 26+:** Use [StikDebug](https://github.com/StikDebug/StikDebug) and follow the [StikDebug guide](https://github.com/StikDebug/StikDebug-Guide).
- **Other supported iOS versions:** See the [SideStore JIT guide](https://docs.sidestore.io/docs/advanced/jit) for the available method for your version.
- **Jailbroken devices:** Use TrollStore if it is already installed and supported on your device.

### JIT Resources

- [StikDebug repository](https://github.com/StikDebug/StikDebug)
- [StikDebug Guide](https://github.com/StikDebug/StikDebug-Guide)
- [StikJIT repository](https://github.com/StikDebug/StikJIT)
- [SideStore JIT guide](https://docs.sidestore.io/docs/advanced/jit)

## Android Setup

Install the APK and provide your own legally obtained Wii U game and system files.

## Building

Builds are available through GitHub Actions. Development builds may require platform-specific signing and JIT configuration.

WiiUlator does not include Wii U games or system files.
