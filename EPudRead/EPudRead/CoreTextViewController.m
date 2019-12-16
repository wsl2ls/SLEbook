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

@property (nonatomic, strong) NSMutableArray *pagesArray;
@property (nonatomic, assign) NSInteger currentPage;

@property (nonatomic, assign) CGFloat fontSize;

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
    
    [SLReadConfig shareInstance].fontSize = self.fontSize;
      [SLReadConfig shareInstance].lineSpace = 5;
      [SLReadConfig shareInstance].fontColor = [UIColor blackColor];
      [SLReadConfig shareInstance].theme = [UIColor orangeColor];
    
    SLChapterModel *chapterModel = self.chapterArray[0];
    NSString *text = chapterModel.content;
    
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:text];
    // 创建NSMutableParagraphStyle实例
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = [SLReadConfig shareInstance].lineSpace;       //行间距
//    paragraphStyle.paragraphSpacing = 10;  //段落间距
    NSDictionary *dict = @{NSParagraphStyleAttributeName:paragraphStyle, NSFontAttributeName:[UIFont systemFontOfSize:[SLReadConfig shareInstance].fontSize], NSForegroundColorAttributeName:[SLReadConfig shareInstance].fontColor};
    
    //替换图片富文本
    NSArray *imagesRangs = [self getRangesFromResult:attributeStr.string];
    NSRange currentTitleRange = NSMakeRange(0, attributeStr.length);
    for (int i = 0; i < imagesRangs.count; i++) {
        NSRange range = [imagesRangs[i] rangeValue];
        //注意：每替换一次，原有的位置发生改变，下一轮替换的起点需要重新计算！
        CGFloat newLocation = range.location - (currentTitleRange.length - attributeStr.length);
        SLImageData * imageData = chapterModel.imageArray[i];
        // 文字中加图片
        UIImage *img = [UIImage imageWithContentsOfFile:imageData.url];
        [attributeStr replaceCharactersInRange:NSMakeRange(newLocation, range.length) withAttributedString:[self.coreTextView imageAttributeString:CGSizeMake(SL_kScreenWidth, SL_kScreenWidth*img.size.height/img.size.width) withAttribute:dict]];
    }
    
    [attributeStr addAttributes:dict  range:NSMakeRange(0, attributeStr.length)];

    self.coreTextView.attributedString = attributeStr;
    self.coreTextView.imageArray = chapterModel.imageArray;
    self.coreTextView.backgroundColor = [SLReadConfig shareInstance].theme;
    self.coreTextView.frame = CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenHeight);
    [self.view addSubview:self.scrollView];
    
    [self.scrollView addSubview:self.coreTextView];
    self.scrollView.contentSize = CGSizeMake(SL_kScreenWidth, self.coreTextView.frame.size.height);
    
}

#pragma mark - Help Methods

/// 匹配图片标签<img></img>
- (NSMutableArray *)getRangesFromResult:(NSString *)string {
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

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
