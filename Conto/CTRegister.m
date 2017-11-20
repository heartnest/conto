//

//  Created by HeartNest on 10/08/14.
//  Copyright (c) 2014 asscubo. All rights reserved.
//

#import "CTRegister.h"
#import "CTContants.h"

#import <QuartzCore/QuartzCore.h>
#import "CTAppDelegate.h"


@interface CTRegiser ()
@property (strong, nonatomic) IBOutlet UITextField *field_email;
@property (strong, nonatomic) IBOutlet UITextField *field_password;
@property (strong, nonatomic) IBOutlet UITextField *field_code;
@end

@implementation CTRegiser


static NSString *isIAPedkey = @"com.iap.arePurchaseMade";

#pragma marks - viewController lifecycle -

- (void)viewDidLoad
{
    [super viewDidLoad];
}
- (IBAction)sendCodeBtn:(id)sender {
    NSString *email = self.field_email.text;
    NSString *pwd = self.field_password.text;
    NSString *request_url = [NSString stringWithFormat:@"http://datalet.net/login/mail_req.php?secret=%@&&email=%@&&pwd=%@", DATALET_SECRET , email,pwd];
    [self sendHttpRequest:request_url];
}

- (IBAction)confirmBtn:(id)sender {
    NSString *email = self.field_email.text;
    NSString *pwd = self.field_password.text;
    NSString *code = self.field_code.text;
    NSString *request_url = [NSString stringWithFormat:@"http://datalet.net/login/mail_confirm.php?secret=%@&&email=%@&&pwd=%@&&code=%@", DATALET_SECRET , email,pwd,code];
    [self sendHttpRequest:request_url];
}

-(void) viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
}
-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    NSString *useremail = [[NSUserDefaults standardUserDefaults] objectForKey:  NSUD_USEREMAIL ];
    if(useremail == nil){
        self.field_email.text = @"";
        self.field_email.enabled = YES;
    }else{
        self.field_email.text = useremail;
        self.field_email.enabled = NO;
    }
        
}

-(void) sendHttpRequest:(NSString *)request_url_unsafe {

    
    NSString* request_url = [request_url_unsafe stringByAddingPercentEscapesUsingEncoding:
                            NSASCIIStringEncoding];
    NSLog(@"%@",request_url);
    NSURL *url = [NSURL URLWithString:request_url];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //
        if (data) {
            NSHTTPURLResponse * httpResponse  = (NSHTTPURLResponse*)response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode == 200) {
                NSString* responstr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//                NSLog(@"%@",responstr);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self handleLoginResponse:responstr];
                });
                
                //PERFORM YOUR OPERATIONS
            }
        }else if (error)
        {
            NSLog(@"Errorrrrrrr....%@",error);
        }
        
    }];
    [dataTask resume];
}


-(void) handleLoginResponse:(NSString *)msg{
    NSArray *stringsplit = [msg componentsSeparatedByString:@";"];
    if ([stringsplit[0]  isEqual: @"ok"]) {
        [[NSUserDefaults standardUserDefaults] setObject:stringsplit[1] forKey:NSUD_USERID];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:NSUD_USERNAME];
        [[NSUserDefaults standardUserDefaults] setObject:self.field_email.text forKey:NSUD_USEREMAIL];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    [self alert:stringsplit[0]];
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
        
//        [[UIApplication sharedApplication]
//         openURL:[NSURL URLWithString:APPLINK]];
    }
}

@end
