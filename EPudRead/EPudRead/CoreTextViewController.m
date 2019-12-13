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
    
    // 绘制的内容属性字符串
    NSString *text = @"  【APP】【学员、师资】扫一扫\n       【后台】互动管理、创建课程、创建小节、关联班级、统计数据【前台网页】seewo展示：互动管理、创建课程、创建章和小节、关联班级、统计数据【APP】【学员】参与互动课程和小节：互动课程列表、小节列表（章节）；互动详情页；（参与、结果）【H5】未下载app学  \n  还是哈哈哈";
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:text];
    // 创建NSMutableParagraphStyle实例
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 5;       //行间距
    paragraphStyle.paragraphSpacing = 10;  //段落间距
//    paragraphStyle.firstLineHeadIndent = 20; //首行缩进
//    paragraphStyle.paragraphSpacingBefore = 50; //前段间距
    [attributeStr addAttributes:@{NSParagraphStyleAttributeName:paragraphStyle, NSFontAttributeName:[UIFont systemFontOfSize:self.fontSize]} range:NSMakeRange(0, attributeStr.length)];
    
    self.coreTextView.attributedString = attributeStr;
    [self.view addSubview:self.coreTextView];
    
}


- (SLCoreTextView *)coreTextView {
    if (_coreTextView == nil) {
        _coreTextView = [[SLCoreTextView alloc] initWithFrame:CGRectMake(0, 80, SL_kScreenWidth, SL_kScreenHeight - 80 - 20)];
        _coreTextView.backgroundColor = [UIColor whiteColor];
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
