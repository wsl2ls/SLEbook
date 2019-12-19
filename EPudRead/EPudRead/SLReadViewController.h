//
//  SLReadViewController.h
//  EPudRead
//
//  Created by wsl on 2019/12/19.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLCoreTextView.h"

NS_ASSUME_NONNULL_BEGIN
///  阅读
@interface SLReadViewController : UIViewController

@property (nonatomic, strong) SLCoreTextView *coreTextView;

@end

NS_ASSUME_NONNULL_END
