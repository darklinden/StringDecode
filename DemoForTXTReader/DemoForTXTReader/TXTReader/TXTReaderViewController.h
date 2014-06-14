//
//  TXTReaderViewController.h
//  DemoForReaderTXT
//
//  Created by ryanzhao on 13-3-8.
//  Copyright (c) 2013年 ryanzhao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TXTDocument.h"

@class V_page, TXTDocument;

@interface TXTReaderViewController : UIViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource, TXTDocumentDelegate>

@property (nonatomic, strong) V_page            *txtPage;
@property (nonatomic, strong) TXTDocument       *txtDoc;
@property (nonatomic, strong) NSString          *txtPath;
@property (unsafe_unretained) NSUInteger        startPage;
@property (nonatomic, strong) UISlider          *bookSlider;

- (void)testSearch;

@end
