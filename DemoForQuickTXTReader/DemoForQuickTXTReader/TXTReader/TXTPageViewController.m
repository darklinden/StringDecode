//
//  TXTPageViewController.m
//  DemoForTXTReader
//
//  Created by DarkLinden on 3/25/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import "TXTPageViewController.h"
#import "TXTTileView.h"
#import "TXTDocument.h"

@interface TXTPageViewController ()
@property (nonatomic, strong) TXTTileView       *pV_tile;
@property (nonatomic, strong) UIImageView       *pVimg_bg;
@end

@implementation TXTPageViewController
@synthesize page = _page;

- (id)initWithPage:(TXTPage *)page
       boundsFrame:(CGRect)boundsFrame
        innerFrame:(CGRect)innerFrame
   backgroundImage:(UIImage *)backgroundImage
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.page = page;
        self.txtBoundsFrame = boundsFrame;
        self.txtInnerFrame = innerFrame;
        self.pVimg_bg.image = backgroundImage;
    }
    return self;
}

+ (TXTPageViewController *)viewControllerForPage:(TXTPage *)page
                                     boundsFrame:(CGRect)boundsFrame
                                      innerFrame:(CGRect)innerFrame
                                 backgroundImage:(UIImage *)backgroundImage;
{
    // Create a new view controller and pass suitable data.
    TXTPageViewController *pVC_page = [[TXTPageViewController alloc] initWithPage:page
                                                                      boundsFrame:boundsFrame
                                                                       innerFrame:innerFrame
                                                                  backgroundImage:backgroundImage];
    return pVC_page;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.frame = self.txtBoundsFrame;
    
    self.pVimg_bg = [[UIImageView alloc] initWithFrame:_txtBoundsFrame];
    _pVimg_bg.backgroundColor = [UIColor grayColor];
    [self.view addSubview:_pVimg_bg];
	
    self.pV_tile = [[TXTTileView alloc] initWithFrame:_txtInnerFrame];
	[self.view addSubview:_pV_tile];
    _pV_tile.string = _page.pStr_pageData;
}

- (TXTPage *)page
{
    return _page;
}

- (void)setPage:(TXTPage *)page
{
    _page = page;
    if (_pV_tile) {
        [_pV_tile setString:page.pStr_pageData];
    }
}

@end
