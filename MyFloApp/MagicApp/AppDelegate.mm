//
//  AppDelegate.m
//  MagicApp
//

#import "AppDelegate.h"
#import "Magicxpa.h"

@implementation AppDelegate {
@private
    id _coreViewController;
}


@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize coreViewController = _coreViewController;


- (void)dealloc
{
    [_window release];
    [_viewController release];
    [_coreViewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    [self.window makeKeyAndVisible];
    [Magicxpa start: self.window WrapperDelegate:self];

    //Save the handle to the core VC for raising external event
    _coreViewController = self.window.rootViewController;

	// Let the device know we want to receive push notifications
	//the #if statement and the else block is required to support compilation using xcode 5.x
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000	
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
		UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge |UIRemoteNotificationTypeSound |UIRemoteNotificationTypeAlert) categories:nil];
		[[UIApplication sharedApplication] registerUserNotificationSettings:settings];

		// For ApplicationIconBadge
		UIUserNotificationSettings *badgesettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge categories:nil];
		[[UIApplication sharedApplication] registerUserNotificationSettings:badgesettings];	
	} else {
		UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
	}
#else 
	{
		UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:myTypes];
	}
#endif

	if (launchOptions != nil) 
	{ 
		NSDictionary* dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]; 
		if (dictionary != nil) 
		{ 
			//NSLog(@"Launched from push notification: %@", dictionary); 
			//Stores the notification message so you can later on retrieve it from the application using the ClientOSEnvGet('device_udf|getargs') function.
			_urlArgs = [[[dictionary valueForKey:@"aps"] valueForKey:@"alert"] copy]; 
			// Enable the following line if you wish to raise the External Event when the application is launched from a push notification message. 
			//[Magicxpa invokeExternalEvent:_urlArgs]; 
		}
	}
	// Clear existing push notifications
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	[[UIApplication sharedApplication] cancelAllLocalNotifications];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
	// Clear existing push notifications
	[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	[[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	 // Clear existing push notifications
	 application.applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if (!url) {  return NO; }
	
	_urlArgs = [[url query] copy];
    return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken 
{ 
	//NSLog(@"My token is: %@", deviceToken); 
	//Stores the device token so you can later on retrieve it from the application using the ClientOSEnvGet('device_udf|getpushid') function.
	NSString* newToken = [deviceToken description]; 
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]; 
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""]; 
	_devicePNID = [newToken copy]; 
	// Enable the following line if you wish to raise the External Event when the device registers with the APNs. 
	//[Magicxpa invokeExternalEvent:[NSString stringWithFormat:@"GCM-regID:%@ ",_devicePNID]]; 
} 

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error 
{ 
	NSLog(@"Failed to get token, error: %@", error); 
} 

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo 
{ 
    //NSLog(@"Received notification: %@", userInfo); 
	UIApplicationState state = [application applicationState];
	NSString *message = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
	if (state == UIApplicationStateActive) {
					// Push Notification received in the foreground - show a notification
					UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Notification" message:message delegate:self cancelButtonTitle:@"Close" otherButtonTitles:@"Show", nil];
					[alertView show];
					[alertView release];
	} else {
					// Push Notification received in the background
					_urlArgs = [message copy]; 
					//The following line raises the external event when a push notification message is received. You can retrieve the notification message from the application using the ClientOSEnvGet('device_udf|getargs') function.
					[Magicxpa invokeExternalEvent:_urlArgs]; 
	}
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}
#endif

-(NSString *)userDefinedFunction:(NSString *)str
{
    if ([[str lowercaseString] isEqualToString:@"getargs"]) {
        return _urlArgs;
    }
	else if ([[str lowercaseString] isEqualToString:@"getpushid"]) {
        return _devicePNID;
    }	
    else {
        //write your code here
        return @"Return String";
    }
}

@end
