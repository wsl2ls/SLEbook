//
//  CoreTextViewController.m
//  EPudRead
//
//  Created by wsl on 2019/12/13.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "CoreTextViewController.h"
#import "SLCoreTextView.h"

@interface CoreTextViewController ()

@property (nonatomic, strong) SLCoreTextView *coreTextView;


@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) NSArray *pagesArray;
@property (nonatomic, assign) NSInteger currentPage; //当前章节的页码

@property (nonatomic, assign) CGFloat fontSize;

@property (nonatomic, strong) SLChapterModel *currentChapter; //当前章节

@end

@implementation CoreTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fontSize = 20;
    [self setupUI];
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *previousItem = [[UIBarButtonItem alloc] initWithTitle:@"上一页" style:UIBarButtonItemStyleDone target:self action:@selector(previousPage)];
    UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithTitle:@"下一页" style:UIBarButtonItemStyleDone target:self action:@selector(nextPage)];
    UIBarButtonItem *bigFontItem = [[UIBarButtonItem alloc] initWithTitle:@"大" style:UIBarButtonItemStyleDone target:self action:@selector(bigFont)];
    UIBarButtonItem *littleFontItem = [[UIBarButtonItem alloc] initWithTitle:@"小" style:UIBarButtonItemStyleDone target:self action:@selector(littleFont)];
    self.navigationItem.rightBarButtonItems = @[littleFontItem , bigFontItem ,nextItem, previousItem];
    
    SLChapterModel *chapterModel = self.chapterArray[0];
    _currentChapter = chapterModel;
    
    self.coreTextView.frame = CGRectMake(0, 80, SL_kScreenWidth, SL_kScreenHeight-80);
    [self.view addSubview:self.coreTextView];
    [self update];
    
    //    [self.scrollView addSubview:self.coreTextView];
    //    self.scrollView.contentSize = CGSizeMake(SL_kScreenWidth, self.coreTextView.frame.size.height);
    
}

#pragma mark - Help Methods
/// 匹配图片标签<img></img> 获取所有
- (NSMutableArray *)getImagesRangesFromResult:(NSString *)string {
    NSMutableArray *ranges = [[NSMutableArray alloc] init];
    NSError *error;
    NSString *rangeRegex = @"<img>.*?</img>";
    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:rangeRegex options:0 error:&error];
    if (!error) {
        NSArray * results = [regular matchesInString:string options:0 range:NSMakeRange(0, [string length])];
        for (NSTextCheckingResult *match in results) {
            NSString *result = [string substringWithRange:match.range];
            NSLog(@"%@",result);
            [ranges addObject: [NSValue valueWithRange:match.range]];
        }
    }else{
        NSLog(@"error -- %@",error);
    }
    return ranges;
}
//分页计算 存储每一页的文本和图片
- (NSArray *)coreTextPaging:(NSAttributedString *)attrString textBounds:(CGRect)textBounds{
    NSMutableArray *pagingResult = [NSMutableArray array];
    CFAttributedStringRef cfAttStr = (__bridge CFAttributedStringRef)attrString;
    //直接桥接，引用计数不变
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(cfAttStr);
    CGPathRef path = CGPathCreateWithRect(textBounds, NULL);
    int textPos = 0;
    NSUInteger strLength = [attrString length];
    while (textPos < strLength) {
        //设置路径
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, NULL);
        //生成frame
        CFRange frameRange = CTFrameGetVisibleStringRange(frame);
        NSRange ra = NSMakeRange(frameRange.location, frameRange.length);
        //如果图片占位大小铺满了整个视图，则获取的可见字符串长度为0，就会造成死循环
        if(ra.length == 0) {
            ra.length +=1;
        }
        NSMutableArray *images = [NSMutableArray array];
        for (SLImageData *imageData in _currentChapter.imageArray) {
            if (ra.location < imageData.position && imageData.position <= ra.location + ra.length  ) {
                [images addObject:imageData];
            }
        }
        [pagingResult addObject:@{@"Text":[attrString attributedSubstringFromRange:ra], @"images":[NSArray arrayWithArray:images]}];
        textPos += ra.length;
        //移动当前文本位置
        CFRelease(frame);
    }
    CGPathRelease(path);
    CFRelease(framesetter);
    //释放frameSetter
    return pagingResult;
}

#pragma mark - Getter
- (SLCoreTextView *)coreTextView {
    if (_coreTextView == nil) {
        _coreTextView = [[SLCoreTextView alloc] initWithFrame:CGRectZero];
    }
    return _coreTextView;
}
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight)];
        _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    return _scrollView;
}

#pragma mark - Event Handle
- (void)previousPage {
    if (self.currentPage - 1 >= 0) {
        self.currentPage = self.currentPage - 1;
    }else {
        self.currentPage = self.pagesArray.count - 1;
    }
    self.coreTextView.imageArray = self.pagesArray[self.currentPage][@"images"];
    self.coreTextView.attributedString = self.pagesArray[self.currentPage][@"Text"];
    self.navigationItem.title = [NSString stringWithFormat:@"第 %ld 页",self.currentPage];
}
- (void)nextPage {
    if (self.currentPage + 1 < self.pagesArray.count) {
        self.currentPage = self.currentPage + 1;
    }else {
        self.currentPage = 0;
    }
    self.coreTextView.imageArray = self.pagesArray[self.currentPage][@"images"];
    self.coreTextView.attributedString = self.pagesArray[self.currentPage][@"Text"];
    self.navigationItem.title = [NSString stringWithFormat:@"第 %ld 页",self.currentPage];
}
- (void)bigFont {
    self.fontSize+=5;
    [self update];
}
- (void)littleFont {
    self.fontSize-=5;
    [self update];
}
- (void)update {
    
    //阅读效果配置
    [SLReadConfig shareInstance].fontSize = self.fontSize;
    [SLReadConfig shareInstance].lineSpace = 10;
    [SLReadConfig shareInstance].fontColor = [UIColor purpleColor];
    [SLReadConfig shareInstance].theme = [UIColor orangeColor];
    
    //章节内容
    NSString *text = _currentChapter.content;
    
    //富文本
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:text];
    
    // 创建NSMutableParagraphStyle实例
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = [SLReadConfig shareInstance].lineSpace;       //行间距
    //    paragraphStyle.paragraphSpacing = 10;  //段落间距
    NSDictionary *dict = @{NSParagraphStyleAttributeName:paragraphStyle, NSFontAttributeName:[UIFont systemFontOfSize:[SLReadConfig shareInstance].fontSize], NSForegroundColorAttributeName:[SLReadConfig shareInstance].fontColor};
    
    //图片标签替换为图片占位符
    NSArray *imagesRangs = [self getImagesRangesFromResult:attributeStr.string];
    NSRange currentTitleRange = NSMakeRange(0, attributeStr.length);
    for (int i = 0; i < imagesRangs.count; i++) {
        NSRange range = [imagesRangs[i] rangeValue];
        //注意：每替换一次，原有的位置发生改变，下一轮替换的起点需要重新计算！
        CGFloat newLocation = range.location - (currentTitleRange.length - attributeStr.length);
        SLImageData * imageData = _currentChapter.imageArray[i];
        //该图片占位符的索引
        imageData.position = newLocation+1;
        // 文字中加入图片占位符
        UIImage *img = [UIImage imageWithContentsOfFile:imageData.url];
        CGSize imageSize = CGSizeMake(SL_kScreenWidth, SL_kScreenWidth*img.size.height/img.size.width);
        NSMutableAttributedString *placeHolder = [[NSMutableAttributedString alloc] initWithAttributedString:[self.coreTextView imageAttributeString:imageSize withAttribute:dict]];
        //设置默认位置，是为了解决全屏时执行calculateImagePosition计算占位图位置失效的问题
        imageData.imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
        [attributeStr replaceCharactersInRange:NSMakeRange(newLocation, range.length) withAttributedString:placeHolder];
    }
    [attributeStr addAttributes:dict  range:NSMakeRange(0, attributeStr.length)];
    
    self.coreTextView.backgroundColor = [SLReadConfig shareInstance].theme;
    
    //获取分页后的数据
    self.pagesArray = [self coreTextPaging:attributeStr textBounds:self.coreTextView.bounds];
    if(self.currentPage > self.pagesArray.count - 1) {
        self.currentPage = self.pagesArray.count - 1;
    }
    self.coreTextView.imageArray = self.pagesArray[self.currentPage][@"images"];
    self.coreTextView.linkRanges;
    self.coreTextView.attributedString = self.pagesArray[self.currentPage][@"Text"];
    
    self.navigationItem.title = [NSString stringWithFormat:@"第 %ld 页",self.currentPage];
}

@end
