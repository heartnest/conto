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
@property (strong,nonatomic) NSMutableArray *bills;
@end

@implementation CTTableViewController

static NSString *segueAddID = @"add";
static NSString *segueCellID = @"detail";

static NSString *dbID = @"billsUserDefaultID";



- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    SKProduct *validProduct = nil;
    int count =(int)[response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        NSLog(@"Products Available!");
//        [self purchase:validProduct];
    }
    
    if(!validProduct){
        NSLog(@"No products available");
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
            case SKPaymentTransactionStatePurchasing: NSLog(@"Transaction state -> Purchasing");
                //called when the user is in the process of purchasing, do not add any of your own code here.
                break;
            case SKPaymentTransactionStatePurchased:
                //this is called when the user has successfully purchased the package (Cha-Ching!)
//                [self doRemoveAds];
                NSLog(@"Just purchased");
                //you can add your code for what you want to happen when the user buys the purchase here, for this tutorial we use removing ads
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                NSLog(@"Transaction state -> Purchased");
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
#pragma marks - viewcontroller lifeCycle -

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // load data from iClould and save em in Userlocal
    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
//    NSData *data = [iCloud objectForKey:dbID];
    NSMutableArray *data_array = (NSMutableArray*)[iCloud objectForKey:dbID];

//
//    NSDictionary *myDictionary = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
//    NSMutableArray *data_array = (NSMutableArray*)[NSKeyedUnarchiver unarchiveObjectWithData:data];
//
//    NSLog(@"data_array %@",data_array);
    
//    self.bills = [myDictionary mutableCopy];
    
//    NSMutableArray *tarr = [[[NSUserDefaults standardUserDefaults] objectForKey: dbID] mutableCopy];
//    NSLog(@"data_array %@",tarr);
//    self.bills = [[[NSUserDefaults standardUserDefaults] objectForKey: dbID] mutableCopy];
    self.bills = [data_array mutableCopy];
//    self.bills = [[[NSUserDefaults standardUserDefaults] objectForKey: dbID] mutableCopy];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
    self.tableView.frame = self.view.frame;
}

#pragma marks - lazy instantiations -

-(NSMutableArray *) bills{
    if (_bills == nil) {
        _bills = [[NSMutableArray alloc]init];
    }
    return _bills;
}
- (IBAction)purchase:(id)sender {
    NSLog(@"User requests to remove ads");
    if([SKPaymentQueue canMakePayments]){
        NSLog(@"User can make payments");
        
        //If you have more than one in-app purchase, and would like
        //to have the user purchase a different product, simply define
        //another function and replace kRemoveAdsProductIdentifier with
        //the identifier for the other product
        
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
   return [self.bills count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bill" forIndexPath:indexPath];
    
    unsigned inversedIdx = (unsigned)(self.bills.count -indexPath.row - 1);
    
    //date interpretation
    NSString * timeStampString =[self.bills objectAtIndex:inversedIdx];
    NSTimeInterval _interval=[timeStampString doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
    NSDateFormatter *_formatter=[[NSDateFormatter alloc]init];
    [_formatter setDateFormat:@"dd/MM/yyyy HH:mm"];
    NSString *_date=[_formatter stringFromDate:date];
    
    //title build
    NSString *title = @"default";
    NSString *billDictionaryID = [BILL_DICCONTENT stringByAppendingString:timeStampString];
    
//    NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
//    NSDictionary *composed = [sd dictionaryForKey: billDictionaryID];
//    
    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
//    NSData *data = [iCloud objectForKey:billDictionaryID];
//    NSDictionary *composed = (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSDictionary *composed = (NSDictionary*)[iCloud objectForKey:billDictionaryID];
    
    
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
    NSInteger cellnum = (long)indexPath.row;
    NSString *ts = [self.bills objectAtIndex:[self.bills count]-1-cellnum];
    [self.bills removeObjectAtIndex:[self.bills count]-1-cellnum];
   
//    NSUserDefaults *ud = [[NSUserDefaults alloc]init];
//    [ud setObject:self.bills forKey:dbID];
//    [ud removeObjectForKey:[BILL_DICCONTENT stringByAppendingString:ts]];
//    [ud synchronize];
//    
 
    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
    [iCloud setObject:self.bills forKey:dbID];
    [iCloud removeObjectForKey:[BILL_DICCONTENT stringByAppendingString:ts]];
    [iCloud synchronize];

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
        
        [self.bills addObject:timestamp];
        
        
//        NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
//        [sd setObject:[self.bills copy] forKey:dbID];
//        [sd synchronize];
        
        NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
        [iCloud setObject:[self.bills copy] forKey:dbID];
        [iCloud synchronize];

        
        [self.tableView reloadData];
        
        if ([segue.destinationViewController respondsToSelector:@selector(setBillID:)]) {
            [segue.destinationViewController performSelector:@selector(setBillID:) withObject:timestamp];
        }
    }else if ([segue.identifier isEqualToString:segueCellID]) {
        if ([segue.destinationViewController respondsToSelector:@selector(setBillID:)]) {
        
            NSInteger cellnum = (long)indexPath.row;
            //  NSMutableArray *tmp = [self.bills mutableCopy];
            NSString *ts = [self.bills objectAtIndex:[self.bills count]-1-cellnum];
            [segue.destinationViewController performSelector:@selector(setBillID:) withObject:ts];
        }
    }
}


@end
