//
//  TXTPageViewController.m
//  DemoForTXTReader
//
//  Created by DarkLinden on 3/25/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import "TXTPageViewController.h"
#import "TXTTileView.h"

@interface TXTPageViewController ()
@property (nonatomic, strong) TXTTileView    *pV_tile;
@end

@implementation TXTPageViewController
@synthesize inset = _inset;
@synthesize size = _size;
@synthesize string = _string;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.pVimg_bg = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, _size.width, _size.height)];
    _pVimg_bg.backgroundColor = [UIColor grayColor];
    [self.view addSubview:_pVimg_bg];
	
    self.pV_tile = [[TXTTileView alloc] initWithFrame:CGRectMake(_inset.width, _inset.height, _size.width - (_inset.width * 2.f), _size.height - (_inset.height * 2.f))];
	[self.view addSubview:_pV_tile];
    _pV_tile.string = _string;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    _pVimg_bg.frame = CGRectMake(0.f, 0.f, _size.width, _size.height);
    _pV_tile.frame = CGRectMake(_inset.width, _inset.height, _size.width - (_inset.width * 2.f), _size.height - (_inset.height * 2.f));
    [_pV_tile setString:_string];
}

- (CGSize)inset
{
    return _inset;
}

- (void)setInset:(CGSize)inset
{
    _inset = inset;
    _pV_tile.frame = CGRectMake(_inset.width, _inset.height, _size.width - (_inset.width * 2.f), _size.height - (_inset.height * 2.f));
}

- (CGSize)size
{
    return _size;
}

- (void)setSize:(CGSize)size
{
    _size = size;
    _pVimg_bg.frame = CGRectMake(0.f, 0.f, _size.width, _size.height);
    _pV_tile.frame = CGRectMake(_inset.width, _inset.height, _size.width - (_inset.width * 2.f), _size.height - (_inset.height * 2.f));
}

- (NSAttributedString *)string
{
    return _string;
}

- (void)setString:(NSAttributedString *)string
{
    _string = string;
    if (_pV_tile) [_pV_tile setString:string];
}

@end
