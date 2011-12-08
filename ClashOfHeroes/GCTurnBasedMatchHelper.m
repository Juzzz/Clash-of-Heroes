//
//  GCTurnBasedMatchHelper.m
//  ClashOfHeroes
//
//  Created by Chris Kievit on 24-11-11.
//  Copyright (c) 2011 Pro4all. All rights reserved.
//

#import "GCTurnBasedMatchHelper.h"
#import "AppDelegate.h"
#import "MainMenuViewController.h"
#import "GameViewController.h"

@interface GCTurnBasedMatchHelper()

- (BOOL)isGameCenterAvailable;

@end

@implementation GCTurnBasedMatchHelper

@synthesize gameCenterAvailable, currentMatch, mainMenu = _mainMenu, gameViewController = _gameViewController, currentPlayers = _currentPlayers;

static GCTurnBasedMatchHelper *sharedHelper = nil;

#pragma mark Initialization

- (id)init
{
    if ((self = [super init])) {
        gameCenterAvailable = [self isGameCenterAvailable];
        if (gameCenterAvailable) {
            NSNotificationCenter *nc = 
            [NSNotificationCenter defaultCenter];
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
    
    if ([GKLocalPlayer localPlayer].isAuthenticated && 
        !userAuthenticated) {
        NSLog(@"Authentication changed: player authenticated.");
        userAuthenticated = TRUE;           
    } else if (![GKLocalPlayer localPlayer].isAuthenticated && 
               userAuthenticated) {
        NSLog(@"Authentication changed: player not authenticated");
        userAuthenticated = FALSE;
    }
    
}

+ (GCTurnBasedMatchHelper *) sharedInstance
{
    if (!sharedHelper) {
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
    if ([GKLocalPlayer localPlayer].authenticated == NO) {     
        [[GKLocalPlayer localPlayer] 
         authenticateWithCompletionHandler:nil];        
    } else {
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
    [self.mainMenu presentGameView];
    
    NSLog(@"did find match, %@", match);
    
    self.currentMatch = match;
    
    [self loadPlayerData];
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
    NSLog(@"playerquitforMatch, %@, %@", match, match.currentParticipant);
}

#pragma mark - Player data

- (void)loadPlayerData
{
    NSMutableArray *identifiers = [[NSMutableArray new] autorelease];
    
    for (GKTurnBasedParticipant *participant in self.currentMatch.participants)
    {
        [identifiers addObject:participant.playerID];
    }
    
    [GKPlayer loadPlayersForIdentifiers:identifiers withCompletionHandler:^(NSArray *players, NSError *error) {
        if (error != nil)
        {
            NSLog(@"Error: %@", error);
        }
        if (players != nil)
        {
            self.currentPlayers = players;
            
            [self.gameViewController updateLabels];           
        }
    }];
}

@end