//
//  TXTDocument.h
//  DemoForTXTReader
//
//  Created by DarkLinden on 3/18/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import <Foundation/Foundation.h>

@class V_page, EncodeObj, TXTDocument;

@protocol TXTDocumentDelegate <NSObject>
@required
- (void)didTXTDoc:(TXTDocument *)doc parsed:(NSUInteger)parsedIndex;
- (void)didTXTDoc:(TXTDocument *)doc searched:(NSRange)searchedRange;
@end

@interface TXTDocument : NSObject
@property (nonatomic, strong) NSString              *bookPath;
@property (unsafe_unretained) NSUInteger            bookFileLength;
@property (unsafe_unretained) NSUInteger            bookPageCount;
@property (nonatomic, strong) NSMutableArray        *pArr_indexes;

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

@property (nonatomic, strong) EncodeObj             *encoding;

+ (id)docmentWithBookPath:(NSString *)bookPath
                 delegate:(id<TXTDocumentDelegate>)delegate;

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
         searchBgColor:(UIColor *)searchBgColor;

- (void)startParse;
- (void)stopParse;

- (void)startSearchString:(NSString *)string;
- (void)stopSearch;

- (NSAttributedString *)stringWithPage:(NSUInteger)pageIndex
                   displaySearchResult:(BOOL)displaySearchResult;

@end
