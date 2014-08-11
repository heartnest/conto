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
@property (weak, nonatomic) IBOutlet UILabel *result;
@property (strong,nonatomic) NSString *billDictionaryID;
@end

@implementation CTCalculableTextVC


#pragma marks - viewController lifecycle -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:self.view.window];
    
    NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
    NSDictionary *composed = [sd dictionaryForKey: self.billDictionaryID];
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
    
    NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
    [sd setObject:bill forKey:self.billDictionaryID];
    [sd synchronize];
}

- (void)analyzeContent:(NSString *)text{
    
    float res = 0;
    NSAttributedString *resStr;
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
    
    NSDictionary *attrb = @{ NSForegroundColorAttributeName :[UIColor greenColor]};
    NSDictionary *attre = @{ NSForegroundColorAttributeName :[UIColor redColor]};
    
    
    if (res < 0) {
        res = -res;
        tmpStr = [[NSString alloc] initWithFormat:@"Balance: %.02f Euro" , res];
        resStr = [[NSAttributedString alloc] initWithString:tmpStr attributes:attrb];
    }else{
        tmpStr = [[NSString alloc] initWithFormat:@"Expense: %.02f Euro" , res];
        resStr = [[NSAttributedString alloc] initWithString:tmpStr attributes:attre];
    
    }
    self.result.attributedText = resStr;
}

#pragma marks - adjust textfield frame when keyboard appears -

- (void)keyboardWillShow:(NSNotification *)notif
{
    [self.panel setFrame:CGRectMake(10, 20, 295, 237)]; //Or where ever you want the view to go
}

- (void)keyboardWillHide:(NSNotification *)notif
{
    [self.panel setFrame:CGRectMake(10, 20, 295, 410)]; //return it to its original position
    
}

@end
