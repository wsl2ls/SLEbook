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

@interface SLCoreTextView : UIView

@property (nonatomic, strong) NSMutableAttributedString *attributedString; //富文本

@property (nonatomic,assign) CTFrameRef frameRef;

@property (nonatomic, strong) NSArray <SLImageData *> * imageArray;

@property (nonatomic, assign) CGFloat textHeight; //富文本的高

//返回图片属性字符串
- (NSAttributedString *)imageAttributeString:(CGSize)contenSize withAttribute:(NSDictionary *)attribute;

@end

NS_ASSUME_NONNULL_END
