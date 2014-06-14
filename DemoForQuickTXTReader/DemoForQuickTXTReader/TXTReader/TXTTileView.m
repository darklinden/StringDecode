//
//  TXTTileView.m
//  DemoForReaderTXT
//
//  Created by ryanzhao on 13-3-8.
//  Copyright (c) 2013年 ryanzhao. All rights reserved.
//

#import "TXTTileView.h"
#import <CoreText/CoreText.h>
#import <QuartzCore/QuartzCore.h>

@implementation TXTTileView
@synthesize string = _string;

- (id)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    if (_string) {
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSaveGState(context);
        
        CGAffineTransform flip = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, self.frame.size.height);
        
        CGContextConcatCTM(context, flip);
        
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)_string);
        
        CFRange fitRange;
        
        CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, self.frame.size, &fitRange);
        
        CGMutablePathRef path = CGPathCreateMutable();
        
        CGPathAddRect(path, NULL, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
        
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, fitRange, path, NULL);
        
        CTFrameDraw(frame, context);
        
        CFRelease(frame);
        CFRelease(path);
        CFRelease(framesetter);
        
        CGContextRestoreGState(context);
    }
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self setNeedsDisplay];
}

- (void)setString:(NSAttributedString *)string
{
    _string = string;
    [self setNeedsDisplay];
}

- (NSAttributedString *)string
{
    return _string;
}

@end
