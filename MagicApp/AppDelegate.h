//
//  AppDelegate.h
//  MagicApp
//

#import <UIKit/UIKit.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    NSString    *_urlArgs;
	NSString    *_devicePNID;
}

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ViewController *viewController;
@property (strong, nonatomic) id coreViewController;

@end
