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

#import "CTLogin.h"


@interface CTTableViewController ()
@property (strong,nonatomic) NSMutableDictionary *notes;
@property (strong,nonatomic) NSArray *tabuNotes;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *onCloudLabel;

@end

@implementation CTTableViewController

static NSString *segueAddID = @"add";
static NSString *segueCellID = @"detail";

//static NSString *isIAPedkey = @"com.iap.arePurchaseMade";

#pragma marks - viewcontroller lifeCycle -
NSNumberFormatter * _priceFormatter;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(updateConents)
//                                                 name:NSUserDefaultsDidChangeNotification
//                                               object:nil];

//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(updateAll)
//                                                 name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
//                                               object:nil];

    
//    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] init];
//    // Optional: Place the button in the center of your view.
//    loginButton.center = self.view.center;
//    [self.view addSubview:loginButton];
    

//    NSUbiquitousKeyValueStore *iCloud =  [NSUbiquitousKeyValueStore defaultStore];
//    for (NSString *key in iCloud.dictionaryRepresentation.allKeys)
//    {
//        NSLog(@"working icloud...view 2,%@",key);
//    }
    
    [self updateButtons];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSUserDefaults* ud=[NSUserDefaults standardUserDefaults];
    NSString *userid = [ud objectForKey:  NSUD_USERID ];
    NSString *noteKey =  (userid != nil) ?  [NOTEACCOUNT stringByAppendingString:userid] : NOTEACCOUNT;
    if([ud objectForKey: noteKey] == nil && [ud objectForKey: NOTEACCOUNT] != nil){
//        NSLog(@"performing update");
        [ud setObject:[ud objectForKey: NOTEACCOUNT] forKey:noteKey];
        [ud synchronize];
    }
    
    if (userid != nil) {
        NSUserDefaults *ud = [[NSUserDefaults alloc]init];
        NSString *userid = [ud objectForKey:  NSUD_USERID ];
        NSString *limitedNotesKey =   [NOTELIMIT stringByAppendingString:userid];
        self.tabuNotes = [ud objectForKey:limitedNotesKey];
    }
    
    [self updateAll];
    self.tableView.frame = self.view.frame;
}

-(void)updateAll{
    [self updateButtons];
    [self updateConents];
}

-(void)updateButtons{
    NSString *userid = [[NSUserDefaults standardUserDefaults] objectForKey:  NSUD_USERID ];
    if(userid != nil){
        if ([[NSUserDefaults standardUserDefaults] objectForKey:  NSUD_USERNAME ]) {
            self.onCloudLabel.title = [[NSUserDefaults standardUserDefaults] objectForKey:  NSUD_USERNAME ];
        }else{
            self.onCloudLabel.title = [[NSUserDefaults standardUserDefaults] objectForKey:  NSUD_USEREMAIL ];
        }
    }else{
        self.onCloudLabel.title = @"Welcome";
    }
    [self.onCloudLabel setTintColor:[UIColor blackColor]];
    self.onCloudLabel.enabled = NO;
}

-(void)updateConents{
    NSString *userid = [[NSUserDefaults standardUserDefaults] objectForKey:  NSUD_USERID ];
    NSString *noteKey =  (userid != nil) ?  [NOTEACCOUNT stringByAppendingString:userid] : NOTEACCOUNT;

    self.notes = [[[NSUserDefaults standardUserDefaults] objectForKey: noteKey] mutableCopy];

    
    // set examples if not data initialized
    if([self.notes count] == 0){
        self.notes = [self createExampleDictionary];
        [self commitNoteData]; // necessary for push page
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

- (void)commitNoteData{
    NSUserDefaults *ud = [[NSUserDefaults alloc]init];
    NSString *userid = [ud objectForKey:  NSUD_USERID ];
    NSString *noteKey =  (userid != nil) ?  [NOTEACCOUNT stringByAppendingString:userid] : NOTEACCOUNT;
    [ud setObject:self.notes forKey:noteKey];
    [ud synchronize];
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
    
  
    if([self.tabuNotes containsObject:timekey]){
        cell.textLabel.text = [title stringByAppendingString:@"🔒"];
        cell.textLabel.alpha =0.43f;
        cell.detailTextLabel.alpha = 0.43f;
//        cell.userInteractionEnabled = NO;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapLockedCell)];
        [cell addGestureRecognizer:tap];
    }else{
        cell.textLabel.alpha =1;
        cell.detailTextLabel.alpha = 1;
        cell.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapLockedCell)];
        [cell removeGestureRecognizer:tap];
    }
    return cell;
}


-(void)didTapLockedCell{
    [self alert:@"Please purchase in personal page (at the bottom)"];
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
    
    NSString *userid = [[NSUserDefaults standardUserDefaults] objectForKey:  NSUD_USERID ];
    NSString *noteKey =  (userid != nil) ?  [NOTEACCOUNT stringByAppendingString:userid] : NOTEACCOUNT;
    
    NSUserDefaults *ud = [[NSUserDefaults alloc]init];
    [ud setObject:self.notes forKey:noteKey];
    [ud synchronize];

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

-(void)postJsonData:(NSString *)request_url_unsafe{
    NSError *error;
    NSString* request_url = [request_url_unsafe stringByAddingPercentEscapesUsingEncoding:
                             NSASCIIStringEncoding];
//    NSLog(@"%@",request_url);
    NSURL *url = [NSURL URLWithString:request_url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: @"TEST IOS", @"name",
                             @"IOS TYPE", @"typemap",
                             nil];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
    [request setHTTPBody:postData];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        //
        if (data) {
            NSHTTPURLResponse * httpResponse  = (NSHTTPURLResponse*)response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode == 200) {
                NSString* responstr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//                                NSLog(@"%@",responstr);

            }
        }else if (error)
        {
            NSLog(@"Errorrrrrrr....%@",error);
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
