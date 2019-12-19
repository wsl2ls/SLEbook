//
//  SLReadViewController.m
//  EPudRead
//
//  Created by wsl on 2019/12/19.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLReadViewController.h"
#import "SLCoreTextView.h"

@interface SLReadViewController ()

@end

@implementation SLReadViewController

#pragma mark - Override
- (instancetype)init {
    self = [super init];
    if (self) {
        [self.view addSubview:self.coreTextView];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

#pragma mark - Getter
- (SLCoreTextView *)coreTextView {
    if (_coreTextView == nil) {
        _coreTextView = [[SLCoreTextView alloc] initWithFrame:self.view.bounds];
    }
    return _coreTextView;
}

@end
