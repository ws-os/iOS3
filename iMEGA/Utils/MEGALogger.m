
#import "MEGALogger.h"

@implementation MEGALogger

static MEGALogger *_megaLogger = nil;

+ (MEGALogger *)sharedLogger {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _megaLogger = [[MEGALogger alloc] init];
    });
    
    return _megaLogger;
}

- (void)startLogging {
    [[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"] ? [MEGAChatSdk setLogObject:[MEGALogger sharedLogger]] : [MEGASdk setLogObject:[MEGALogger sharedLogger]];
    
    NSString *logFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"MEGAiOS.log"];
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding],"a+", stderr);
    
    [MEGASdk setLogLevel:MEGALogLevelMax];
    [MEGAChatSdk setLogLevel:MEGAChatLogLevelMax];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"logging"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)stopLogging {
    [[NSUserDefaults standardUserDefaults] boolForKey:@"IsChatEnabled"] ? [MEGAChatSdk setLogObject:nil] : [MEGASdk setLogObject:nil];
    
    NSString *logFilePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"MEGAiOS.log"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
    }
    
#ifndef DEBUG
    [MEGASdk setLogLevel:MEGALogLevelFatal];
    [MEGAChatSdk setLogLevel:MEGAChatLogLevelFatal];
#endif
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"logging"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)useSDKLogger {
    [MEGAChatSdk setLogObject:nil];
    [MEGASdk setLogObject:_megaLogger];
}

- (void)useChatSDKLogger {
    [MEGASdk setLogObject:nil];
    [MEGAChatSdk setLogObject:_megaLogger];
}

- (void)logWithTime:(NSString *)time logLevel:(NSInteger)logLevel source:(NSString *)source message:(NSString *)message {
    NSString *m = [[NSString alloc] init];
    
    switch (logLevel) {
        case MEGALogLevelDebug:
            m = [m stringByAppendingString:@" (debug) "];
            break;
        case MEGALogLevelError:
            m = [m stringByAppendingString:@" (error) "];
            break;
        case MEGALogLevelFatal:
            m = [m stringByAppendingString:@" (fatal) "];
            break;
        case MEGALogLevelInfo:
            m = [m stringByAppendingString:@" (info) "];
            break;
        case MEGALogLevelMax:
            m = [m stringByAppendingString:@" (verb) "];
            break;
        case MEGALogLevelWarning:
            m = [m stringByAppendingString:@" (warn) "];
            break;
            
        default:
            break;
    }
    
    m = [m stringByAppendingString:message];
    m = [m stringByAppendingString:source];
    NSLog(@"%@", m);
}

- (void)logWithLevel:(NSInteger)logLevel message:(NSString *)message {
    fprintf(stderr, "%s", [message UTF8String]);
}

@end