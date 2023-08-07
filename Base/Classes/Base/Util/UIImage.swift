//
//  UIImage.swift
//  HejhomeIpc
//
//  Created by Dasom Kim on 2023/05/03.
//

import Foundation

extension UIImage {
    static func ty_qrCode(with str: String, width: CGFloat) -> UIImage? {
        guard let data = str.data(using: .utf8), let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        filter.setDefaults()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        
        guard let outPutImage = filter.outputImage else {
            return nil
        }
        
        return _ty_createNonInterpolatedImage(from: outPutImage, with: width)
    }

    private static func _ty_createNonInterpolatedImage(from image: CIImage, with size: CGFloat) -> UIImage? {
        let extent = image.extent.integral
        let scale = min(size / extent.width, size / extent.height)
        let width = extent.width * scale
        let height = extent.height * scale
        
        guard let cs = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2) else {
            return nil
        }
        
        guard let bitmapRef = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: cs, bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            return nil
        }
        
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(image, from: extent) else {
            return nil
        }
        
        bitmapRef.interpolationQuality = .none
        bitmapRef.scaleBy(x: scale, y: scale)
        bitmapRef.draw(cgImage, in: extent)
        
        guard let scaledImage = bitmapRef.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: scaledImage)
    }

}
