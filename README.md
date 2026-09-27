<p align="center">
  <img src="docs/wiiulator.png" alt="WiiUlator app icon" width="128">
</p>

<p align="left">
  <img src="docs/wordmark.png" alt="WiiUlator wordmark" width="240">
</p>

# WiiUlator

WiiUlator is an open-source Wii U emulator for iOS, iPadOS, and Android. The project is currently focused on building a portable emulator core alongside native platform frontends.

## Source Code

The repository is organized around the emulator core and platform-specific frontends:

- `Sources/` — Swift source code and iOS/iPadOS frontend
- `android/` — Android application and Android-specific frontend
- `Tests/` — emulator and platform tests
- `.github/workflows/` — automated builds and development workflows

The emulator is being developed as a modular codebase so CPU, memory, graphics, audio, input, and platform layers can evolve independently.

## Current Development

WiiUlator is in early development. Current work includes:

- Native SwiftUI frontend for iOS and iPadOS
- Native Material 3 Android frontend
- Game library and importing
- Emulator core development
- CPU and memory emulation
- Metal graphics work for Apple platforms
- Vulkan/OpenGL ES work for Android
- Configurable controls
- Graphics and performance settings
- GitHub Actions builds

## Platform Support

### iOS / iPadOS

- iOS 16.0+
- ARM64
- SwiftUI
- Metal
- Experimental Vulkan support planned
- JIT / dynamic recompilation planned

### Android

- Android 8.0+ (API 26)
- ARM64
- Native Android UI
- Vulkan / OpenGL ES graphics backends

## Game Storage

Imported games are stored inside the app's private game directory. WiiUlator does not bundle proprietary Wii U game or system files.

## Development Roadmap

1. Platform frontends
2. Game library and management
3. Emulator core
4. CPU emulation
5. Memory and system emulation
6. GPU and graphics rendering
7. Audio and input
8. Dynamic recompilation / JIT
9. Performance optimization
10. Compatibility testing

## Building

Builds are automated with GitHub Actions.

Development and testing builds may require platform-specific signing, debugging, or JIT configurations.

## Contributing

WiiUlator is currently in active early development. Contributions to the emulator core, platform frontends, graphics, input, performance, testing, and tooling are welcome.

Please do not add proprietary Nintendo game, system, or copyrighted distribution files to the repository.

## Status

🚧 **Early development**

WiiUlator is currently focused on building the source code and emulator architecture before expanding compatibility.
