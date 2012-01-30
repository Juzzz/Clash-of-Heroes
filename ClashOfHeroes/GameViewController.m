//
//  GameViewController.m
//  ClashOfHeroes
//
//  Created by Chris Kievit on 22-11-11.
//  Copyright Pro4all 2011. All rights reserved.
//

//
// RootViewController + iAd
// If you want to support iAd, use this class as the controller of your iAd
//

#import <GameKit/GameKit.h>
#import "cocos2d.h"
#import "GameViewController.h"
#import "GameConfig.h"
#import "GameLayer.h"
#import "GCTurnBasedMatchHelper.h"
#import "Turn.h"
#import "Player.h"
#import "COHAlertViewController.h"
#import "Phase.h"
#import "MovementPhase.h"
#import "CombatPhase.h"
#import "Unit.h"

@interface GameViewController()
- (void)setPlayerOneLabelsHidden:(BOOL)hidden;
- (void)setPlayerTwoLabelsHidden:(BOOL)hidden;
- (UIImage *)imageForUnitName:(NSString *)unitName;
@end

@implementation GameViewController
@synthesize playerOneLabel;
@synthesize playerOneUnitImageView;
@synthesize playerOneUnitNameLabel;
@synthesize playerOneUnitHealthLabel;
@synthesize playerOneUnitAttackPowerLabel;
@synthesize playerOneUnitDefenseLabel;
@synthesize playerOneHealthLabel;
@synthesize playerOneAttackLabel;
@synthesize playerOneDefenseLabel;
@synthesize playerTwoLabel;
@synthesize playerTwoUnitImageView;
@synthesize playerTwoUnitNameLabel;
@synthesize playerTwoUnitHealthLabel;
@synthesize playerTwoUnitAttackPowerLabel;
@synthesize playerTwoUnitDefenseLabel;
@synthesize playerTwoHealthLabel;
@synthesize playerTwoAttackLabel;
@synthesize playerTwoDefenseLabel;
@synthesize phaseLabel;
@synthesize movesLabel;
@synthesize gameLayer = _gameLayer;

- (void)setupCocos2D 
{
    EAGLView *glView = [EAGLView viewWithFrame:self.view.bounds
                                   pixelFormat:kEAGLColorFormatRGB565	// kEAGLColorFormatRGBA8
                                   depthFormat:0                        // GL_DEPTH_COMPONENT16_OES
                        ];
    glView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:glView atIndex:0];
    [[CCDirector sharedDirector] setOpenGLView:glView];
    [[CCDirector sharedDirector] runWithScene:[GameLayer sceneWithDelegate:self]];
}

- (void)updateLabels
{
    Player *playerOne = [[GCTurnBasedMatchHelper sharedInstance] playerForLocalPlayer];
    Player *playerTwo = [[GCTurnBasedMatchHelper sharedInstance] playerForEnemyPlayer];
    
    if(playerOne) [playerOneLabel setText:playerOne.gameCenterInfo.alias];
    if(playerTwo) [playerOneLabel setText:playerTwo.gameCenterInfo.alias];
    
    [phaseLabel setText:[self.gameLayer.currentPhase description]];
    [movesLabel setText:[NSString stringWithFormat:@"Remaining moves: %d", self.gameLayer.currentPhase.remainingMoves]];
    
}

- (IBAction)endTurn:(id)sender {
    COHAlertViewController *alertView = [[COHAlertViewController alloc] initWithTitle:@"End turn" andMessage:@"Are you sure you want to end this turn? This will cancel any remaining moves."];
    
    alertView.view.frame = self.view.frame;
    alertView.view.center = self.view.center;
    [alertView setTag:1];
    [alertView setDelegate:self];
    [self.view addSubview:alertView.view];
    [alertView show];
}

- (IBAction)endPhase:(id)sender {    
    COHAlertViewController *alertView = [[COHAlertViewController alloc] initWithTitle:@"End phase" andMessage:@"Are you sure you want to end this phase? This will cancel any remaining moves."];
    alertView.view.frame = self.view.frame;
    alertView.view.center = self.view.center;
    [alertView setTag:2];
    [alertView setDelegate:self];
    [self.view addSubview:alertView.view];
    [alertView show];
}

- (IBAction)backButtonPressed:(id)sender 
{
    COHAlertViewController *alertView = [[COHAlertViewController alloc] initWithTitle:@"Back to menu" andMessage:@"Are you sure you want to quit? This will revert any moves you have made."];
    
    alertView.view.frame = self.view.frame;
    alertView.view.center = self.view.center;
    [alertView setTag:3];
    [alertView setDelegate:self];
    [self.view addSubview:alertView.view];
    [alertView show];
}

#pragma mark - COHAlertView delegate

- (void)alertView:(COHAlertViewController *)alert wasDismissedWithButtonIndex:(NSInteger)buttonIndex;
{
    NSLog(@"buttonindex: %d", buttonIndex);
    if (buttonIndex == 2)
    {
        if (alert.tag == 1)
        {
            Turn *lastTurn = [Turn new];
            
            NSMutableDictionary *move = [NSMutableDictionary dictionary];
            [move setValue:@"piece 24" forKey:@"piece"];
            
            NSMutableDictionary *action = [NSMutableDictionary dictionary];
            [action setValue:@"Attack" forKey:@"action"];
            
            [lastTurn.movements addObject:move];
            [lastTurn.actions addObject:action];
            
            [[GCTurnBasedMatchHelper sharedInstance] endTurn:lastTurn];
        }
        else if (alert.tag == 2)
        {
            [self.gameLayer.currentPhase endPhase];
        }
        else if (alert.tag == 3)
        {
            [self.gameLayer removeUnits];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    
    //[self updateLabels];
}

#pragma mark - View lifecycle

- (void) viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [super viewWillAppear:animated];
}

- (void)viewDidLoad 
{
    [super viewDidLoad];    
    [self setupCocos2D];
    
    [[GCTurnBasedMatchHelper sharedInstance] setGameViewController:self];
    [self updateLabels];
    
    if (![[GCTurnBasedMatchHelper sharedInstance] localPlayerIsCurrentParticipant])
    {
        COHAlertViewController *alertView = [[COHAlertViewController alloc] initWithTitle:@"Waiting for player" andMessage:@"Waiting for your opponent to make his move."];
        
        alertView.view.frame = self.view.frame;
        alertView.view.center = self.view.center;
        [alertView setTag:3];
        [alertView setDelegate:self];
        [self.view addSubview:alertView.view];
        [alertView show];
    }
}


- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [self setPlayerOneLabel:nil];
    [self setPlayerTwoLabel:nil];
    [self setPhaseLabel:nil];
    [self setMovesLabel:nil];
    [self setPlayerOneUnitAttackPowerLabel:nil];
    [self setPlayerOneUnitImageView:nil];
    [self setPlayerOneUnitNameLabel:nil];
    [self setPlayerOneUnitHealthLabel:nil];
    [self setPlayerOneUnitDefenseLabel:nil];
    [self setPlayerTwoUnitImageView:nil];
    [self setPlayerTwoUnitNameLabel:nil];
    [self setPlayerTwoUnitHealthLabel:nil];
    [self setPlayerTwoUnitAttackPowerLabel:nil];
    [self setPlayerTwoUnitDefenseLabel:nil];
    [self setPlayerOneHealthLabel:nil];
    [self setPlayerOneAttackLabel:nil];
    [self setPlayerOneDefenseLabel:nil];
    [self setPlayerTwoHealthLabel:nil];
    [self setPlayerTwoAttackLabel:nil];
    [self setPlayerTwoDefenseLabel:nil];
    [super viewDidUnload];
    
    [[CCDirector sharedDirector] end];
}

- (void)setPlayerOneLabelsHidden:(BOOL)hidden
{
    [self.playerOneUnitImageView setHidden:hidden];
    [self.playerOneUnitNameLabel setHidden:hidden];
    [self.playerOneUnitAttackPowerLabel setHidden:hidden];
    [self.playerOneUnitDefenseLabel setHidden:hidden];
    [self.playerOneUnitHealthLabel setHidden:hidden];
    [self.playerOneHealthLabel setHidden:hidden];
    [self.playerOneAttackLabel setHidden:hidden];
    [self.playerOneDefenseLabel setHidden:hidden];
}

- (void)setPlayerTwoLabelsHidden:(BOOL)hidden
{
    [self.playerTwoUnitImageView setHidden:hidden];
    [self.playerTwoUnitNameLabel setHidden:hidden];
    [self.playerTwoUnitAttackPowerLabel setHidden:hidden];
    [self.playerTwoUnitDefenseLabel setHidden:hidden];
    [self.playerTwoUnitHealthLabel setHidden:hidden];
    [self.playerTwoHealthLabel setHidden:hidden];
    [self.playerTwoAttackLabel setHidden:hidden];
    [self.playerTwoDefenseLabel setHidden:hidden];
}

- (UIImage *)imageForUnitName:(NSString *)unitName
{
    UIImage *image = nil;
    
    //imager
    if([unitName isEqualToString:@"Warrior"])
        image = [UIImage imageNamed:@"rune_warrior.png"];
    else if([unitName isEqualToString:@"Mage"])
        image = [UIImage imageNamed:@"rune_mage.png"];
    else if([unitName isEqualToString:@"Ranger"])
        image = [UIImage imageNamed:@"rune_ranger.png"];
    else if([unitName isEqualToString:@"Priest"])
        image = [UIImage imageNamed:@"rune_priest.png"];
    else if([unitName isEqualToString:@"Shapeshifter"])
        image = [UIImage imageNamed:@"rune_shapeshifter.png"];
    else
        image = [UIImage imageNamed:@"rune_hero.png"];
    
    return image;
}

- (void)updatePlayerOneUnit:(Unit *)unit
{
    UIImage *image = nil;
    
    if(unit)
    {
        [self setPlayerOneLabelsHidden:NO];
        
        image = [self imageForUnitName:unit.name];
        
        [self.playerOneUnitNameLabel setText:unit.name];
        [self.playerOneUnitAttackPowerLabel setText:[NSString stringWithFormat:@"%d", unit.physicalDefense]];
        [self.playerOneUnitDefenseLabel setText:[NSString stringWithFormat:@"%d", unit.physicalDefense]];
        [self.playerOneUnitHealthLabel setText:[NSString stringWithFormat:@"%d", unit.healthPoints]];
    }
    else
    {
        [self setPlayerOneLabelsHidden:YES];
    }
    
    [self.playerOneUnitImageView setImage:image];
}

- (void)updatePlayerTwoUnit:(Unit *)unit
{
    UIImage *image = nil;
    
    if(unit)
    {
        [self setPlayerTwoLabelsHidden:NO];
        
        image = [self imageForUnitName:unit.name];
        
        [self.playerTwoUnitNameLabel setText:unit.name];
        [self.playerTwoUnitAttackPowerLabel setText:[NSString stringWithFormat:@"%d", unit.physicalDefense]];
        [self.playerTwoUnitDefenseLabel setText:[NSString stringWithFormat:@"%d", unit.physicalDefense]];
        [self.playerTwoUnitHealthLabel setText:[NSString stringWithFormat:@"%d", unit.healthPoints]];
    }
    else
    {
        [self setPlayerTwoLabelsHidden:YES];
    }
    
    [self.playerTwoUnitImageView setImage:image];
}

- (void)hidePlayerLabels
{
    [self updatePlayerOneUnit:nil];
    [self updatePlayerTwoUnit:nil];
}

- (void)dealloc {
    [playerOneLabel release];
    [playerTwoLabel release];
    [phaseLabel release];
    [movesLabel release];
    [playerOneUnitAttackPowerLabel release];
    [playerOneUnitImageView release];
    [playerOneUnitNameLabel release];
    [playerOneUnitHealthLabel release];
    [playerOneUnitDefenseLabel release];
    [playerTwoUnitImageView release];
    [playerTwoUnitNameLabel release];
    [playerTwoUnitHealthLabel release];
    [playerTwoUnitAttackPowerLabel release];
    [playerTwoUnitDefenseLabel release];
    [playerOneHealthLabel release];
    [playerOneAttackLabel release];
    [playerOneDefenseLabel release];
    [playerTwoHealthLabel release];
    [playerTwoAttackLabel release];
    [playerTwoDefenseLabel release];
    [super dealloc];
}


@end

