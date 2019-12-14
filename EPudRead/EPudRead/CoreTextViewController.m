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
    
    
    SLChapterModel *chapterModel = self.chapterArray[0];
    
    // 绘制的内容属性字符串
    NSString *text = chapterModel.content;
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:text];
    // 创建NSMutableParagraphStyle实例
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 5;       //行间距
    paragraphStyle.paragraphSpacing = 10;  //段落间距
//    paragraphStyle.firstLineHeadIndent = 20; //首行缩进
//    paragraphStyle.paragraphSpacingBefore = 50; //前段间距
    
    self.coreTextView.attributes = @{NSParagraphStyleAttributeName:paragraphStyle, NSFontAttributeName:[UIFont systemFontOfSize:self.fontSize]};
    [attributeStr addAttributes: self.coreTextView.attributes range:NSMakeRange(0, attributeStr.length)];

    self.coreTextView.attributedString = attributeStr;
    self.coreTextView.imageArray = chapterModel.imageArray;
    [self.view addSubview:self.coreTextView];
    self.coreTextView.contentSize = CGSizeMake(SL_kScreenWidth, SL_kScreenWidth *10);
    
}


- (SLCoreTextView *)coreTextView {
    if (_coreTextView == nil) {
        _coreTextView = [[SLCoreTextView alloc] initWithFrame:CGRectMake(0, 80, SL_kScreenWidth, SL_kScreenHeight - 80 - 20)];
        _coreTextView.backgroundColor = [UIColor grayColor];
    }
    return _coreTextView;
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
