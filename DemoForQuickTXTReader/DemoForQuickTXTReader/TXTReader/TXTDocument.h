//
//  TXTDocument.h
//  DemoForTXTReader
//
//  Created by DarkLinden on 3/18/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TXTPage : NSObject
@property (unsafe_unretained) NSUInteger            uintStartIndex;
@property (unsafe_unretained) NSUInteger            uintEndIndex;
@property (nonatomic, strong) NSAttributedString    *pStr_pageData;

+ (id)pageWithStart:(NSUInteger)start
                end:(NSUInteger)end
            content:(NSAttributedString *)content;

@end

@class V_page, EncodeObj, TXTDocument;

@protocol TXTDocumentDelegate <NSObject>
@required
- (void)didTXTDoc:(TXTDocument *)doc searched:(NSRange)searchedRange;
@end

@interface TXTDocument : NSObject
@property (nonatomic, strong) NSString              *bookPath;
@property (unsafe_unretained) NSUInteger            bookFileLength;

@property (nonatomic, strong) UIFont                *bookDisplayFont;
@property (nonatomic, strong) UIColor               *bookDisplayColor;
@property (nonatomic, strong) UIColor               *bookDisplaySearchBgColor;
@property (unsafe_unretained) CGSize                bookDisplaySize;
@property (unsafe_unretained) CTTextAlignment       bookDisplayTextAlignment;
@property (unsafe_unretained) CTLineBreakMode       bookDisplayLineBreakMode;
@property (unsafe_unretained) CGFloat               bookDisplayFirstLineHeadIndent;
@property (unsafe_unretained) CGFloat               bookDisplaySpacing;
@property (unsafe_unretained) CGFloat               bookDisplayTopSpacing;
@property (unsafe_unretained) CGFloat               bookDisplayLineSpacing;
@property (nonatomic, strong) NSMutableArray        *pArr_searchResult;

@property (nonatomic, strong) EncodeObj             *encoding;

- (id)initWithBookPath:(NSString *)bookPath
              encoding:(EncodeObj *)encoding;

+ (id)docmentWithBookPath:(NSString *)bookPath
                 encoding:(EncodeObj *)encoding;

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
            searchBgColor:(UIColor *)searchBgColor;

- (TXTPage *)reloadPage:(TXTPage *)page;

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
          searchBgColor:(UIColor *)searchBgColor;

- (TXTPage *)previousPageOfPage:(TXTPage *)page;

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
                  searchBgColor:(UIColor *)searchBgColor;

- (TXTPage *)nextPageOfPage:(TXTPage *)page;

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
              searchBgColor:(UIColor *)searchBgColor;

- (void)startSearchString:(NSString *)string
             withDelegate:(id<TXTDocumentDelegate>)delegate;
- (void)stopSearch;

@end
