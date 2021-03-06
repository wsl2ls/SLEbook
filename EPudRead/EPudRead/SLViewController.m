//
//  SLViewController.m
//  EPudRead
//
//  Created by wsl on 2019/12/11.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLViewController.h"
#import <YYText.h>


@interface SLTextView : UITextView

@end
@implementation SLTextView

/*
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
      //设置菜单
        UIMenuItem *copyMenuItem = [[UIMenuItem alloc]initWithTitle:@"复制" action:@selector(copyMenuItem:)];
        UIMenuItem *noteMenuItem = [[UIMenuItem alloc]initWithTitle:@"笔记" action:@selector(noteMenuItem:)];
        UIMenuController *menuController = [UIMenuController sharedMenuController];
         menuController.menuItems = @[copyMenuItem, noteMenuItem];
    }
    return self;
}
-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(copyMenuItem:) || action == @selector(noteMenuItem:)) {
        return YES;
    }
    return NO;
}

- (void)copyMenuItem:(id)sender{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [self.attributedText attributedSubstringFromRange:[self selectedText]].string ;
    NSLog(@"复制内容： %@",pasteboard.string);
}

- (void)noteMenuItem:(id)sender {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    [attributedString addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:[self selectedText]];
    [attributedString addAttributes:@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle), NSUnderlineColorAttributeName:[UIColor purpleColor]} range:[self selectedText]];
    self.attributedText = attributedString;
}

- (NSRange)selectedText {
    UITextPosition* beginning = self.beginningOfDocument;
    UITextRange* selectedRange = self.selectedTextRange;
    UITextPosition* selectionStart = selectedRange.start;
    UITextPosition* selectionEnd = selectedRange.end;
    NSInteger location = [self offsetFromPosition:beginning toPosition:selectionStart];
    NSInteger length = [self offsetFromPosition:selectionStart toPosition:selectionEnd];
    NSRange range = NSMakeRange(location, length);
    return range;
}
*/
@end


@interface SLViewController () <UITextViewDelegate>

@property (nonatomic, strong) SLTextView *textView;

@property (nonatomic, strong) NSMutableArray *pagesArray;
@property (nonatomic, assign) NSInteger currentPage;

@property (nonatomic, assign) CGFloat fontSize;

@end

@implementation SLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    self.fontSize = 20;
    [self update];
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor whiteColor];
    UIBarButtonItem *previousItem = [[UIBarButtonItem alloc] initWithTitle:@"上一页" style:UIBarButtonItemStyleDone target:self action:@selector(previousPage)];
    UIBarButtonItem *nextItem = [[UIBarButtonItem alloc] initWithTitle:@"下一页" style:UIBarButtonItemStyleDone target:self action:@selector(nextPage)];
    UIBarButtonItem *bigFontItem = [[UIBarButtonItem alloc] initWithTitle:@"大" style:UIBarButtonItemStyleDone target:self action:@selector(bigFont)];
    UIBarButtonItem *littleFontItem = [[UIBarButtonItem alloc] initWithTitle:@"小" style:UIBarButtonItemStyleDone target:self action:@selector(littleFont)];
    self.navigationItem.rightBarButtonItems = @[littleFontItem , bigFontItem ,nextItem, previousItem];
    [self.view addSubview:self.textView];
}

#pragma mark - Getter
- (SLTextView *)textView {
    if (!_textView) {
        _textView = [[SLTextView alloc] initWithFrame:CGRectMake(0, 80, SL_kScreenWidth, SL_kScreenHeight - 80 - 20)];
        _textView.editable = NO;
        _textView.delegate = self;
        //        _textView.selectable = NO;
        //        _textView.scrollEnabled = NO;
        _textView.textContainerInset = UIEdgeInsetsZero;
        _textView.backgroundColor = [UIColor grayColor];
    }
    return _textView;
}

#pragma mark - Event Handle
- (void)previousPage {
    if (self.currentPage - 1 >= 0) {
        self.currentPage = self.currentPage - 1;
    }else {
        self.currentPage = self.pagesArray.count - 1;
    }
    self.textView.attributedText = self.pagesArray[self.currentPage];
}
- (void)nextPage {
    if (self.currentPage + 1 < self.pagesArray.count) {
        self.currentPage = self.currentPage + 1;
    }else {
        self.currentPage = 0;
    }
    self.textView.attributedText = self.pagesArray[self.currentPage];
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
    
    SLChapterModel *model = self.chapterArray[0];
    
    NSString *text = model.content;
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:text];
    // 创建NSMutableParagraphStyle实例
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 10;       //行间距
    paragraphStyle.paragraphSpacing = 15;  //段间距
    //    paragraphStyle.firstLineHeadIndent = 20; //首行缩进
    paragraphStyle.paragraphSpacingBefore = 20; //段首行空白空
    [attributeStr addAttributes:@{NSParagraphStyleAttributeName:paragraphStyle, NSFontAttributeName:[UIFont systemFontOfSize:self.fontSize]} range:NSMakeRange(0, attributeStr.length)];
    
    //替换图片富文本
    NSArray *imagesRangs = [self getRangesFromResult:attributeStr.string];
    NSRange currentTitleRange = NSMakeRange(0, attributeStr.length);
    for (int i = 0; i < imagesRangs.count; i++) {
        NSRange range = [imagesRangs[i] rangeValue];
        //注意：每替换一次，原有的位置发生改变，下一轮替换的起点需要重新计算！
        CGFloat newLocation = range.location - (currentTitleRange.length - attributeStr.length);
        SLImageData * imageData = model.imageArray[i];
        // 文字中加图片
        NSTextAttachment *attachment=[[NSTextAttachment alloc] init];
        UIImage *img = [UIImage imageWithContentsOfFile:imageData.url];
        attachment.image = img;
        attachment.bounds=CGRectMake(0, 0, SL_kScreenWidth, SL_kScreenWidth*img.size.height/img.size.width);
        NSMutableAttributedString *attachmentStr = [[NSMutableAttributedString alloc] init];
        //        [attachmentStr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        [attachmentStr appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
        //        [attachmentStr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        //图片添加点击效果 特殊字符串编码
        [attachmentStr addAttributes:@{NSLinkAttributeName:[imageData.url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]} range:NSMakeRange(0, attachmentStr.length)];
        [attributeStr replaceCharactersInRange:NSMakeRange(newLocation, range.length) withAttributedString:attachmentStr];
    }
    
    self.pagesArray = [self coreTextPaging:attributeStr contentSize:CGRectMake(0, 0, self.textView.frame.size.width, self.textView.frame.size.height).size];
    
    if (self.currentPage > self.pagesArray.count - 1) {
        self.currentPage = self.pagesArray.count- 1 ;
    }
    self.textView.attributedText = self.pagesArray[self.currentPage];
}

#pragma mark - Help Methods

/// 匹配图片标签<img>.*?</img>
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
// 文本和图片附件 分页计算
- (NSMutableArray *)coreTextPaging:(NSMutableAttributedString *)orginAttString contentSize:(CGSize)contentSize {
    NSMutableArray *pagingArray = [NSMutableArray array];
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:orginAttString];
    NSLayoutManager* layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    while (YES) {
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:contentSize];
        [layoutManager addTextContainer:textContainer];
        NSRange rang = [layoutManager glyphRangeForTextContainer:textContainer];
        if (rang.length <= 0) {
            break;
        }
        NSAttributedString *attStr =[textStorage attributedSubstringFromRange:rang];
        [pagingArray addObject:attStr];
    }
    return pagingArray;
}

#pragma mark - UITextViewDelegate
//点击链接
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    //特殊字符串解码
    NSString *imagePath = [URL.absoluteString stringByRemovingPercentEncoding];
    NSLog(@"点击链接 %@", imagePath);
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    return NO;
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
