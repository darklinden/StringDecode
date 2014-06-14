//
//  StringDecode.h
//  StringDecode
//
//  Created by DarkLinden on 3/15/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EncodeObj : NSObject
@property (nonatomic, assign) unsigned long encoding;
@property (nonatomic, retain) NSString      *encodingName;

+ (id)encoding:(unsigned long)encoding name:(NSString *)name;

@end

@interface StringDecode : NSObject
+ (NSArray *)availableEncodingList;

+ (EncodeObj *)getStringEncoding:(NSData *)data
                      confidence:(double)confidence;

+ (BOOL)canDecodeString:(NSData *)data
               encoding:(EncodeObj *)encoding;

+ (NSString *)getDecodedString:(NSData *)data
                      encoding:(EncodeObj *)encoding
                        length:(NSUInteger*)length;

+ (NSData *)encodedString:(NSString *)string
                 encoding:(EncodeObj *)encoding;

+ (EncodeObj *)getFileEncoding:(NSString *)path
                    confidence:(double)confidence;

+ (BOOL)canDecodeFile:(NSString *)path
             encoding:(EncodeObj *)encoding;

+ (void)exportSrcPath:(NSString *)src_path
         withEncoding:(EncodeObj *)src_encoding
            toDesPath:(NSString *)des_path
        usingEncoding:(NSStringEncoding)des_encoding;
@end
