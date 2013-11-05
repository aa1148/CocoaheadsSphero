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

#pragma mark - RK functions

/**
 Do stuff to restore some initial state
 */
- (void)restoreRobotState
{
    //Turn on Stabilization
    [RKStabilizationCommand sendCommandWithState:(RKStabilizationStateOn)];
    //Send Roll Stop
    [RKRollCommand sendStop];
    //Change heading back to 0
    [RKRollCommand sendCommandWithHeading:0 velocity:0.f];
    [RKRGBLEDOutputCommand sendCommandWithRed:0.f green:0.f blue:1.f];
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

- (void)driveforward:(int)heading;
{
    assert(heading >= 0 && heading < 360);
    // velocity range 0-1 where 0 = stop and 1 = full throttle
    [RKRollCommand sendCommandWithHeading:heading velocity:0.75f];
}

/**
 Macro : Sphero rolls a square!
 */
- (void)runSquareShapeRollMacro
{
    //Create a new macro object to send to Sphero
    RKMacroObject *macro = [RKMacroObject new];
    
    //Change Color to green
    [macro addCommand:[RKMCRGB commandWithRed:0.f green:1.f blue:0.f delay:0]];
    //Sphero drives forward in the 0 angle
    [macro addCommand:[RKMCRoll commandWithSpeed:0.75f heading:0 delay:750]];
    [macro addCommand:[RKMCRoll commandWithSpeed:0.f heading:0 delay:3000]];
    
    //Have Sphero to come to stop to make sharp turn
    [macro addCommand:[RKMCWaitUntilStop commandWithDelay:500]];
    
    //Change Color to blue
    [macro addCommand:[RKMCRGB commandWithRed:0.f green:0.f blue:1.f delay:0]];
    //Sphero drives forward in the 90 angle
    [macro addCommand:[RKMCRoll commandWithSpeed:0.75f heading:90 delay:750]];
    [macro addCommand:[RKMCRoll commandWithSpeed:0.f heading:90 delay:3000]];
    //Have Sphero to come to stop to make sharp turn
    [macro addCommand:[RKMCWaitUntilStop commandWithDelay:500]];
    
    //Change Color to yellow
    [macro addCommand:[RKMCRGB commandWithRed:1.f green:1.f blue:0.f delay:0]];
    //Sphero drives forward in the 180 angle
    [macro addCommand:[RKMCRoll commandWithSpeed:0.75f heading:180 delay:750]];
    [macro addCommand:[RKMCRoll commandWithSpeed:0.f heading:180 delay:3000]];
    //Have Sphero to come to stop to make sharp turn
    [macro addCommand:[RKMCWaitUntilStop commandWithDelay:500]];
    
    //Change Color to red
    [macro addCommand:[RKMCRGB commandWithRed:1.f green:0.f blue:0.f delay:0]];
    //Sphero drives forward in the 270 angle
    [macro addCommand:[RKMCRoll commandWithSpeed:0.75f heading:270 delay:750]];
    [macro addCommand:[RKMCRoll commandWithSpeed:0.f heading:270 delay:3000]];
    //Have Sphero to come to stop to make sharp turn
    [macro addCommand:[RKMCWaitUntilStop commandWithDelay:500]];
    
    //Change Color to white
    [macro addCommand:[RKMCRGB commandWithRed:1.f green:1.f blue:1.f delay:0]];
    //Sphero comes to stop in the 0 angle
    [macro addCommand:[RKMCRoll commandWithSpeed:0.f heading:0 delay:3000]];
  
    //Send full command dowm to Sphero to play
    [macro playMacro];
}

/**
 Macro : Sphero rolls a figure 8!!
 */
- (void)runFigureEightRollMacro
{
    //Create a new macro object to send to Sphero
    RKMacroObject *macro = [RKMacroObject new];
    
    //Tell Robot to look forward and to start driving
    [macro addCommand:[RKMCRoll commandWithSpeed:0.4f heading:0 delay:1000]];
    
    //Start Loop
    [macro addCommand:[RKMCLoopFor commandWithRepeats:4]];
    
    ///Tell Robot to perform 1st turn in the postive direction.
    [macro addCommand:[RKMCRotateOverTime commandWithRotation:360 delay:3000]];
    
    //Add delay to allow the rotateovertime command to perform.
    [macro addCommand:[RKMCDelay commandWithDelay:3000]];
    
    //Rotate to pertform the 2nd turn in the negitive direction
    [macro addCommand:[RKMCRotateOverTime commandWithRotation:-360 delay:3000]];
    
    //Add delay to allow the rotateovertime command to perform.
    [macro addCommand:[RKMCDelay commandWithDelay:3000]];
    
    //Finsh loop
    [macro addCommand:[RKMCLoopEnd command]];
    
    //Come to stop
    [macro addCommand:[RKMCRoll commandWithSpeed:0.f heading:0 delay:500]];

    //Send full command dowm to Sphero to play
    [macro playMacro];
}

/**
 Aborts current running macro and set robot back to an initial state.
 */
- (void)runMacroAbort
{
    //Abort Command
    [RKAbortMacroCommand sendCommand];
    // restore
    [self restoreRobotState];
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
    [self driveforward:0];
}

- (IBAction)drive90Heading:(id)sender
{
    [self driveforward:90];
}

- (IBAction)drive180Heading:(id)sender
{
    [self driveforward:180];
}

- (IBAction)drive270Heading:(id)sender
{
    [self driveforward:270];
}

- (IBAction)goSquare:(id)sender
{
    [self runSquareShapeRollMacro];
}

- (IBAction)goFigureEight:(id)sender
{
    [self runFigureEightRollMacro];
}

- (IBAction)abortAbort:(id)sender
{
    [self runMacroAbort];
}

@end
