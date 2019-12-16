//
//  SLChapterModel.h
//  EPudRead
//
//  Created by wsl on 2019/12/10.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>

NS_ASSUME_NONNULL_BEGIN

/// 富文本配置
@interface SLReadConfig : NSObject
+(instancetype)shareInstance;
@property (nonatomic) CGFloat fontSize;  //字体大小
@property (nonatomic) CGFloat lineSpace; //行间距
@property (nonatomic,strong) UIColor *fontColor; //字体颜色
@property (nonatomic,strong) UIColor *theme;  //主题 背景色
@end


/// 图片数据
@interface SLImageData : NSObject
@property (nonatomic,strong) NSString *url; //图片链接
@property (nonatomic,assign) CGRect imageRect;  //图片位置
@property (nonatomic,assign) NSInteger position;

@end

/// 章节数据模型
@interface SLChapterModel : NSObject 

@property (nonatomic,strong) NSString *content;  //章节文本内容 和 图片标签
@property (nonatomic,strong) NSString *title;   // 章节标题
@property (nonatomic, assign) NSUInteger pageCount;  //页码

@property (nonatomic, copy) NSString *epubImagePath; // 

@property (nonatomic,copy) NSString *chapterpath; // 章节路径
@property (nonatomic,copy) NSString *html;  //HTML字符串

@property (nonatomic,copy) NSArray <SLImageData *> *imageArray;  // 图片

+(id)chapterWithEpub:(NSString *)chapterpath title:(NSString *)title imagePath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
