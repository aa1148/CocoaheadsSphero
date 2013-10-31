//
//  MainViewController.m
//  CocoaheadsSphero
//
//  Created by Brian Buck on 10/30/13.
//  Copyright (c) 2013 Brian Buck. All rights reserved.
//

#import "MainViewController.h"
#import "RobotKit/RobotKit.h"
#import "RobotUIKit/RobotUIKit.h"

#define ARC4RANDOM_MAX  0x100000000

@interface MainViewController ()

@end

@implementation MainViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    /*Register for application lifecycle notifications so we known when to connect and disconnect from the robot*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    /*Only start the blinking loop when the view loads*/
    robotOnline = NO;
    
    calibrateHandler = [[RUICalibrateGestureHandler alloc] initWithView:self.view];
}

-(void)appWillResignActive:(NSNotification*)notification
{
    /*When the application is entering the background we need to close the connection to the robot*/
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKDeviceConnectionOnlineNotification object:nil];
    [RKRGBLEDOutputCommand sendCommandWithRed:0.0 green:0.0 blue:0.0];
    [[RKRobotProvider sharedRobotProvider] closeRobotConnection];
}

-(void)appDidBecomeActive:(NSNotification*)notification
{
    /*When the application becomes active after entering the background we try to connect to the robot*/
    [self setupRobotConnection];
}

- (void)handleRobotOnline
{
    /*The robot is now online, we can begin sending commands*/
    if(!robotOnline)
    {
        /*Only start the blinking loop once*/
        [self toggleLED];
//        [self driveforward];
    }
    robotOnline = YES;
}

- (void)toggleLED
{
    /*Toggle the LED on and off*/
    if (ledON)
    {
        ledON = NO;
        [RKRGBLEDOutputCommand sendCommandWithRed:0.0 green:0.0 blue:0.0];
    }
    else
    {
        ledON = YES;
        
        // random rgb colors
        double redRand = ((double)arc4random() / ARC4RANDOM_MAX);
        double greenRand = ((double)arc4random() / ARC4RANDOM_MAX);
        double blueRand = ((double)arc4random() / ARC4RANDOM_MAX);
        
        [RKRGBLEDOutputCommand sendCommandWithRed:redRand green:greenRand blue:blueRand];
    }
    [self performSelector:@selector(toggleLED) withObject:nil afterDelay:0.5];
}

- (void)stop
{
    [RKRollCommand sendStop];
}

- (void)driveforward
{
    [RKRollCommand sendCommandWithHeading:0.0 velocity:0.5];
    [self performSelector:@selector(stop) withObject:nil afterDelay:2.0];
}

- (void)setupRobotConnection
{
    /*Try to connect to the robot*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRobotOnline) name:RKDeviceConnectionOnlineNotification object:nil];
    
    if ([[RKRobotProvider sharedRobotProvider] isRobotUnderControl])
    {
        [[RKRobotProvider sharedRobotProvider] openRobotConnection];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
