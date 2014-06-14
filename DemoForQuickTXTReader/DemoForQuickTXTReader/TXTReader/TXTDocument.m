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

@implementation TXTPage

+ (id)pageWithStart:(NSUInteger)start
                end:(NSUInteger)end
            content:(NSAttributedString *)content
{
    __autoreleasing TXTPage *page = [[TXTPage alloc] init];
    page.uintStartIndex = start;
    page.uintEndIndex = end;
    page.pStr_pageData = content;
    return page;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<TXTPage start:%u end:%u text:%@>", _uintStartIndex, _uintEndIndex, _pStr_pageData];
}

@end

@interface TXTDocument ()
@property (nonatomic, strong) NSString                  *cachesBookPath;
@property (nonatomic, strong) NSThread                  *pThrd_parser;
@property (unsafe_unretained) id<TXTDocumentDelegate>   delegate;
@property (unsafe_unretained) BOOL                      searchCancel;

@property (nonatomic, strong) NSThread                  *pThrd_searcher;
@property (nonatomic, strong) NSString                  *pStr_searching;

@end

@implementation TXTDocument
@synthesize bookPath = _bookPath;
@synthesize bookFileLength = _bookFileLength;
@synthesize encoding = _encoding;
@synthesize cachesBookPath = _cachesBookPath;
@synthesize searchCancel = _searchCancel;

#define PATH_TXTDocumentCaches [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"TXTDocumentCaches"]

#pragma mark - life circle

- (NSString *)guidName
{
	CFUUIDRef theUUID;
	CFStringRef theString;
    
	theUUID = CFUUIDCreate(NULL);
    
	theString = CFUUIDCreateString(NULL, theUUID);
    
	NSString *unique = [NSString stringWithFormat:@"%@.txt", (__bridge id)theString];
    
	CFRelease(theString); CFRelease(theUUID); // Cleanup
    
	return unique;
}

- (id)initWithBookPath:(NSString *)bookPath
              encoding:(EncodeObj *)encoding
{
    if (!bookPath) {
        NSLog(@"No book path");
        return nil;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:bookPath]) {
        NSLog(@"No book at path");
        return nil;
    }
    
    if (!encoding) {
        NSLog(@"No encoding");
        return nil;
    }
    
    if (![StringDecode canDecodeFile:bookPath
                           encoding:encoding]) {
        NSLog(@"encoding not match");
        return nil;
    }
    
    self = [super init];
    if (self) {
        _bookPath = bookPath;
        _encoding = encoding;
        _bookFileLength = 0;
        _searchCancel = NO;
        
        //create cache file
        _cachesBookPath = [PATH_TXTDocumentCaches stringByAppendingPathComponent:[self guidName]];
        
        [StringDecode exportSrcPath:_bookPath
                       withEncoding:_encoding
                          toDesPath:_cachesBookPath
                      usingEncoding:NSUnicodeStringEncoding];
        
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:_cachesBookPath error:nil];
        if (attributes) {
            _bookFileLength = [[attributes objectForKey:NSFileSize] unsignedIntegerValue];
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSFileManager defaultManager] removeItemAtPath:_cachesBookPath
                                               error:nil];
}

+ (id)docmentWithBookPath:(NSString *)bookPath
                 encoding:(EncodeObj *)encoding
{
    TXTDocument *doc = [[TXTDocument alloc] initWithBookPath:bookPath
                                                    encoding:encoding];
	return doc;
}

+ (id)docmentWithBookPath:(NSString *)bookPath
                 encoding:(EncodeObj *)encoding
                     font:(UIFont *)font
                     size:(CGSize)size
                    color:(UIColor *)color
            textAlignment:(CTTextAlignment)textAlignment
            lineBreakMode:(CTLineBreakMode)lineBreakMode
      firstLineHeadIndent:(CGFloat)firstLineHeadIndent
                  spacing:(CGFloat)spacing
               topSpacing:(CGFloat)topSpacing
              lineSpacing:(CGFloat)lineSpacing
            searchBgColor:(UIColor *)searchBgColor
{
    TXTDocument *doc = [self docmentWithBookPath:bookPath encoding:encoding];
    if (doc) {
        doc.bookDisplayFont = font;
        doc.bookDisplaySize = size;
        doc.bookDisplayColor = color;
        doc.bookDisplayTextAlignment = textAlignment;
        doc.bookDisplayLineBreakMode = lineBreakMode;
        doc.bookDisplayFirstLineHeadIndent = firstLineHeadIndent;
        doc.bookDisplaySpacing = spacing;
        doc.bookDisplayTopSpacing = topSpacing;
        doc.bookDisplayLineSpacing = lineSpacing;
        doc.bookDisplaySearchBgColor = searchBgColor;
    }
    
    return doc;
}

#pragma mark - page

- (TXTPage *)loadPageWithPage:(TXTPage *)page
{
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:_bookPath];
    
    NSUInteger offset = page.uintStartIndex;
	NSUInteger length = page.uintEndIndex - page.uintStartIndex;
    
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
    
    labelStr = nil;
    data = nil;
    
#ifdef DEBUG
    printf("%s \nstart:%u \nend:%u \ntext:\n%s\n",
           __FUNCTION__,
           page.uintStartIndex,
           page.uintEndIndex,
           as.description.UTF8String);
#endif
    
    return [TXTPage pageWithStart:page.uintStartIndex
                                      end:page.uintEndIndex
                                  content:as];
}

static void hexdump(NSData *data)
{
    int l = data.length;
    const unsigned char *s = data.bytes;
    for(int n = 0; n < l;n++) {
        printf(" %02x", s[n]);
    }
    printf("\n");
}

- (NSUInteger)pageEndWithStart:(NSUInteger)startIndex
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:_cachesBookPath];
    NSUInteger offset = startIndex;
    [handle seekToFileOffset:offset];
    
    @autoreleasepool {
        NSUInteger fileSize = _bookFileLength;
        NSUInteger DATA_STEP = 98;
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
        
        NSUInteger dataLength = tmpOffsetLength;
        do {
            dataLength -= 2;
            @autoreleasepool {
                [handle seekToFileOffset:offset];
                NSData *data = [handle readDataOfLength:dataLength];
                NSString *labelStr = [StringDecode getDecodedString:data encoding:_encoding length:&tmplength];
                if (labelStr.length == visibleLength) {
                    offset += tmplength;
                    break;
                }
            }
        } while (YES);
    }
    [handle closeFile];
    return offset;
}

- (NSUInteger)pageStartWithEnd:(NSUInteger)endIndex
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:_cachesBookPath];
    NSUInteger offset = 0;
    @autoreleasepool {
        NSUInteger DATA_STEP = 98;
        NSUInteger tmpOffsetLength = 0;
        NSUInteger visibleLength = 0;
        NSUInteger tmplength = 0;
        
        do {
            tmpOffsetLength += DATA_STEP;
            
            NSUInteger startIndex = 0;
            if (endIndex > tmpOffsetLength) {
                startIndex = endIndex - tmpOffsetLength;
            }
            else {
                tmpOffsetLength = endIndex;
            }
            
            [handle seekToFileOffset:startIndex];
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
                
                if (endIndex - tmplength <= 0) {
                    break;
                }
            }
        } while(YES);
        
        tmpOffsetLength += DATA_STEP;
        NSUInteger startIndex = 0;
        if (endIndex > tmpOffsetLength) {
            startIndex = endIndex - tmpOffsetLength;
        }
        else {
            tmpOffsetLength = endIndex;
        }
        
        [handle seekToFileOffset:startIndex];
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
        
        NSUInteger dataLength = tmpOffsetLength;
        do {
            dataLength -= 2;
            @autoreleasepool {
                NSUInteger startIndex = 0;
                if (endIndex > dataLength) {
                    startIndex = endIndex - dataLength;
                }
                else {
                    dataLength = endIndex;
                }
                
                [handle seekToFileOffset:startIndex];
                NSData *data = [handle readDataOfLength:dataLength];
                NSString *labelStr = [StringDecode getDecodedString:data encoding:_encoding length:&tmplength];
                if (labelStr.length == visibleLength) {
                    offset = endIndex - tmplength;
                    break;
                }
            }
        } while (YES);
    }
    [handle closeFile];
    return offset;
}

- (TXTPage *)reloadPage:(TXTPage *)page
{
    if (page.uintStartIndex != NSNotFound) {
        NSUInteger endIndex = [self pageEndWithStart:page.uintStartIndex];
        TXTPage *pPage_range = [TXTPage pageWithStart:page.uintStartIndex
                                                  end:endIndex
                                              content:nil];
        return [self loadPageWithPage:pPage_range];
    }
    else {
        NSUInteger startIndex = [self pageStartWithEnd:page.uintEndIndex];
        TXTPage *pPage_range = [TXTPage pageWithStart:startIndex
                                                  end:page.uintEndIndex
                                              content:nil];
        return [self loadPageWithPage:pPage_range];
    }
}

- (TXTPage *)reloadPage:(TXTPage *)page
                   font:(UIFont *)font
                   size:(CGSize)size
                  color:(UIColor *)color
          textAlignment:(CTTextAlignment)textAlignment
          lineBreakMode:(CTLineBreakMode)lineBreakMode
    firstLineHeadIndent:(CGFloat)firstLineHeadIndent
                spacing:(CGFloat)spacing
             topSpacing:(CGFloat)topSpacing
            lineSpacing:(CGFloat)lineSpacing
          searchBgColor:(UIColor *)searchBgColor
{
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
    return [self reloadPage:page];
}

- (TXTPage *)previousPageOfPage:(TXTPage *)page
{
    NSUInteger endIndex = page.uintStartIndex;
    NSUInteger startIndex = [self pageStartWithEnd:endIndex];
    TXTPage *pPage_range = [TXTPage pageWithStart:startIndex
                                              end:endIndex
                                          content:nil];
    return [self loadPageWithPage:pPage_range];
}

- (TXTPage *)previousPageOfPage:(TXTPage *)page
                           font:(UIFont *)font
                           size:(CGSize)size
                          color:(UIColor *)color
                  textAlignment:(CTTextAlignment)textAlignment
                  lineBreakMode:(CTLineBreakMode)lineBreakMode
            firstLineHeadIndent:(CGFloat)firstLineHeadIndent
                        spacing:(CGFloat)spacing
                     topSpacing:(CGFloat)topSpacing
                    lineSpacing:(CGFloat)lineSpacing
                  searchBgColor:(UIColor *)searchBgColor
{
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
    return [self previousPageOfPage:page];
}

- (TXTPage *)nextPageOfPage:(TXTPage *)page
{
    NSUInteger startIndex = page.uintEndIndex;
    NSUInteger endIndex = [self pageEndWithStart:startIndex];
    TXTPage *pPage_range = [TXTPage pageWithStart:startIndex
                                              end:endIndex
                                          content:nil];
    return [self loadPageWithPage:pPage_range];
}

- (TXTPage *)nextPageOfPage:(TXTPage *)page
                       font:(UIFont *)font
                       size:(CGSize)size
                      color:(UIColor *)color
              textAlignment:(CTTextAlignment)textAlignment
              lineBreakMode:(CTLineBreakMode)lineBreakMode
        firstLineHeadIndent:(CGFloat)firstLineHeadIndent
                    spacing:(CGFloat)spacing
                 topSpacing:(CGFloat)topSpacing
                lineSpacing:(CGFloat)lineSpacing
              searchBgColor:(UIColor *)searchBgColor
{
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
    return [self nextPageOfPage:page];
}

#pragma mark - search
- (void)startSearchString:(NSString *)string withDelegate:(id<TXTDocumentDelegate>)delegate
{
    self.delegate = delegate;
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
    self.delegate = nil;
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

- (void)didSearched:(NSValue *)rangeValue
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

#pragma mark - AttributedString

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
//    CGFloat maxHeight = 1.f;
//    CGFloat minHeight = 1.f;
    
    CTParagraphStyleSetting theSettings[6] =
    {
        { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &textAlignment },
        { kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode },
        { kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineHeadIndent },
        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &spacing },
        { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &topSpacing },
        { kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing }
//        { kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(CGFloat), &maxHeight },
//        { kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(CGFloat), &minHeight }
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

@end
