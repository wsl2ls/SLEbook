//
//  SLTextRunDelegate.h
//  EPudRead
//
//  Created by wsl on 2019/12/26.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
Wrapper for CTRunDelegateRef.

Example:

    SLTextRunDelegate *delegate = [SLTextRunDelegate new];
    delegate.ascent = 20;
    delegate.descent = 4;
    delegate.width = 20;
    CTRunDelegateRef ctRunDelegate = delegate.CTRunDelegate;
    if (ctRunDelegate) {
        /// add to attributed string
        CFRelease(ctRunDelegate);
    }

*/

@interface SLTextRunDelegate : NSObject <NSCopying, NSCoding>

/**
 Creates and returns the CTRunDelegate.
 
 @discussion You need call CFRelease() after used.
 The CTRunDelegateRef has a strong reference to this YYTextRunDelegate object.
 In CoreText, use CTRunDelegateGetRefCon() to get this YYTextRunDelegate object.
 
 @return The CTRunDelegate object.
 */
- (nullable CTRunDelegateRef)CTRunDelegate CF_RETURNS_RETAINED;

/**
 Additional information about the the run delegate.
 */
@property (nullable, nonatomic, strong) NSDictionary *userInfo;

/**
 The typographic ascent of glyphs in the run.
 */
@property (nonatomic) CGFloat ascent;

/**
 The typographic descent of glyphs in the run.
 */
@property (nonatomic) CGFloat descent;

/**
 The typographic width of glyphs in the run.
 */
@property (nonatomic) CGFloat width;

@end

NS_ASSUME_NONNULL_END
