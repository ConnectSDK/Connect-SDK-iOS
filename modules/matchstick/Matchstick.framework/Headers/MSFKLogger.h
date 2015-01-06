//
// Created by Jiang Lu on 14-4-1.
// Copyright (C) 2013-2014, Infthink (Beijing) Technology Co., Ltd.
//

#import <Foundation/Foundation.h>
#import <stdarg.h>

@protocol MSFKLoggerDelegate;

/**
 * A singleton object used for logging by the framework. By default, log messages are written to
 * NSLog() in debug builds and are discarded otherwise. If a delegate is assigned, the formatted
 * log messages are passed to the delegate instead.
 */

@interface MSFKLogger : NSObject

/** The delegate to pass log messages to. */
@property(nonatomic, weak) id<MSFKLoggerDelegate> delegate;
/**
 * Returns the MSFKLogger singleton instance.
 */
+ (MSFKLogger *)sharedInstance;

/**
 * Logs a message.
 *
 * @param function The calling function, normally <code>__func__</code>.
 * @param format The format string.
 */
- (void)logFromFunction:(const char *)function message:(NSString *)format, ...
NS_FORMAT_FUNCTION(2, 3);

@end

/**
 * The MSFKLogger delegate interface.
 */
@protocol MSFKLoggerDelegate

/**
 * Logs a message.
 *
 * @param function The calling function, normally <code>__func__</code>.
 * @param message The log message.
 */
- (void)logFromFunction:(const char *)function message:(NSString *)message;

@end


/**
 * @macro MSFKLog
 *
 * A convenience macro for logging to the MSFKLogger singleton. This is a drop-in replacement
 * for NSLog().
 */
#define MSFKLog(FORMAT, ...) \
[[MSFKLogger sharedInstance] logFromFunction:__func__ message:FORMAT, ##__VA_ARGS__]