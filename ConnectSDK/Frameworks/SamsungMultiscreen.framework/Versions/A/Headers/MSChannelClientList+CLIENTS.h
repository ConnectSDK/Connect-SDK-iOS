//
//  NSArray+CLIENTS.h
//  SamsungMultiscreen
//
//  Created by Andres Ortega on 10/4/13.
//  Copyright (c) 2013 Samsung. All rights reserved.
//

#import <Foundation/Foundation.h>

@compatibility_alias MSChannelClientList NSArray;

@class MSChannelClient;

/**
 *  The MSChannel collection
 */
@interface MSChannelClientList (ARRAY)

/**
 *  Returns the client that represents the host
 */
@property (nonatomic,readonly) MSChannelClient *host;

/**
 *  Returns the client in the list that represents your client
 */
@property (nonatomic,readonly) MSChannelClient *me;

/**
 *  Returns a client by id
 *
 *  @param clientId The client uuid
 *
 *  @return a SCChannelClient instance
 */
- (MSChannelClient *)getClientById:(NSString *)clientId;


///---------------------------------------------------------------------------------------
/// @name Get client lists
///---------------------------------------------------------------------------------------

/**
 *  Add a filter and sort block to the client array
 *
 *  @param predicate  The predicate filter
 *  @param comparator The sorting block
 *  @param key        The key for your custom filtered array
 */
- (void)setFilteredClientListPredicate:(NSPredicate *)predicate
                        sortComparator:(NSComparator)comparator
                                forKey:(NSString *)key;

/**
 *  Retrieves an array of filtered clients
 *
 *  @param key The key for your custom filtered array
 *
 *  @return A filtered array of clients
 */
- (NSArray *)filteredClientListForKey:(NSString *)key;

/**
 *  Remove the filtered array of clients
 *
 *  @param key The key for your custom filtered array
 */
- (void)removeFilteredClientListForKey:(NSString *)key;
@end
