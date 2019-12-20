//
//  SLPageViewController.m
//  EPudRead
//
//  Created by wsl on 2019/12/19.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLPageViewController.h"
#import "SLReadViewController.h"

@interface SLPageViewController ()<UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (nonatomic, strong) UIPageViewController * pageViewController; //分页控制器

@property (nonatomic, strong) NSArray *pagesArray; //当前章节分页后的数据
@property (nonatomic, assign) NSInteger currentPage; //当前页码
@property (nonatomic, assign) NSInteger willPage; //可能要翻到的页码 默认是与当前页码相等，主要用来解决手动翻页时即将前往的页码，也可能取消翻页

@property (nonatomic, strong) NSMutableArray * attributesRange; //所有的链接

@end

@implementation SLPageViewController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}
- (void)dealloc {
    [self.pageViewController removeFromParentViewController];
    [self.pageViewController.view removeFromSuperview];
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *previousItem = [[UIBarButtonItem alloc] initWithTitle:@"上一页" style:UIBarButtonItemStyleDone target:self action:@selector(previousPage)];
    UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithTitle:@"下一页" style:UIBarButtonItemStyleDone target:self action:@selector(nextPage)];
    UIBarButtonItem *bigFontItem = [[UIBarButtonItem alloc] initWithTitle:@"大" style:UIBarButtonItemStyleDone target:self action:@selector(bigFont)];
    UIBarButtonItem *littleFontItem = [[UIBarButtonItem alloc] initWithTitle:@"小" style:UIBarButtonItemStyleDone target:self action:@selector(littleFont)];
    self.navigationItem.rightBarButtonItems = @[littleFontItem , bigFontItem ,nextItem, previousItem];
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    
    _attributesRange= [NSMutableArray array];
    [_attributesRange addObject:@{[NSValue valueWithRange:NSMakeRange(50, 30)] : @{@"" : @"", @"value":@"链接值"}}];
    
    
    //获取分页后的数据
    self.pagesArray = [self coreTextPaging:[self textAttributedString] textBounds:self.view.bounds];
    
    //UIPageViewControllerNavigationDirectionForward,//前进
    //UIPageViewControllerNavigationDirectionReverse// 后退
    SLReadViewController *readerController = [self readViewControllerWithPage:self.currentPage];
    [self.pageViewController setViewControllers:@[readerController]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
 
    self.currentPage = 0;
    self.navigationItem.title = [NSString stringWithFormat:@"第 %ld 页",self.currentPage];
}

#pragma mark - Help methods
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
        for (SLImageData *imageData in _chapterModel.imageArray) {
            if (ra.location < imageData.position && imageData.position <= ra.location + ra.length  ) {
                [images addObject:imageData];
            }
        }
        [pagingResult addObject:@{@"Text":[attrString attributedSubstringFromRange:ra], @"images":[NSArray arrayWithArray:images]}];
        //移动当前文本位置
        textPos += ra.length;
        CFRelease(frame);
    }
    CGPathRelease(path);
    CFRelease(framesetter);
    //释放frameSetter
    return pagingResult;
}
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
//返回图片占位属性字符串.string是nil
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

#pragma mark - setter
- (void)setCurrentPage:(NSInteger)currentPage {
    _currentPage = currentPage;
    _willPage = currentPage;
}
#pragma mark - Getter
- (UIPageViewController *)pageViewController {
    if(!_pageViewController) {
        /*
         UIPageViewControllerTransitionStylePageCurl//拟真
         UIPageViewControllerTransitionStyleScroll//滚动
         UIPageViewControllerNavigationOrientationHoriz//横向
         UIPageViewControllerNavigationOrientationVertical//纵向
         */
        _pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
        _pageViewController.delegate = self;
        _pageViewController.dataSource = self;
        _pageViewController.view.backgroundColor = [UIColor whiteColor];
    }
    return _pageViewController;
}
//获取对应页码的阅读控制器
- (SLReadViewController *)readViewControllerWithPage:(NSInteger)page {
    SLReadViewController *readViewController = [[SLReadViewController alloc] init];
    readViewController.coreTextView.imageArray = self.pagesArray[page][@"images"];
    readViewController.coreTextView.attributedString = self.pagesArray[page][@"Text"];
    readViewController.coreTextView.backgroundColor = [SLReadConfig shareInstance].theme;
    return readViewController;
}
// 本章内容
- (NSMutableAttributedString *)textAttributedString {
    //章节内容
    NSString *text = _chapterModel.content;
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
        SLImageData * imageData = _chapterModel.imageArray[i];
        //该图片占位符的索引
        imageData.position = newLocation+1;
        // 文字中加入图片占位符
        UIImage *img = [UIImage imageWithContentsOfFile:imageData.url];
        CGSize imageSize = CGSizeMake(SL_kScreenWidth, SL_kScreenWidth*img.size.height/img.size.width);
        NSMutableAttributedString *placeHolder = [[NSMutableAttributedString alloc] initWithAttributedString:[self imageAttributeString:imageSize withAttribute:dict]];
        //设置默认位置，是为了解决全屏时执行calculateImagePosition计算占位图位置失效的问题
        imageData.imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
        [attributeStr replaceCharactersInRange:NSMakeRange(newLocation, range.length) withAttributedString:placeHolder];
    }
    [attributeStr addAttributes:dict  range:NSMakeRange(0, attributeStr.length)];
    
    return attributeStr;
}

#pragma mark - Events Handle
- (void)previousPage {
    if (self.currentPage - 1 >= 0) {
        self.currentPage = self.currentPage - 1;
    }else {
        return;
    }
    SLReadViewController * readViewController = [self readViewControllerWithPage:self.currentPage];
    [self.pageViewController setViewControllers:@[readViewController]
                                      direction:UIPageViewControllerNavigationDirectionReverse
                                       animated:YES
                                     completion:nil];
    self.navigationItem.title = [NSString stringWithFormat:@"第 %ld 页",self.currentPage];
}
- (void)nextPage {
    if (self.currentPage + 1 < self.pagesArray.count) {
        self.currentPage = self.currentPage + 1;
    }else {
        return;
    }
    SLReadViewController * readViewController = [self readViewControllerWithPage:self.currentPage];
    [self.pageViewController setViewControllers:@[readViewController]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:nil];
    self.navigationItem.title = [NSString stringWithFormat:@"第 %ld 页",self.currentPage];
}
- (void)bigFont {
    [SLReadConfig shareInstance].fontSize+=5;
    [self updateFontSize];
}
- (void)littleFont {
    [SLReadConfig shareInstance].fontSize-=5;
    [self updateFontSize];
}
//调整文字大小 需要更新分页数据
- (void)updateFontSize {
    if(self.currentPage > self.pagesArray.count - 1) {
        self.currentPage = self.pagesArray.count - 1;
    }
    //更新分页后的数据
    self.pagesArray = [self coreTextPaging:[self textAttributedString] textBounds:self.view.bounds];
    SLReadViewController * readViewController = [self readViewControllerWithPage:self.currentPage];
    [self.pageViewController setViewControllers:@[readViewController]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    self.navigationItem.title = [NSString stringWithFormat:@"第 %ld 页",self.currentPage];
}

#pragma mark - UIPageViewControllerDelegate,UIPageViewControllerDataSource
//后退翻页是执行
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    if (self.currentPage - 1 >= 0) {
        SLReadViewController * readViewController = [self readViewControllerWithPage:self.currentPage - 1];
        self.willPage = self.currentPage - 1;
        return readViewController;
    } else {
        return nil;
    }
}
//前进翻页时执行
- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    if (self.currentPage + 1 < self.pagesArray.count) {
        SLReadViewController * readViewController = [self readViewControllerWithPage:self.currentPage + 1];
        self.willPage = self.currentPage + 1;
        return readViewController;
    } else {
        return nil;
    }
}
//在动画执行完毕后被调用，即controller切换完成后，我们可以在这个代理中进行一些后续操作
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(nonnull NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    //动画完成 取消翻页
    if (finished && !completed) {
        self.willPage = self.currentPage;
    }
    // 翻页完成
    if (completed) {
        self.currentPage = self.willPage;
        self.navigationItem.title = [NSString stringWithFormat:@"第 %ld 页",self.currentPage];
    }
}

@end
