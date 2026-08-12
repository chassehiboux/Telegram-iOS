#import <Foundation/Foundation.h>

typedef NS_ENUM(int32_t, MTHttpConnectParserResult) {
    MTHttpConnectParserResultIncomplete = 0,
    MTHttpConnectParserResultSuccess = 1,
    MTHttpConnectParserResultAuthenticationRequired = 2,
    MTHttpConnectParserResultFailure = 3
};

@interface MTHttpConnectParser : NSObject

- (instancetype)initWithMaximumHeaderLength:(NSUInteger)maximumHeaderLength;
- (MTHttpConnectParserResult)appendData:(NSData *)data trailingData:(NSData * _Nullable * _Nullable)trailingData statusCode:(NSInteger * _Nullable)statusCode;

@end

FOUNDATION_EXPORT NSString * _Nullable MTHttpConnectAuthority(NSString *host, uint16_t port);
FOUNDATION_EXPORT NSData * _Nullable MTHttpConnectRequest(NSString *host, uint16_t port, NSString * _Nullable username, NSString * _Nullable password);
