//
//  StringDecode.m
//  StringDecode
//
//  Created by DarkLinden on 3/15/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import "StringDecode.h"
#import "XADString.h"

@implementation EncodeObj
@synthesize encoding, encodingName;

+ (id)encoding:(unsigned long)encoding
          name:(NSString *)name
{
    __autoreleasing EncodeObj *obj = [[[EncodeObj alloc] init] autorelease];
    obj.encoding = encoding;
    obj.encodingName = name;
    return obj;
}

- (void)dealloc
{
    [encodingName release], encodingName = nil;
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<encodeName %@ encoding %lu >", encodingName, encoding];
}

@end

@implementation StringDecode

+ (NSArray *)availableEncodingList
{
	NSMutableArray *array = [NSMutableArray array];
    
	const CFStringEncoding *encodings = CFStringGetListOfAvailableEncodings();
    
	while (*encodings != kCFStringEncodingInvalidId) {
        NSString *name = (NSString *)CFStringConvertEncodingToIANACharSetName(*encodings);
        unsigned long encoding = CFStringConvertEncodingToNSStringEncoding(*encodings);
        NSString *description = [NSString localizedNameOfStringEncoding:encoding];
		if (name) {
            if (description && description.length > 0)
                [array addObject:[EncodeObj encoding:encoding name:description]];
            else
                [array addObject:[EncodeObj encoding:encoding name:name]];
		}
		encodings++;
	}
    
	return array;
}

+ (EncodeObj *)getStringEncoding:(NSData *)data
                      confidence:(double)confidence
{
    XADStringSource *src = [[XADStringSource alloc] init];
    XADString *str = [XADString analyzedXADStringWithData:data source:src];
    EncodeObj *encode = nil;
    if (str.confidence >= confidence) {
        unsigned long encoding = [str encoding];
        unsigned long cfencoding = CFStringConvertNSStringEncodingToEncoding(encoding);
        NSString *name = (NSString *)CFStringConvertEncodingToIANACharSetName(cfencoding);
        NSString *description = [NSString localizedNameOfStringEncoding:encoding];
		if (name) {
            if (description && description.length > 0)
                encode = [EncodeObj encoding:encoding name:description];
            else
                encode = [EncodeObj encoding:encoding name:name];
		}
    }
    [src release], src = nil;
    return encode;
}

+ (BOOL)canDecodeString:(NSData *)data
               encoding:(EncodeObj *)encoding
{
    CFStringEncoding cfenc = CFStringConvertNSStringEncodingToEncoding(encoding.encoding);
	if (cfenc == kCFStringEncodingInvalidId) return NO;
	CFStringRef str = CFStringCreateWithBytes(kCFAllocatorDefault, data.bytes, data.length, cfenc, false);
	if (str) { CFRelease(str); return YES; }
	else return NO;
}

+ (NSString *)getDecodedString:(NSData *)data encoding:(EncodeObj *)encoding length:(NSUInteger *)length
{
    CFStringEncoding cfenc = CFStringConvertNSStringEncodingToEncoding(encoding.encoding);
	if (cfenc == kCFStringEncodingInvalidId) return nil;
    
    NSUInteger datalength = data.length;
    NSUInteger errCnt = 0;
	CFStringRef str = CFStringCreateWithBytes(kCFAllocatorDefault, data.bytes, datalength, cfenc, false);
    
    while (!str) {
        if (datalength > 1)
        {
            datalength--;
            errCnt++;
        }
        else
        {
            break;
        }
        
        str = CFStringCreateWithBytes(kCFAllocatorDefault, data.bytes, datalength, cfenc, false);
        if (errCnt >= 10) {
            break;
        }
    }
    
    NSString *ret = nil;
    if (str) {
        ret = [NSString stringWithString:(NSString *)str];
        CFRelease(str);
        *length = datalength;
    }
    
	return ret;
}

+ (NSData *)encodedString:(NSString *)string
                 encoding:(EncodeObj *)encoding
{
    return [string dataUsingEncoding:encoding.encoding];
}

+ (EncodeObj *)getFileEncoding:(NSString *)path
                    confidence:(double)confidence
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *data = [fileHandle readDataOfLength:1024];
    [fileHandle closeFile];
    EncodeObj *src_encoding = [StringDecode getStringEncoding:data confidence:confidence];
    return src_encoding;
}

+ (BOOL)canDecodeFile:(NSString *)path
             encoding:(EncodeObj *)encoding
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    NSData *data = [fileHandle readDataOfLength:1024];
    [fileHandle closeFile];
    
    NSUInteger datalength = data.length;
    CFStringEncoding cfenc = CFStringConvertNSStringEncodingToEncoding(encoding.encoding);
    CFStringRef str = CFStringCreateWithBytes(kCFAllocatorDefault, data.bytes, datalength, cfenc, false);
    while (!str) {
        if (datalength - 4 > 0) {
            if (datalength > datalength - 4)
                datalength--;
            else {
                break;
            }
        }
        else {
            if (datalength > 0)
                datalength--;
            else {
                break;
            }
        }
        
        str = CFStringCreateWithBytes(kCFAllocatorDefault, data.bytes, datalength, cfenc, false);
    }
    
	if (str) { CFRelease(str); return YES; }
	else return NO;
}

static void hexdump(const unsigned char *s, int l)
{
    for(int n = 0; n < l;n++) {
        printf(" %02x", s[n]);
    }
    printf("\n");
}

+ (void)exportSrcPath:(NSString *)src_path
         withEncoding:(EncodeObj *)src_encoding
            toDesPath:(NSString *)des_path
        usingEncoding:(NSStringEncoding)des_encoding
{
    //prepare des
    NSString *folderPath = [des_path stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    
    //prepare src
    NSFileHandle *src_handle = [NSFileHandle fileHandleForReadingAtPath:src_path];
    NSUInteger tmplength = 0;
    NSUInteger offset = 0;
    NSUInteger DATA_STEP = 1024 * 10;
    NSUInteger tmpOffsetLength = DATA_STEP * 2;
    NSUInteger fileSize = 0;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:src_path error:nil];
	if (attributes) fileSize = [[attributes objectForKey:NSFileSize] unsignedIntegerValue];
    
    do {
        [src_handle seekToFileOffset:offset];
        tmpOffsetLength += DATA_STEP;
        NSData *data = [src_handle readDataOfLength:tmpOffsetLength];
        
        if (data) {
            tmpOffsetLength = DATA_STEP * 2;
            tmplength = 0;
            NSString *labelStr = [StringDecode getDecodedString:data encoding:src_encoding length:&tmplength];
            
            if (labelStr) {
                FILE *fp = fopen(des_path.UTF8String, "a");
                NSData *des_data = [labelStr dataUsingEncoding:des_encoding];
                const unsigned char *buffer = des_data.bytes;
                NSUInteger len = des_data.length;
                
                //hack remove bom
                if (buffer[0] == 0xff
                    && buffer[1] == 0xfe) {
                    buffer += 2;
                    len -= 2;
                }
                
                fwrite(buffer, 1, len, fp);
                fclose(fp);
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
}

@end