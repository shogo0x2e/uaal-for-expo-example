#import <Foundation/Foundation.h>
#import "NativeCallProxy.h"


@implementation FrameworkLibAPI

id<NativeCallsProtocol> api = NULL;
+(void) registerAPIforNativeCalls:(id<NativeCallsProtocol>) aApi
{
    api = aApi;
}

@end


extern "C" {
    void showHostMainWindow(const char* color) {
        return [api showHostMainWindow:[NSString stringWithUTF8String:color]];
    }

    void sendMessageToReactNative(const char* message) {
        return [api sendMessageToReactNative:[NSString stringWithUTF8String:message]];
    }
}

