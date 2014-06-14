//
//  TXTReaderViewController.m
//  DemoForReaderTXT
//
//  Created by ryanzhao on 13-3-8.
//  Copyright (c) 2013年 ryanzhao. All rights reserved.
//

#import "TXTReaderViewController.h"
#import "TXTPageViewController.h"
#import "StringDecode.h"

@interface TXTReaderViewController ()
@property (nonatomic, strong) UIPageViewController  *pageViewController;
@property (unsafe_unretained) BOOL                  pageIsAnimating;
@property (unsafe_unretained) TXTPage               *currentPage;
@end

@implementation TXTReaderViewController
@synthesize startPage;
@synthesize txtDoc;
@synthesize txtPath;
@synthesize bookSlider;

- (void)didTXTDoc:(TXTDocument *)doc searched:(NSRange)searchedRange
{
    NSLog(@"searchedRange %@", NSStringFromRange(searchedRange));
}

- (void)testSearch
{
    [txtDoc startSearchString:@"苦" withDelegate:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    EncodeObj *encoding = [StringDecode getFileEncoding:txtPath
                                             confidence:0.9];
    encoding = [EncodeObj encoding:NSUnicodeStringEncoding name:@"uni"];
    self.txtDoc = [TXTDocument docmentWithBookPath:txtPath
                                          encoding:encoding
                                              font:[UIFont systemFontOfSize:20.f]
                                              size:self.view.bounds.size
                                             color:[UIColor blackColor]
                                     textAlignment:kCTTextAlignmentLeft
                                     lineBreakMode:kCTLineBreakByCharWrapping
                               firstLineHeadIndent:0.f
                                           spacing:1.f
                                        topSpacing:1.f
                                       lineSpacing:1.f
                                     searchBgColor:[UIColor yellowColor]];
	
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.delegate = self;
    
    TXTPage *page = [txtDoc reloadPage:startPage];
    TXTPageViewController *startingViewController = [TXTPageViewController viewControllerForPage:page
                                                                                     boundsFrame:self.view.bounds
                                                                                      innerFrame:self.view.bounds
                                                                                 backgroundImage:nil];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    
    self.pageViewController.dataSource = self;
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    
    CGRect pageViewRect = self.view.bounds;
    self.pageViewController.view.frame = pageViewRect;
    
    [self.pageViewController didMoveToParentViewController:self];
    
    self.view.gestureRecognizers = self.pageViewController.gestureRecognizers;
    
    self.bookSlider = [[UISlider alloc] initWithFrame:CGRectMake(10.f, self.view.bounds.size.height - 20.f, self.view.bounds.size.width - 20.f, 20.f)];
	self.bookSlider.maximumValue = txtDoc.bookFileLength;
	self.bookSlider.minimumValue = 0;
	self.bookSlider.value = 0;
	self.bookSlider.alpha = 0.4;
	[self.bookSlider addTarget:self action:@selector(sliderEvent) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:self.bookSlider];
}

//- (void)viewDidAppear:(BOOL)animated
//{
//    [super viewDidAppear:animated];
//    TXTPage *page = [txtDoc reloadPage:startPage];
//    
//    TXTPageViewController *startingViewController = [TXTPageViewController viewControllerForPage:page
//                                                                                     boundsFrame:self.view.bounds
//                                                                                      innerFrame:self.view.bounds
//                                                                                 backgroundImage:nil];
//    NSArray *viewControllers = @[startingViewController];
//    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
//}

- (void)sliderEvent
{
	NSUInteger endIndex = self.bookSlider.value - ((NSUInteger)self.bookSlider.value % 4);
    
    TXTPage *page = [TXTPage pageWithStart:NSNotFound
                                       end:endIndex
                                   content:nil];
    
    _currentPage = [txtDoc reloadPage:page];
    
    TXTPageViewController *startingViewController = [TXTPageViewController viewControllerForPage:_currentPage
                                                                                     boundsFrame:self.view.bounds
                                                                                      innerFrame:self.view.bounds
                                                                                 backgroundImage:nil];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
}


#pragma mark - UIPageViewController delegate methods

- (void)pageViewController:(UIPageViewController *)pageViewController
willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    _pageIsAnimating = YES;
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    if (completed || finished) _pageIsAnimating = NO;
}

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController
                   spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    TXTPageViewController *currentViewController = (TXTPageViewController *)self.pageViewController.viewControllers[0];
    NSArray *viewControllers = @[currentViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    
    self.pageViewController.doubleSided = NO;
    return UIPageViewControllerSpineLocationMin;
    
    /*
     TXTPageViewController *currentViewController = self.pageViewController.viewControllers[0];
     NSArray *viewControllers = nil;
     
     NSUInteger indexOfCurrentViewController = [self indexOfViewController:currentViewController];
     if (indexOfCurrentViewController == 0 || indexOfCurrentViewController % 2 == 0) {
     UIViewController *nextViewController = [self pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController];
     viewControllers = @[currentViewController, nextViewController];
     } else {
     UIViewController *previousViewController = [self pageViewController:self.pageViewController viewControllerBeforeViewController:currentViewController];
     viewControllers = @[previousViewController, currentViewController];
     }
     [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
     
     
     return UIPageViewControllerSpineLocationMid;
     */
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    if (_pageIsAnimating) return nil;
    
    TXTPage *pPage_current = [(TXTPageViewController *)viewController page];
    self.bookSlider.value = pPage_current.uintEndIndex;
    
    _currentPage = [txtDoc previousPageOfPage:pPage_current];
    
    TXTPageViewController *previousViewController = [TXTPageViewController viewControllerForPage:_currentPage
                                                                             boundsFrame:self.view.bounds
                                                                              innerFrame:self.view.bounds
                                                                         backgroundImage:nil];
    
    return previousViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if (_pageIsAnimating) return nil;
    
    TXTPage *pPage_current = [(TXTPageViewController *)viewController page];
    self.bookSlider.value = pPage_current.uintEndIndex;
    
    _currentPage = [txtDoc nextPageOfPage:pPage_current];
    
    TXTPageViewController *previousViewController = [TXTPageViewController viewControllerForPage:_currentPage
                                                                                     boundsFrame:self.view.bounds
                                                                                      innerFrame:self.view.bounds
                                                                                 backgroundImage:nil];
    
    return previousViewController;
}

- (void)addloading
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)removeLoading
{
    NSLog(@"%s", __FUNCTION__);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.pageViewController.view removeFromSuperview];
    [self.pageViewController removeFromParentViewController];
    self.pageViewController = nil;
    
    self.bookSlider.frame = CGRectMake(10.f, self.view.bounds.size.height - 20.f, self.view.bounds.size.width - 20.f, 20.f);
    _currentPage = [txtDoc reloadPage:_currentPage
                                           font:[UIFont systemFontOfSize:20.f]
                                           size:self.view.bounds.size
                                          color:[UIColor blackColor]
                                  textAlignment:kCTTextAlignmentLeft
                                  lineBreakMode:kCTLineBreakByCharWrapping
                            firstLineHeadIndent:0.f
                                        spacing:1.f
                                     topSpacing:1.f
                                    lineSpacing:1.f
                                  searchBgColor:[UIColor yellowColor]];
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.delegate = self;
    
    TXTPageViewController *startingViewController = [TXTPageViewController viewControllerForPage:_currentPage
                                                                                     boundsFrame:self.view.bounds
                                                                                      innerFrame:self.view.bounds
                                                                                 backgroundImage:nil];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    
    self.pageViewController.dataSource = self;
    
    [self addChildViewController:self.pageViewController];
    [self.view insertSubview:self.pageViewController.view belowSubview:self.bookSlider];
    
    CGRect pageViewRect = self.view.bounds;
    self.pageViewController.view.frame = pageViewRect;
    
    [self.pageViewController didMoveToParentViewController:self];
    [self addloading];
}

@end
