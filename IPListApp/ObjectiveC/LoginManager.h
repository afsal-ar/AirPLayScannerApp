//
//  LoginManager.h
//  IPListApp
//
//  Created by Afsal  on 26/08/24.
//

#import <Foundation/Foundation.h>
#import "SafariServices/SafariServices.h"
NS_ASSUME_NONNULL_BEGIN



@interface LoginManager : NSObject <SFSafariViewControllerDelegate>
@property (atomic,weak) NSString *accessToken;
@property (atomic,weak) NSDate *tokenExpiration;
@property(nonatomic,strong) SFSafariViewController *safariWebviewVC;

+(LoginManager *)sharedManager;
-(void)loginAction:(void (^)(BOOL success,NSError *error))completion;
-(void)silentLoginAction:(void (^)(BOOL success,NSError *error))completion;
-(void)logoutAction;
-(BOOL)isTokenValid;
- (void)handleOAuthCallbackWithURL:(NSURL *)url completion:(void (^)(BOOL success, NSError *error))completion;
@end

NS_ASSUME_NONNULL_END
