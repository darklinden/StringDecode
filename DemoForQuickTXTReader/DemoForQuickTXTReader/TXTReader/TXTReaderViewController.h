//
//  TXTReaderViewController.h
//  DemoForReaderTXT
//
//  Created by ryanzhao on 13-3-8.
//  Copyright (c) 2013年 ryanzhao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TXTDocument.h"

@class TXTDocument;

@interface TXTReaderViewController : UIViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource, TXTDocumentDelegate>

@property (nonatomic, strong) TXTPage           *startPage;
@property (nonatomic, strong) TXTDocument       *txtDoc;
@property (nonatomic, strong) NSString          *txtPath;
@property (nonatomic, strong) UISlider          *bookSlider;

- (void)testSearch;

@end
