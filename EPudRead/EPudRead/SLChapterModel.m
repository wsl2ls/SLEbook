//
//  SLChapterModel.m
//  EPudRead
//
//  Created by wsl on 2019/12/10.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLChapterModel.h"
#import "LSYReadConfig.h"
#import "LSYReadParser.h"
#import "NSString+HTML.h"

@interface SLReadConfig()
@end
@implementation SLReadConfig
+(instancetype)shareInstance {
    static SLReadConfig *readConfig = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        readConfig = [[self alloc] init];
    });
    return readConfig;
}
@end

@interface SLImageData ()
@end
@implementation SLImageData
@end

@interface SLChapterModel ()
@property (nonatomic,strong) NSMutableArray *pageArray;
@end
@implementation SLChapterModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _pageArray = [NSMutableArray array];
    }
    return self;
}

+(id)chapterWithEpub:(NSString *)chapterpath title:(NSString *)title imagePath:(NSString *)path
{
    SLChapterModel *model = [[SLChapterModel alloc] init];
    
    model.title = title;
    model.epubImagePath = path;
    model.chapterpath = chapterpath;
    NSString * fullPath = chapterpath;
    NSString* html = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:fullPath]] encoding:NSUTF8StringEncoding];
    model.html = html;
    //去掉html标签，保留图片信息
    model.content = [html stringByConvertingHTMLToPlainText];
    [model parserEpubToDictionary];
    return model;
}

-(void)parserEpubToDictionary
{
    NSMutableArray *array = [NSMutableArray array];
    NSMutableArray *imageArray = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:self.content];
    NSMutableString *newString = [[NSMutableString alloc] init];
    while (![scanner isAtEnd]) {
        if ([scanner scanString:@"<img>" intoString:NULL]) {
            NSString *img;
            [scanner scanUpToString:@"</img>" intoString:&img];
            NSString *imageString = [self.epubImagePath stringByAppendingPathComponent:img];
            UIImage *image = [UIImage imageWithContentsOfFile:imageString];
            
            CGFloat width = SL_kScreenWidth - LeftSpacing - RightSpacing;
            CGFloat height = SL_kScreenHeight - TopSpacing - BottomSpacing;
            CGFloat scale = image.size.width / width;
            CGFloat realHeight = image.size.height / scale;
            CGSize size = CGSizeMake(width, realHeight);
            
            if (size.height > (height - 20)) {
                size.height = height - 20;
            }
            [array addObject:@{@"type":@"img",@"content":imageString?imageString:@"",@"width":@(size.width),@"height":@(size.height)}];
            //存储图片信息
            SLImageData *imageData = [[SLImageData alloc] init];
            imageData.url = imageString?imageString:@"";
            if (imageArray.count) {
                imageData.position = newString.length + imageArray.count;
            } else {
                imageData.position = newString.length;
            }
            //            imageData.imageRect = CGRectMake(0, 0, size.width, size.height);
            [imageArray addObject:imageData];
            
            //            [newString appendString:@" "];
            [scanner scanString:@"</img>" intoString:NULL];
        } else {
            NSString *content;
            if ([scanner scanUpToString:@"<img>" intoString:&content]) {
                [array addObject:@{@"type":@"txt",@"content":content?content:@""}];
                [newString appendString:content?content:@""];
            }
        }
    }
    self.imageArray = [imageArray copy];
}

@end
