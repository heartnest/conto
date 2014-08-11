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
@property (strong,nonatomic) NSString *billContentID;
@end

@implementation CTCalculableTextVC


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:self.view.window];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification object:self.view.window];
    
    NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
    NSString *text = [sd objectForKey:self.billContentID];
    if (text != nil) {
        self.panel.text = text;
        [self analyzeContent:text];
    }
}

-(void) viewWillDisappear:(BOOL)animated {
    if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
        // back button was pressed.  We know this is true because self is no longer
        // in the navigation stack.
        //read text
        NSString *text = self.panel.text;
        //save text
        NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
        [sd setObject:text forKey:self.billContentID];
        [sd synchronize];
    }
    [super viewWillDisappear:animated];
}

-(void)setBillID:(NSString *)billID{
    _billID = billID;
    _billContentID = [BILL_DICCONTENT stringByAppendingString:billID];
}

- (IBAction)calculate:(UIBarButtonItem *)sender {
    
    //read text
    NSString *text = self.panel.text;
    //save text
    NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
    [sd setObject:text forKey:self.billContentID];
    [sd synchronize];

    //hide keyboard
    [self.panel resignFirstResponder];
    
    //show result
    [self analyzeContent:text];
}

- (void)analyzeContent:(NSString *)text{
    
    float res = 0;
    
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray *items = [text componentsSeparatedByString:@"\n"];
    
    for(NSString *item in items){
        NSString *cp = item;
        cp = [cp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray *splitted = [cp componentsSeparatedByString:@" "];
        float val =[[splitted objectAtIndex:0] floatValue];
        res += val;
    }
    
    self.result.text = [[NSString alloc] initWithFormat:@"%.02f Euro" , res];
}


- (void)keyboardWillShow:(NSNotification *)notif
{
    [self.panel setFrame:CGRectMake(10, 20, 295, 237)]; //Or where ever you want the view to go
}

- (void)keyboardWillHide:(NSNotification *)notif
{
    [self.panel setFrame:CGRectMake(10, 20, 295, 410)]; //return it to its original position
    
}

@end
