//
//  GCTurnBasedMatchHelper.m
//  ClashOfHeroes
//
//  Created by Chris Kievit on 24-11-11.
//  Copyright (c) 2011 Pro4all. All rights reserved.
//

#import "GCTurnBasedMatchHelper.h"
#import "MainMenuViewController.h"
#import "GameViewController.h"
#import "Player.h"
#import "Turn.h"
#import "MatchData.h"
#import "CDPlayer.h"
#import <GameKit/GameKit.h>

#import "Hero.h"
#import "UnitData.h"

@interface GCTurnBasedMatchHelper()

- (BOOL)isGameCenterAvailable;
- (void)synchronizeMatchData:(NSDictionary *)matchData;

@end

@implementation GCTurnBasedMatchHelper

@synthesize gameCenterAvailable, currentMatch, mainMenu = _mainMenu, gameViewController = _gameViewController, currentPlayers = _currentPlayers;

static GCTurnBasedMatchHelper *sharedHelper = nil;

#pragma mark Initialization

- (id)init
{
    if ((self = [super init])) 
    {
        gameCenterAvailable = [self isGameCenterAvailable];
        
        if (gameCenterAvailable) 
        {
            NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
            
            [nc addObserver:self 
                   selector:@selector(authenticationChanged) 
                       name:GKPlayerAuthenticationDidChangeNotificationName 
                     object:nil];
        }
    }
    
    return self;
}

#pragma mark - Authentication

- (void)authenticationChanged
{    
    if ([GKLocalPlayer localPlayer].isAuthenticated && !userAuthenticated)
    {
        NSLog(@"Authentication changed: player authenticated.");
        [self.mainMenu.startButton setEnabled:YES];
        [self.mainMenu.achievementsButton setEnabled:YES];
        [self.mainMenu.LeaderboardButton setEnabled:YES];
        
        CDPlayer *player = [StatsController playerForGameCenterId:[GKLocalPlayer localPlayer].playerID];
        if(!player) player = [StatsController newPlayerAndStatsForPlayerWithGameCenterId:[GKLocalPlayer localPlayer].playerID]; //new user
        
        [self.mainMenu updateStatsWithName:[GKLocalPlayer localPlayer].alias andStats:(CDStats *)player.stats];
        
        userAuthenticated = TRUE;
    } 
    else if (![GKLocalPlayer localPlayer].isAuthenticated && userAuthenticated)
    {
        NSLog(@"Authentication changed: player not authenticated");
        
        [self.mainMenu updateStatsWithName:@"" andStats:nil];
        
        userAuthenticated = FALSE;
    }
}

+ (GCTurnBasedMatchHelper *)sharedInstance
{
    if (!sharedHelper) 
    {
        sharedHelper = [[GCTurnBasedMatchHelper alloc] init];
    }
    return sharedHelper;
}

- (BOOL)isGameCenterAvailable
{
    // check for presence of GKLocalPlayer API
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
    
    // check if the device is running iOS 4.1 or later
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer     
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (gcClass && osVersionSupported);
}

#pragma mark User methods

- (void)authenticateLocalUser
{ 
    if (!gameCenterAvailable) return;
    
    NSLog(@"Authenticating local user...");
    
    if ([GKLocalPlayer localPlayer].authenticated == NO)
    {    
        [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:nil];        
    } 
    else 
    {
        NSLog(@"Already authenticated!");
    }
}

#pragma mark - Match setup

- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers viewController:(UIViewController *)viewController
{
    if (!gameCenterAvailable) return;               
    
    presentingViewController = viewController;
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init]; 
    request.minPlayers = minPlayers;     
    request.maxPlayers = maxPlayers;
    
    GKTurnBasedMatchmakerViewController *mmvc = [[GKTurnBasedMatchmakerViewController alloc] initWithMatchRequest:request];    
    mmvc.turnBasedMatchmakerDelegate = self;
    mmvc.showExistingMatches = YES;
    
    [presentingViewController presentModalViewController:mmvc animated:YES];
}

#pragma mark GKTurnBasedMatchmakerViewControllerDelegate

-(void)turnBasedMatchmakerViewController: (GKTurnBasedMatchmakerViewController *)viewController didFindMatch:(GKTurnBasedMatch *)match
{
    [presentingViewController dismissModalViewControllerAnimated:YES];
    
    //NSLog(@"Matchdata (%d bytes): %@", match.matchData.length, match.matchData);
    NSDictionary *matchData = [NSKeyedUnarchiver unarchiveObjectWithData:match.matchData];
    
    //NSLog(@"MatchData %@", matchData);
    
    self.currentMatch = match;
    
    [self loadPlayerDataWithMatchData:matchData];
}

-(void)turnBasedMatchmakerViewControllerWasCancelled: (GKTurnBasedMatchmakerViewController *)viewController
{
    [presentingViewController dismissModalViewControllerAnimated:YES];
    NSLog(@"has cancelled");
}

-(void)turnBasedMatchmakerViewController: (GKTurnBasedMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    [presentingViewController dismissModalViewControllerAnimated:YES];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error finding match" message:error.localizedDescription delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
    [alert show];
    NSLog(@"Error finding match: %@", error.localizedDescription);
}

-(void)turnBasedMatchmakerViewController: (GKTurnBasedMatchmakerViewController *)viewController playerQuitForMatch:(GKTurnBasedMatch *)match
{
    NSUInteger currentIndex = 
    [match.participants indexOfObject:match.currentParticipant];
    GKTurnBasedParticipant *part;
    
    for (int i = 0; i < [match.participants count]; i++) {
        part = [match.participants objectAtIndex:
                (currentIndex + 1 + i) % match.participants.count];
        if (part.matchOutcome != GKTurnBasedMatchOutcomeQuit) {
            break;
        } 
    }
    NSLog(@"playerquitforMatch, %@, %@", 
          match, match.currentParticipant);
    [match participantQuitInTurnWithOutcome:
     GKTurnBasedMatchOutcomeQuit nextParticipant:part 
                                  matchData:match.matchData completionHandler:nil];
}

#pragma mark - Player data

- (void)loadPlayerDataWithMatchData:(NSDictionary *)dataDictionary
{
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, dataDictionary);
    
    NSMutableArray *identifiers = [NSMutableArray array];
    
    for (GKTurnBasedParticipant *participant in self.currentMatch.participants)
    {
        if(participant.playerID) [identifiers addObject:participant.playerID];
    }
    
    [GKPlayer loadPlayersForIdentifiers:identifiers withCompletionHandler:^(NSArray *players, NSError *error) 
    {
        if (error)
        {
            NSLog(@"Error: %@", error);
        }
        
        if (players)
        {
            _currentPlayers = [NSMutableArray new];
            
            for(GKPlayer *gkplayer in players)
            {
                Player *player = [[Player alloc] initForGKPlayer:gkplayer];
                NSLog(@"add player %@", player.gameCenterInfo.alias);
                [_currentPlayers addObject:player];
            }        
        }
        
        if (dataDictionary) [self synchronizeMatchData:dataDictionary];
             
        if ([[GCTurnBasedMatchHelper sharedInstance] localPlayerIsCurrentParticipant])
        {
            if(self.currentMatch.currentParticipant.lastTurnDate)
            {
                NSLog(@"Load game");
                [self.mainMenu presentGameView];
            }
            else
            {
                NSLog(@"new game");
                [self.mainMenu presentNewGameView];
            }
        }
        else
        {
            COHAlertViewController *alertView = [[COHAlertViewController alloc] initWithTitle:@"Waiting for player" andMessage:@"Waiting for your opponent to make his move."];
            
            alertView.view.frame = self.mainMenu.view.frame;
            alertView.view.center = self.mainMenu.view.center;
            [alertView setTag:1];
            [alertView setDelegate:self];
            [self.mainMenu.view addSubview:alertView.view];
            [alertView show];
        }
    }];
}

- (void)synchronizeMatchData:(NSDictionary *)matchData
{
    //NSLog(@"synchronizeMatchData %@", matchData);
    for (Player *player in self.currentPlayers)
    {
        NSDictionary *playerData = [matchData objectForKey:player.gameCenterInfo.playerID];
        [player setTurnNumber:[[playerData valueForKey:@"turnNumber"] integerValue]];
        
        if (playerData)
        {
            NSDictionary *heroDict = [playerData objectForKey:@"hero"];
            NSDictionary *warriorDict = [playerData objectForKey:@"Warrior"];
            NSDictionary *mageDict = [playerData objectForKey:@"Mage"];
            NSDictionary *rangerDict = [playerData objectForKey:@"Ranger"];
            NSDictionary *priestDict = [playerData objectForKey:@"Priest"];
            NSDictionary *shifterDict = [playerData objectForKey:@"Shapeshifter"];
            
            if (heroDict) 
            {
                Hero *heroUnit = [Hero new];
                
                [heroUnit setHeroName:[heroDict valueForKey:@"heroName"]];
                [heroUnit setCurrentHealth:[[heroDict valueForKey:@"health"] integerValue]];
                [heroUnit setAbilityOne:[heroDict valueForKey:@"abilityOne"]];
                [heroUnit setAbilityTwo:[heroDict valueForKey:@"abilityTwo"]];
                [heroUnit setAbilityThree:[heroDict valueForKey:@"abilityThree"]];
                [heroUnit setAbilityFour:[heroDict valueForKey:@"abilityFour"]];
                
                [heroUnit setBonusRange:[[heroDict valueForKey:@"bonusRange"] integerValue]];
                [heroUnit setBonusPhysicalDefensePower:[[heroDict valueForKey:@"bonusPhysicalDefensePower"] integerValue]];
                [heroUnit setBonusPhysicalAttackPower:[[heroDict valueForKey:@"bonusPhysicalAttackPower"] integerValue]];
                [heroUnit setBonusMovement:[[heroDict valueForKey:@"bonusMovement"] integerValue]];
                [heroUnit setBonusMagicalDefensePower:[[heroDict valueForKey:@"bonusMagicalDefensePower"] integerValue]];
                [heroUnit setBonusMagicalAttackPower:[[heroDict valueForKey:@"bonusMagicalAttackPower"] integerValue]];
                [heroUnit setBonusHealthPoints:[[heroDict valueForKey:@"bonusHealthPoints"] integerValue]];
                
                [player setHero:heroUnit];
            }
            
            NSMutableArray *unitArray = [NSMutableArray array];
            
            if (warriorDict)
            {                
                UnitData *warriorUnit = [[UnitData alloc] initWithType:WARRIOR
                                                                  name:@"Warrior"
                                                            tag:[[warriorDict valueForKey:@"tag"] integerValue]
                                                           andLocation:[[warriorDict valueForKey:@"location"] CGPointValue]];
                [warriorUnit setCurrentHealth:[[warriorDict valueForKey:@"health"] integerValue]];
                [unitArray addObject:warriorUnit];
            }
            
            if (mageDict)
            {
                UnitData *mageUnit = [[UnitData alloc] initWithType:MAGE
                                                               name:@"Mage"
                                                                   tag:[[mageDict valueForKey:@"tag"] integerValue]
                                                           andLocation:[[mageDict valueForKey:@"location"] CGPointValue]];
                [mageUnit setCurrentHealth:[[mageDict valueForKey:@"health"] integerValue]];
                [unitArray addObject:mageUnit];
            }
            
            if (rangerDict)
            {
                UnitData *rangerUnit = [[UnitData alloc] initWithType:RANGER
                                                                 name:@"Ranger"
                                                                   tag:[[rangerDict valueForKey:@"tag"] integerValue]
                                                           andLocation:[[rangerDict valueForKey:@"location"] CGPointValue]];
                [rangerUnit setCurrentHealth:[[rangerDict valueForKey:@"health"] integerValue]];                
                [unitArray addObject:rangerUnit];
            }
            
            if (priestDict)
            {
                UnitData *priestUnit = [[UnitData alloc] initWithType:PRIEST
                                                                 name:@"Priest"
                                                                   tag:[[priestDict valueForKey:@"tag"] integerValue]
                                                          andLocation:[[priestDict valueForKey:@"location"] CGPointValue]];
                NSLog(@"setting current health for unit data: %d", [[priestDict valueForKey:@"health"] integerValue]);
                [priestUnit setCurrentHealth:[[priestDict valueForKey:@"health"] integerValue]];
                [unitArray addObject:priestUnit];
            }
            
            if (shifterDict)
            {
                UnitData *shifterUnit = [[UnitData alloc] initWithType:SHAPESHIFTER
                                                                  name:@"Shapeshifter"
                                                                   tag:[[shifterDict valueForKey:@"tag"] integerValue]
                                                           andLocation:[[shifterDict valueForKey:@"location"] CGPointValue]];
                [shifterUnit setCurrentHealth:[[shifterDict valueForKey:@"health"] integerValue]];
                [unitArray addObject:shifterUnit];
            }
            
            [player setUnitData:unitArray];      
        }
    }
}

#pragma mark - players
- (Player *)playerForLocalPlayer
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    for(Player *player in _currentPlayers)
    {
        if([player.gameCenterInfo.playerID isEqualToString:localPlayer.playerID]) return player;
    }
    
    return nil;
}

- (Player *)playerForEnemyPlayer
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    for(Player *player in _currentPlayers)
    {
        if(![player.gameCenterInfo.playerID isEqualToString:localPlayer.playerID]) return player;
    }
    
    return nil;
}

- (BOOL)localPlayerIsCurrentParticipant
{
    return [self.playerForLocalPlayer.gameCenterInfo.playerID isEqualToString:self.currentMatch.currentParticipant.playerID];
}

#pragma mark - Turns

- (void)endTurn:(Turn *)turn
{   
    Player *localPlayer = [self playerForLocalPlayer];
    
    localPlayer.turnNumber += 1;
    
    MatchData *matchData = [MatchData new];
    [matchData setPlayerOne:localPlayer];
    [matchData setPlayerTwo:[self playerForEnemyPlayer]];    
    
    NSData *compressedData = [NSKeyedArchiver archivedDataWithRootObject:[matchData toDictionary]];
    
    NSLog(@"data size: %d bytes.", compressedData.length);
    
    NSUInteger currentIndex = [self.currentMatch.participants indexOfObject:self.currentMatch.currentParticipant];
    
    GKTurnBasedParticipant *nextParticipant;
    nextParticipant = [self.currentMatch.participants objectAtIndex:((currentIndex + 1) % [self.currentMatch.participants count ])];
    [currentMatch endTurnWithNextParticipant:nextParticipant matchData:compressedData completionHandler:^(NSError *error) {
                                       if (error) {
                                           NSLog(@"%@", error);
                                       }
                                   }];
}

- (void)endMatchWithOutcome:(GKTurnBasedMatchOutcome)outcome
{
    Player *localPlayer = [self playerForLocalPlayer];
    
    localPlayer.turnNumber += 1;
    
    MatchData *matchData = [MatchData new];
    [matchData setPlayerOne:localPlayer];
    [matchData setPlayerTwo:[self playerForEnemyPlayer]];    
    
    NSData *compressedData = [NSKeyedArchiver archivedDataWithRootObject:[matchData toDictionary]];
    
    for (GKTurnBasedParticipant *part in currentMatch.participants) {
        if (part.playerID == localPlayer.gameCenterInfo.playerID) part.matchOutcome = outcome;
        else part.matchOutcome = GKTurnBasedMatchOutcomeLost;
    }
    [currentMatch endMatchInTurnWithMatchData:compressedData 
                            completionHandler:^(NSError *error) {
                                if (error) {
                                    NSLog(@"%@", error);
                                }
                            }];
}

#pragma mark - GameCenterManagerDelegate
- (void)achievementSubmitted:(GKAchievement*)ach error:(NSError*)error
{
    if(!error && ach)
    {
        
        [GKAchievementDescription loadAchievementDescriptionsWithCompletionHandler:^(NSArray *descriptions, NSError *error) {
            if (error != nil) {
                NSLog(@"Error getting achievement descriptions: %@", error);
            }
            
            NSMutableDictionary *achievementDescriptions = [NSMutableDictionary new];
            
            for (GKAchievementDescription *achievementDescription in descriptions) 
            {
                [achievementDescriptions setObject:achievementDescription forKey:achievementDescription.identifier];
            }
            
            GKAchievementDescription *achievementDescription = [achievementDescriptions objectForKey:ach.identifier];
            NSLog(@"You have earned an achievement: %@(%d)!", achievementDescription.title, achievementDescription.maximumPoints);
            [self.gameViewController presentMessage:[NSString stringWithFormat:@"You have earned an achievement: %@(%d)!", achievementDescription.title, achievementDescription.maximumPoints]];
        }];
    }
    else
    {
        NSLog(@"error submitting achievement: %@", [error localizedDescription]);
    }
}

- (void)scoreReported: (NSError*) error
{
    if(!error)
    {
        NSLog(@"Leaderboard updated");
    }
    else
    {
        NSLog(@"error submitting to Leaderboard: %@", [error localizedDescription]);
    }
}

#pragma mark - COHAlertView delegate

- (void)alertView:(COHAlertViewController *)alert wasDismissedWithButtonIndex:(NSInteger)buttonIndex;
{

}

@end
