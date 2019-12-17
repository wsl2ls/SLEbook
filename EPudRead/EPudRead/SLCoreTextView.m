//
//  SLCoreTextView.m
//  EPudRead
//
//  Created by wsl on 2019/12/13.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLCoreTextView.h"

/// 放大镜视图
@interface SLMagnifierView : UIView
@property (nonatomic,weak) UIView *readView;
@property (nonatomic) CGPoint touchPoint;
@end
@implementation SLMagnifierView
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:CGRectMake(0, 0, 80, 80)]) {
        self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        [self setBackgroundColor:[SLReadConfig shareInstance].theme];
        self.layer.borderWidth = 1;
        self.layer.cornerRadius = 40;
        self.layer.masksToBounds = YES;
    }
    return self;
}
- (void)setTouchPoint:(CGPoint)touchPoint {
    _touchPoint = touchPoint;
    self.center = CGPointMake(touchPoint.x, touchPoint.y - 70);
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, self.frame.size.width*0.5,self.frame.size.height*0.5);
    CGContextScaleCTM(context, 1.5, 1.5);
    CGContextTranslateCTM(context, -1 * (_touchPoint.x), -1 * (_touchPoint.y));
    [self.readView.layer renderInContext:context];
}
@end


@interface SLCoreTextView ()
{
    CGRect _menuRect; //菜单选中的区域  坐标原点在左下角
    BOOL _selectState;  //是否是选中状态
    BOOL _direction; //滑动方向  (0---左侧滑动 1 ---右侧滑动)
    
    NSRange _selectRange;  //选中的内容区间
    NSRange _calRange;
    NSArray *_pathArray; //选中的路径数组
    
    UIPanGestureRecognizer *_pan;
    //滑动手势有效区间
    CGRect _leftRect;
    CGRect _rightRect;
}
@property (nonatomic,assign) CTFrameRef frameRef; //绘制的帧内容
@property (nonatomic,strong) SLMagnifierView *magnifierView; //放大镜视图
@end

@implementation SLCoreTextView

#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initConfigure];
    }
    return self;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        [self initConfigure];
    }
    return self;
}
//初始化配置
- (void)initConfigure {
    self.userInteractionEnabled = YES;
    //长按选中手势
    [self addGestureRecognizer:({
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressSelected:)];
        longPress;
    })];
    //拖拽调整选中范围手势
    [self addGestureRecognizer:({
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panChangeRange:)];
        pan.enabled = NO;
        _pan = pan;
        pan;
    })];
}
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawFrame];
}
- (void)dealloc {
    if (self.frameRef) {
        CFRelease(self.frameRef);
        _frameRef = nil;
    }
}
//是否能变成第一响应者，YES才能弹出系统的UIMenuController
- (BOOL)canBecomeFirstResponder {
    return YES;
}
#pragma mark - CoreText绘制
//绘制内容
- (void)drawFrame {
    // 使用NSMutableAttributedString创建CTFrame
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedString);
    
    //注意：一定要先释放，否则内存会一直增长
    if (self.frameRef) {
        CFRelease(self.frameRef);
        _frameRef = nil;
    }
    // 绘制区域
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));
    self.frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, self.attributedString.length), path, NULL);
    
    //由于上下文(左下角)和设备屏幕(左上角)坐标系原点的不同，所以需要翻转一下
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1, -1);
    
    //给选中的部分添加背景色
    CGRect leftDot,rightDot = CGRectZero;
    [self drawSelectedPath:_pathArray LeftDot:&leftDot RightDot:&rightDot];
    
    // 使用CTFrame在CGContextRef上下文上绘制
    CTFrameDraw(self.frameRef, context);
    
    //计算图片位置
    [self calculateImagePosition];
    for (SLImageData *imageData in self.imageArray) {
        //绘制图片
        CGContextDrawImage(context, imageData.imageRect, [UIImage imageWithContentsOfFile:imageData.url].CGImage);
    }
    
    //绘制选中左右分割图
    [self drawDotWithLeft:leftDot right:rightDot];
    
    CFRelease(framesetter);
    CFRelease(path);
}
// 给选中区域绘制背景色
-(void)drawSelectedPath:(NSArray *)array LeftDot:(CGRect *)leftDot RightDot:(CGRect *)rightDot{
    if (!array.count) {
        _pan.enabled = NO;
        //        if ([self.delegate respondsToSelector:@selector(readViewEndEdit:)]) {
        //            [self.delegate readViewEndEdit:nil];
        //        }
        [self hiddenMagnifier];
        return;
    }
    //    if ([self.delegate respondsToSelector:@selector(readViewEditeding:)]) {
    //        [self.delegate readViewEditeding:nil];
    //    }
    _pan.enabled = YES;
    CGMutablePathRef _path = CGPathCreateMutable();
    [[UIColor redColor] setFill];
    for (int i = 0; i < [array count]; i++) {
        CGRect rect = CGRectFromString([array objectAtIndex:i]);
        CGPathAddRect(_path, NULL, rect);
        if (i == 0) {
            *leftDot = rect;
            _menuRect = rect;
        }
        if (i == [array count]-1) {
            *rightDot = rect;
        }
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddPath(ctx, _path);
    CGContextFillPath(ctx);
    CGPathRelease(_path);
}
//绘制选中区间的左右分割点
-(void)drawDotWithLeft:(CGRect)Left right:(CGRect)right {
    if (CGRectEqualToRect(CGRectZero, Left) || (CGRectEqualToRect(CGRectZero, right))){
        return;
    }
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGMutablePathRef _path = CGPathCreateMutable();
    [[UIColor orangeColor] setFill];
    CGPathAddRect(_path, NULL, CGRectMake(CGRectGetMinX(Left)-2, CGRectGetMinY(Left),2, CGRectGetHeight(Left)));
    CGPathAddRect(_path, NULL, CGRectMake(CGRectGetMaxX(right), CGRectGetMinY(right),2, CGRectGetHeight(right)));
    CGContextAddPath(ctx, _path);
    CGContextFillPath(ctx);
    CGPathRelease(_path);
    CGFloat dotSize = 15;
    _leftRect = CGRectMake(CGRectGetMinX(Left)-dotSize/2-10, self.bounds.size.height-(CGRectGetMaxY(Left)-dotSize/2-10)-(dotSize+20), dotSize+20, dotSize+20);
    _rightRect = CGRectMake(CGRectGetMaxX(right)-dotSize/2-10,self.bounds.size.height- (CGRectGetMinY(right)-dotSize/2-10)-(dotSize+20), dotSize+20, dotSize+20);
    CGContextDrawImage(ctx,CGRectMake(CGRectGetMinX(Left)-dotSize/2, CGRectGetMaxY(Left)-dotSize/2, dotSize, dotSize),[UIImage imageNamed:@"r_drag-dot"].CGImage);
    CGContextDrawImage(ctx,CGRectMake(CGRectGetMaxX(right)-dotSize/2, CGRectGetMinY(right)-dotSize/2, dotSize, dotSize),[UIImage imageNamed:@"r_drag-dot"].CGImage);
}

#pragma mark - Setter
- (void)setAttributedString:(NSMutableAttributedString *)attributedString {
    _attributedString = attributedString;
    [self setNeedsDisplay];
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

#pragma mark - Events Handle
//长按选中，弹出选择框
- (void)longPressSelected:(UILongPressGestureRecognizer *)longPress {
    CGPoint point = [longPress locationInView:self];
    [self hiddenMenu];
    if (longPress.state == UIGestureRecognizerStateBegan || longPress.state == UIGestureRecognizerStateChanged) {
        //选中位置坐标，坐标原点是左下角 需要转换
        CGRect rect = [self parserRectWithPoint:point range:&_selectRange frameRef:self.frameRef];
        if(CGRectEqualToRect(rect, CGRectZero)) {
            return;
        }
        _menuRect = rect;
        [self showMagnifier];
        self.magnifierView.touchPoint = point;
        if (!CGRectEqualToRect(rect, CGRectZero)) {
            _pathArray = @[NSStringFromCGRect(rect)];
            [self setNeedsDisplay];
        }
    }
    if (longPress.state == UIGestureRecognizerStateEnded) {
        [self hiddenMagnifier];
        if (!CGRectEqualToRect(_menuRect, CGRectZero)) {
            [self showMenu];
            NSLog(@"选中：%@",[self.attributedString attributedSubstringFromRange:_selectRange].string);
        }
    }
}
//拖拽调整选中范围
- (void)panChangeRange:(UIPanGestureRecognizer *)pan {
    //在屏幕上的触摸点
    CGPoint point = [pan locationInView:self];
    [self hiddenMenu];
    if (pan.state == UIGestureRecognizerStateBegan || pan.state == UIGestureRecognizerStateChanged) {
        [self showMagnifier];
        self.magnifierView.touchPoint = point;
        if (CGRectContainsPoint(_rightRect, point)||CGRectContainsPoint(_leftRect, point)) {
            if (CGRectContainsPoint(_leftRect, point)) {
                _direction = NO;   //从左侧滑动
            }
            else{
                _direction=  YES;    //从右侧滑动
            }
            _selectState = YES;
        }
        if (_selectState) {
            NSArray *paths = [self parserRectsWithPoint:point range:&_selectRange frameRef:_frameRef direction:_direction];
            _pathArray = paths;
            [self setNeedsDisplay];
        }
    }
    if (pan.state == UIGestureRecognizerStateEnded) {
        [self hiddenMagnifier];
        _selectState = NO;
        if (!CGRectEqualToRect(_menuRect, CGRectZero)) {
            [self showMenu];
            NSLog(@"选中：%@",[self.attributedString attributedSubstringFromRange:_selectRange].string);
        }
    }
    
}
-(void)menuCopy:(id)sender {
    
}
-(void)menuNote:(id)sender {
    
}
-(void)menuShare:(id)sender {
    
}

#pragma mark - Help Methods
//展示放大镜
-(void)showMagnifier {
    if (!_magnifierView) {
        self.magnifierView = [[SLMagnifierView alloc] init];
        self.magnifierView.readView = self;
        [self addSubview:self.magnifierView];
    }
}
//隐藏放大镜
-(void)hiddenMagnifier {
    if (_magnifierView) {
        [self.magnifierView removeFromSuperview];
        self.magnifierView = nil;
    }
}
//隐藏菜单
-(void)hiddenMenu {
    //     [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    [[UIMenuController sharedMenuController] hideMenu];
}
// 弹出菜单 必须becomeFirstResponder和实现菜单action
-(void)showMenu {
    if ([self becomeFirstResponder]) {
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        UIMenuItem *menuItemCopy = [[UIMenuItem alloc] initWithTitle:@"复制" action:@selector(menuCopy:)];
        UIMenuItem *menuItemNote = [[UIMenuItem alloc] initWithTitle:@"笔记" action:@selector(menuNote:)];
        UIMenuItem *menuItemShare = [[UIMenuItem alloc] initWithTitle:@"分享" action:@selector(menuShare:)];
        NSArray *menus = @[menuItemCopy,menuItemNote,menuItemShare];
        [menuController setMenuItems:menus];
        //        [menuController setTargetRect:CGRectMake(CGRectGetMidX(_menuRect), self.bounds.size.height-CGRectGetMidY(_menuRect), CGRectGetHeight(_menuRect), CGRectGetWidth(_menuRect)) inView:self];
        //                [menuController setMenuVisible:YES animated:YES];
        [menuController showMenuFromView:self rect:CGRectMake(CGRectGetMidX(_menuRect), self.bounds.size.height-CGRectGetMidY(_menuRect), CGRectGetHeight(_menuRect), CGRectGetWidth(_menuRect))];
    }
}

#pragma mark - CoreText计算
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

//计算图片所在的位置
- (void)calculateImagePosition {
    int imageIndex = 0;
    if (imageIndex >= self.imageArray.count) {
        return;
    }
    // CTFrameGetLines获取但CTFrame内容的行数
    NSArray *lines = (NSArray *)CTFrameGetLines(self.frameRef);
    //如果self.attributedString只是图片占位字符，则lines为nil
    if (lines.count == 0 && self.attributedString != nil) {
    }
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

/// 根据长按屏幕的点坐标 获取对应位置的两个文本和区域坐标(坐标原点是左下角)
/// @param point 触碰点
/// @param selectRange 选中的区域
- (CGRect)parserRectWithPoint:(CGPoint)point range:(NSRange *)selectRange frameRef:(CTFrameRef)frameRef
{
    CFIndex index = -1;
    CGPathRef pathRef = CTFrameGetPath(frameRef);
    CGRect bounds = CGPathGetBoundingBox(pathRef);
    CGRect rect = CGRectZero;
    NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frameRef);
    if (!lines) {
        return rect;
    }
    NSInteger lineCount = [lines count];
    CGPoint *origins = malloc(lineCount * sizeof(CGPoint)); //给每行的起始点开辟内存
    if (lineCount) {
        CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 0), origins);
        for (int i = 0; i<lineCount; i++) {
            CGPoint baselineOrigin = origins[i];
            CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:i];
            CGFloat ascent,descent,linegap; //声明字体的上行高度和下行高度和行距
            CGFloat lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, &linegap);
            CGRect lineFrame = CGRectMake(baselineOrigin.x, CGRectGetHeight(bounds)-baselineOrigin.y-ascent, lineWidth, ascent+descent+linegap+[SLReadConfig shareInstance].lineSpace);    //没有转换坐标系，左下角为坐标原点 字体高度为上行高度加下行高度
            if (CGRectContainsPoint(lineFrame,point)){
                CFRange stringRange = CTLineGetStringRange(line);
                index = CTLineGetStringIndexForPosition(line, point);
                CGFloat xStart = CTLineGetOffsetForStringIndex(line, index, NULL);
                CGFloat xEnd;
                //默认选中两个单位
                if (index > stringRange.location+stringRange.length-2) {
                    xEnd = xStart;
                    xStart = CTLineGetOffsetForStringIndex(line,index-2,NULL);
                    (*selectRange).location = index-2;
                } else {
                    xEnd = CTLineGetOffsetForStringIndex(line,index+2,NULL);
                    (*selectRange).location = index;
                }
                
                (*selectRange).length = 2;
                rect = CGRectMake(origins[i].x+xStart,baselineOrigin.y-descent,fabs(xStart-xEnd), ascent+descent);
                
                break;
            }
        }
    }
    free(origins);
    return rect;
}

///  改变选中内容时，所有选中的内容路径数组
/// @param point 触摸点
/// @param selectRange 选中文本范围
/// @param frameRef 帧内容
/// @param paths 已选中的内容路径
/// @param direction 选择的方向
-(NSArray *)parserRectsWithPoint:(CGPoint)point range:(NSRange *)selectRange frameRef:(CTFrameRef)frameRef direction:(BOOL) direction {
    CFIndex index = -1;
    NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frameRef);
    NSMutableArray *newPaths = [NSMutableArray array];
    NSInteger lineCount = [lines count];
    CGPoint *origins = malloc(lineCount * sizeof(CGPoint)); //给每行的起始点开辟内存
    index = [self parserIndexWithPoint:point frameRef:frameRef];
    if (index == -1) {
        return _pathArray;
    }
    if (direction) //从右侧滑动
    {
        if (!(index>(*selectRange).location)) {
            //扩大选中内容
            (*selectRange).length = (*selectRange).location-index+(*selectRange).length;
            (*selectRange).location = index;
        }
        else{
            //减少选中内容
            (*selectRange).length = index-(*selectRange).location;
        }
    }
    else    //从左侧滑动
    {
        if (!(index>(*selectRange).location+(*selectRange).length)) {
            (*selectRange).length = (*selectRange).location-index+(*selectRange).length;
            (*selectRange).location = index;
        }
    }
    //    NSLog(@"selectRange - %@",NSStringFromRange((*selectRange)));
    if (lineCount) {
        CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 0), origins);
        for (int i = 0; i<lineCount; i++){
            CGPoint baselineOrigin = origins[i];
            CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:i];
            CGFloat ascent,descent,linegap; //声明字体的上行高度和下行高度和行距
            CTLineGetTypographicBounds(line, &ascent, &descent, &linegap);
            CFRange stringRange = CTLineGetStringRange(line);
            CGFloat xStart;
            CGFloat xEnd;
            NSRange drawRange = [self selectRange:NSMakeRange((*selectRange).location, (*selectRange).length) lineRange:NSMakeRange(stringRange.location, stringRange.length)];
            
            if (drawRange.length) {
                xStart = CTLineGetOffsetForStringIndex(line, drawRange.location, NULL);
                xEnd = CTLineGetOffsetForStringIndex(line, drawRange.location+drawRange.length, NULL);
                CGRect rect = CGRectMake(xStart, baselineOrigin.y-descent, fabs(xStart-xEnd), ascent+descent);
                if (rect.size.width ==0 || rect.size.height == 0) {
                    continue;
                }
                //每一行选中的区域
                [newPaths addObject:NSStringFromCGRect(rect)];
            }
            
        }
        
    }
    free(origins);
    return newPaths;
}
/// 返回 某坐标点的文本 在总文本中的索引
- (CFIndex)parserIndexWithPoint:(CGPoint)point frameRef:(CTFrameRef)frameRef {
    CFIndex index = -1;
    CGPathRef pathRef = CTFrameGetPath(frameRef);
    CGRect bounds = CGPathGetBoundingBox(pathRef);
    NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frameRef);
    if (!lines) {
        return index;
    }
    NSInteger lineCount = [lines count];
    CGPoint *origins = malloc(lineCount * sizeof(CGPoint)); //给每行的起始点开辟内存
    if (lineCount) {
        CTFrameGetLineOrigins(frameRef, CFRangeMake(0, 0), origins);
        for (int i = 0; i<lineCount; i++) {
            CGPoint baselineOrigin = origins[i];
            CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex:i];
            CGFloat ascent,descent,linegap; //声明字体的上行高度和下行高度和行距
            CGFloat lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, &linegap);
            CGRect lineFrame = CGRectMake(baselineOrigin.x, CGRectGetHeight(bounds)-baselineOrigin.y-ascent, lineWidth, ascent+descent+linegap+[SLReadConfig shareInstance].lineSpace);    //没有转换坐标系左下角为坐标原点 字体高度为上行高度加下行高度
            if (CGRectContainsPoint(lineFrame,point)){
                index = CTLineGetStringIndexForPosition(line, point);
                break;
            }
        }
    }
    free(origins);
    return index;
    
}
/// 返回每一行选中的区域范围
- (NSRange)selectRange:(NSRange)selectRange lineRange:(NSRange)lineRange {
    NSRange range = NSMakeRange(NSNotFound, 0);
    if (lineRange.location>selectRange.location) {
        NSRange tmp = lineRange;
        lineRange = selectRange;
        selectRange = tmp;
    }
    if (selectRange.location<lineRange.location+lineRange.length) {
        range.location = selectRange.location;
        NSUInteger end = MIN(selectRange.location+selectRange.length, lineRange.location+lineRange.length);
        range.length = end-range.location;
    }
    return range;
}

@end
