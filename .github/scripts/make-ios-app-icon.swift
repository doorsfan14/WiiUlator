import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: make-ios-app-icon.swift <output-directory> <source-size>\n", stderr)
    exit(2)
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let sourceSize = CGFloat(Double(CommandLine.arguments[2]) ?? 1024)

let backgroundURL = outputDirectory.appendingPathComponent("background.png")
let foregroundURL = outputDirectory.appendingPathComponent("icon.png")

guard let background = NSImage(contentsOf: backgroundURL),
      let foreground = NSImage(contentsOf: foregroundURL) else {
    fputs("Unable to load icon artwork.\n", stderr)
    exit(1)
}

let sourceCanvasSize = NSSize(width: sourceSize, height: sourceSize)
let composed = NSImage(size: sourceCanvasSize)
composed.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high
let sourceRect = NSRect(origin: .zero, size: sourceCanvasSize)
background.draw(in: sourceRect, from: NSRect(origin: .zero, size: background.size), operation: .copy, fraction: 1.0)
foreground.draw(in: sourceRect, from: NSRect(origin: .zero, size: foreground.size), operation: .sourceOver, fraction: 1.0)
composed.unlockFocus()

let sizes: [(String, CGFloat)] = [
    ("WiiUlator-60@2x.png", 120),
    ("WiiUlator-60@3x.png", 180),
    ("WiiUlator-76@2x.png", 152),
    ("WiiUlator-83.5@2x.png", 167),
    ("WiiUlator-1024.png", 1024)
]

for (filename, pixels) in sizes {
    let outputSize = NSSize(width: pixels, height: pixels)
    let image = NSImage(size: outputSize)
    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    composed.draw(in: NSRect(origin: .zero, size: outputSize),
                  from: sourceRect,
                  operation: .copy,
                  fraction: 1.0)
    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        fputs("Unable to encode \(filename).\n", stderr)
        exit(1)
    }

    try png.write(to: outputDirectory.appendingPathComponent(filename))
    print("Generated \(filename)")
}