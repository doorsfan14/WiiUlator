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

## Game Setup

Get your legally obtained `.wud` game dump and put it inside the `games` directory.

WiiUlator expects users to provide their own game dumps. Do not provide or distribute game files through the project.

## Building

Builds are provided through GitHub Actions.

## Known Limitations

WiiUlator is beta software, so crashes and other instability are expected.

Devices with limited memory may be more prone to crashes, especially:

- iPhone 11
- iPhone 11 Pro
- iPhone 11 Pro Max
- iPhone 12
- iPhone 12 mini
- iPhone 13
- iPhone 13 mini

These devices have 4 GB of RAM, which can be a limitation for WiiUlator depending on the game and emulator workload.

## Contributing

Contributions are welcome.

You can help with:

- Optimization
- Performance improvements
- Making custom clients
- Other development work related to WiiUlator

## Legal Disclaimer

Support will not assist with issues involving illegally obtained copies of games or system files that were not legitimately dumped from real Wii U hardware.

Please use your own legally obtained game dumps and legitimately dumped system files when reporting issues or requesting support.

## Credits

- **Nintendo** — Wii U hardware, software, and related intellectual property.
- **Habib** — WiiUlator development.

## License

GNU General Public License 3.0
