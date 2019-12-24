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
        //阅读效果默认配置
        readConfig.fontSize = 16;
        readConfig.lineSpace = 10;
        readConfig.fontColor = [UIColor blackColor];
        readConfig.theme = [UIColor whiteColor];
    });
    return readConfig;
}
@end

@interface SLImageData ()
@end
@implementation SLImageData
@end

@interface SLChapterModel ()
@property (nonatomic,copy) NSString *html;  //HTML字符串
@end
@implementation SLChapterModel

- (instancetype)init
{
    self = [super init];
    if (self) {
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
    
    NSString * htmlWithoutImg = [model replaceImgTagOfHtml:html];
    NSData *data = [htmlWithoutImg dataUsingEncoding:NSUnicodeStringEncoding];
    NSDictionary* options = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType};
    NSMutableAttributedString* attrs = [[NSMutableAttributedString alloc] initWithData:data options:options documentAttributes:nil error:nil];
    model.content = attrs.string;
    return model;
}

//替换HTML中的img图片标签(SLImg=src)，防止HTML转富文本的时图片标签被清除了; 存储图片地址
- (NSString *)replaceImgTagOfHtml:(NSString *)htmlString {
    //扫描图片标签
    NSScanner * imgTagScanner = [NSScanner scannerWithString:htmlString];
    //扫描图片地址
    NSScanner * imgSrcScanner = [NSScanner scannerWithString:htmlString];
    NSMutableArray *imagesArray = [NSMutableArray array];
    while([imgSrcScanner isAtEnd] == NO) {
        NSString *imgTagStr = @"";
        //找到标签的起始位置
        if ([imgTagScanner scanUpToString:@"<img" intoString:nil]) {
            //找到标签的结束位置
            [imgTagScanner scanUpToString:@"/>" intoString:&imgTagStr];
        }
        
        //扫描出图片地址
        if ([imgSrcScanner scanUpToString:@"<img" intoString:nil]) {
            [imgSrcScanner scanUpToString:@"src" intoString:NULL];
            [imgSrcScanner scanString:@"src" intoString:NULL];
            [imgSrcScanner scanString:@"=" intoString:NULL];
            [imgSrcScanner scanString:@"\'" intoString:NULL];
            [imgSrcScanner scanString:@"\"" intoString:NULL];
            NSString *imgString;
            if ([imgSrcScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"\'"] intoString:&imgString]) {
                //替换字符
                htmlString  =  [htmlString  stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/>",imgTagStr] withString:[NSString stringWithFormat:@"SLImg=%@=SLImg",imgString]];
                SLImageData *imageData = [[SLImageData alloc] init];
                imageData.url = [self.epubImagePath stringByAppendingPathComponent:imgString];
                [imagesArray addObject:imageData];
                imgString = nil;
            }
        }
    }
    self.imageArray = imagesArray;
    return htmlString;
}

@end
