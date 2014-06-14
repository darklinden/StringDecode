//
//  TXTPageViewController.h
//  DemoForTXTReader
//
//  Created by DarkLinden on 3/25/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TXTPageViewController : UIViewController
@property (unsafe_unretained) CGSize                size;
@property (unsafe_unretained) NSUInteger            index;
@property (nonatomic, strong) NSAttributedString    *string;
@property (unsafe_unretained) CGSize                inset;
@property (nonatomic, strong) UIImageView           *pVimg_bg;
@end
