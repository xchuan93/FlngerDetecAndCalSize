//
//  ViewController.swift
//  PaperRecognition
//
//  Created by mac on 2024/4/7.
//


import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadModelSplitFinger()
        
//        splitFinger()
    }
    
    func loadModelSplitFinger() {
        
        guard let model = try? fingerSize(configuration: MLModelConfiguration()).model else {
            fatalError("无法加载模型")
        }
        
        let imagePath = Bundle.main.path(forResource: "finger_image", ofType: "png")
        
        guard let image = UIImage(contentsOfFile: imagePath!) else {
            fatalError("无法加载图像")
        }
        
        guard let scaleImage = scaleImage(image, size: 416) else { return }
        
        
        let pixelBufferRef = ImageAndCVPixelBufferRef.cvPixelBufferRef(from: scaleImage)
        let pixelBuffer: CVPixelBuffer = pixelBufferRef.takeUnretainedValue()
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 416, height: 416))
        imageView.image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
        self.view.addSubview(imageView)
        
        let input = fingerSizeInput(imagePath: pixelBuffer)
        if let output = try? model.prediction(from: input) {
            
            if let confidenceFeature = output.featureValue(for: "confidence"),
               let confidenceMultiArray = confidenceFeature.multiArrayValue {
                // 访问类别置信度的 MultiArray 值
                print("Confidence MultiArray: \(confidenceMultiArray)")
            }
            
            if let coordinatesFeature = output.featureValue(for: "coordinates"),
               let coordinatesMultiArray = coordinatesFeature.multiArrayValue {
                // 访问坐标信息的 MultiArray 值
                drawPicture(coordinatesMultiArray: coordinatesMultiArray, scaleImage: scaleImage)
            }
            
        } else {
            print("Failed to make prediction.")
        }
        
    }
    
    func drawPicture(coordinatesMultiArray :MLMultiArray,scaleImage: UIImage) {
        
        let w = 416.0
        let h = 416.0
        
        let numberOfObjects = coordinatesMultiArray.count / 4 // 每个对象有四个值
        for i in 0..<numberOfObjects {
            let startIndex = i * 4
            let x = coordinatesMultiArray[startIndex]
            let y = coordinatesMultiArray[startIndex + 1]
            let width = coordinatesMultiArray[startIndex + 2]
            let height = coordinatesMultiArray[startIndex + 3]
            
            // 计算绝对坐标
            let absoluteX = x.doubleValue * w
            let absoluteY = y.doubleValue * h
            let absoluteWidth = width.doubleValue * w
            let absoluteHeight = height.doubleValue * h
            let rect = CGRect(x: CGFloat(absoluteX - absoluteWidth / 2),
                              y: CGFloat(absoluteY - absoluteHeight / 2),
                              width: CGFloat(absoluteWidth),
                              height: CGFloat(absoluteHeight))
            
            // 创建绘图上下文
            UIGraphicsBeginImageContext(scaleImage.size)
            let context = UIGraphicsGetCurrentContext()
            
            // 绘制矩形框
            context?.setStrokeColor(UIColor.red.cgColor)
            context?.setLineWidth(2.0)
            context?.addRect(rect)
            context?.drawPath(using: .stroke)
            
            // 从绘图上下文中获取图像
            let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            // 在图像视图上显示带有矩形框的图像
            let imageViewWithRect = UIImageView(frame: CGRect(x: 0, y: 0, width: 416, height: 416))
            imageViewWithRect.image = drawnImage
            self.view.addSubview(imageViewWithRect)
            
            let image = extractSubviewFromImage(image: scaleImage, rect: rect)
            
            let ellipseImage = UIImageAndMat.drawellipse(image!)
            
            let fingerImageView = UIImageView(frame: CGRect(x: 20 + (75) * CGFloat(i), y: 420, width: rect.width, height: rect.height))
            fingerImageView.image = ellipseImage
            
            self.view.addSubview(fingerImageView)
            
            
        }
    }
    
    func extractSubviewFromImage(image: UIImage, rect: CGRect) -> UIImage? {
        // 根据传入的矩形区域裁剪图像
        if let cgImage = image.cgImage?.cropping(to: rect) {
            let croppedImage = UIImage(cgImage: cgImage)
            return croppedImage
        }
        return nil
    }
    
    func scaleImage(_ image: UIImage, size: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size, height: size), true, 1)
        
        var x: CGFloat = 0, y: CGFloat = 0, w: CGFloat = 0, h: CGFloat = 0
        let imageW = image.size.width
        let imageH = image.size.height
        if imageW > imageH {
            w = imageW / imageH * size
            h = size
            x = (size - w) / 2
            y = 0
        } else {
            h = imageH / imageW * size
            w = size
            y = (size - h) / 2
            x = 0
        }
        
        image.draw(in: CGRect(x: x, y: y, width: w, height: h))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage
    }
    
    
//    func splitFinger() {
//        let vc = FingerDetectionViewController()
//        vc.view.frame = self.view.frame
//        self.addChild(vc)
//        self.view.addSubview(vc.view)
//    }
    
}


extension UIImage {
    func pixelBuffer() -> CVPixelBuffer? {
        let width = size.width
        let height = size.height
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32BGRA, attrs, &pixelBuffer)
        guard let buffer = pixelBuffer, status == kCVReturnSuccess else { return nil }
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        if let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                   width: Int(width),
                                   height: Int(height),
                                   bitsPerComponent: 8,
                                   bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                   space: CGColorSpaceCreateDeviceRGB(),
                                   bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) {
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1, y: -1)
            UIGraphicsPushContext(context)
            draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            UIGraphicsPopContext()
            return buffer
        }
        return nil
    }
}
