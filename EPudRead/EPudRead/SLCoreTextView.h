//
//  SLCoreTextView.h
//  EPudRead
//
//  Created by wsl on 2019/12/13.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLCoreTextView : UIView

@property (nonatomic, strong) NSMutableAttributedString *attributedString; //富文本

@property (nonatomic, strong) NSMutableDictionary *attributes;  //富文本属性

@end

NS_ASSUME_NONNULL_END
