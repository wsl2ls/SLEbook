//
//  SLCoreTextView.m
//  EPudRead
//
//  Created by wsl on 2019/12/13.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLCoreTextView.h"

@interface SLCoreTextView ()

@end

@implementation SLCoreTextView

#pragma mark - Override

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawFrame];
}
- (void)drawFrame{
    // 使用NSMutableAttributedString创建CTFrame
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedString);
    
    // 绘制区域
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
    self.frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, self.attributedString.length), path, NULL);
    
    //由于上下文(左下角)和设备屏幕(左上角)坐标系原点的不同，所以需要翻转一下
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1, -1);
    
    // 使用CTFrame在CGContextRef上下文上绘制
    CTFrameDraw(self.frameRef, context);
    
    //计算图片位置
    [self calculateImagePosition];
    for (SLImageData *imageData in self.imageArray) {
        //绘制图片
        CGContextDrawImage(context, imageData.imageRect, [UIImage imageWithContentsOfFile:imageData.url].CGImage);
    }
    CFRelease(framesetter);
    CFRelease(path);
}

#pragma mark - Getter
- (CGFloat)textHeight {
    // 使用NSMutableAttributedString创建CTFrame
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedString);
    //计算富文本的实际高
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, self.attributedString.length), NULL, CGSizeMake(self.bounds.size.width, MAXFLOAT), NULL);
    _textHeight = suggestedSize.height;
    CFRelease(framesetter);
    return _textHeight;
}

#pragma mark - Help Methods
// CTRunDelegateCallbacks 回调方法
static CGFloat getAscent(void *ref) {
    float height = [(NSNumber *)[(__bridge NSDictionary *)ref objectForKey:@"height"] floatValue];
    return height;
}
static CGFloat getDescent(void *ref) {
    return 0;
}
static CGFloat getWidth(void *ref) {
    float width = [(NSNumber *)[(__bridge NSDictionary *)ref objectForKey:@"width"] floatValue];
    return width;
}
//返回图片占位属性字符串
- (NSAttributedString *)imageAttributeString:(CGSize)contenSize withAttribute:(NSDictionary *)attribute {
    // 1 创建CTRunDelegateCallbacks
    CTRunDelegateCallbacks callback;
    memset(&callback, 0, sizeof(CTRunDelegateCallbacks));
    callback.getAscent = getAscent;
    callback.getDescent = getDescent;
    callback.getWidth = getWidth;
    
    // 2 创建CTRunDelegateRef
    NSDictionary *metaData = @{@"width": @(contenSize.width), @"height": @(contenSize.height)};
    CTRunDelegateRef runDelegate = CTRunDelegateCreate(&callback, (__bridge_retained void *)(metaData));
    
    // 3 设置占位使用的图片属性字符串
    // 参考：https://en.wikipedia.org/wiki/Specials_(Unicode_block)  U+FFFC  OBJECT REPLACEMENT CHARACTER, placeholder in the text for another unspecified object, for example in a compound document.
    unichar objectReplacementChar = 0xFFFC;
    NSMutableAttributedString *imagePlaceHolderAttributeString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithCharacters:&objectReplacementChar length:1] attributes:attribute];
    
    // 4 设置RunDelegate代理
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)imagePlaceHolderAttributeString, CFRangeMake(0, 1), kCTRunDelegateAttributeName, runDelegate);
    CFRelease(runDelegate);
    return imagePlaceHolderAttributeString;
}

//计算图片所在的位置的代码：
- (void)calculateImagePosition {
    
    int imageIndex = 0;
    if (imageIndex >= self.imageArray.count) {
        return;
    }
    
    // CTFrameGetLines获取但CTFrame内容的行数
    NSArray *lines = (NSArray *)CTFrameGetLines(self.frameRef);
    // CTFrameGetLineOrigins获取每一行的起始点，保存在lineOrigins数组中
    CGPoint lineOrigins[lines.count];
    CTFrameGetLineOrigins(self.frameRef, CFRangeMake(0, 0), lineOrigins);
    for (int i = 0; i < lines.count; i++) {
        CTLineRef line = (__bridge CTLineRef)lines[i];
        
        NSArray *runs = (NSArray *)CTLineGetGlyphRuns(line);
        for (int j = 0; j < runs.count; j++) {
            CTRunRef run = (__bridge CTRunRef)(runs[j]);
            NSDictionary *attributes = (NSDictionary *)CTRunGetAttributes(run);
            if (!attributes) {
                continue;
            }
            // 从属性中获取到创建属性字符串使用CFAttributedStringSetAttribute设置的delegate值
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[attributes valueForKey:(id)kCTRunDelegateAttributeName];
            if (!delegate) {
                continue;
            }
            // CTRunDelegateGetRefCon方法从delegate中获取使用CTRunDelegateCreate初始时候设置的元数据
            NSDictionary *metaData = (NSDictionary *)CTRunDelegateGetRefCon(delegate);
            if (!metaData) {
                continue;
            }
            
            // 找到代理则开始计算图片位置信息
            CGFloat ascent;
            CGFloat desent;
            // 可以直接从metaData获取到图片的宽度和高度信息
            CGFloat width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &desent, NULL);
            
            // CTLineGetOffsetForStringIndex获取CTRun的起始位置
            CGFloat xOffset = lineOrigins[i].x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
            CGFloat yOffset = lineOrigins[i].y;
            
            // 更新ImageItem对象的位置
            SLImageData *imageData = self.imageArray[imageIndex];
            imageData.imageRect = CGRectMake(xOffset, yOffset, width, ascent + desent);
            
            imageIndex ++;
            if (imageIndex >= self.imageArray.count) {
                return;
            }
        }
    }
}

@end
