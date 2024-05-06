# miniply-swift

`miniply-swift` is a Swift wrapper for the [miniply](https://github.com/vilya/miniply) C++ library, designed to simplify the process of loading .ply files in your Swift projects.

> [!WARNING]  
> This wrapper is not complete. The only functionality implemented is loading of basic property types (int, float, double, etc.) from a `.ply` file. List property types are not supported.
>
> Pull requests are welcome!

## Features
* Swift-friendly API for loading .ply files.
* Leverages the power and efficiency of the `miniply` C++ library.
* Easy to integrate into your Swift projects.

## Installation

> **Warning**: These instructions are untested. Please let me know if you encounter any issues.

You can install `miniply-swift` using the Swift Package Manager. Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/Netruk44/miniply-swift", from: "0.1.0")
]
```

In addition, you will need to change your Swift project's build settings to use Objective-C++. To do this, go to your project's settings and go to the "Build Settings" tab. Search for "Interop" to find the `C++ and Objective-C Interoperability` setting, and set it to "C++ / Objective-C++".


## Usage

Here's a basic example of how to use `miniply-swift` to load a `.ply` file:

```swift
import miniply_swift

// For example purposes, throw strings.
extension String : Error { }

class MyClass {

  private struct VertexData {
        // Note: ALL properties must be of the same type (e.g. Float).
        //       If you need to load multiple types, you will need to create
        //       separate structs for each type.

        var x: Float = 0
        var y: Float = 0
        var z: Float = 0
        
        var scaleX: Float = 0
        var scaleY: Float = 0
        var scaleZ: Float = 0
        
        var orientationX: Float = 0
        var orientationY: Float = 0
        var orientationZ: Float = 0
        var orientationW: Float = 0
        
        var colorR: Float = 0
        var colorG: Float = 0
        var colorB: Float = 0
        var opacity: Float = 0
        
        // Elements of this array MUST follow the same ordering as this struct
        // Otherwise the memory won't be copied into this object correctly.
        //
        // You will need to update these strings for your specific .ply file.
        static let requiredProperties = [
            "x", "y", "z",
            "scale_0", "scale_1", "scale_2",
            "rot_0", "rot_1", "rot_2", "rot_3",
            "colorR", "colorG", "colorB", "colorA"
        ]
    }

    func loadPlyFile(plyFilePath: String) {
        let reader = PlyReader(fromFilePath: plyFile)
        guard reader.isValid() else { throw "Invalid .ply file." }

        while reader.hasElement() {
          // Look for the vertex element
          guard reader.currentElementIs(ofType: .VertexElement) else {
            reader.nextElement()
            continue
          }

          guard reader.loadElement() else { throw "Failed to load vertex element." }

          guard let foundIndices = reader.findPropertyIndices(forProperties: VertexData.requiredProperties) else {
            throw "Failed to find required properties."
          }

          guard var loadedData: [VertexData] = reader.retrieveProperties(forIndices: foundIndices, ofType: .Float) else {
            throw "Failed to retrieve properties."
          }

          // TODO: Do something with the loaded data.
        }
    }
}
```

## License

`miniply-swift` is released under the MIT license. See [license.md](license.md) for details.