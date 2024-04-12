//
//  UIimageAndMat.h
//  PaperRecognition
//
//  Created by mac on 2024/4/9.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface UIImageAndMat : NSObject
//+(cv::Mat)cvMatFromImage:(UIImage *)image;
//+(UIImage *)ImageFromCVMat:(cv::Mat)cvMat;
//
//#pragma mark - cvMatFromUIImage    4通道RGBA图
//+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
//#pragma mark - cvMatGrayFromUIImage    单通道灰度图
//+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;
//#pragma mark - UIImageFromCVMat
//+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;

+ (UIImage *)drawellipse:(UIImage *)fingerImage;
@end

NS_ASSUME_NONNULL_END
