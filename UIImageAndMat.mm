//
//  UIimageAndMat.m
//  PaperRecognition
//
//  Created by mac on 2024/4/9.
//
#import <opencv2/opencv.hpp>
#import "UIImageAndMat.h"

@implementation UIImageAndMat

+(cv::Mat)cvMatFromImage:(UIImage *)image{
    //获取图片的CGImageRef结构体
    CGImageRef imageRef = CGImageCreateCopy([image CGImage]);
    //获取图片尺寸
    CGSize size = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    //获取图片宽度
    CGFloat cols = size.width;
    //获取图高度
    CGFloat rows = size.height;
    //获取图片颜色空间，创建图片对应Mat对象，需要使用同样的颜色空间
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    
    //判断图片的通道位深及通道数 默认使用8位4通道格式
    int type = CV_16UC4;
    //获取bitmpa位数
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    //获取通道位深
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    //获取通道数
    size_t channels = bitsPerPixel/bitsPerComponent;
    if(channels == 3 || channels == 4){  // 因为quartz框架只支持处理带有alpha通道的数据，所以3通道的图片采取跟4通道的图片一样的处理方式，转化的时候alpha默认会赋最大值，归一化的数值位1.0，这样即使给图片增加了alpha通道，也并不会影响图片的展示
        if(bitsPerComponent == 8){
            //8位3通道 因为iOS端只支持
            type = CV_8UC4;
        }else if(bitsPerComponent == 16){
            //16位3通道
            type = CV_16UC4;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else{
        printf("图片格式不支持");
        abort();
    }
    
    //创建位图信息  根据通道位深及通道数判断使用的位图信息
    CGBitmapInfo bitmapInfo;
    
    if(bitsPerComponent == 8){
        if(channels == 3){
            bitmapInfo = kCGImageAlphaNone | kCGImageByteOrderDefault;
        }else  if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrderDefault;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else if(bitsPerComponent == 16){
        if(channels == 3){  //虽然是三通道，但是iOS端的CGBitmapContextCreate方法不支持16位3通道的创建，所以仍然作为4通道处理
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrder16Little;
        }else  if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrder16Little;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else{
        printf("图片格式不支持");
        abort();
    }
    
    
    //使用获取到的宽高创建mat对象CV_16UC4 为传入的矩阵类型
    cv::Mat cvMat(rows, cols, type); // 每通道8bit 共有4通道（RGB + Alpha通道 RGBA格式）
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // 数据源
                                                    cols,                       // 每行像素数
                                                    rows,                       // 列数（高度）
                                                    bitsPerComponent,                          // 每个通道bit数
                                                    cvMat.step[0],              // 每行字节数
                                                    colorSpace,                 // 颜色空间
                                                    bitmapInfo); // 位图信息(alpha通道信息，字节读取信息)
    //将图片绘制到上下文中mat对象中
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    //释放imageRef对象
    CGImageRelease(imageRef);
    //释放颜色空间
    CGColorSpaceRelease(colorSpace);
    //释放上下文环境
    CGContextRelease(contextRef);
    return cvMat;
}

+ (UIImage *)ImageFromCVMat:(cv::Mat)cvMat{
    //获取矩阵数据
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    //判断矩阵使用的颜色空间
    CGColorSpaceRef colorSpace;
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    //创建数据privder
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    //获取bitmpa位数
    size_t bitsPerPixel = cvMat.elemSize()*8;
    //获取通道数
    size_t channels = cvMat.channels();
    //获取通道位深
    size_t bitsPerComponent = bitsPerPixel/channels;
    
    //创建位图信息  根据通道位深及通道数判断使用的位图信息
    CGBitmapInfo bitmapInfo;
    if(bitsPerComponent == 8){
        if(channels == 3){
            bitmapInfo = kCGImageAlphaNone | kCGImageByteOrderDefault;
        }else if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrderDefault;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else if(bitsPerComponent == 16){
        if(channels == 3){
            bitmapInfo = kCGImageAlphaNone | kCGImageByteOrder16Little;
        }else if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrder16Little;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else{
        printf("图片格式不支持");
        abort();
    }
    
    
    
    //根据矩阵及相关信息创建CGImageRef结构体
    CGImageRef imageRef = CGImageCreate(cvMat.cols, //矩阵宽度
                                        cvMat.rows, //矩阵列数
                                        bitsPerComponent,        //通道位深
                                        8 * cvMat.elemSize(),  //每个像素位深
                                        cvMat.step[0],  //每行占用字节数
                                        colorSpace,    //使用的颜色空间
                                        bitmapInfo,//通道排序、大小端读取顺序信息
                                        provider, //数据源
                                        NULL,   //解码数组 一般传null
                                        true, //是否抗锯齿
                                        kCGRenderingIntentDefault   //使用默认的渲染方式
                                        );
    // 通过cgImage转化出来UIImage对象
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    //释放imageRef
    CGImageRelease(imageRef);
    //释放provider
    CGDataProviderRelease(provider);
    //释放颜色空间
    CGColorSpaceRelease(colorSpace);
    return finalImage;
}

#pragma mark - cvMatFromUIImage    4通道RGBA图
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

#pragma mark - cvMatGrayFromUIImage    单通道灰度图
+ (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

#pragma mark - UIImageFromCVMat
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat{
    
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return finalImage;
}


+ (UIImage *)drawellipse:(UIImage *)fingerImage {
    
    cv::Mat image = [UIImageAndMat cvMatFromUIImage:fingerImage];
    // 转换为灰度图像
    cv::Mat gray;
    cv::cvtColor(image, gray, cv::COLOR_BGR2GRAY);
    
    // 高斯模糊处理
    cv::GaussianBlur(gray, gray, cv::Size(5, 5), 0);
    
    // 中值滤波处理
    cv::medianBlur(gray, gray, 5);
    
    // 对灰度图像应用拉普拉斯算子进行锐化
//    cv::Mat sharpImage;
//    Laplacian(gray, sharpImage, CV_16S, 3);
//    convertScaleAbs(sharpImage, sharpImage);
//    
//    // Canny 边缘检测
//    cv::Mat edges;
//    cv::Canny(sharpImage, edges, 50, 150);
    
    // Canny 边缘检测
    cv::Mat edges;
    cv::Canny(gray, edges, 50, 150);
    
    
    // 查找轮廓
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(edges, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    
    double maxArea = 0;
    int maxAreaContourIndex = -1;
    for (size_t i = 0; i < contours.size(); ++i) {
        double area = cv::contourArea(contours[i]);
        if (area > maxArea) {
            maxArea = area;
            maxAreaContourIndex = static_cast<int>(i);
        }
    }
    
    cv::RotatedRect rrt = cv::fitEllipseAMS(contours[maxAreaContourIndex]);
    cv::Point2f center = rrt.center;
    float w = rrt.size.width;
    float h = rrt.size.height;
    float angle = rrt.angle;
    printf("w1 = %f, h1 = %f , angle1 = %f\n",w,h,angle);
    cv::ellipse(image,rrt, cv::Scalar(225, 0, 0), 2, 2);
    
    //1 pt = 1/72 英寸 · 1 英寸= 2.54 公分 · 1 pt = 1/72*2.54 = 0.035278 公分
    float realW = w / 72 * 2.45 * 10;
    std::stringstream stream;
    stream << std::fixed << std::setprecision(1) << realW;
    std::string text = stream.str() + "mm";
    
    cv::putText(image, text, cv::Point(w / 2, 50), cv::FONT_HERSHEY_SIMPLEX, 0.3, cv::Scalar(225, 0, 225), 1);
    
    UIImage *ellipseImage = [UIImageAndMat ImageFromCVMat:image];
    
    return ellipseImage;
    
}

@end
