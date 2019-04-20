#import "KonbanSpringboard.h"
#import "Konban.m"

#ifndef SIMULATOR
HBPreferences *preferences;
#endif
BOOL dpkgInvalid = false;
BOOL visible = false;
bool enabled;
bool enabledCoverSheet;
bool enabledHomeScreen;
CGFloat scale = 0.8;
CGFloat cornerRadius = 16;
NSString *bundleID = @"com.apple.calculator";
UIViewController *ourVC = nil;

%group Konban

%hook SBHomeScreenTodayViewController

%property (nonatomic, retain) UIView *konHostView;
%property (nonatomic, retain) UIActivityIndicatorView *konSpinnerView;

-(void)viewDidLayoutSubviews {
    %orig;
    [Konban rehost:bundleID];
}

-(void)viewWillAppear:(bool)arg1 {
    %orig;

    [Konban dehost:bundleID];
    [self.konSpinnerView stopAnimating];
    [self.konSpinnerView removeFromSuperview];
    [self.konHostView removeFromSuperview];
    if (enabled) {
        for (UIView *view in [self.view subviews]) {
            view.hidden = YES;
        }

        if (!self.konSpinnerView) self.konSpinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.konSpinnerView.hidesWhenStopped = YES;
        self.konSpinnerView.frame = self.view.frame;
        [self.view addSubview:self.konSpinnerView];
        [self.konSpinnerView startAnimating];

        self.konHostView = [Konban viewFor:bundleID];
        self.konHostView.frame = self.view.frame;
        self.konHostView.transform = CGAffineTransformMakeScale(scale, scale); 
        self.konHostView.layer.cornerRadius = cornerRadius;
        self.konHostView.layer.masksToBounds = true;
        [self.view addSubview:self.konHostView];
        [self.view bringSubviewToFront:self.konHostView];
        self.konHostView.hidden = NO;
        visible = YES;

        if (!self.konHostView) {
            [self.konSpinnerView startAnimating];
            [self.view bringSubviewToFront:self.konSpinnerView];

            [self performSelector:@selector(viewWillAppear:) withObject:nil afterDelay:0.5];
        }
    } else {
        for (UIView *view in [self.view subviews]) {
            view.hidden = NO;
        }

        [self.konHostView removeFromSuperview];
    }
}

-(void)viewDidDisappear:(bool)arg1 {
    %orig;
    visible = NO;
    [self.konHostView removeFromSuperview];
    [Konban dehost:bundleID];
}

%end

%end

%group KonbanIntegrityFail

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)arg1 {
    %orig;
    if (!dpkgInvalid) return;
    UIAlertController *alertController = [UIAlertController
        alertControllerWithTitle:@"😡😡😡"
        message:@"The build of Konban you're using comes from an untrusted source. Pirate repositories can distribute malware and you will get subpar user experience using any tweaks from them.\nRemember: Konban is free. Uninstall this build and install the proper version of Konban from:\nhttps://repo.nepeta.me/\n(it's free, damnit, why would you pirate that!?)"
        preferredStyle:UIAlertControllerStyleAlert
    ];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Damn!" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [((UIApplication*)self).keyWindow.rootViewController dismissViewControllerAnimated:YES completion:NULL];
        [((UIApplication*)self) openURL:[NSURL URLWithString:@"https://repo.nepeta.me/"] options:@{} completionHandler:nil];
    }]];

    [((UIApplication*)self).keyWindow.rootViewController presentViewController:alertController animated:YES completion:NULL];
}

%end

%end

void changeApp() {
    NSMutableDictionary *appList = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/me.nepeta.konban-app.plist"];
    if (!appList) return;
    
    if ([appList objectForKey:@"App"]) {
        bundleID = [appList objectForKey:@"App"];
    }
}

%ctor{
    #ifndef SIMULATOR
    preferences = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.konban"];
    [preferences registerBool:&enabled default:YES forKey:@"Enabled"];
    [preferences registerFloat:&cornerRadius default:16 forKey:@"CornerRadius"];
    [preferences registerFloat:&scale default:0.8 forKey:@"Scale"];
    dpkgInvalid = ![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/me.nepeta.konban.list"];
    #else
    enabled = YES;
    dpkgInvalid = NO;
    #endif

    if (dpkgInvalid) {
        %init(KonbanIntegrityFail);
        return;
    }

    changeApp();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)changeApp, (CFStringRef)@"me.nepeta.konban/ReloadApp", NULL, (CFNotificationSuspensionBehavior)kNilOptions);
    %init(Konban);
}