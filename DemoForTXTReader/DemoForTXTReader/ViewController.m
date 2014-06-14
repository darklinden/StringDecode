//
//  ViewController.m
//  DemoForTXTReader
//
//  Created by DarkLinden on 3/18/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import "ViewController.h"
#import "TXTReaderViewController.h"

@interface ViewController ()
@property (nonatomic, strong) NSMutableArray *array;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = CGRectMake(0.f, 0.f, 100.f, 30.f);
    btn.center = self.view.center;
    [btn setTitle:@"show" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(show) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    [[NSFileManager defaultManager] copyItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test.txt"] toPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.txt"] error:nil];
}

- (void)show
{
    TXTReaderViewController *reader = [[TXTReaderViewController alloc] initWithNibName:nil bundle:nil];
    reader.txtPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"test.txt"];
    [self presentViewController:reader animated:YES completion:nil];
//    [reader performSelector:@selector(testSearch) withObject:nil afterDelay:2.f];
}

@end
