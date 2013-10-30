//
//  MainViewController.h
//  CocoaheadsSphero
//
//  Created by Brian Buck on 10/30/13.
//  Copyright (c) 2013 Brian Buck. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RobotUIKit/RobotUIKit.h>

@interface MainViewController : UIViewController {
    BOOL ledON;
    BOOL robotOnline;
    RUICalibrateGestureHandler *calibrateHandler;
}

-(void)setupRobotConnection;
-(void)handleRobotOnline;
-(void)toggleLED;

@end
