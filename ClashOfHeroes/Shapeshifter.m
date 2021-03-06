//
//  Shapeshifter.m
//  ClashOfHeroes
//
//  Created by Chris Kievit on 06-12-11.
//  Copyright (c) 2011 Pro4all. All rights reserved.
//

#import "Shapeshifter.h"

@implementation Shapeshifter

#define spriteLocationSelf CGRectMake(633, 477, 26, 62)
#define spriteLocationEnemy CGRectMake(628, 285, 25, 59)

- (id)initForPlayer:(Player *)player withTag:(NSInteger)tag
{
    CGRect spriteLocation = spriteLocationEnemy;
    
    //if unit is for local player
    if([[[GCTurnBasedMatchHelper sharedInstance] playerForLocalPlayer].gameCenterInfo.playerID isEqualToString:player.gameCenterInfo.playerID])
    {
        spriteLocation = spriteLocationSelf;
    }
    
    if (self == [super initWithName:@"Shapeshifter" 
                             player:player
    andBaseStatsPhysicalAttackPower:8
                 magicalAttackPower:3
                    physicalDefense:3
                     magicalDefense:3
                       healthPoints:100
                              range:3
                           movement:3
                                tag:tag
                               file:@"sprites.png"
                               rect:spriteLocation]
        )
    {
        [self setMoveDirection: FORWARD | LEFT | RIGHT | BACKWARD];
        [self setAttackDirection: FORWARD | LEFT | RIGHT | BACKWARD];
    }
    
    return self;
}

@end
