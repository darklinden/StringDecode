//
//  AppDelegate.m
//  DemoForStringDecode
//
//  Created by DarkLinden on 3/15/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import "AppDelegate.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "StringDecode.h"

@implementation AppDelegate

- (void)exportSrcPath:(NSString *)src_path
             encoding:(EncodeObj *)src_encoding
            toDesPath:(NSString *)des_path
             encoding:(EncodeObj *)des_encoding
{
    [[NSFileManager defaultManager] createFileAtPath:des_path contents:nil attributes:nil];
    NSFileHandle *des_handle = [NSFileHandle fileHandleForWritingAtPath:des_path];
    
    NSFileHandle *src_handle = [NSFileHandle fileHandleForReadingAtPath:src_path];
    NSUInteger tmplength = 0;
    NSUInteger offset = 0;
    NSUInteger DATA_STEP = 1024 * 10;
    NSUInteger tmpOffsetLength = DATA_STEP * 2;
    NSUInteger fileSize = 0;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:src_path error:nil];
	if (attributes) fileSize = [[attributes objectForKey:NSFileSize] unsignedLongLongValue];
    
    do {
        [src_handle seekToFileOffset:offset];
        tmpOffsetLength += DATA_STEP;
        NSData *data = [src_handle readDataOfLength:tmpOffsetLength];
        
        if (data) {
            tmpOffsetLength = DATA_STEP * 2;
            tmplength = 0;
            NSString *labelStr = [StringDecode getDecodedString:data encoding:src_encoding length:&tmplength];
            
            if (labelStr) {
                NSData *des_data = [labelStr dataUsingEncoding:des_encoding.encoding];
                [des_handle writeData:des_data];
            }
            
            if (offset + tmplength >= fileSize) {
                break;
            }
            else {
                offset += tmplength;
            }
        }
        
    } while(YES);
    
    [src_handle closeFile];
    [des_handle closeFile];
}

- (EncodeObj *)getFileEncoding:(NSString *)path
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *data = [fileHandle readDataOfLength:1024];
    EncodeObj *src_encoding = [StringDecode getStringEncoding:data confidence:0.9];
    return src_encoding;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSString *src_path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"src.txt"];
    NSString *des_path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"des.txt"];
    //    NSLog(@"%@", [StringDecode availableEncodingList]);
    
    EncodeObj *src_encoding = [self getFileEncoding:src_path];
    EncodeObj *des_encoding = [EncodeObj encoding:10 name:@"Unicode (UTF-16)"];
    if (!src_encoding) {
        src_encoding = [EncodeObj encoding:2147485234 name:@"gb18030"];
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:des_path error:nil];
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:src_path];
    if (fileExist) {
        NSLog(@"start");
        [self exportSrcPath:src_path
                   encoding:src_encoding
                  toDesPath:des_path
                   encoding:des_encoding];
        NSLog(@"end");
    }
    
    exit(0);
    return YES;
}

@end
