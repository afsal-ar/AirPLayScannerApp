//
//  LoginManager.m
//  IPListApp
//
//  Created by Afsal  on 26/08/24.
//

#import "LoginManager.h"

@implementation LoginManager


+ (LoginManager *)sharedManager {
    static LoginManager *sharedManager = nil;
    if(sharedManager == nil){
        sharedManager = [[LoginManager alloc] init];
    }
    return  sharedManager;
}
- (BOOL)isTokenValid {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *storedToken = [defaults objectForKey:@"accessToken"];
        NSDate *storedExpirationDate = [defaults objectForKey:@"tokenExpiration"];

        BOOL hasToken = (storedToken != nil);

        BOOL isTokenExp = NO;
        if (storedExpirationDate) {
            NSDate *currentDate = [NSDate date];
            isTokenExp = [storedExpirationDate compare:currentDate] == NSOrderedDescending;
        }

        return hasToken && isTokenExp;
    
}

- (void)logoutAction {
    self.accessToken = nil;
    self.tokenExpiration = nil;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"token"];
    [userDefaults removeObjectForKey:@"tokenExp"];
    [userDefaults synchronize];
    
  
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *loginVC = [storyboard instantiateViewControllerWithIdentifier:@"LoginVC"];
        UIWindow *window = UIApplication.sharedApplication.delegate.window;
        window.rootViewController = loginVC;
        
        // Ensure the transition is animated
        [UIView transitionWithView:window
                          duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:nil
                        completion:nil];
}

- (void)silentLoginAction:(nonnull void (^)(BOOL, NSError * _Nonnull __strong))completion {
    if ([self isTokenValid]) {
         completion(YES, nil);
     } else {
         // Token expired or not available, force logout
         [self logoutAction];
         NSError *error = [NSError errorWithDomain:@"SilentLoginError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Token expired or not available."}];
         completion(NO, error);
     }
}

- (void)loginAction:(nonnull void (^)(BOOL, NSError * _Nonnull __strong))completion {
    
    NSString *clientId = @"Ov23liCFiQ8yv2yuCttj";
    NSString *redirectURI = @"iplistapp://callback";
    NSString *scope = @"user";
    NSString *authUrlStr =[NSString stringWithFormat:@"https://github.com/login/oauth/authorize?client_id=%@&redirect_uri=%@&scope=%@", clientId, redirectURI, scope];
    NSURL *url = [NSURL URLWithString:authUrlStr];
    
    
    self.safariWebviewVC = [[SFSafariViewController alloc]initWithURL:url];
    self.safariWebviewVC.delegate = self;
    
    UIWindow *window = [self getActiveWindow];
        
        if (window) {
            UIViewController *rootViewController = window.rootViewController;
            [rootViewController presentViewController:self.safariWebviewVC animated:YES completion:nil];
        }
    
    
}

- (void)handleOAuthCallbackWithURL:(NSURL *)url completion:(void (^)(BOOL, NSError * _Nonnull))completion {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSString *code = nil;
    
    for (NSURLQueryItem *item in urlComponents.queryItems) {
        if ([item.name isEqualToString:@"code"]) {
            code = item.value;
            break;
        }
    }
    
    if (code) {
        [self exchangeCodeForAccessToken:code completion:completion];
    } else {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"OAuthError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to retrieve authorization code"}];
            completion(NO, error);
        }
    }
}



- (void)exchangeCodeForAccessToken:(NSString *)code completion:(void (^)(BOOL, NSError *))completion {
    NSString *clientID = @"Ov23liCFiQ8yv2yuCttj";
    NSString *clientSecret = @"ea4d4690fc79add45a8f2e16c9b9e6bee1e00c6f";
    NSString *redirectURI = @"iplistapp://callback";
    
    NSString *tokenURLString = @"https://github.com/login/oauth/access_token";
    NSURL *tokenURL = [NSURL URLWithString:tokenURLString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:tokenURL];
    [request setHTTPMethod:@"POST"];
    
    NSString *bodyString = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&code=%@&redirect_uri=%@", clientID, clientSecret, code, redirectURI];
    NSData *bodyData = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:bodyData];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSDictionary *responseParams = [self parseQueryString:responseString];
        
        NSString *accessToken = responseParams[@"access_token"];
        if (accessToken) {
            self.accessToken = accessToken;
            self.tokenExpiration = [NSDate dateWithTimeIntervalSinceNow:3600]; //
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:self.accessToken forKey:@"accessToken"];
            [userDefaults setObject:self.tokenExpiration forKey:@"tokenExpiration"];
            [userDefaults synchronize];
            
            if (completion) {
                completion(YES, nil);
            }
        } else {
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"OAuthError" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Failed to retrieve access token"}];
                completion(NO, error);
            }
        }
    }];
    
    [dataTask resume];
}



- (NSDictionary *)parseQueryString:(NSString *)query {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        if (elements.count == 2) {
            NSString *key = [elements[0] stringByRemovingPercentEncoding];
            NSString *value = [elements[1] stringByRemovingPercentEncoding];
            dict[key] = value;
        }
    }
    
    return [dict copy];
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
   
}
- (UIWindow *)getActiveWindow {
    UIWindow *activeWindow = nil;
    
    
        
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                activeWindow = windowScene.windows.firstObject;
                break;
            }
        }
    
    
    return activeWindow;
}
@end
