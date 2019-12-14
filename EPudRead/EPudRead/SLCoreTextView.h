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

@interface SLCoreTextView : UIScrollView

@property (nonatomic, strong) NSMutableAttributedString *attributedString; //富文本

@property (nonatomic, strong) NSDictionary *attributes;  //富文本属性

@property (nonatomic,assign) CTFrameRef frameRef;

@property (nonatomic, strong) NSArray <SLImageData *> * imageArray;

@end

NS_ASSUME_NONNULL_END
