//
//  TXTPageViewController.h
//  DemoForTXTReader
//
//  Created by DarkLinden on 3/25/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TXTPage;
@interface TXTPageViewController : UIViewController
@property (unsafe_unretained) CGRect                txtBoundsFrame;
@property (unsafe_unretained) CGRect                txtInnerFrame;
@property (nonatomic, strong) TXTPage               *page;

+ (TXTPageViewController *)viewControllerForPage:(TXTPage *)page
                                     boundsFrame:(CGRect)boundsFrame
                                      innerFrame:(CGRect)innerFrame
                                 backgroundImage:(UIImageView*)backgroundImage;

@end
