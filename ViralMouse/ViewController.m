//
//  ViewController.m
//  ViralMouse
//
//  Created by dlleng on 2018/3/24.
//  Copyright © 2018年 leng. All rights reserved.
//

#import "ViewController.h"
#import "VideoEncoder.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    [self screenshot];
}

- (void)screenshot {
//    CGDirectDisplayID displayId = CGMainDisplayID();
//    CGImageRef imageRef = CGDisplayCreateImage(displayId);
//
//    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
//    // save
//    NSString *filename = @"/Users/dlleng/Downloads/a.png";
//
//    NSData *data = [bitmapRep representationUsingType: NSPNGFileType properties: nil];
    //[data writeToFile: filename atomically: NO];
}
- (IBAction)btnClick:(id)sender {
    static BOOL b = true;
    if(b)
    {
        [[VideoEncoder share] startEncode];
    }
    else
    {
        [[VideoEncoder share] stopEncode];
    }
    b = !b;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
