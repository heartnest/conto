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
//@property (weak, nonatomic) IBOutlet UILabel *result;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *total;
@property (strong,nonatomic) NSString *billDictionaryID;
@end

@implementation CTCalculableTextVC


#pragma marks - viewController lifecycle -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    self.panel.edgesForExtendedLayout = UIRectEdgeNone;
//    self.panel.textContainer.lineFragmentPadding = 0;
    self.automaticallyAdjustsScrollViewInsets = NO;
//    self.panel.textContainerInset = 0;
//    self.panel.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:self.view.window];
    
    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *composed = [iCloud dictionaryForKey: self.billDictionaryID];
//    NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
//    NSDictionary *composed = [sd dictionaryForKey: self.billDictionaryID];
    if (composed != nil) {
        NSString *text = [composed objectForKey:BILL_DICCONTENT];
        NSString *title = [composed objectForKey:BILL_DICTITLE];
        self.title= title;
        self.panel.text = text;
        [self analyzeContent:text];
    }
    
//    
//    UIImageView *imgView = [[UIImageView alloc]initWithFrame: self.panel.frame];
//    imgView.image = [UIImage imageNamed: @"bg1.jpg"];
//    
//    UIImageView *img = [[UIImageView alloc]initWithFrame: self.panel.frame];
//    img.image = [UIImage imageNamed: @"bg1.jpg"];
////    [self.panel addSubview:self.panel];
////    [self.panel insertSubview:img belowSubview:self.panel];
//    
////    self.panel.background = [UIImage imageNamed:@"textFieldImage.png"];
////    [self.panel addSubview: imgView];
////    [self.panel sendSubviewToBack: imgView];
////    [window addSubview: textView];
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
    _billID = billID;
    _billDictionaryID = [BILL_DICCONTENT stringByAppendingString:billID];
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
    
//    NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
//    [sd setObject:bill forKey:self.billDictionaryID];
//    [sd synchronize];
    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
    [iCloud setObject:bill forKey:self.billDictionaryID];
    [iCloud synchronize];
    
    
    
//    NSData *dicdata = [NSKeyedArchiver archivedDataWithRootObject:[NSUserDefaults standardUserDefaults]];
//    //Save Data To NSUserDefault
//    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
//    //let ios know we want to save the data
//    [iCloud setObject:dicdata forKey:ICLOUD_DICKEY];
//    //iOS will save the data when it is ready.
//    [iCloud synchronize];
    

}

- (void)analyzeContent:(NSString *)text{
    
    float res = 0;
//    NSAttributedString *resStr;
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
    
//    NSDictionary *attrb = @{ NSForegroundColorAttributeName :[UIColor greenColor]};
//    NSDictionary *attre = @{ NSForegroundColorAttributeName :[UIColor redColor]};
    
    
    if (res < 0) {
        res = -res;
        tmpStr = [[NSString alloc] initWithFormat:@"Total: %.02f" , res];
//        resStr = [[NSAttributedString alloc] initWithString:tmpStr attributes:attrb];
    }else{
        tmpStr = [[NSString alloc] initWithFormat:@"Total: %.02f" , res];
//        resStr = [[NSAttributedString alloc] initWithString:tmpStr attributes:attre];
    
    }
//    self.result.attributedText = resStr;
    self.total.title = tmpStr;
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
