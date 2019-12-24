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
@property (nonatomic) CGFloat lineSpace; //行间距 默认10
@property (nonatomic) CGFloat fontSize;  //字体大小 默认16
@property (nonatomic,strong) UIColor *fontColor; //字体颜色 默认 黑 
@property (nonatomic,strong) UIColor *theme;  //主题 背景色  默认 白
@end


/// 图片数据
@interface SLImageData : NSObject
@property (nonatomic,strong) NSString *url; //图片链接
@property (nonatomic,assign) CGRect imageRect;  //图片位置
@property (nonatomic,assign) NSInteger position;  //该图片占位字符的索引

@end

/// 章节数据模型
@interface SLChapterModel : NSObject 

@property (nonatomic,strong) NSString *content;  //章节文本内容 和 图片信息
@property (nonatomic,strong) NSString *title;   // 章节标题
@property (nonatomic, assign) NSUInteger pageCount;  //页数

@property (nonatomic, copy) NSString *epubImagePath; //图片所在的相对路径
@property (nonatomic,copy) NSString *chapterpath; // 章节路径

@property (nonatomic,copy) NSArray <SLImageData *> *imageArray;  // 该章节包含的图片

+(id)chapterWithEpub:(NSString *)chapterpath title:(NSString *)title imagePath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
