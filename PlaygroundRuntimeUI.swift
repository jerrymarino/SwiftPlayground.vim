// PlaygroundRuntime.swift provides the logging built-ins for playground.
//
// These functions are executed by the Standard Library for code compiled with
// the playground frontend action.
//
// @see the transform logic here
// https://github.com/apple/swift/blob/master/lib/Sema/PlaygroundTransform.cpp
// https://github.com/apple/swift/blob/e156713/test/PlaygroundTransform/Inputs/PlaygroundsRuntime.swift

func __builtin_send_data(_ record: AnyObject?) {
    let record = record as! LogRecord
    guard record.api == "$builtin_log" else { return }

    if let imageRepresentable = record.object as? OpaqueImageRepresentable {
        let fileName: String = "\(record.range.text)_\(record.api)_repr"

        // NB: assetDirectory variable is generated via runner script.
        let outputPath: String = "\(assetDirectory)/\(fileName)@2x.png"

        if let pngData = imageRepresentable.pngData(), pngData.count > 0 {
            _ = try? pngData.write(to: URL(fileURLWithPath: outputPath), options: [.atomic])
        }
    }

    print(record.text)
}

private protocol OpaqueImageRepresentable {
    func pngData() -> Data?
}

#if os(iOS) || os(tvOS)
import UIKit

extension UIView: OpaqueImageRepresentable {
    func pngData() -> Data? {
        return UIGraphicsImageRenderer(size: bounds.size).pngData { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
#endif

#if os(iOS) || os(tvOS)
extension UIImage: OpaqueImageRepresentable {}
#endif

#if os(iOS) || os(tvOS)
import CoreGraphics

extension CGImage: OpaqueImageRepresentable {
    func pngData() -> Data? {
        #if os(iOS) || os(tvOS)
        return UIImage(cgImage: self).pngData()
        #endif
    }
}
#endif
