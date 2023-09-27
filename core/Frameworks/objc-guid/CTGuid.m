//
//  CTGuid.m
//  Copyright (c) 2012 Thong Nguyen (tumtumtum@gmail.com). All rights reserved.
//  Source: https://code.google.com/p/objc-guid/
//
//  Connect SDK Note:
//  CT has been prepended to all members of this framework to avoid namespace collisions
//

#import "CTGuid.h"

#define ConvertToHexCharLower(x) (((x) >= 0 && (x) <= 9) ? (char)((x) + '0') : (char)((x) - 10 + 'a'))
#define ConvertToHexCharUpper(x) (((x) >= 0 && (x) <= 9) ? (char)((x) + '0') : (char)((x) - 10 + 'A'))
#define IsHexChar(x) ((((x) >= '0' && (x) <= '9') || ((x) >= 'a' && (x) <= 'f') || ((x) >= 'A' && (x) <= 'F')))

@interface CTGuid ()
-(id) initWithCFUUIDBytes:(CFUUIDBytes)bytes;
-(id) initWithBytePointer:(unsigned char*)bytes;
+(BOOL) guidBytesFromString:(NSString*)guidString bytes:(UInt8*)bytes;
@end

@implementation CTGuid

-(id) initWithCoder:(NSCoder*)decoder
{
	if (self = [super init])
	{
		NSUInteger length;
		
		const uint8_t* bytes = [decoder decodeBytesForKey:@"data" returnedLength:&length];
		
		if (length == 16)
		{
			memcpy(data, bytes, length);
		}
	}
	
	return self;
}

-(void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeBytes:&data[0] length:16 forKey:@"data"];
}

+(CTGuid *) emptyGuid
{
	static CTGuid * retval;
	
	if (retval == nil)
	{
		retval = [[CTGuid alloc] init];
	}
	
	return retval;
}

-(id) initWithBytes:(UInt8[16])bytes
{
    return [self initWithBytePointer:&bytes[0]];
}

-(id) initWithCFUUIDBytes:(CFUUIDBytes)bytes
{
	if (self = [super init])
	{
		memcpy(data, &bytes, 16);
	}
	
	return self;
}

-(id) initWithBytePointer:(UInt8*)bytes
{
    if (self = [super init])
    {
		memcpy(data, bytes, 16);
    }
    
    return self;
}

-(id) initWithString:(NSString*)string
{
    if (self = [super init])
    {
		if (![CTGuid guidBytesFromString:string bytes:&data[0]])
		{
			[NSException raise:@"Guid wrong format" format:@"The string %@ is not a value guid", string];
		}
    }
    
    return self;
}

-(NSString*) stringValueWithFormat:(CTGuidFormat)format
{
	int index = 0;
	unichar buffer[32 + 4 + 2];
	
	if (format & CTGuidFormatIncludeBraces)
	{
		buffer[index++] = '{';
	}
	else if (format & CTGuidFormatIncludeParenthesis)
	{
		buffer[index++] = '(';
	}
	
	if (format & CTGuidFormatUpperCase)
	{
		if (format & CTGuidFormatIncludeDashes)
		{
			for (int i = 0; i < 4; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharUpper(c2);
				buffer[index++] = ConvertToHexCharUpper(c1);
			}
			
			buffer[index++] = '-';
			
			for (int i = 4; i < 6; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharUpper(c2);
				buffer[index++] = ConvertToHexCharUpper(c1);
			}
			
			buffer[index++] = '-';
			
			for (int i = 6; i < 8; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharUpper(c2);
				buffer[index++] = ConvertToHexCharUpper(c1);
			}
			
			buffer[index++] = '-';
			
			for (int i = 8; i < 10; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharUpper(c2);
				buffer[index++] = ConvertToHexCharUpper(c1);
			}
			
			buffer[index++] = '-';
			
			for (int i = 10; i < 16; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharUpper(c2);
				buffer[index++] = ConvertToHexCharUpper(c1);
			}
		}
		else
		{
			for (int i = 0; i < 16; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharUpper(c2);
				buffer[index++] = ConvertToHexCharUpper(c1);
			}
		}
	}
	else
	{
		if (format & CTGuidFormatIncludeDashes)
		{
			for (int i = 0; i < 4; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharLower(c2);
				buffer[index++] = ConvertToHexCharLower(c1);
			}
			
			buffer[index++] = '-';
			
			for (int i = 4; i < 6; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharLower(c2);
				buffer[index++] = ConvertToHexCharLower(c1);
			}
			
			buffer[index++] = '-';
			
			for (int i = 6; i < 8; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharLower(c2);
				buffer[index++] = ConvertToHexCharLower(c1);
			}
			
			buffer[index++] = '-';
			
			for (int i = 8; i < 10; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharLower(c2);
				buffer[index++] = ConvertToHexCharLower(c1);
			}
			
			buffer[index++] = '-';
			
			for (int i = 10; i < 16; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharLower(c2);
				buffer[index++] = ConvertToHexCharLower(c1);
			}
		}
		else
		{
			for (int i = 0; i < 16; i++)
			{
				unsigned char c = data[i];
				unsigned char c1 = c & 0x0f;
				unsigned char c2 = (c & 0xf0) >> 4;
				
				buffer[index++] = ConvertToHexCharLower(c2);
				buffer[index++] = ConvertToHexCharLower(c1);
			}
		}
	}		
	if (format & CTGuidFormatIncludeBraces)
	{
		buffer[index++] = '}';
	}
	else if (format & CTGuidFormatIncludeParenthesis)
	{
		buffer[index++] = ')';
	}

	return [NSString stringWithCharacters:buffer length:index];
}

+(CTGuid *) randomGuid
{
	CFUUIDRef uuid = CFUUIDCreate(0);
	CFUUIDBytes bytes = CFUUIDGetUUIDBytes(uuid);
	CFRelease(uuid);
	
	CTGuid * retval = [[CTGuid alloc] initWithCFUUIDBytes:bytes];
	
	return retval;
}
		 
+(CTGuid *) guidFromString:(NSString*)guidString
{
	UInt8 bytes[16];
	
	if ([self guidBytesFromString:guidString bytes:&bytes[0]])
	{
		return [[CTGuid alloc] initWithBytes:bytes];
	}
	
	return nil;
}

+(BOOL) guidBytesFromString:(NSString*)guidString bytes:(UInt8*)bytes
{
	int offset = 0;
	int length = (int)guidString.length;
	
	if (guidString == nil || length == 0)
	{
		return NO;
	}
	
	char firstChar = [guidString characterAtIndex:0];
	memset(bytes, 0, 16);
    
    if (firstChar == '{')
    {
		if (length == 0x26)
		{
			if ([guidString characterAtIndex:0x25] != '}')
			{
				return NO;
			}
		}
		else if (length == 0x22)
		{
			if ([guidString characterAtIndex:0x21] != '}')
			{
				return NO;
			}
		}
		else 
		{
			return NO;
		}
        
        offset = 1;
    }
    else if (firstChar == '(')
    {
        if (length == 0x26)
		{
			if ([guidString characterAtIndex:0x25] != ')')
			{
				return NO;
			}
		}
		else if (length == 0x22)
		{
			if ([guidString characterAtIndex:0x21] != ')')
			{
				return NO;
			}
		}
		else 
		{
			return NO;
		}
        
        offset = 1;
    }
    else if (length != 0x24 && length != 0x20)
    {
        return NO;
    }
	
	if ((offset == 1 && length == 0x26) || (offset == 0 && length == 0x24))
	{
		if ((([guidString characterAtIndex:8 + offset] != '-') || ([guidString characterAtIndex:13 + offset] != '-'))
			|| (([guidString characterAtIndex:0x12 + offset] != '-' || ([guidString characterAtIndex:0x17 + offset] != '-'))))
		{
			return NO;
		}
	}
    
	int x = 0;
	int dataIndex = 0;
    
    for (int i = 0, j = 0; i < guidString.length; i++, dataIndex++)
    {
        unichar c = [guidString characterAtIndex:i];
        
        if (c == '{' || c == '}' || c == '-')
        {
            continue;
        }
        
        int shift;
		int mask;
		
		x = j / 2;
        
        if (j % 2 == 0)
        {
            shift = 4;
            mask = 0xf0;
        }
        else
        {
            shift = 0;
            mask = 0x0f;
        }
        
        if (x >= 16)
        {
            return NO;
        }
        
        if (c >= 'a' && c <= 'f')
        {
            bytes[x] |= (((c - 'a' + 10) << shift) & mask);
        }
        else if (c >= 'A' && c <= 'F')
        {
            bytes[x] |= (((c - 'A' + 10) << shift) & mask);
        }
        else if (c >= '0' && c <= '9')
        {
            bytes[x] |= (((c - '0') << shift) & mask);
        }
        else 
        {
            return NO;
        }
        
        j++;
    }
	
	return x == 15;
}

-(BOOL) isEqual:(id)other
{
	if (other == self)
	{
		return YES;
	}
	
    if (other == nil || [other class] != CTGuid.class)
	{
        return NO;
	}
	
    return memcmp(&data[0], ((CTGuid *)other)->data, 16) == 0;
}

-(NSUInteger) hash
{
	register UInt32* intData = (UInt32*)&data[0];
	
	return intData[0] ^ intData[1] ^ intData[2] ^ intData[3];
}

-(CFUUIDBytes) uuidBytes
{
	CFUUIDBytes retval;
	
	memcpy(&retval, data, 16);
	
	return retval;
}

-(void) byteDataToBuffer:(UInt8*)bytes
{
    memcpy(bytes, data, 16);
}

-(BOOL) isEmpty
{
	return [self isEqual:CTGuid.emptyGuid];
}

-(NSString*) stringValue
{
	return [self stringValueWithFormat:CTGuidFormatDashed];
}

-(NSString*) description
{
	return [self stringValueWithFormat:CTGuidFormatDashed];
}

-(NSString*) compactStringValue
{
	return [self stringValueWithFormat:CTGuidFormatCompact];
}

-(id) copyWithZone:(NSZone*)zone
{
	CTGuid * retval = [[CTGuid alloc] initWithBytes:data];

	return retval;
}

@end
