//
//  CTTableViewController.m
//  Conto
//
//  Created by HeartNest on 10/08/14.
//  Copyright (c) 2014 asscubo. All rights reserved.
//

#import "CTTableViewController.h"
#import "CTContants.h"
#import "CTCalculableTextVC.h"

#import <StoreKit/StoreKit.h>

//#define iapProductIdentifierOLD @"harnestlabjishu"
#define iapProductIdentifier @"harnestlabaddnote"

@interface CTTableViewController ()<SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cloudButton;
@property (strong,nonatomic) NSMutableDictionary *notes;
@property (strong, nonatomic) SKProductsRequest *request; //compatibility with old ipad and ios
@property (strong, nonatomic) IBOutlet UIBarButtonItem *onCloudLabel;

@end

@implementation CTTableViewController

static NSString *segueAddID = @"add";
static NSString *segueCellID = @"detail";

static NSString *noteIdx = @"comaddnotenoteindexes";
static NSString *noteCont = @"comaddnotefullstore";
//static NSString *hasPaidKey = @"com.icloud.key.hasPaid";
static NSString *isIAPedkey = @"com.iap.arePurchaseMade";
//static bool isPurchased = NO;

#pragma marks - viewcontroller lifeCycle -
NSNumberFormatter * _priceFormatter;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(updateConents)
//                                                 name:NSUserDefaultsDidChangeNotification
//                                               object:nil];
//
//
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAll)
                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                               object:nil];
//    [[NSNotificationCenter defaultCenter]
//     addObserver: self
//     selector: @selector (resetApplicationAccount)
//     name: NSUbiquityIdentityDidChangeNotification
//     object: nil];
    
    
//     testing reason
//     NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
//     [iCloud setBool:YES forKey:isIAPedkey];
//     [iCloud synchronize];
    
//    [self updateConents];
//    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
    
//    NSLog(@"icloud keys: %@",iCloud.dictionaryRepresentation.allKeys);
    
//    for (NSString *key in iCloud.dictionaryRepresentation.allKeys)
//    {
//        NSLog(@"working icloud...view 2,%@",key);
//    }
    
//    bool isPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:isIAPedkey];
    bool isPurchased = [[NSUbiquitousKeyValueStore defaultStore] boolForKey:isIAPedkey];
    if (!isPurchased) {
//        [self.spinner startAnimating];
        NSLog(@"iCloud said no purchase record ...");
        
//        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
//        [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
    }else{
        
    }
    
    [self updateButtons];
    NSLog(@"finished check");
    
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateConents];
    
    self.tableView.frame = self.view.frame;
}


-(void)updateAll{
    [self updateButtons];
    [self updateConents];
    
}
-(void)updateButtons{
    bool isPurchased = [[NSUbiquitousKeyValueStore defaultStore] boolForKey:isIAPedkey];
    if(isPurchased){
        self.onCloudLabel.title = @"On-iCloud";
        [self.onCloudLabel setTintColor:[UIColor blackColor]];
        self.onCloudLabel.enabled = NO;
    }else{
        self.onCloudLabel.title = @"Not-on-iCloud";
        [self.onCloudLabel setTintColor:[UIColor blackColor]];
        self.onCloudLabel.enabled = NO;
    }

}
-(void)updateConents{
    bool isPurchased = [[NSUbiquitousKeyValueStore defaultStore] boolForKey:isIAPedkey];
    if(isPurchased){
        NSLog(@"Update content: icloud mode");
        NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
        self.notes = [[iCloud objectForKey:noteCont] mutableCopy];
//        NSLog(@"finised %@",self.notes );
//        self.cloudButton.title = @"On-Cloud";
//        [self.cloudButton setTintColor:[UIColor blackColor]];
//        self.cloudButton.enabled = NO;
    }else{
        NSLog(@"Update content: local mode");
        self.notes = [[[NSUserDefaults standardUserDefaults] objectForKey: noteCont] mutableCopy];
    }
    
    // set examples if not data initialized
    if([self.notes count] == 0){
        NSLog(@"Update content: no data");
        self.notes = [self createExampleDictionary];
        [self commitNoteData]; // necessary for push page
    }else{
        NSLog(@"Update content: data available");
    }
    
    
    [self.tableView reloadData];
    
}


#pragma marks - lazy instantiations -

-(NSMutableDictionary *) notes{
    if (_notes == nil) {
        _notes = [[NSMutableDictionary alloc]init];
    }
    return _notes;
}

#pragma marks - IBAction Outlets  -

- (IBAction)purchaseTapped:(id)sender {
    
    if([SKPaymentQueue canMakePayments]){
        self.request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:iapProductIdentifier]];
        self.request.delegate = self;
        [self.request start];

    }
    else{
        NSLog(@"User cannot make payments due to parental controls");
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
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                NSLog(@"Transaction state -> Purchased");
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state from paymentQueue -> Restored");
                //add the same code as you did from SKPaymentTransactionStatePurchased here
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finish
                if(transaction.error.code == SKErrorPaymentCancelled){
                    NSLog(@"Transaction state -> Cancelled");
                    //the user cancelled the payment ;(
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            default:
                
                ;
        }
    }

}


//- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
//{
//    NSLog(@"Transaction state from QueueRestoreCompleted Received Restored transactions: %lu", (unsigned long)queue.transactions.count);
//    for(SKPaymentTransaction *transaction in queue.transactions){
//        if(transaction.transactionState == SKPaymentTransactionStateRestored){
//            //called when the user successfully restores a purchase
//            NSLog(@"Transaction state from QueueRestoreCompleted -> Restored");
//            
//            
//            NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
//            [ud setBool:YES forKey:isIAPedkey];
//            [ud synchronize];
//
//            [self updateConents];
//            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//            break;
//        }
//    }
//    [self.spinner stopAnimating];
//}

- (void)commitPurchase{
    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
    [iCloud setObject:[self.notes copy] forKey:noteCont];
    [iCloud setBool:YES forKey:isIAPedkey];
    [iCloud synchronize];
    
//    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
//    [ud setBool:YES forKey:isIAPedkey];
//    [ud synchronize];
//    
    [self updateConents];
    [self updateButtons];
    NSLog(@"purchase syn and commited");
}

- (void)commitNoteData{
    bool isPurchased = [[NSUbiquitousKeyValueStore defaultStore] boolForKey:isIAPedkey];
    if(isPurchased){
        NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
        [iCloud setObject:self.notes forKey:noteCont];
        [iCloud synchronize];
        
    }else{
        NSUserDefaults *ud = [[NSUserDefaults alloc]init];
        [ud setObject:self.notes forKey:noteCont];
        [ud synchronize];
    }
}

//-(void)resetApplicationAccount{
//    NSLog(@"app reset called ...");
//    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
//    [ud setBool:NO forKey:isIAPedkey];
//    [ud synchronize];
//    [self updateConents];
//
//}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.notes count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bill" forIndexPath:indexPath];
    
    NSArray*keys_unsort =[self.notes allKeys];
    NSArray* keys = [keys_unsort sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    unsigned inversedIdx = (unsigned)(self.notes.count -indexPath.row - 1);
    NSString *timekey = keys[inversedIdx];
    
    
    //date interpretation
    
    NSArray*pieces = [timekey componentsSeparatedByString:BILL_DICCONTENT];
    NSString * timeStampString;
    if ([pieces count] > 1) {
        timeStampString =[pieces objectAtIndex:1];
    }else{
        timeStampString =timekey;
    }
    
    NSTimeInterval _interval=[timeStampString doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
    NSDateFormatter *_formatter=[[NSDateFormatter alloc]init];
    [_formatter setDateFormat:@"dd/MM/yyyy HH:mm"];
    NSString *_date=[_formatter stringFromDate:date];
    
    //title build
    NSString *title = @"default";
    
    NSDictionary *composed;
    
    
    composed = (NSDictionary*)[self.notes objectForKey:timekey];
    if (composed != nil) {
        title = [composed objectForKey:BILL_DICTITLE];
    }
    
    cell.textLabel.text = title;
    cell.detailTextLabel.text = _date;
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}



// Override to support editing the table view. DELETE
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSArray*keys_unsort =[self.notes allKeys];
    NSArray* keys = [keys_unsort sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    unsigned inversedIdx = (unsigned)(self.notes.count -indexPath.row - 1);
    NSString *timekey = keys[inversedIdx];
    
    [self.notes removeObjectForKey:timekey];
    bool isPurchased = [[NSUbiquitousKeyValueStore defaultStore] boolForKey:isIAPedkey];
    if(isPurchased){
        NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
        [iCloud setObject:self.notes forKey:noteCont];
        [iCloud synchronize];
        
    }else{
        NSUserDefaults *ud = [[NSUserDefaults alloc]init];
        [ud setObject:self.notes forKey:noteCont];
        [ud synchronize];
    }
    
    
    [self.tableView reloadData];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    NSIndexPath *indexPath = nil;
    
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    }
    
    if ([segue.identifier isEqualToString:segueAddID]) {
        NSString *timestamp = [NSString stringWithFormat: @"%f", [[NSDate date]timeIntervalSince1970]];
        
        
        [self.tableView reloadData];
        
        if ([segue.destinationViewController respondsToSelector:@selector(setBillID:)]) {
            [segue.destinationViewController performSelector:@selector(setBillID:) withObject:timestamp];
        }
    }else if ([segue.identifier isEqualToString:segueCellID]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setBillID:)]) {
            
            NSArray*keys_unsort =[self.notes allKeys];
            NSArray* keys = [keys_unsort sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            unsigned inversedIdx = (unsigned)(self.notes.count -indexPath.row - 1);
            NSString *timekey = keys[inversedIdx];
            
            [segue.destinationViewController performSelector:@selector(setBillID:) withObject:timekey];
        }
    }
}




#pragma marks - toolkits -




- (NSMutableDictionary *)createExampleDictionary{
    NSDictionary *eg1 = @{BILL_DICTITLE: @"trip with friends (example)", BILL_DICSUM: @"33.00", BILL_DICCONTENT:@"trip with friends\n\n12 Jim tickets\n8   Mark parking\n-2   2 coins found on road\n15 Emmy bought cookies\n"};
    
    NSDictionary *eg2 = @{BILL_DICTITLE: @"bookings (example)", BILL_DICSUM: @"880.00", BILL_DICCONTENT:@"bookings\n\n360 car rental\n420 hotel\n80 trains\n20 museum reservation\n\n"};
    
    NSDictionary *eg3 = @{BILL_DICTITLE: @"Milan oct. 12th (example)", BILL_DICSUM: @"98.00", BILL_DICCONTENT:@"milan oct. 12th\n\n10 airport Bus\n5 coffee\n10 kfc\n18 dinner\n40 hotel\n3 metro\n12 gifts"};
    
    NSMutableDictionary *exampledic=[[NSMutableDictionary alloc] init];
    [exampledic setValue:eg1 forKey:@"1505462367.326380"];
    [exampledic setValue:eg2 forKey:@"1505462354.214234"];
    [exampledic setValue:eg3 forKey:@"1505462363.529691"];
    
    return exampledic;
}
@end
