//
//  SLCoreTextView.h
//  EPudRead
//
//  Created by wsl on 2019/12/13.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLChapterModel.h"



NS_ASSUME_NONNULL_BEGIN

@class SLCoreTextView;
@protocol SLCoreTextViewDelegate <NSObject>
///点击图片
- (void)coreTextView:(SLCoreTextView *)textView didClickImage:(NSString *)url;
///点击链接
- (void)coreTextView:(SLCoreTextView *)textView didClickLink:(NSString *)url textRange:(NSRange)range;
@end

@interface SLCoreTextView : UIView

@property (nonatomic, strong) NSMutableAttributedString *attributedString; //富文本

@property (nonatomic, strong) NSArray <SLImageData *> * imageArray;

@property (nonatomic, strong) NSMutableArray *attributesRange; //自定义属性

@property (nonatomic, assign, readonly) CGFloat textHeight; //富文本的高度

@property (nonatomic, weak) id <SLCoreTextViewDelegate> delegate; //代理

@end

NS_ASSUME_NONNULL_END
