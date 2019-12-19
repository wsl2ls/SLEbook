//
//  SLPageViewController.h
//  EPudRead
//
//  Created by wsl on 2019/12/19.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLChapterModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLPageViewController : UIViewController
/// 当前章节
@property (nonatomic, strong) SLChapterModel *chapterModel;
@end

NS_ASSUME_NONNULL_END
