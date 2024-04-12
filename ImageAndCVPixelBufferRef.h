//
//  ImageAndCVPixelBufferRef.h
//  PaperRecognition
//
//  Created by mac on 2024/4/11.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageAndCVPixelBufferRef : NSObject
+ (CVPixelBufferRef)CVPixelBufferRefFromUiImage:(UIImage *)img;

+ (CVPixelBufferRef) pixelBufferFromCGImage:(CGImageRef)image;


@end

NS_ASSUME_NONNULL_END
