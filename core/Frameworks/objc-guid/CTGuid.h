//
//  CTGuid.m
//  Copyright (c) 2012 Thong Nguyen (tumtumtum@gmail.com). All rights reserved.
//  Source: https://code.google.com/p/objc-guid/
//
//  Connect SDK Note:
//  CT has been prepended to all members of this framework to avoid namespace collisions
//

#import <Foundation/Foundation.h>

typedef enum
{
	CTGuidFormatCompact = 0,
	CTGuidFormatIncludeDashes = 1,
	CTGuidFormatIncludeBraces = 2,
	CTGuidFormatIncludeParenthesis = 4,
	CTGuidFormatUpperCase = 8,
	CTGuidFormatDashed = CTGuidFormatIncludeDashes,
	CTGuidFormatBraces = CTGuidFormatIncludeDashes | CTGuidFormatIncludeBraces,
	CTGuidFormatParenthesis = CTGuidFormatIncludeDashes | CTGuidFormatIncludeParenthesis
}
CTGuidFormat;

@interface CTGuid : NSObject<NSCoding>
{
@private
    UInt8 data[16];
}

-(id) initWithString:(NSString*)string;
-(id) initWithBytes:(UInt8[16])bytes;
-(NSString*) stringValue;
-(CFUUIDBytes) uuidBytes;
-(void) byteDataToBuffer:(UInt8*)bytes;
-(NSString*) stringValueWithFormat:(CTGuidFormat)format;
-(BOOL) isEmpty;
-(BOOL) isEqual:(id)object;
-(NSUInteger) hash;
-(NSString*) description;

+(CTGuid *) randomGuid;
+(CTGuid *) emptyGuid;
+(CTGuid *) guidFromString:(NSString*)guidString;

@end
