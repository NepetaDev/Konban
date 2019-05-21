#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIControl.h>
#import <Cephei/HBPreferences.h>

@interface SBRootFolderView : UIView

-(UIViewController *)todayViewController;

@end

@interface SBHomeScreenTodayViewController : UIViewController

@property (nonatomic, retain) UIView *konHostView;
@property (nonatomic, retain) UIActivityIndicatorView *konSpinnerView;

@end

@interface SBDashBoardTodayViewController : UIViewController

@property (nonatomic, retain) UIView *konHostView;
@property (nonatomic, retain) UIActivityIndicatorView *konSpinnerView;

@end

@interface SBFUserAuthenticationController
	- (void)_setAuthState:(long long)arg1;
@end