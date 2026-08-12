#import <XCTest/XCTest.h>
#import <MtProtoKit/MTHttpConnectParser.h>

@interface MTHttpConnectParserTests : XCTestCase
@end

@implementation MTHttpConnectParserTests

- (void)testSuccessfulAndTrailingData {
    MTHttpConnectParser *parser = [[MTHttpConnectParser alloc] initWithMaximumHeaderLength:16384];
    NSData *trailingData = nil;
    NSInteger statusCode = 0;
    NSData *input = [@"HTTP/1.1 200 Connection established\r\nX-Test: yes\r\n\r\nabc" dataUsingEncoding:NSISOLatin1StringEncoding];
    XCTAssertEqual([parser appendData:input trailingData:&trailingData statusCode:&statusCode], MTHttpConnectParserResultSuccess);
    XCTAssertEqual(statusCode, 200);
    XCTAssertEqualObjects(trailingData, [@"abc" dataUsingEncoding:NSASCIIStringEncoding]);
}

- (void)testFragmentationAndAll2xx {
    for (NSNumber *code in @[@200, @204, @299]) {
        MTHttpConnectParser *parser = [[MTHttpConnectParser alloc] initWithMaximumHeaderLength:16384];
        NSString *response = [NSString stringWithFormat:@"HTTP/1.1 %@ OK\r\nHeader: value\r\n\r\n", code];
        NSData *data = [response dataUsingEncoding:NSASCIIStringEncoding];
        const uint8_t *bytes = data.bytes;
        for (NSUInteger index = 0; index < data.length; index++) {
            MTHttpConnectParserResult result = [parser appendData:[NSData dataWithBytes:&bytes[index] length:1] trailingData:nil statusCode:nil];
            XCTAssertEqual(result, index + 1 == data.length ? MTHttpConnectParserResultSuccess : MTHttpConnectParserResultIncomplete);
        }
    }
}

- (void)testErrorResponsesAndMalformedStatus {
    for (NSDictionary *item in @[
        @{@"response": @"HTTP/1.1 407 Proxy Authentication Required\r\n\r\n", @"result": @(MTHttpConnectParserResultAuthenticationRequired)},
        @{@"response": @"HTTP/1.1 403 Forbidden\r\n\r\n", @"result": @(MTHttpConnectParserResultFailure)},
        @{@"response": @"NOT HTTP\r\n\r\n", @"result": @(MTHttpConnectParserResultFailure)}
    ]) {
        MTHttpConnectParser *parser = [[MTHttpConnectParser alloc] initWithMaximumHeaderLength:16384];
        MTHttpConnectParserResult result = [parser appendData:[item[@"response"] dataUsingEncoding:NSASCIIStringEncoding] trailingData:nil statusCode:nil];
        XCTAssertEqual(result, [item[@"result"] intValue]);
    }
}

- (void)testOversizedHeader {
    MTHttpConnectParser *parser = [[MTHttpConnectParser alloc] initWithMaximumHeaderLength:32];
    NSData *input = [[@"HTTP/1.1 200 OK\r\n" stringByPaddingToLength:33 withString:@"x" startingAtIndex:0] dataUsingEncoding:NSASCIIStringEncoding];
    XCTAssertEqual([parser appendData:input trailingData:nil statusCode:nil], MTHttpConnectParserResultFailure);
}

- (void)testAuthorityAndBasicAuthentication {
    XCTAssertEqualObjects(MTHttpConnectAuthority(@"149.154.167.50", 443), @"149.154.167.50:443");
    XCTAssertEqualObjects(MTHttpConnectAuthority(@"2001:db8::1", 443), @"[2001:db8::1]:443");
    XCTAssertEqualObjects(MTHttpConnectAuthority(@"[2001:db8::1]", 443), @"[2001:db8::1]:443");
    NSString *request = [[NSString alloc] initWithData:MTHttpConnectRequest(@"example.com", 443, @"user", @"password") encoding:NSASCIIStringEncoding];
    XCTAssertTrue([request containsString:@"CONNECT example.com:443 HTTP/1.1\r\n"]);
    XCTAssertTrue([request containsString:@"Proxy-Authorization: Basic dXNlcjpwYXNzd29yZA==\r\n"]);
    XCTAssertNil(MTHttpConnectAuthority(@"example.com\r\nInjected: yes", 443));
    XCTAssertNil(MTHttpConnectAuthority(@"[2001:db8::1", 443));
    XCTAssertNil(MTHttpConnectAuthority(@"пример.рф", 443));
    XCTAssertNil(MTHttpConnectAuthority(@"bad_host.example", 443));
    XCTAssertNil(MTHttpConnectAuthority(@"example.com", 0));
    XCTAssertNil(MTHttpConnectRequest(@"example.com\r\nInjected: yes", 443, nil, nil));
    XCTAssertNil(MTHttpConnectRequest(@"example.com", 443, @"invalid:user", @"password"));
}

- (void)testMalformedHeaderFraming {
    for (NSString *response in @[
        @"HTTP/1.1 200 OK\nHeader: value\r\n\r\n",
        @"HTTP/1.1 200 OK\rHeader: value\r\n\r\n",
        @"HTTP/1.1 200 OK\r\nInvalidHeader\r\n\r\n",
        @"HTTP/1.1 200 OK\r\nInvalid Header: value\r\n\r\n"
    ]) {
        MTHttpConnectParser *parser = [[MTHttpConnectParser alloc] initWithMaximumHeaderLength:16384];
        NSData *data = [response dataUsingEncoding:NSISOLatin1StringEncoding];
        XCTAssertEqual([parser appendData:data trailingData:nil statusCode:nil], MTHttpConnectParserResultFailure);
    }

    NSMutableData *nulResponse = [[@"HTTP/1.1 200 OK\r\nHeader: value" dataUsingEncoding:NSASCIIStringEncoding] mutableCopy];
    const uint8_t nulByte = 0;
    [nulResponse appendBytes:&nulByte length:1];
    [nulResponse appendData:[@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding]];
    MTHttpConnectParser *parser = [[MTHttpConnectParser alloc] initWithMaximumHeaderLength:16384];
    XCTAssertEqual([parser appendData:nulResponse trailingData:nil statusCode:nil], MTHttpConnectParserResultFailure);
}

@end
