//
//  TXTReaderViewController.m
//  DemoForReaderTXT
//
//  Created by ryanzhao on 13-3-8.
//  Copyright (c) 2013年 ryanzhao. All rights reserved.
//

#import "TXTReaderViewController.h"
#import "TXTPageViewController.h"

@interface TXTReaderViewController ()
@property (nonatomic, strong) UIPageViewController  *pageViewController;
@property (unsafe_unretained) BOOL                  pageIsAnimating;
@property (unsafe_unretained) NSUInteger            currentIndex;
@end

@implementation TXTReaderViewController
@synthesize txtPage;
@synthesize txtDoc;
@synthesize txtPath;
@synthesize bookSlider;

- (void)didTXTDoc:(TXTDocument *)doc searched:(NSRange)searchedRange
{
    NSLog(@"searchedRange %@", NSStringFromRange(searchedRange));
}

- (void)testSearch
{
//    [txtDoc startSearchString:@"苦"];
}

- (void)didTXTDoc:(TXTDocument *)doc parsed:(NSUInteger)parsedIndex
{
    TXTPageViewController *currentviewController = [self.pageViewController.viewControllers lastObject];
    if (!currentviewController.string && currentviewController.index < txtDoc.bookPageCount) {
        NSLog(@"currentviewController.index %u", currentviewController.index);
        TXTPageViewController *startingViewController = [self viewControllerAtIndex:currentviewController.index];
        NSArray *viewControllers = @[startingViewController];
        [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
        [self removeLoading];
        self.bookSlider.value = currentviewController.index;
    }
    
    if (parsedIndex == txtDoc.bookFileLength) {
        NSLog(@"parsedIndex %u bookFileLength %u percent %f", parsedIndex, txtDoc.bookFileLength, (CGFloat)parsedIndex / (CGFloat)txtDoc.bookFileLength);
    }
    self.bookSlider.maximumValue = txtDoc.bookPageCount;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.txtDoc = [TXTDocument docmentWithBookPath:txtPath delegate:self];
    [txtDoc prepareForFont:[UIFont systemFontOfSize:20.f]
                      size:self.view.bounds.size
                     color:[UIColor blackColor]
             textAlignment:kCTTextAlignmentLeft
             lineBreakMode:kCTLineBreakByWordWrapping
       firstLineHeadIndent:0.f
                   spacing:10.f
                topSpacing:10.f
               lineSpacing:10.f
        ignoreParsedResult:NO
             searchBgColor:[UIColor yellowColor]];
	
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.delegate = self;
    
    TXTPageViewController *startingViewController = [self viewControllerAtIndex:_startPage];
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
	self.bookSlider.maximumValue = 2;
	self.bookSlider.minimumValue = 1;
	self.bookSlider.value = 1;
	self.bookSlider.alpha = 0.4;
	[self.bookSlider addTarget:self action:@selector(sliderEvent) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:self.bookSlider];
    
//    [txtDoc startSearchString:@"谢谢"];
    [txtDoc startParse];
}

- (void)sliderEvent
{
	NSUInteger page = self.bookSlider.value;
    
    TXTPageViewController *startingViewController = [self viewControllerAtIndex:page];
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
}


#pragma mark - UIPageViewController delegate methods

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    _pageIsAnimating = YES;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed || finished) _pageIsAnimating = NO;
}

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController
                   spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    TXTPageViewController *currentViewController = (TXTPageViewController *)self.pageViewController.viewControllers[0];
    currentViewController.size = self.view.bounds.size;
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

- (TXTPageViewController *)viewControllerAtIndex:(NSUInteger)index
{
    _currentIndex = index;
    // Return the data view controller for the given index.
    if (txtDoc.bookPageCount <= index) {
        TXTPageViewController *dataViewController = [[TXTPageViewController alloc] initWithNibName:nil bundle:nil];
        dataViewController.size = self.view.bounds.size;
        dataViewController.index = index;
        return dataViewController;
    }
    
    // Create a new view controller and pass suitable data.
    TXTPageViewController *dataViewController = [[TXTPageViewController alloc] initWithNibName:nil bundle:nil];
    dataViewController.size = self.view.bounds.size;
    dataViewController.string = [txtDoc stringWithPage:index displaySearchResult:YES];
    dataViewController.index = index;
    return dataViewController;
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if (_pageIsAnimating) return nil;
    
    NSUInteger index = [(TXTPageViewController *)viewController index];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    self.bookSlider.value = index;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if (_pageIsAnimating) return nil;
    
    NSUInteger index = [(TXTPageViewController *)viewController index];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == txtDoc.bookPageCount) {
        return nil;
    }
    self.bookSlider.value = index;
    return [self viewControllerAtIndex:index];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [txtDoc stopParse];
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
    [txtDoc prepareForFont:[UIFont systemFontOfSize:20.f]
                      size:self.view.bounds.size
                     color:[UIColor blackColor]
             textAlignment:kCTTextAlignmentLeft
             lineBreakMode:kCTLineBreakByWordWrapping
       firstLineHeadIndent:0.f
                   spacing:10.f
                topSpacing:10.f
               lineSpacing:10.f
        ignoreParsedResult:YES
             searchBgColor:[UIColor yellowColor]];
    
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.delegate = self;
    
    TXTPageViewController *startingViewController = [self viewControllerAtIndex:_currentIndex];
    NSLog(@"index %u startingViewController.index %u", _currentIndex, startingViewController.index);
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    
    self.pageViewController.dataSource = self;
    
    [self addChildViewController:self.pageViewController];
    [self.view insertSubview:self.pageViewController.view belowSubview:self.bookSlider];
    
    CGRect pageViewRect = self.view.bounds;
    self.pageViewController.view.frame = pageViewRect;
    
    [self.pageViewController didMoveToParentViewController:self];
    [self addloading];
    [txtDoc startParse];
}

@end
