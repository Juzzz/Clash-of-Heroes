//
//  Turn.h
//  ClashOfHeroes
//
//  Created by Chris Kievit on 09-01-12.
//  Copyright (c) 2012 Pro4all. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Turn : NSObject

/**
 Deze twee arrays bevatten NSDictionairies. Deze Dicts bevatten key/value pairs voor de actie die begaan is.
 Bijvoorbeeld: Movement array bevat per Move-actie een array met source-unit, source-coord en destination-coord.
 **/
@property (nonatomic, strong) NSMutableArray *movements;
@property (nonatomic, strong) NSMutableArray *actions;

@property (nonatomic, strong) NSObject *hero;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;

@end
