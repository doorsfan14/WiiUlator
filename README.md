# WiiUlator

WiiUlator is an open-source Wii U emulator for iOS and iPadOS, built with SwiftUI and optimized for ARM64 Apple devices. It focuses on performance, stability, and a modular emulator core, with Metal graphics, JIT support, and GitHub Actions builds planned.

## Features

- SwiftUI-based interface
- iOS and iPadOS support
- iOS 16.0 minimum
- ARM64 optimization
- Metal graphics backend
- Experimental Vulkan backend planned
- JIT / dynamic recompilation planned
- Game library and management
- Game search
- Game importing to `Documents/Apps/Games`
- Square game artwork support through GameTDB-compatible title artwork
- Configurable controls
- Graphics settings
- Performance options
- Optional developer debugging/performance overlay
- Debug logging toggle
- GitHub Actions IPA builds

## Performance

WiiUlator is designed with modern Apple hardware in mind, with the iPhone 13 and A15 Bionic being an early performance target.

The goal is stable emulation speed and good frame pacing rather than simply maximizing FPS.

Planned performance features include:

- 30 FPS modes
- Performance modes
- Frame pacing
- Dynamic recompilation
- Device-specific optimization

## Graphics

Metal will be the primary graphics backend for Apple platforms.

A graphics abstraction layer will allow additional backends to be implemented later, including an experimental Vulkan backend.

## JIT

JIT and dynamic recompilation are planned as important parts of WiiUlator's performance architecture.

The App Store build will not depend on JIT being available. Development and testing builds may use appropriate signing and debugging configurations for environments where JIT can be enabled.

## Development

WiiUlator is currently in early development.

The first development milestone, **WiiUlator Nightly 1.0**, focuses on building the SwiftUI frontend and establishing the GitHub Actions build system.

The planned development order is:

1. SwiftUI frontend
2. Game library
3. Settings and configuration
4. GitHub Actions IPA builds
5. Emulator core
6. CPU emulation
7. Memory and system emulation
8. GPU and Metal rendering
9. Audio and input
10. Performance optimization
11. Compatibility testing

## Game Storage

Imported games are copied into the app container at `Documents/Apps/Games`, exposed in the app as `Apps/Games`. WiiUlator does not bundle proprietary Wii U game or system files.

## Game Artwork

WiiUlator's game library uses square artwork for game icons. A useful source for Wii U 1:1 artwork is the LaunchBox Community **Nintendo Wii U 1:1 Pack**, which provides 500×500 square images. GameTDB is also used for Wii U game metadata and artwork.

## Testing

Game files and proprietary Nintendo system files will not be included in the repository or distributed with WiiUlator.

Private testing will be performed separately from the public project.

Testing will eventually cover:

- Game booting
- CPU correctness
- GPU rendering
- Audio
- Controller input
- Wii U GamePad functionality
- Saves
- Performance
- Frame pacing
- Stability
- Regression testing

## Build

WiiUlator uses GitHub Actions to build the iOS application.

The nightly workflow targets **iOS 16.0+** and produces an IPA for testing.

## Future Platforms

The initial focus is iOS and iPadOS.

The emulator core will be designed with portability in mind, allowing future work on platforms such as Android.

## Status

🚧 WiiUlator is currently in early development.

The immediate goal is to build the frontend, establish reliable IPA builds, and progressively implement the emulator core.
