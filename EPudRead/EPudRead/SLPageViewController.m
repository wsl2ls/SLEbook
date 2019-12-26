//
//  SLPageViewController.m
//  EPudRead
//
//  Created by wsl on 2019/12/19.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLPageViewController.h"
#import "SLReadViewController.h"
#import "SLTextRunDelegate.h"

@interface SLPageViewController ()<UIPageViewControllerDelegate, UIPageViewControllerDataSource>

@property (nonatomic, strong) UIPageViewController * pageViewController; //分页控制器

@property (nonatomic, strong) NSArray *pagesArray; //当前章节分页后的数据
@property (nonatomic, assign) NSInteger currentPage; //当前页码
@property (nonatomic, assign) NSInteger willPage; //可能要翻到的页码 默认是与当前页码相等，主要用来解决手动翻页时即将前往的页码，也可能取消翻页

@property (nonatomic, strong) NSMutableArray * attributesRange; //自定义属性

@property (nonatomic, strong) NSMutableAttributedString *textAttribute; //当前富文本

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
    self.view.backgroundColor = [UIColor grayColor];
    UIBarButtonItem *previousItem = [[UIBarButtonItem alloc] initWithTitle:@"上一页" style:UIBarButtonItemStyleDone target:self action:@selector(previousPage)];
    UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithTitle:@"下一页" style:UIBarButtonItemStyleDone target:self action:@selector(nextPage)];
    UIBarButtonItem *bigFontItem = [[UIBarButtonItem alloc] initWithTitle:@"大" style:UIBarButtonItemStyleDone target:self action:@selector(bigFont)];
    UIBarButtonItem *littleFontItem = [[UIBarButtonItem alloc] initWithTitle:@"小" style:UIBarButtonItemStyleDone target:self action:@selector(littleFont)];
    self.navigationItem.rightBarButtonItems = @[littleFontItem , bigFontItem ,nextItem, previousItem];
    
    [SLReadConfig shareInstance].theme = [UIColor orangeColor];
    
    [self addChildViewController:self.pageViewController];
    self.pageViewController.view.frame = CGRectMake(0, 64, SL_kScreenWidth, SL_kScreenHeight - 64);
    [self.view addSubview:self.pageViewController.view];
    
    //富文本属性
    _attributesRange= [NSMutableArray array];
    //    [_attributesRange addObject:@{[NSValue valueWithRange:NSMakeRange(50, 30)] : @{@"Link" : @"链接值1", @"FontColor":[UIColor blueColor], @"Underline":@"样式1"}}];
    [_attributesRange addObject:@{[NSValue valueWithRange:NSMakeRange(100, 400)] : @{@"Link" : @"链接值2", @"FontColor":[UIColor blueColor], @"Underline":@"样式1"}}];
    
    //获取分页后的数据
    self.pagesArray = [self coreTextPaging:[self textAttributedString] textBounds:self.pageViewController.view.bounds];
    
    self.currentPage = 0;
    //UIPageViewControllerNavigationDirectionForward,//前进
    //UIPageViewControllerNavigationDirectionReverse// 后退
    SLReadViewController *readViewController = [self readViewControllerWithPage:self.currentPage];
    [self.pageViewController setViewControllers:@[readViewController]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:NO
                                     completion:nil];
    
    self.navigationItem.title = [NSString stringWithFormat:@"第 %ld 页",self.currentPage];
}

#pragma mark - Help methods
//分页计算 存储每一页的文本和图片
- (NSArray *)coreTextPaging:(NSAttributedString *)attrString textBounds:(CGRect)textBounds{
    if (attrString == nil) {
        return nil;
    }
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
        NSRange pageRange = NSMakeRange(frameRange.location, frameRange.length);
        //如果图片占位大小铺满了整个视图，则获取的可见字符串长度为0，就会造成死循环
        if(pageRange.length == 0) {
            pageRange.length +=1;
        }
        //图片分页
        NSMutableArray *images = [NSMutableArray array];
        for (SLImageData *imageData in _chapterModel.imageArray) {
            if (pageRange.location < imageData.position && imageData.position <= pageRange.location + pageRange.length  ) {
                [images addObject:imageData];
            }
        }
        //富文本属性分页
        NSMutableArray *attributes = [NSMutableArray array];
        for (NSDictionary *attributeDict in self.attributesRange) {
            NSRange range = [attributeDict.allKeys.firstObject rangeValue];
            //不在当前页范围
            if(range.location > pageRange.location+pageRange.length || range.location + range.length < pageRange.location) continue;
            NSRange newRange = NSMakeRange(0, 0);
            if (range.location < pageRange.location) {
                //起点在上一页
                newRange.location = 0;
                if (range.location+range.length <= pageRange.location + pageRange.length) {
                    //终点在当前页
                    newRange.length = range.location+range.length - pageRange.location;
                }else {
                    //终点在下一页
                    newRange.length = pageRange.length;
                }
            }else {
                //起点在当前页
                newRange.location = range.location;
                if (range.location+range.length <= pageRange.location + pageRange.length) {
                    //终点在当前页
                    newRange.length = range.length;
                }else {
                    //终点在下一页
                    newRange.length = pageRange.location+pageRange.length - range.location;
                }
            }
            [attributes addObject:@{[NSValue valueWithRange:newRange]:attributeDict.allValues.firstObject}];
        }
        
        [pagingResult addObject:@{@"Range":[NSValue valueWithRange:pageRange], @"Images":[NSArray arrayWithArray:images], @"Attributes":[NSArray arrayWithArray:attributes]}];
        //移动当前文本位置
        textPos += pageRange.length;
        CFRelease(frame);
    }
    CGPathRelease(path);
    CFRelease(framesetter);
    //释放frameSetter
    return pagingResult;
}

//返回图片占位属性字符串.string是nil
- (NSAttributedString *)imageAttributeString:(CGSize)contenSize withAttribute:(NSDictionary *)attribute {
    
    //CTRunDelegateRef的包装 占位空间信息
    SLTextRunDelegate *delegate = [SLTextRunDelegate new];
    delegate.ascent = contenSize.height;
    delegate.descent = 0;
    delegate.width = contenSize.width;
    CTRunDelegateRef ctRunDelegate = delegate.CTRunDelegate;
    
    // 设置占位使用的图片属性字符串
    // 参考：https://en.wikipedia.org/wiki/Specials_(Unicode_block)  U+FFFC  OBJECT REPLACEMENT CHARACTER, placeholder in the text for another unspecified object, for example in a compound document.
    unichar objectReplacementChar = 0xFFFC;
    NSMutableAttributedString *imagePlaceHolderAttributeString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithCharacters:&objectReplacementChar length:1] attributes:attribute];
    
    // 设置RunDelegate代理
    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)imagePlaceHolderAttributeString, CFRangeMake(0, 1), kCTRunDelegateAttributeName, ctRunDelegate);
    if (ctRunDelegate) {
        /// add to attributed string
        CFRelease(ctRunDelegate);
    }
    return imagePlaceHolderAttributeString;
}
/// 匹配图片标签(SLImg=*) 获取所有
- (NSMutableArray *)getImagesRangesFromResult:(NSString *)string {
    NSMutableArray *ranges = [[NSMutableArray alloc] init];
    NSError *error;
    NSString *rangeRegex = @"SLImg=.*?=SLImg";
    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:rangeRegex options:0 error:&error];
    if (!error) {
        NSArray * results = [regular matchesInString:string options:0 range:NSMakeRange(0, [string length])];
        for (NSTextCheckingResult *match in results) {
            //            NSString *result = [string substringWithRange:match.range];
            //            NSLog(@"%@",result);
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
    readViewController.view.frame = self.pageViewController.view.bounds;
    readViewController.coreTextView.frame = self.pageViewController.view.bounds;
    readViewController.coreTextView.imageArray = self.pagesArray[page][@"Images"];
    readViewController.coreTextView.attributedString = [[NSMutableAttributedString alloc] initWithAttributedString: [_textAttribute attributedSubstringFromRange:[self.pagesArray[page][@"Range"] rangeValue]]];
    readViewController.coreTextView.attributesRange = self.pagesArray[page][@"Attributes"];
    readViewController.coreTextView.backgroundColor = [SLReadConfig shareInstance].theme;
    return readViewController;
}
// 本章内容
- (NSMutableAttributedString *)textAttributedString {
    //章节内容
    NSString *text = _chapterModel.content;
    if(text == nil) {
        return nil;
    }
    //富文本
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:text];
    
    // 创建NSMutableParagraphStyle实例
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = [SLReadConfig shareInstance].lineSpace;       //行间距
    //    paragraphStyle.paragraphSpacing = 10;  //段落间距
    //    paragraphStyle.firstLineHeadIndent = 20;
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
    _textAttribute = attributeStr;
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
    
    //记录当前所在页的范围，便于重新分页之后定位到对应内容页
    NSRange currentRange = [self.pagesArray[self.currentPage][@"Range"] rangeValue];
    //更新分页后的数据
    self.pagesArray = [self coreTextPaging:[self textAttributedString] textBounds:self.pageViewController.view.bounds];
    //定位到当前浏览内容所在页
    for (int i = 0; i < self.pagesArray.count; i++) {
        NSRange range = [self.pagesArray[i][@"Range"] rangeValue];
        if (currentRange.location >= range.location && currentRange.location < range.location + range.length) {
            self.currentPage = i;
            break;
        }
    }
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
