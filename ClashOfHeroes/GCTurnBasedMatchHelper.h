//
//  GCTurnBasedMatchHelper.h
//  ClashOfHeroes
//
//  Created by Chris Kievit on 24-11-11.
//  Copyright (c) 2011 Pro4all. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "GameCenterManager.h"

@class MainMenuViewController;
@class GameViewController;
@class Player;
@class Turn;

@interface GCTurnBasedMatchHelper : NSObject <GKTurnBasedMatchmakerViewControllerDelegate, GameCenterManagerDelegate>
{
    BOOL gameCenterAvailable;
    BOOL userAuthenticated;
    UIViewController *presentingViewController;
}

@property (assign, readonly) BOOL gameCenterAvailable;
@property (retain) GKTurnBasedMatch * currentMatch;
@property (nonatomic, retain) NSMutableArray *currentPlayers;
@property (nonatomic, retain) MainMenuViewController *mainMenu;
@property (nonatomic, retain) GameViewController *gameViewController;

- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers viewController:(UIViewController *)viewController;
+ (GCTurnBasedMatchHelper *)sharedInstance;
- (void)authenticateLocalUser;
- (void)loadPlayerDataWithMatchData:(NSDictionary *)dataDictionary;
- (Player *)playerForLocalPlayer;
- (Player *)playerForEnemyPlayer;
- (void)endTurn:(Turn *)turn;
- (BOOL)localPlayerIsCurrentParticipant;

@end
