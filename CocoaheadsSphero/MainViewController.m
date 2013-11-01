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
#define BLINK_TIME 5

@interface MainViewController ()
{
    BOOL ledON, robotOnline, isBlinkingColors;
    RUICalibrateGestureHandler * calibrateHandler;
}

@property (strong, nonatomic) IBOutlet UIButton * blinkColorButton;

@end

@implementation MainViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    /* Register for application lifecycle notifications so we known when to connect and disconnect robot */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    
    robotOnline = NO;
    
    /* In RK UI you can initialize a built in gesture handler control for robot calibration */
    calibrateHandler = [[RUICalibrateGestureHandler alloc] initWithView:self.view];
}

-(void)appWillResignActive:(NSNotification*)notification
{
    /* When the application is entering the background we need to close the connection to the robot */
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKDeviceConnectionOnlineNotification object:nil];
    [[RKRobotProvider sharedRobotProvider] closeRobotConnection];
}

-(void)appDidBecomeActive:(NSNotification*)notification
{
    /* When the application becomes active after entering the background we try to connect to the robot */
    [self setupRobotConnection];
}

- (void)setupRobotConnection
{
    /* Try to connect to the robot */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRobotOnline) name:RKDeviceConnectionOnlineNotification object:nil];
    
    if ([[RKRobotProvider sharedRobotProvider] isRobotUnderControl])
    {
        [[RKRobotProvider sharedRobotProvider] openRobotConnection];
    }
}

- (void)handleRobotOnline
{
    /* The robot is now online, we can begin sending commands */
    robotOnline = YES;
    isBlinkingColors = NO;
}

/**
 Call this on backgroud queue
 */
- (void)toggleLED
{
    if (isBlinkingColors) // we are already blinking, punt.
    {
        return;
    }
    
    /* Toggle the LED on and off */
    if (ledON)
    {
        ledON = isBlinkingColors = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.blinkColorButton setTitle:@"Blink Color" forState:UIControlStateNormal];
        });
        
        [RKRGBLEDOutputCommand sendCommandWithRed:0.0 green:0.0 blue:0.0];
    }
    else
    {
        ledON = isBlinkingColors = YES;

        time_t loopTS;
        time_t startTS = loopTS = time(&startTS);
        do
        {
            // random rgb colors
            float redRand = ((float)arc4random() / ARC4RANDOM_MAX);
            float greenRand = ((float)arc4random() / ARC4RANDOM_MAX);
            float blueRand = ((float)arc4random() / ARC4RANDOM_MAX);
            
            [RKRGBLEDOutputCommand sendCommandWithRed:redRand green:greenRand blue:blueRand];
            
            time_t current;
            loopTS = time(&current);
            
            NSLog(@"blink LED time: %u", (uint)(loopTS-startTS));
            
        } while ((loopTS-startTS) < BLINK_TIME);
        
        isBlinkingColors = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.blinkColorButton setTitle:@"Color Off" forState:UIControlStateNormal];
        });
    }
}

- (void)stop
{
    [RKRollCommand sendStop];
}

- (void)driveforward:(float)heading;
{
    assert(heading >= 0.f && heading < 360.f);
    // velocity range 0-1 where 0 = stop and 1 = full throttle
    [RKRollCommand sendCommandWithHeading:heading velocity:0.75f];
}

#pragma mark - UI action

- (IBAction)blinkColors:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self toggleLED];
    });
}

- (IBAction)driveStop:(id)sender
{
    [self stop];
}

- (IBAction)drive0Heading:(id)sender
{
    [self driveforward:0.f];
}

- (IBAction)drive90Heading:(id)sender
{
    [self driveforward:90.f];
}

- (IBAction)drive180Heading:(id)sender
{
    [self driveforward:180.f];
}

- (IBAction)drive270Heading:(id)sender
{
    [self driveforward:270.f];
}

@end
