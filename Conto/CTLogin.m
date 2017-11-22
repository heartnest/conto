//
//  CTCalculableTextVC.m
//  Conto
//
//  Created by HeartNest on 10/08/14.
//  Copyright (c) 2014 asscubo. All rights reserved.
//

#import "CTLogin.h"
#import "CTContants.h"
#import "CTRegister.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <QuartzCore/QuartzCore.h>
#import "CTAppDelegate.h"

#import <StoreKit/StoreKit.h>


@interface CTLogin ()<SKProductsRequestDelegate, SKPaymentTransactionObserver,UIActionSheetDelegate>

@property (strong, nonatomic) IBOutlet UITextField *login_mail;
@property (strong, nonatomic) IBOutlet UITextField *login_pwd;
@property (strong, nonatomic) IBOutlet UIButton *login_btn;
@property (strong, nonatomic) IBOutlet UIButton *login_register_btn;

@property (strong, nonatomic) IBOutlet UIButton *logout_btn;
@property (strong, nonatomic) IBOutlet FBSDKLoginButton *fb_login_btn;
@property (strong, nonatomic) IBOutlet UILabel *label_purchase_state;

@property (weak, nonatomic) IBOutlet UIImageView *imgProfilePicture;


@property (weak, nonatomic) IBOutlet UILabel *lblFullname;
@property (weak, nonatomic) IBOutlet UILabel *lblEmail;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *purchaseBtn;

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (strong, nonatomic) NSString *userid;
@property (strong, nonatomic) NSString *useremail;
@property (strong, nonatomic) SKProductsRequest *request; //compatibility with old ipad and ios
@property (nonatomic, strong) CTAppDelegate *appDelegate;


@end

@implementation CTLogin


# pragma marks - viewController lifecycle -

- (void)viewDidLoad
{
    [super viewDidLoad];
     [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
    
    [self drawLogoutBtn];
    [self drawPurchaeStateBtn];
    [self drawFacebookBtn];
    [self drawRegisterBtn];
    
    self.spinner.hidesWhenStopped = YES;
    
   
//    self.imgProfilePicture.layer.masksToBounds = YES;
//    self.imgProfilePicture.layer.cornerRadius = 30.0;
//    self.imgProfilePicture.layer.borderColor = [UIColor whiteColor].CGColor;
//    self.imgProfilePicture.layer.borderWidth = 1.0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fbProfileChange)
                                                 name:FBSDKProfileDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accessTokenChange)
                                                 name:FBSDKAccessTokenDidChangeNotification
                                               object:nil];
    
    
    self.lblFullname.hidden = YES;
    self.lblEmail.hidden = YES;
    self.imgProfilePicture.hidden = YES;

    
}


-(void) viewWillAppear:(BOOL)animated{
    NSString *uid = [[NSUserDefaults standardUserDefaults] objectForKey:NSUD_USERID];
    NSString *uemail = [[NSUserDefaults standardUserDefaults] objectForKey:NSUD_USEREMAIL];

    if (uid != nil) {
        [self toggleLayoutForAccount:YES];
        NSUserDefaults *ud = [[NSUserDefaults alloc]init];
        NSString *userid = [ud objectForKey:  NSUD_USERID ];
        NSString *purchaseKey =   [USERPURCHASEKEY stringByAppendingString:userid];
        NSString *hasPurchase = [ud objectForKey:purchaseKey];
        
        NSLog(@"%@",hasPurchase);
        if ([hasPurchase isEqual:@"YES"]) {
            
            [self UIShowPurchasedState];

        }else{
            [self UIShowUnpurchasedState];
        }
        self.navigationItem.title = uemail;
    }else{
        [self toggleLayoutForAccount:NO];
        self.navigationItem.title = @"Connect to Addnote";
    }
}
-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

// Once the button is clicked, show the login dialog
//-(void)loginButtonClicked
//{
//    if ([FBSDKProfile currentProfile])
//    {
//        NSLog(@"User name: %@",[FBSDKProfile currentProfile].name);
//        NSLog(@"User ID: %@",[FBSDKProfile currentProfile].userID);
//    }
//    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
//    [login
//     logInWithReadPermissions: @[@"public_profile", @"email", @"user_friends"]
//     fromViewController:self
//     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
//         if (error) {
//             NSLog(@"Process error");
//         } else if (result.isCancelled) {
//             NSLog(@"Cancelled");
//         } else {
//             NSString *userid = [FBSDKAccessToken currentAccessToken].userID;
//             self.lblFullname.text =userid;
//             NSLog(@"Logged in %@",userid);
//             [self fetchFbUserInfo];
//         }
//     }];
//}


# pragma marks - UI design -

-(void)drawFacebookBtn{

    self.fb_login_btn =  [[FBSDKLoginButton alloc] init];
    self.fb_login_btn.readPermissions =
    @[@"public_profile", @"email"];

    self.fb_login_btn.frame= CGRectMake(0,0,260,35);
    self.fb_login_btn.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.width/2+120);

    [self.view addSubview:self.fb_login_btn];

}

-(void)drawRegisterBtn{
    self.login_register_btn.frame=CGRectMake(0,0,260,35);
    self.login_register_btn.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.width*7/10);
}

-(void)drawPurchaeStateBtn{
    self.label_purchase_state=[[UILabel alloc] init];
    self.label_purchase_state.frame=CGRectMake(0,0,180,40);
    self.label_purchase_state.center = CGPointMake(self.view.frame.size.width/2, 150);
    [self.view addSubview:self.label_purchase_state];
}

-(void)drawLogoutBtn{
        self.logout_btn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.logout_btn.backgroundColor=[UIColor lightGrayColor];
        self.logout_btn.frame=CGRectMake(60,30,260,35);
        self.logout_btn.center = self.view.center;
        [ self.logout_btn setTitle: @"Log Out" forState: UIControlStateNormal];
        [ self.logout_btn
         addTarget:self
         action:@selector(logoutButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.logout_btn];
}

-(void)toggleLayoutForAccount:(BOOL)isLogged{
    if (isLogged) {
        [ self.login_register_btn setTitle: @"Change Password" forState: UIControlStateNormal];

    }else{
         [ self.login_register_btn setTitle: @"Register with email" forState: UIControlStateNormal];
    }
    self.login_pwd.hidden = isLogged;
    self.login_btn.hidden = isLogged;
    self.login_mail.hidden = isLogged;
    self.label_purchase_state.hidden = !isLogged;
    self.logout_btn.hidden = !isLogged;
    
    self.fb_login_btn.hidden = isLogged;
}

-(void) UIShowPurchasedState{
    self.purchaseBtn.title = @"";
    self.label_purchase_state.text = @"App Purchased";
}

-(void) UIShowUnpurchasedState{
    self.purchaseBtn.title = @"Purchase";
    self.label_purchase_state.text = @"App Not Purchased";
}

# pragma marks - FACEBOOK flow -

-(void) accessTokenChange{
    if ([FBSDKAccessToken currentAccessToken]) {
        // get user info when login
        [self fetchFbUserInfo];
    }else{
        // do something when user logout (already treated with log out)
    }
}

-(void) fbProfileChange{
    if ([FBSDKAccessToken currentAccessToken]) {
       // do something when profile updated
        
    }else{
    }
}
-(void)fetchFbUserInfo{
    
    if ([FBSDKAccessToken currentAccessToken])
    {
        NSLog(@"Token is available : %@",[[FBSDKAccessToken currentAccessToken]tokenString]);
//        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id, name, link, first_name, last_name, picture.type(large), email, birthday ,location ,friends ,hometown , friendlists"}]
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id, name, first_name, last_name, picture.type(large), email"}]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             if (!error)
             {
//                 NSLog(@"resultisfetchFbUserInfo:%@",result);
                 [self handleFacebookResponse:result];
                 
             }
             else
             {
                 NSLog(@"ErrorfetchFbUserInfo %@",error);
             }
         }];
        
    }else{
        NSLog(@"Not available");
    }
    
}
-(void)handleFacebookResponse:(NSDictionary *)result{
    // profile image
//    NSURL *pictureURL = [NSURL URLWithString:[[[result objectForKey:@"picture"] objectForKey:@"data"] objectForKey:@"url"]];
//    self.imgProfilePicture.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:pictureURL]];
    
    NSString *fbid = [result objectForKey:@"id"];
    NSString *fbname = [result objectForKey:@"first_name"];
    NSString *fbemail = [result objectForKey:@"email"];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:fbname forKey:NSUD_USERNAME];
    
    self.useremail = fbemail;
    NSString *request_url = [NSString stringWithFormat:@"http://datalet.net/login/facebook.php?secret=%@&&email=%@&&fbname=%@&&fbid=%@", DATALET_SECRET , fbemail,fbname,fbid];
    [self sendHttpRequest:request_url withSel:@"login_facebook"];
    //webserver http call, handle login event.
    // get user database id, commit login operations.
    
//    NSLog(@"%@,%@",fbid,fbname);
}


#pragma marks - IBAction Outlets  -

- (IBAction)loginBtn:(UIButton *)sender {

    NSString *lgmail = self.login_mail.text;
    NSString *lgpwd = self.login_pwd.text;
     self.useremail = lgmail;
    NSString *request_url = [NSString stringWithFormat:@"http://datalet.net/login/mail_login.php?secret=%@&&email=%@&&pwd=%@", DATALET_SECRET , lgmail,lgpwd];
    [self sendHttpRequest:request_url withSel:@"login"];

}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (popup.tag) {
        case 1: {
            switch (buttonIndex) {
                case 0:
                    [self logoutAction];
                    break;
            
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}


- (IBAction)purchaseTapped:(id)sender {
    [self.spinner startAnimating];
    NSUserDefaults *ud =[NSUserDefaults standardUserDefaults];
    NSString *userid = [ud objectForKey:  NSUD_USERID ];
    if (userid == nil) {
        [self alert:@"Please Login"];
        [self.spinner stopAnimating];
    }else{

    if([SKPaymentQueue canMakePayments]){
        self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:iapProductIdentifier]];
        self.request.delegate = self;
        [self.request start];

    }
    else{
        NSLog(@"User cannot make payments due to parental controls");
        [self.spinner stopAnimating];
    }
            }
}


-(void)logoutButtonClicked{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure to log out?"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Log out"
                                                    otherButtonTitles: nil];
    
    actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
    actionSheet.tag = 1;
    [actionSheet showInView:self.view];
    
}
-(void)logoutAction{
    // data
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:NSUD_USERID];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:NSUD_USERNAME];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:NSUD_USEREMAIL];
    
    // UI
    [self toggleLayoutForAccount:NO];
    self.navigationItem.title = @"Connect to AddNote";
    self.purchaseBtn.title = @"Purchase";
    
    // facebook
    if ([FBSDKAccessToken currentAccessToken]) {
        [[FBSDKLoginManager new] logOut];
    }
    
}



#pragma marks - in-app payment handlers -

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    SKProduct *validProduct = nil;
    int count =(int)[response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        [self purchase:validProduct];
    }
    if(!validProduct){
        NSLog(@"product id is not valid");
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"request - didFailWithError: %@", [[error userInfo] objectForKey:@"NSLocalizedDescription"]);
}

- (void)purchase:(SKProduct *)product{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        
        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing:
                                NSLog(@"Transaction state -> Purchasing");
                break;
            case SKPaymentTransactionStatePurchased:
                                NSLog(@"Just purchased");
                [self commitPurchase];
                [self.spinner stopAnimating];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                                NSLog(@"Transaction state -> Purchased");
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state from paymentQueue -> Restored");
                [self.spinner stopAnimating];
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                if(transaction.error.code == SKErrorPaymentCancelled){
                    [self.spinner stopAnimating];
                    NSLog(@"Transaction state -> Cancelled");
                }
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            default:
                
                ;
        }
    }
    
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"Transaction state from QueueRestoreCompleted Received Restored transactions: %lu", (unsigned long)queue.transactions.count);
    for(SKPaymentTransaction *transaction in queue.transactions){
        if(transaction.transactionState == SKPaymentTransactionStateRestored){
            //called when the user successfully restores a purchase
            NSLog(@"Transaction state from QueueRestoreCompleted -> Restored");

            [self commitPurchase];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        }
    }
}

- (void)commitPurchase{
    NSUserDefaults *ud =[NSUserDefaults standardUserDefaults];
    NSString *userid = [ud objectForKey:  NSUD_USERID ];
    NSString *useremail = [ud objectForKey:  NSUD_USEREMAIL ];
    NSString *request_url = [NSString stringWithFormat:@"http://datalet.net/addnote/handle_purchase.php?secret=%@&&userid=%@&&email=%@", DATALET_SECRET , userid,useremail];
    
    NSString *purchaseKey =   [USERPURCHASEKEY stringByAppendingString:userid];
    [ud setObject:@"YES" forKey:purchaseKey];

    NSString *limitedNotesKey =   [NOTELIMIT stringByAppendingString:userid];
    [ud setObject:nil forKey:limitedNotesKey];
    
    [self UIShowPurchasedState];
    [self sendHttpRequest:request_url withSel:@"purchase"];
}


-(void) handlePurchaseResponse:(NSString *)msg{
    [self.spinner stopAnimating];
}

# pragma marks - Event Hanlders -

-(void) handleReloadNote:(NSDictionary *)dic{
    NSString *paid = [dic objectForKey:@"paid"];
    NSString *content = [dic objectForKey:@"content"];
    NSError *err;
    NSDictionary* json =     [NSJSONSerialization JSONObjectWithData: [content dataUsingEncoding:NSUTF8StringEncoding]
                                                             options: NSJSONReadingMutableContainers
                                                               error: &err];
    
    if (![content isEqual:@""]) {
        NSUserDefaults *ud = [[NSUserDefaults alloc]init];
        NSString *userid = [ud objectForKey:  NSUD_USERID ];
        
        NSString *noteKey =   [NOTEACCOUNT stringByAppendingString:userid];
        
        if ([paid isEqual:@"NO"]) {
            NSString *limitedNotesKey =   [NOTELIMIT stringByAppendingString:userid];
            NSArray *keys = [json allKeys];
            if ([keys count] > 3) {
                unsigned take = MIN(keys.count/2, [keys count]-3);
                NSArray *smallArray = [keys subarrayWithRange:NSMakeRange(3, take)];
                
                [ud setObject:smallArray forKey:limitedNotesKey];
            }
        }
        
        [ud setObject:json forKey:noteKey];
        [ud synchronize];
        
    }
    
}
-(void) handleLoginResponse:(NSString *)msg{
    NSArray *stringsplit = [msg componentsSeparatedByString:@";"];
    if ([stringsplit[0]  isEqual: @"ok"]) {
        
        // data
        NSString *userid = stringsplit[1];
        
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:userid forKey:NSUD_USERID];
        [ud setObject:self.useremail forKey:NSUD_USEREMAIL];
        if (stringsplit.count > 2) {
            [[NSUserDefaults standardUserDefaults] setObject:stringsplit[2] forKey:NSUD_USERNAME];
        }
        
        // load saved notes
        NSString *noteKey =  [NOTEACCOUNT stringByAppendingString:userid];
        if([ud objectForKey:noteKey] == nil){
            NSString *request_url = [NSString stringWithFormat:@"http://datalet.net/addnote/handle_loadnote.php?secret=%@&&userid=%@&&email=%@", DATALET_SECRET ,userid,self.useremail];
            [self sendHttpRequest:request_url withSel:@"reload"];
        }
        
        // load purchase history
        NSString *request_url2 = [NSString stringWithFormat:@"http://datalet.net/addnote/handle_hasPurchase.php?secret=%@&&userid=%@&&email=%@", DATALET_SECRET ,userid,self.useremail];
        [self sendHttpRequest:request_url2 withSel:@"hasPurchase"];
        
        // view
        [self toggleLayoutForAccount:YES];
        [self.view endEditing:YES];
        self.navigationItem.title = self.useremail;
    }
    [self alert:stringsplit[0]];
}


# pragma marks - Tools -


-(void) sendHttpRequest:(NSString *)request_url_unsafe withSel:(NSString *)sel{

    NSString* request_url = [request_url_unsafe stringByAddingPercentEscapesUsingEncoding:
                             NSUTF8StringEncoding];
    NSLog(@"HTTP: %@",request_url);
    NSURL *url = [NSURL URLWithString:request_url];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        if (data) {
            NSHTTPURLResponse * httpResponse  = (NSHTTPURLResponse*)response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode == 200) {
                NSString* responstr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([sel isEqual:@"login"]) {
                        [self handleLoginResponse:responstr];
                    }else if([sel isEqual:@"purchase"]){
                        // just successful purchased
                        [self handlePurchaseResponse:responstr];
                        [self UIShowPurchasedState];
                    }else if([sel isEqual:@"reload"]){
//                        NSLog(@"%@",responstr);
                        NSError *err;
                        NSDictionary* json =     [NSJSONSerialization JSONObjectWithData: [responstr dataUsingEncoding:NSUTF8StringEncoding]
                                                                                 options: NSJSONReadingMutableContainers
                                                                                   error: &err];
                        
                        [self handleReloadNote:json];
                    }else if([sel isEqual:@"hasPurchase"]){
                        // purchased before
                        if ([responstr isEqual:@"YES"]) {
                            [self UIShowPurchasedState];
                        }else{
                            [self UIShowUnpurchasedState];
                            
                        }
                        NSUserDefaults *ud = [[NSUserDefaults alloc]init];
                        NSString *userid = [ud objectForKey:  NSUD_USERID ];
                        NSString *purchaseKey =   [USERPURCHASEKEY stringByAppendingString:userid];
                        [ud setObject:responstr forKey:purchaseKey];
                    }
                    else if([sel isEqual:@"login_facebook"]){
//                        NSLog(@"%@",responstr);
                        [self handleLoginResponse:responstr];
                    }
                    
                });
                
            }
        }else if (error)
        {
            NSLog(@"Error with url %@ ....%@",request_url_unsafe,error);
        }
        
    }];
    [dataTask resume];
}



-(void) alert:(NSString *)msg{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message"
                                                    message:msg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        // user hit dismiss so don't do anything
    }
    else if (buttonIndex == 1) //review the app
    {

    }
}
@end
