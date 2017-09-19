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


static NSString *noteCont = @"comaddnotefullstore";
static NSString *hasPaidKey = @"com.icloud.key.hasPaid";
static bool hasPaid = NO;

#pragma marks - viewController lifecycle -

- (void)viewDidLoad
{
    [super viewDidLoad];
    

    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:self.view.window];
    
    
    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
    hasPaid = [iCloud boolForKey:hasPaidKey];
    NSDictionary *composed,*nsdic;
    if (hasPaid) {
        nsdic = [iCloud dictionaryForKey: noteCont];
//        NSLog(@"working icloud...view 2");
    }else{
        NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
        nsdic = [sd dictionaryForKey: noteCont];
//        NSLog(@"working local...view 2");
    }
    
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
        // react to the completion
//        if (completed) {
//            // user shared an item
//            NSLog(@"We used activity type%@", activityType);
//        } else {
//            // user cancelled
//            NSLog(@"We didn't want to share anything after all.");
//        }
//        
//        if (error) {
//            NSLog(@"An Error occured: %@, %@", error.localizedDescription, error.localizedFailureReason);
//        }
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
    

    if(hasPaid){
        NSUbiquitousKeyValueStore *store =  [NSUbiquitousKeyValueStore defaultStore];
        NSMutableDictionary *cnt = [[store objectForKey:noteCont] mutableCopy];
        if(!cnt){
            cnt =[[NSMutableDictionary alloc] init];
        }
        [cnt setValue:bill forKey:self.billDictionaryID];
        [store setObject:cnt forKey:noteCont];
        [store synchronize];
        
    }
    else{
        NSUserDefaults *store = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *cnt = [[NSMutableDictionary alloc] init];
        cnt = [[store objectForKey:noteCont] mutableCopy];
        if(!cnt){
            cnt =[[NSMutableDictionary alloc] init];
        }
        [cnt setObject:bill forKey:self.billDictionaryID];
        [store setObject:cnt forKey:noteCont];
        [store synchronize];
    }

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

@end
