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

#define kRemoveAdsProductIdentifier @"harnestlabjishu"

@interface CTTableViewController ()<SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cloudButton;
@property (strong,nonatomic) NSMutableDictionary *notes;
@end

@implementation CTTableViewController

static NSString *segueAddID = @"add";
static NSString *segueCellID = @"detail";

static NSString *noteIdx = @"comaddnotenoteindexes";
static NSString *noteCont = @"comaddnotefullstore";
static NSString *hasPaidKey = @"com.icloud.key.hasPaid";

static bool hasPaid = NO;

#pragma marks - viewcontroller lifeCycle -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    

//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(updateConents)
//                                                 name:NSUserDefaultsDidChangeNotification
//                                               object:nil];
//
//
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(updateConents)
//                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
//                                               object:nil];
    
//     testing reason
//     NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
//     [iCloud setBool:NO forKey:hasPaidKey];
//     [iCloud synchronize];
    
//    [self updateConents];
}


-(void)updateConents{
    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
    hasPaid = [iCloud boolForKey:hasPaidKey];

    if(hasPaid){
        self.notes = [[iCloud objectForKey:noteCont] mutableCopy];
        self.cloudButton.title = @"On Cloud";
        [self.cloudButton setTintColor:[UIColor blackColor]];
        self.cloudButton.enabled = NO;
//        NSLog(@"working in iCloud");
    }else{
        self.notes = [[[NSUserDefaults standardUserDefaults] objectForKey: noteCont] mutableCopy];
//        NSLog(@"working in local");
    }
    
    [self checkContent];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateConents];
    [self.tableView reloadData];
    self.tableView.frame = self.view.frame;
}

#pragma marks - lazy instantiations -

-(NSMutableDictionary *) notes{
    if (_notes == nil) {
        _notes = [[NSMutableDictionary alloc]init];
    }
    return _notes;
}

#pragma marks - IBAction Outlets  -

- (IBAction)purchase:(id)sender {
//    NSLog(@"User requests to remove ads");
    if([SKPaymentQueue canMakePayments]){
//        NSLog(@"User can make payments");
        
        SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kRemoveAdsProductIdentifier]];
        productsRequest.delegate = self;
        [productsRequest start];
        
    }
    else{
        NSLog(@"User cannot make payments due to parental controls");
        //this is called the user cannot make payments, most likely due to parental controls
    }
}


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

    if(hasPaid){
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



#pragma marks - in-app payment handlers -

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    SKProduct *validProduct = nil;
    int count =(int)[response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
//        NSLog(@"Products Available!");
        [self commitPurchase:validProduct];
    }
    
    if(!validProduct){
//        NSLog(@"No products available");
        //this is called if your product id is not valid, this shouldn't be called unless that happens.
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    for(SKPaymentTransaction *transaction in transactions){
        //if you have multiple in app purchases in your app,
        //you can get the product identifier of this transaction
        //by using transaction.payment.productIdentifier
        //
        //then, check the identifier against the product IDs
        //that you have defined to check which product the user
        //just purchased
        
        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing:
//                NSLog(@"Transaction state -> Purchasing");
                //called when the user is in the process of purchasing, do not add any of your own code here.
                break;
            case SKPaymentTransactionStatePurchased:
                //this is called when the user has successfully purchased the package (Cha-Ching!)
                //                [self doRemoveAds];
//                NSLog(@"Just purchased");
                //you can add your code for what you want to happen when the user buys the purchase here, for this tutorial we use removing ads
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//                NSLog(@"Transaction state -> Purchased");
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state -> Restored");
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


- (void)commitPurchase:(SKProduct *)SKProduct{
    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
    hasPaid = YES;
    [iCloud setBool:hasPaid forKey:hasPaidKey];
    [iCloud setObject:[self.notes copy] forKey:noteCont];
    [iCloud synchronize];
    [self updateConents];
    NSLog(@"Syn done");
}


#pragma marks - toolkits -


- (void)checkContent{
    if([self.notes count] == 0){
        self.notes = [self createExampleDictionary];
        [self commitNoteData];
    }
        
}

- (void)commitNoteData{
    if(hasPaid){
        NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
        [iCloud setObject:self.notes forKey:noteCont];
        [iCloud synchronize];
        
    }else{
        NSUserDefaults *ud = [[NSUserDefaults alloc]init];
        [ud setObject:self.notes forKey:noteCont];
        [ud synchronize];
    }
}

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
