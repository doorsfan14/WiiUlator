import AppKit
import Foundation

guard CommandLine.arguments.count == 4 else {
    fputs("usage: make-ios-app-icon.swift <background.png> <foreground.png> <output.png>\n", stderr)
    exit(2)
}

let backgroundURL = URL(fileURLWithPath: CommandLine.arguments[1])
let foregroundURL = URL(fileURLWithPath: CommandLine.arguments[2])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[3])

guard let background = NSImage(contentsOf: backgroundURL),
      let foreground = NSImage(contentsOf: foregroundURL) else {
    fputs("Unable to load icon artwork.\n", stderr)
    exit(1)
}

let size = NSSize(width: 1024, height: 1024)
let canvas = NSImage(size: size)

canvas.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high

let destination = NSRect(origin: .zero, size: size)
background.draw(in: destination, from: NSRect(origin: .zero, size: background.size), operation: .copy, fraction: 1.0)
foreground.draw(in: destination, from: NSRect(origin: .zero, size: foreground.size), operation: .sourceOver, fraction: 1.0)

canvas.unlockFocus()

guard let tiff = canvas.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fputs("Unable to encode the generated app icon.\n", stderr)
    exit(1)
}

try png.write(to: outputURL)
print("Generated \(outputURL.path)")
