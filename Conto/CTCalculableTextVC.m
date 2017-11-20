//
//  CTCalculableTextVC.m
//  Conto
//
//  Created by HeartNest on 10/08/14.
//  Copyright (c) 2014 asscubo. All rights reserved.
//

#import "CTCalculableTextVC.h"
#import "CTContants.h"

@interface CTCalculableTextVC ()
@property (weak, nonatomic) IBOutlet UITextView *panel;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *totalLabel;
@property (strong,nonatomic) NSString *billDictionaryID;
@property (strong,nonatomic) NSString *textSum;
@end

@implementation CTCalculableTextVC

#pragma marks - viewController lifecycle -

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:self.view.window];
    
    

    
    NSString *userid = [[NSUserDefaults standardUserDefaults] objectForKey:  NSUD_USERID ];
    NSString *noteKey =  (userid != nil) ?  [NOTEACCOUNT stringByAppendingString:userid] : NOTEACCOUNT;

    NSDictionary *composed,*nsdic;

    NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
    nsdic = [sd dictionaryForKey: noteKey];

    composed = [nsdic objectForKey: self.billDictionaryID];

    if (composed != nil) {
        NSString *text = [composed objectForKey:BILL_DICCONTENT];
        NSString *title = [composed objectForKey:BILL_DICTITLE];
        self.title= title;
        self.panel.text = text;
        [self analyzeContent:text];
    }

}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        //save text
        [self saveContent];
    }
    [super viewWillDisappear:animated];
}

#pragma marks - Lazy instantiations -

-(void)setBillID:(NSString *)billID{
    _billDictionaryID = billID;
}

#pragma marks - IBActions -

- (IBAction)calculate:(UIBarButtonItem *)sender {
    
    //save text
    [self saveContent];

    //hide keyboard
    [self.panel resignFirstResponder];
    
    //show result
    [self analyzeContent:self.panel.text];
}
- (IBAction)shareAction:(id)sender {
    NSString *theMessage = self.panel.text;
    theMessage = [theMessage stringByAppendingString: [@"\n===\n" stringByAppendingString: self.textSum]];
    NSArray *items = @[theMessage];
    
    // build an activity view controller
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    
    // and present it
    [self presentActivityController:controller];
}

- (void)presentActivityController:(UIActivityViewController *)controller {
    
    // for iPad: make the presentation a Popover
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];
    
    UIPopoverPresentationController *popController = [controller popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popController.barButtonItem = self.navigationItem.leftBarButtonItem;
    
    // access the completion handler
    controller.completionWithItemsHandler = ^(NSString *activityType,
                                              BOOL completed,
                                              NSArray *returnedItems,
                                              NSError *error){
    };
}


#pragma marks - text interpretations -

- (void)saveContent{
    //sum
    float sum = 0;
    
    //read text
    NSString *text = self.panel.text;
    
    //shrink and split component
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray *items = [text componentsSeparatedByString:@"\n"];
    
    //read title
    NSString *title = [items objectAtIndex:0];
    
    for(NSString *item in items){
        NSString *cp = item;
        cp = [cp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *splitted = [cp componentsSeparatedByString:@" "];
        float val =[[splitted objectAtIndex:0] floatValue];
        sum += val;
    }
    
    NSString *sumStr = [[NSString alloc] initWithFormat:@"%.02f" , sum];
    
    //create stuff
    NSDictionary *bill = @{BILL_DICTITLE: title, BILL_DICCONTENT: text, BILL_DICSUM: sumStr};
    
    
    NSString *useremail = [[NSUserDefaults standardUserDefaults] objectForKey:  NSUD_USEREMAIL ];
    NSString *userid = [[NSUserDefaults standardUserDefaults] objectForKey:  NSUD_USERID ];
    NSString *noteKey =  (userid != nil) ?  [NOTEACCOUNT stringByAppendingString:userid] : NOTEACCOUNT;
    
    NSUserDefaults *store = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *cnt = [[NSMutableDictionary alloc] init];
    cnt = [[store objectForKey:noteKey] mutableCopy];
    if(!cnt){
        cnt =[[NSMutableDictionary alloc] init];
    }
    [cnt setObject:bill forKey:self.billDictionaryID];
    
//    NSLog(@"saving for %@",noteKey); 
    [store setObject:cnt forKey:noteKey];
    [store synchronize];


    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber *timeStampObj = [NSNumber numberWithDouble: timeStamp];
    NSString *timestamp = [timeStampObj stringValue];
    NSString *request_url = [NSString stringWithFormat:@"http://datalet.net/addnote/handle_update.php?secret=%@&&userid=%@&&email=%@&&time=%@", DATALET_SECRET , userid,useremail,timestamp];
    [self postJsonData:request_url dictionary:[cnt copy] ];


}

- (void)analyzeContent:(NSString *)text{
    
    float res = 0;
    NSString *tmpStr;
    
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray *items = [text componentsSeparatedByString:@"\n"];
    
    for(NSString *item in items){
        NSString *cp = item;
        cp = [cp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *splitted = [cp componentsSeparatedByString:@" "];
        float val =[[splitted objectAtIndex:0] floatValue];
        res += val;
    }
    
    
    if (res < 0) {
        tmpStr = [[NSString alloc] initWithFormat:@"Total: %.02f" , res];
    }else{
        tmpStr = [[NSString alloc] initWithFormat:@"Total: %.02f" , res];
    }
    self.textSum =tmpStr;
    self.totalLabel.title = tmpStr;
}

#pragma marks - adjust textfield frame when keyboard appears -

- (void)keyboardWillShow:(NSNotification *)notif
{
    NSValue *keyboardRectAsObject =
    [[notif userInfo]
     objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    
    CGRect keyboardRect = CGRectZero;
    [keyboardRectAsObject getValue:&keyboardRect];
    
    
    self.panel.contentInset =
    UIEdgeInsetsMake(0.0f,
                     0.0f,
                     keyboardRect.size.height,
                     0.0f);
}

- (void)keyboardWillHide:(NSNotification *)notif
{
    self.panel.contentInset = UIEdgeInsetsZero;
}


-(void)postJsonData:(NSString *)request_url_unsafe dictionary:(NSDictionary *)mapData{
    NSError *error1;
    NSString* request_url = [request_url_unsafe stringByAddingPercentEscapesUsingEncoding:
                             NSASCIIStringEncoding];

    NSURL *url = [NSURL URLWithString:request_url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error1];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

        if (data) {
            NSHTTPURLResponse * httpResponse  = (NSHTTPURLResponse*)response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode == 200) {
                NSString* responstr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"%@",responstr);
                
            }
        }else if (error)
        {
            NSLog(@"Errorrrrrrr....%@",error);
        }
        
    }];
    [dataTask resume];
}


@end
