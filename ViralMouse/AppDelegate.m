//
//  AppDelegate.m
//  ViralMouse
//
//  Created by dlleng on 2018/3/24.
//  Copyright © 2018年 leng. All rights reserved.
//
#import "AppDelegate.h"
#import "UDPUtil.h"
#import "TCPUtil.h"
#import "ViralUtil.h"
#import "defines.h"

#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "DDLog.h"
#import "DDTTYLogger.h"

@interface AppDelegate ()<NSWindowDelegate>
{
    HTTPServer *httpServer;
}
@property(weak) NSWindow *window;
@property (strong, nonatomic) NSStatusItem *statusItem;
@end

@implementation AppDelegate
NSArray *arr = nil;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //NSLog(@"%@",[NSApplication sharedApplication].windows);
    _window = [NSApplication sharedApplication].windows.firstObject;//[NSApplication sharedApplication].mainWindow;
    _window.delegate = self;
    
    // Insert code here to initialize your application
    [[UDPUtil share] startServer:SERVER_PORT];
    [[TCPUtil share] startServerAtPort:TCP_PORT];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setImage:[NSImage imageNamed:@"1"]];
    [self.statusItem setHighlightMode:YES];
    
    NSMenu *subMenu = [[NSMenu alloc] init];
    
    [subMenu addItemWithTitle:@"显示窗口"action:@selector(btnShow:) keyEquivalent:@""];
    NSMenuItem *item = [subMenu addItemWithTitle:@"开机启动"action:@selector(btnStart:) keyEquivalent:@""];
    item.state = [self isDaemon];
    [subMenu addItemWithTitle:@"退出"action:@selector(btnExit:) keyEquivalent:@""];
    self.statusItem.menu = subMenu;
    
    
    [self startHttpServer];
}
-(void)startHttpServer
{
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    httpServer = [[HTTPServer alloc] init];
    [httpServer setConnectionClass:[MyHTTPConnection class]];
    [httpServer setType:@"_http._tcp."];
    [httpServer setPort:HTTP_PORT];
    [httpServer setDocumentRoot:@"/"];
    NSError *error;
    BOOL success = [httpServer start:&error];
    if(!success)
    {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    //NSLog(@"exit");
    [[UDPUtil share] stopServer];
    [UDPUtil uninstance];
}
#pragma mark menu item
- (void)btnShow:(NSMenuItem*)item{
    [_window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];//没有这句会被别的窗口遮挡
}
- (void)btnStart:(NSMenuItem*)item{
    if(item.state)
        [self removeDaemon];
    else
        [self addDaemon];
    item.state = [self isDaemon];
}
- (void)btnExit:(NSMenuItem*)item{
    [[NSApplication sharedApplication] terminate:nil];
}


#pragma mark window delegate
-(void)windowWillClose:(NSNotification *)notification
{
    //[NSApp terminate:self];
    [NSApp hide:_window];
}
-(BOOL)windowShouldClose:(NSWindow *)sender
{
    return YES;
}

//开机启动
-(void)addDaemon{
    NSString* launchFolder = [NSString stringWithFormat:@"%@/Library/LaunchAgents",NSHomeDirectory()];
    NSString * boundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey];
    NSString* dstLaunchPath = [launchFolder stringByAppendingFormat:@"/%@.plist",boundleID];
    NSFileManager* fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    //已经存在启动项中，就不必再创建
    if ([fm fileExistsAtPath:dstLaunchPath isDirectory:&isDir] && !isDir) {
        return;
    }
    //下面是一些配置
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    [arr addObject:[[NSBundle mainBundle] executablePath]];
    [arr addObject:@"-runMode"];
    [arr addObject:@"autoLaunched"];
    [dict setObject:[NSNumber numberWithBool:true] forKey:@"RunAtLoad"];
    [dict setObject:boundleID forKey:@"Label"];
    [dict setObject:arr forKey:@"ProgramArguments"];
    isDir = NO;
    if (![fm fileExistsAtPath:launchFolder isDirectory:&isDir] && isDir) {
        [fm createDirectoryAtPath:launchFolder withIntermediateDirectories:NO attributes:nil error:nil];
    }
    [dict writeToFile:dstLaunchPath atomically:NO];
}
// 取消配置开机默认启动
-(void)removeDaemon{
    NSString* launchFolder = [NSString stringWithFormat:@"%@/Library/LaunchAgents",NSHomeDirectory()];
    NSString * boundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey];
    NSString* srcLaunchPath = [launchFolder stringByAppendingFormat:@"/%@.plist",boundleID];
    
    BOOL isDir = NO;
    NSFileManager* fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:srcLaunchPath isDirectory:&isDir] && !isDir) {
        [fm removeItemAtPath:srcLaunchPath error:nil];
    }
    
}
-(BOOL)isDaemon
{
    NSString* launchFolder = [NSString stringWithFormat:@"%@/Library/LaunchAgents",NSHomeDirectory()];
    NSString * boundleID = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey];
    NSString* srcLaunchPath = [launchFolder stringByAppendingFormat:@"/%@.plist",boundleID];
    
    BOOL isDir = NO;
    NSFileManager* fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:srcLaunchPath isDirectory:&isDir] && !isDir) {
        return YES;
    }
    
    return NO;
}
@end
