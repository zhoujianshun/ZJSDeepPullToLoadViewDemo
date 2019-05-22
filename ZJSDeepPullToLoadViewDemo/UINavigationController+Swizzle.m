//
//  UINavigationController+Swizzle.m
//  HQHaoxee
//
//  Created by asan on 15/7/9.
//  Copyright (c) 2015年 ASAN. All rights reserved.
//

#import "UINavigationController+Swizzle.h"
#import <objc/runtime.h>

@implementation UINavigationController (Swizzle)

+ (void)load
{
    swizzleAllNavigationController();
}

- (void)__custom__pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([NSStringFromClass([viewController class]) rangeOfString:@"ZJSHomeViewController"].location != NSNotFound  ) {
        viewController.hidesBottomBarWhenPushed = NO;
    }else{
        viewController.hidesBottomBarWhenPushed = YES;
    }

    
    [self __custom__pushViewController:viewController animated:animated];
}

void swizzleAllNavigationController()
{
    __swizzle__([UINavigationController class], @selector(pushViewController:animated:), @selector(__custom__pushViewController:animated:));
}

void __swizzle__(Class c,SEL origSEL,SEL newSEL)
{
    Method origMethod = class_getInstanceMethod(c, origSEL);
    Method newMethod = nil;
    if (!origMethod) {
        origMethod = class_getClassMethod(c, origSEL);
        if (!origMethod) {
            return;
        }
        newMethod = class_getClassMethod(c, newSEL);
        if (!newMethod) {
            return;
        }
    }else{
        newMethod = class_getInstanceMethod(c, newSEL);
        if (!newMethod) {
            return;
        }
    }
    
    //自身已经有了就添加不成功，直接交换即可
    if(class_addMethod(c, origSEL, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))){
        class_replaceMethod(c, newSEL, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }else{
        method_exchangeImplementations(origMethod, newMethod);
    }
}

@end


