//
//  TXTDocument.m
//  DemoForTXTReader
//
//  Created by DarkLinden on 3/18/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import "TXTDocument.h"
#import "StringDecode.h"
#import <CoreText/CoreText.h>

@interface TXTDocument ()
@property (nonatomic, strong) NSFileHandle              *bookFileHandle;
@property (nonatomic, strong) NSThread                  *pThrd_parser;
@property (unsafe_unretained) id<TXTDocumentDelegate>   delegate;
@property (unsafe_unretained) BOOL                      parseCancel;
@property (unsafe_unretained) BOOL                      searchCancel;

@property (nonatomic, strong) NSThread                  *pThrd_searcher;
@property (nonatomic, strong) NSString                  *pStr_searching;
@property (nonatomic, strong) NSMutableArray            *pArr_searchResult;
@end

@implementation TXTDocument
@synthesize bookPath = _bookPath;
@synthesize bookFileLength = _bookFileLength;
@synthesize encoding = _encoding;
@synthesize bookFileHandle = _bookFileHandle;
@synthesize parseCancel = _parseCancel;
@synthesize searchCancel = _searchCancel;

#pragma life circle

- (id)init
{
    self = [super init];
    if (self) {
        _bookFileLength = 0L;
        _parseCancel = NO;
        _searchCancel = NO;
    }
    return self;
}

+ (id)docmentWithBookPath:(NSString *)bookPath
                 delegate:(id<TXTDocumentDelegate>)delegate
{
    if (!bookPath || ![[NSFileManager defaultManager] fileExistsAtPath:bookPath])
        return nil;
    
    TXTDocument *doc = [[TXTDocument alloc] init];
	if (doc) {
        doc.bookPath = bookPath;
        doc.bookFileHandle = [NSFileHandle fileHandleForReadingAtPath:bookPath];
        doc.delegate = delegate;
	}
	
	return doc;
}

- (void)stopParse
{
    _parseCancel = YES;
    self.pThrd_parser = nil;
}

- (void)prepareForFont:(UIFont *)font
                  size:(CGSize)size
                 color:(UIColor *)color
         textAlignment:(CTTextAlignment)textAlignment
         lineBreakMode:(CTLineBreakMode)lineBreakMode
   firstLineHeadIndent:(CGFloat)firstLineHeadIndent
               spacing:(CGFloat)spacing
            topSpacing:(CGFloat)topSpacing
           lineSpacing:(CGFloat)lineSpacing
    ignoreParsedResult:(BOOL)ignoreParsedResult
         searchBgColor:(UIColor *)searchBgColor
{
    _parseCancel = YES;
    self.pThrd_parser = nil;
    
	NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_bookPath error:nil];
	if (attributes) _bookFileLength = [[attributes objectForKey:NSFileSize] unsignedLongLongValue];
    
    self.pArr_indexes = nil;
    if (!ignoreParsedResult) {
        NSString *bookIndexPath = [[_bookPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"];
        _pArr_indexes = [NSMutableArray arrayWithContentsOfFile:bookIndexPath];
    }
    if (!_pArr_indexes) _pArr_indexes = [NSMutableArray array];
    _bookPageCount = _pArr_indexes.count;
    _bookDisplayFont = font;
    _bookDisplaySize = size;
    _bookDisplayColor = color;
    _bookDisplayTextAlignment = textAlignment;
    _bookDisplayLineBreakMode = lineBreakMode;
    _bookDisplayFirstLineHeadIndent = firstLineHeadIndent;
    _bookDisplaySpacing = spacing;
    _bookDisplayTopSpacing = topSpacing;
    _bookDisplayLineSpacing = lineSpacing;
    _bookDisplaySearchBgColor = searchBgColor;
    
    [_bookFileHandle seekToFileOffset:0];
    NSData *data = [_bookFileHandle readDataOfLength:100];
    self.encoding = [StringDecode getStringEncoding:data confidence:0.9];
    NSLog(@"confidence %f encoding %@", 0.9, _encoding);
    [_bookFileHandle seekToFileOffset:0L];
}

- (void)startParse
{
    _parseCancel = NO;
    if (_bookFileLength > 0) {
        if (_pArr_indexes.count) {
            NSUInteger index = [[_pArr_indexes lastObject] unsignedLongLongValue];
            if (index < _bookFileLength) {
                self.pThrd_parser = [[NSThread alloc] initWithTarget:self selector:@selector(parseThread) object:nil];
                [_pThrd_parser start];
            }
            
            [self didParsed:[_pArr_indexes lastObject]];
        }
        else {
            self.pThrd_parser = [[NSThread alloc] initWithTarget:self selector:@selector(parseThread) object:nil];
            [_pThrd_parser start];
        }
    }
}

- (void)parseThread
{
    @autoreleasepool {
        @synchronized (_pArr_indexes) {
            NSUInteger index = 0;
            if ([_pArr_indexes count])
                index = [[_pArr_indexes lastObject] unsignedLongLongValue];
            
            while (index < _bookFileLength) {
                if (_parseCancel) {
                    NSString *bookIndexPath = [[_bookPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"];
                    [_pArr_indexes writeToFile:bookIndexPath atomically:YES];
                    return;
                }
                [_bookFileHandle seekToFileOffset:index];
                index = [self indexOfPage:_bookFileHandle textFont:_bookDisplayFont];
                [_pArr_indexes addObject:[NSNumber numberWithUnsignedLongLong:index]];
                [self performSelectorOnMainThread:@selector(didParsed:) withObject:[NSNumber numberWithUnsignedLongLong:index] waitUntilDone:NO];
            }
            
            NSString *bookIndexPath = [[_bookPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"plist"];
            [_pArr_indexes writeToFile:bookIndexPath atomically:YES];
        }
    }
}

- (void)didParsed:(NSNumber *)offset
{
    if (_parseCancel) return;
    _bookPageCount = self.pArr_indexes.count;
    if (_delegate) {
        if ([_delegate respondsToSelector:@selector(didTXTDoc:parsed:)]) {
            [_delegate didTXTDoc:self parsed:offset.unsignedLongLongValue];
        }
    }
}

- (void)startSearchString:(NSString *)string
{
    self.pStr_searching = string;
    _searchCancel = NO;
    self.pArr_searchResult = [NSMutableArray array];
    if (_bookFileLength > 0) {
        self.pThrd_searcher = [[NSThread alloc] initWithTarget:self selector:@selector(searchThread:) object:string];
        [_pThrd_searcher start];
    }
}

- (void)stopSearch
{
    _searchCancel = YES;
    self.pStr_searching = nil;
    self.pThrd_searcher = nil;
}

- (void)searchThread:(NSString *)string
{
    @autoreleasepool {
        
        @synchronized (_pStr_searching) {
            if (![_pStr_searching isEqualToString:string]) return;
        }
        
        NSFileHandle *handle = nil;
        
        @synchronized (_bookPath) {
            handle = [NSFileHandle fileHandleForReadingAtPath:_bookPath];
        }
        
        @synchronized (_pArr_searchResult) {
            NSUInteger index = 0;
            while (index < _bookFileLength) {
                
                if (_searchCancel) return;
                
                @synchronized (_pStr_searching) {
                    if (![_pStr_searching isEqualToString:string]) return;
                }
                
                [handle seekToFileOffset:index];
                NSUInteger step = string.length * 100;
                NSRange range = [self rangeOfFileHandle:handle
                                           searchString:string
                                             fromOffset:index
                                                 length:step * 10
                                                   step:step];
                
                if (range.location != NSNotFound) {
                    
                    //                    NSLog(@"%@", NSStringFromRange(range));
                    //                    [handle seekToFileOffset:range.location];
                    //                    NSData *data = [handle readDataOfLength:range.length];
                    //                    NSUInteger length = 0;
                    //                    NSString *label = [StringDecode getDecodedString:data
                    //                                                            encoding:_encoding
                    //                                                              length:&length];
                    //                    NSLog(@"%@", label);
                    
                    index = range.location + range.length;
                }
                else {
                    index = _bookFileLength;
                }
                [self performSelectorOnMainThread:@selector(didSearched:) withObject:[NSValue valueWithRange:range] waitUntilDone:NO];
            }
        }
    }
}

- (NSRange)rangeOfFileHandle:(NSFileHandle *)handle
                searchString:(NSString *)string
                  fromOffset:(NSUInteger)offset
                      length:(NSUInteger)length
                        step:(NSUInteger)step
{
    @autoreleasepool {
        [handle seekToFileOffset:offset];
        NSData *data = [handle readDataOfLength:length];
        NSUInteger desLength = 0;
        NSString *labelStr = [StringDecode getDecodedString:data encoding:_encoding length:&desLength];
        if (labelStr) {
            NSRange range = [labelStr rangeOfString:string options:NSCaseInsensitiveSearch];
            if (range.location == NSNotFound) {
                //get data offset string length = label length - string length
                
                if (offset + desLength >= _bookFileLength) {
                    return NSMakeRange(NSNotFound, 0);
                }
                
                NSUInteger decreasedLength = desLength;
                NSUInteger decreasedStrLength = 0;
                do {
                    @autoreleasepool {
                        NSData *subData = [data subdataWithRange:NSMakeRange(0, --decreasedLength)];
                        NSString *tmpStr = [StringDecode getDecodedString:subData encoding:_encoding length:&desLength];
                        decreasedStrLength = tmpStr.length;
                    }
                } while (decreasedStrLength == labelStr.length - string.length);
                
                return [self rangeOfFileHandle:handle
                                  searchString:string
                                    fromOffset:offset + desLength
                                        length:step * 10
                                          step:step];
            }
            else {
                //convert string range to data range
                NSUInteger decreasedLength = desLength;
                NSUInteger dataStart = 0;
                NSUInteger dataEnd = 0;
                do {
                    @autoreleasepool {
                        desLength = 0;
                        NSData *subData = [data subdataWithRange:NSMakeRange(0, decreasedLength)];
                        NSString *tmpStr = [StringDecode getDecodedString:subData encoding:_encoding length:&desLength];
                        if (tmpStr.length == range.location + range.length) {
                            dataEnd = desLength;
                        }
                        
                        if (tmpStr.length == range.location) {
                            dataStart = desLength;
                            break;
                        }
                        --decreasedLength;
                    }
                } while (YES);
                
                return NSMakeRange(offset + dataStart, dataEnd - dataStart);
            }
        }
        else {
            return [self rangeOfFileHandle:handle
                              searchString:string
                                fromOffset:offset
                                    length:length + step
                                      step:step];
        }
    }
}

- (void)didSearched :(NSValue *)rangeValue
{
    if (_searchCancel) return;
    
    if (rangeValue.rangeValue.location != NSNotFound) {
        [_pArr_searchResult addObject:rangeValue];
    }
    
    if (_delegate) {
        if ([_delegate respondsToSelector:@selector(didTXTDoc:searched:)]) {
            [_delegate didTXTDoc:self searched:rangeValue.rangeValue];
        }
    }
}

- (NSMutableAttributedString *)attributedStringWithString:(NSString *)string
                                                     font:(UIFont *)font
                                                    color:(UIColor *)color
                                            textAlignment:(CTTextAlignment)textAlignment
                                            lineBreakMode:(CTLineBreakMode)lineBreakMode
                                      firstLineHeadIndent:(CGFloat)firstLineHeadIndent
                                                  spacing:(CGFloat)spacing
                                               topSpacing:(CGFloat)topSpacing
                                              lineSpacing:(CGFloat)lineSpacing
{
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    NSRange range = NSMakeRange(0, [string length]);
    
    if (font != nil) {
        [attributedString addAttribute:(NSString *)kCTFontAttributeName
                                 value:(id)font
                                 range:range];
    }
    
    if (color != nil) {
        [attributedString addAttribute:(NSString *)kCTForegroundColorAttributeName
                                 value:(id)color.CGColor
                                 range:range];
    }
    
    CFIndex theNumberOfSettings = 6;
    CTParagraphStyleSetting theSettings[6] =
    {
        { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &textAlignment },
        { kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode },
        { kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineHeadIndent },
        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &spacing },
        { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &topSpacing },
        { kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing }
    };
    
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(theSettings, theNumberOfSettings);
    [attributedString addAttribute:(NSString *)kCTParagraphStyleAttributeName
                             value:(__bridge id)paragraphStyle
                             range:range];
    
    CFRelease(paragraphStyle);
    return attributedString;
}

- (unsigned long)attributedString:(NSAttributedString *)string visibleLengthinSize:(CGSize)size
{
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)string);
    
    CFRange fitRange;
    
    CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, size, &fitRange);
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathAddRect(path, NULL, CGRectMake(0, 0, size.width, size.height));
    
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, fitRange, path, NULL);
    
    CFRange frameRange = CTFrameGetVisibleStringRange(frame);
    
    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);
    
    return frameRange.length;
}

- (NSUInteger)indexOfPage:(NSFileHandle *)handle textFont:(UIFont *)font
{
    NSUInteger offset = [handle offsetInFile];
    
    @autoreleasepool {
        NSUInteger fileSize = _bookFileLength;
        NSUInteger DATA_STEP = 50;
        NSUInteger tmpOffsetLength = 0;
        NSUInteger visibleLength = 0;
        NSUInteger tmplength = 0;
        
        do {
            [handle seekToFileOffset:offset];
            tmpOffsetLength += DATA_STEP;
            NSData *data = [handle readDataOfLength:tmpOffsetLength];
            
            if (data) {
                tmplength = 0;
                NSString *labelStr = [StringDecode getDecodedString:data encoding:_encoding length:&tmplength];
                
                if (labelStr) {
                    NSAttributedString *as = [self attributedStringWithString:labelStr
                                                                         font:_bookDisplayFont
                                                                        color:_bookDisplayColor
                                                                textAlignment:_bookDisplayTextAlignment
                                                                lineBreakMode:_bookDisplayLineBreakMode
                                                          firstLineHeadIndent:_bookDisplayFirstLineHeadIndent
                                                                      spacing:_bookDisplaySpacing
                                                                   topSpacing:_bookDisplayTopSpacing
                                                                  lineSpacing:_bookDisplayLineSpacing];
                    
                    visibleLength = [self attributedString:as visibleLengthinSize:_bookDisplaySize];
                    
                    if (visibleLength < as.length) {
                        break;
                    }
                }
                
                if (offset + tmplength >= fileSize) {
                    break;
                }
            }
        } while(YES);
        
        [handle seekToFileOffset:offset];
        tmpOffsetLength += DATA_STEP;
        NSData *data = [handle readDataOfLength:tmpOffsetLength];
        
        NSUInteger length = 0;
        NSString *labelStr = [StringDecode getDecodedString:data encoding:_encoding length:&length];
        
        if (labelStr) {
            NSAttributedString *as = [self attributedStringWithString:labelStr
                                                                 font:_bookDisplayFont
                                                                color:_bookDisplayColor
                                                        textAlignment:_bookDisplayTextAlignment
                                                        lineBreakMode:_bookDisplayLineBreakMode
                                                  firstLineHeadIndent:_bookDisplayFirstLineHeadIndent
                                                              spacing:_bookDisplaySpacing
                                                           topSpacing:_bookDisplayTopSpacing
                                                          lineSpacing:_bookDisplayLineSpacing];
            
            visibleLength = [self attributedString:as visibleLengthinSize:_bookDisplaySize];
        }
        
        NSUInteger dataLength = tmplength;
        do {
            dataLength -= 1;
            @autoreleasepool {
                [handle seekToFileOffset:offset];
                NSData *data = [handle readDataOfLength:dataLength];
                
                tmplength = 0;
                NSString *labelStr = [StringDecode getDecodedString:data encoding:_encoding length:&tmplength];
                
                if (labelStr.length == visibleLength) {
                    offset += tmplength;
                    break;
                }
            }
        } while (YES);
    }
    [handle seekToFileOffset:offset];
    return offset;
}

- (NSAttributedString *)stringWithPage:(NSUInteger)pageIndex
                   displaySearchResult:(BOOL)displaySearchResult
{
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:_bookPath];
    
    NSUInteger offset = 0;
    if (pageIndex > 0) {
		offset = [[_pArr_indexes objectAtIndex:pageIndex - 1] unsignedLongLongValue];
	}
	NSUInteger length = [[_pArr_indexes objectAtIndex:pageIndex] unsignedLongLongValue] - offset;
    
    [handle seekToFileOffset:offset];
	NSData *data = [handle readDataOfLength:length];
    
    NSUInteger tmplength = 0;
    NSString *labelStr = [StringDecode getDecodedString:data encoding:_encoding length:&tmplength];
    
    NSMutableAttributedString *as = [self attributedStringWithString:labelStr
                                                                font:_bookDisplayFont
                                                               color:_bookDisplayColor
                                                       textAlignment:_bookDisplayTextAlignment
                                                       lineBreakMode:_bookDisplayLineBreakMode
                                                 firstLineHeadIndent:_bookDisplayFirstLineHeadIndent
                                                             spacing:_bookDisplaySpacing
                                                          topSpacing:_bookDisplayTopSpacing
                                                         lineSpacing:_bookDisplayLineSpacing];
    
    if (displaySearchResult) {
        if (_pArr_searchResult.count > 0) {
            NSUInteger i = 0;
            NSRange range = [_pArr_searchResult[i] rangeValue];
            while (range.location < offset + length) {
                range = [_pArr_searchResult[i++] rangeValue];
                if (range.location + range.length < offset) continue;
                if (range.location > offset + length) break;
                
                NSRange searchedRange;
                
                if (range.location < offset
                    && range.location + range.length > offset) {
                    
                    if (range.location + range.length < offset + length) {
                        [handle seekToFileOffset:offset];
                        NSData *tmpdata = [handle readDataOfLength:range.location + range.length - offset];
                        
                        NSUInteger tmpStrLength = 0;
                        NSString *searchStr = [StringDecode getDecodedString:tmpdata encoding:_encoding length:&tmpStrLength];
                        
                        searchedRange = NSMakeRange(0, searchStr.length);
                    }
                    else {
                        searchedRange = NSMakeRange(0, as.length);
                    }
                }
                
                if (range.location > offset) {
                    
                    [handle seekToFileOffset:offset];
                    NSData *tmpdata = [handle readDataOfLength:range.location - offset];
                    NSUInteger tmpStrLength = 0;
                    NSString *searchStr = [StringDecode getDecodedString:tmpdata encoding:_encoding length:&tmpStrLength];
                    
                    NSUInteger strStart = searchStr.length;
                    
                    [handle seekToFileOffset:offset];
                    tmpdata = [handle readDataOfLength:range.location + range.length - offset];
                    tmpStrLength = 0;
                    searchStr = [StringDecode getDecodedString:tmpdata encoding:_encoding length:&tmpStrLength];
                    
                    NSUInteger strEnd = searchStr.length;
                    
                    searchedRange = NSMakeRange(strStart, strEnd - strStart);
                }
                
                [as addAttribute:(NSString *)kCTForegroundColorAttributeName
                           value:(id)_bookDisplaySearchBgColor
                           range:searchedRange];
                [as addAttribute:(NSString *)NSBackgroundColorAttributeName
                           value:(id)_bookDisplaySearchBgColor
                           range:searchedRange];
            }
            
        }
    }
    
    labelStr = nil;
    data = nil;
    
    return as;
}

@end
