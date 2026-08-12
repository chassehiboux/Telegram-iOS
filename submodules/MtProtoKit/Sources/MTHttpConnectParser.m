#import <MtProtoKit/MTHttpConnectParser.h>

#import <arpa/inet.h>

@interface MTHttpConnectParser ()
{
    NSUInteger _maximumHeaderLength;
    NSMutableData *_buffer;
    bool _finished;
}
@end

@implementation MTHttpConnectParser

- (instancetype)initWithMaximumHeaderLength:(NSUInteger)maximumHeaderLength {
    self = [super init];
    if (self != nil) {
        _maximumHeaderLength = maximumHeaderLength;
        _buffer = [[NSMutableData alloc] init];
    }
    return self;
}

- (MTHttpConnectParserResult)appendData:(NSData *)data trailingData:(NSData **)trailingData statusCode:(NSInteger *)statusCode {
    if (_finished || data.length == 0) {
        return _finished ? MTHttpConnectParserResultFailure : MTHttpConnectParserResultIncomplete;
    }
    [_buffer appendData:data];
    NSData *separator = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    NSRange separatorRange = [_buffer rangeOfData:separator options:0 range:NSMakeRange(0, _buffer.length)];
    if (separatorRange.location == NSNotFound) {
        if (_buffer.length > _maximumHeaderLength) {
            _finished = true;
            return MTHttpConnectParserResultFailure;
        }
        return MTHttpConnectParserResultIncomplete;
    }
    NSUInteger headerLength = NSMaxRange(separatorRange);
    if (headerLength > _maximumHeaderLength) {
        _finished = true;
        return MTHttpConnectParserResultFailure;
    }
    _finished = true;
    NSData *headerData = [_buffer subdataWithRange:NSMakeRange(0, separatorRange.location)];
    const uint8_t *headerBytes = headerData.bytes;
    for (NSUInteger index = 0; index < headerData.length; index++) {
        uint8_t byte = headerBytes[index];
        if (byte == 0 || (byte < 0x20 && byte != '\r' && byte != '\n' && byte != '\t') || byte == 0x7f) {
            return MTHttpConnectParserResultFailure;
        }
        if (byte == '\r' && (index + 1 >= headerData.length || headerBytes[index + 1] != '\n')) {
            return MTHttpConnectParserResultFailure;
        }
        if (byte == '\n' && (index == 0 || headerBytes[index - 1] != '\r')) {
            return MTHttpConnectParserResultFailure;
        }
    }
    NSString *header = [[NSString alloc] initWithData:headerData encoding:NSISOLatin1StringEncoding];
    NSArray<NSString *> *lines = [header componentsSeparatedByString:@"\r\n"];
    NSString *statusLine = [lines firstObject];
    NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^HTTP/[0-9]+\\.[0-9]+[ \\t]+([0-9]{3})(?:[ \\t].*)?$" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:statusLine ?: @"" options:0 range:NSMakeRange(0, statusLine.length)];
    if (match == nil) {
        return MTHttpConnectParserResultFailure;
    }
    for (NSUInteger index = 1; index < lines.count; index++) {
        NSString *line = lines[index];
        NSRange colonRange = [line rangeOfString:@":"];
        if (line.length == 0 || colonRange.location == NSNotFound || colonRange.location == 0) {
            return MTHttpConnectParserResultFailure;
        }
        NSString *fieldName = [line substringToIndex:colonRange.location];
        NSCharacterSet *fieldNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"!#$%&'*+-.^_`|~abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"];
        if ([fieldName rangeOfCharacterFromSet:[fieldNameCharacters invertedSet]].location != NSNotFound) {
            return MTHttpConnectParserResultFailure;
        }
    }
    NSInteger parsedStatusCode = [[statusLine substringWithRange:[match rangeAtIndex:1]] integerValue];
    if (statusCode != nil) {
        *statusCode = parsedStatusCode;
    }
    if (trailingData != nil && _buffer.length > headerLength) {
        *trailingData = [_buffer subdataWithRange:NSMakeRange(headerLength, _buffer.length - headerLength)];
    }
    if (parsedStatusCode >= 200 && parsedStatusCode <= 299) {
        return MTHttpConnectParserResultSuccess;
    } else if (parsedStatusCode == 407) {
        return MTHttpConnectParserResultAuthenticationRequired;
    } else {
        return MTHttpConnectParserResultFailure;
    }
}

@end

NSString *MTHttpConnectAuthority(NSString *host, uint16_t port) {
    if (port == 0) {
        return nil;
    }
    NSString *trimmedHost = [host stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedHost.length == 0 || [trimmedHost rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound || ![trimmedHost canBeConvertedToEncoding:NSASCIIStringEncoding]) {
        return nil;
    }
    NSCharacterSet *controlSet = [NSCharacterSet controlCharacterSet];
    if ([trimmedHost rangeOfCharacterFromSet:controlSet].location != NSNotFound) {
        return nil;
    }
    NSString *unbracketedHost = trimmedHost;
    if ([trimmedHost hasPrefix:@"["] || [trimmedHost hasSuffix:@"]"]) {
        if (![trimmedHost hasPrefix:@"["] || ![trimmedHost hasSuffix:@"]"] || trimmedHost.length <= 2) {
            return nil;
        }
        unbracketedHost = [trimmedHost substringWithRange:NSMakeRange(1, trimmedHost.length - 2)];
    }
    struct in6_addr ip6;
    if ([unbracketedHost containsString:@":"]) {
        if (inet_pton(AF_INET6, unbracketedHost.UTF8String, &ip6) != 1) {
            return nil;
        }
        return [NSString stringWithFormat:@"[%@]:%u", unbracketedHost, port];
    }
    if (unbracketedHost.length > 253) {
        return nil;
    }
    NSCharacterSet *hostnameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-"];
    for (NSString *label in [unbracketedHost componentsSeparatedByString:@"."]) {
        if (label.length == 0 || label.length > 63 || [label hasPrefix:@"-"] || [label hasSuffix:@"-"] || [label rangeOfCharacterFromSet:[hostnameCharacters invertedSet]].location != NSNotFound) {
            return nil;
        }
    }
    return [NSString stringWithFormat:@"%@:%u", unbracketedHost, port];
}

NSData *MTHttpConnectRequest(NSString *host, uint16_t port, NSString *username, NSString *password) {
    NSString *authority = MTHttpConnectAuthority(host, port);
    if (authority == nil || [username containsString:@":"]) {
        return nil;
    }
    NSMutableString *request = [[NSMutableString alloc] initWithFormat:@"CONNECT %@ HTTP/1.1\r\nHost: %@\r\nProxy-Connection: Keep-Alive\r\n", authority, authority];
    if (username != nil || password != nil) {
        NSString *credentials = [NSString stringWithFormat:@"%@:%@", username ?: @"", password ?: @""];
        NSString *encodedCredentials = [[credentials dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
        [request appendFormat:@"Proxy-Authorization: Basic %@\r\n", encodedCredentials];
    }
    [request appendString:@"\r\n"];
    return [request dataUsingEncoding:NSASCIIStringEncoding];
}
