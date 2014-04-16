//
//  Guid.m
//  Copyright (c) 2012 Thong Nguyen (tumtumtum@gmail.com). All rights reserved.
//  Source: https://code.google.com/p/objc-guid/
//

#import <Foundation/Foundation.h>

typedef enum
{
	GuidFormatCompact = 0,
	GuidFormatIncludeDashes = 1,
	GuidFormatIncludeBraces = 2,
	GuidFormatIncludeParenthesis = 4,
	GuidFormatUpperCase = 8,
	GuidFormatDashed = GuidFormatIncludeDashes,
	GuidFormatBraces = GuidFormatIncludeDashes | GuidFormatIncludeBraces,
	GuidFormatParenthesis = GuidFormatIncludeDashes | GuidFormatIncludeParenthesis
}
GuidFormat;

@interface Guid : NSObject<NSCoding>
{
@private
    UInt8 data[16];
}

-(id) initWithString:(NSString*)string;
-(id) initWithBytes:(UInt8[16])bytes;
-(NSString*) stringValue;
-(CFUUIDBytes) uuidBytes;
-(void) byteDataToBuffer:(UInt8*)bytes;
-(NSString*) stringValueWithFormat:(GuidFormat)format;
-(BOOL) isEmpty;
-(BOOL) isEqual:(id)object;
-(NSUInteger) hash;
-(NSString*) description;

+(Guid*) randomGuid;
+(Guid*) emptyGuid;
+(Guid*) guidFromString:(NSString*)guidString;

@end
