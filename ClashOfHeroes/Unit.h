//
//  Unit.h
//  ClashOfHeroes
//
//  Created by Chris Kievit on 06-12-11.
//  Copyright (c) 2011 Pro4all. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Upgrade;
@class Player;

typedef enum
{
    TOP = 1,
    BOTTOM = 2,
    LEFT = 4,
    RIGHT = 8,
    TOPLEFT = 16,
    TOPRIGHT = 32,
    BOTTOMLEFT = 64,
    BOTTOMRIGHT = 128
}Direction;

@interface Unit : NSObject
{
    Player *_player;
    
@protected
    NSString *_name;
    Upgrade *_upgrade;
    NSInteger _basePhysicalAttackPower;
    NSInteger _baseMagicalAttackPower;
    NSInteger _basePhysicalDefense;
    NSInteger _baseMagicalDefense;
    NSInteger _baseHealthPoints;
    NSInteger _baseRange;
    NSInteger _baseMovement;
    NSString *_code;
    Direction _moveDirection;
    Direction _attackDirection;
    NSInteger _recievedDamage;
    NSInteger _spriteTag;
}

@property (nonatomic, assign) Player *player;
@property (nonatomic, retain) Upgrade *upgrade;
@property (nonatomic, assign) Direction moveDirection;
@property (nonatomic, assign) Direction attackDirection;
@property (nonatomic) BOOL canAttackTroughAir;
@property (nonatomic) NSInteger spriteTag;

- (id)initWithName:(NSString *)name player:(Player *)player andBaseStatsPhysicalAttackPower:(NSInteger)physicalAttackPower magicalAttackPower:(NSInteger)magicalAttackPower physicalDefense:(NSInteger)physicalDefense magicalDefense:(NSInteger)magicalDefense healthPoints:(NSInteger)healthPoints range:(NSInteger)range movement:(NSInteger)movement;
- (NSInteger)physicalAttackPower;
- (NSInteger)magicalAttackPower;
- (NSInteger)physicalDefense;
- (NSInteger)magicalDefense;
- (NSInteger)healthPoints;
- (NSInteger)range;
- (NSInteger)movement;

- (BOOL)belongsToPlayer:(Player *)player;
- (BOOL)containsDirection:(Direction)direction InDirection:(Direction)directionList;
- (BOOL)canMoveInDirection:(Direction)direction;
- (BOOL)canAttackInDirection:(Direction)direction;

- (BOOL)recieveDamage:(NSInteger)damage;
- (void)reduceDamage:(NSInteger)damage;

//for printing
- (void)setCode:(NSString *)code;
- (NSString *)printCode;

@end
