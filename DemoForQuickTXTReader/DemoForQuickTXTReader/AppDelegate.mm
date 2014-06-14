//
//  AppDelegate.m
//  DemoForTXTReader
//
//  Created by DarkLinden on 3/18/13.
//  Copyright (c) 2013 darklinden. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /*
     NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"斗破苍穹.txt"];
     
     NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
     NSData *data = [fileHandle readDataOfLength:101];
     
     EncodeObj *encoding = [StringDecode getStringEncoding:data confidence:0.9];
     if (encoding) {
     NSString *str = [StringDecode getDecodedString:data encoding:encoding];
     if (str)
     NSLog(@"%@ confidence %@", encoding.encodingName, str);
     else {
     NSData *subdata = [data subdataWithRange:NSMakeRange(0, data.length - 1)];
     NSLog(@"%@ confidence %@", encoding.encodingName, [StringDecode getDecodedString:subdata encoding:encoding]);
     }
     }
     else
     for (EncodeObj *encoding in [StringDecode availableEncodingList]) {
     if ([StringDecode canDecodeString:data encoding:encoding])
     NSLog(@"%@ can %@", encoding.encodingName, [StringDecode getDecodedString:data encoding:encoding]);
     else {
     NSData *subdata = [data subdataWithRange:NSMakeRange(0, data.length - 1)];
     if ([StringDecode canDecodeString:subdata encoding:encoding])
     NSLog(@"%@ can %@", encoding.encodingName, [StringDecode getDecodedString:subdata encoding:encoding]);
     else
     NSLog(@"%@ can't", encoding.encodingName);
     }
     }
     */
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[ViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
