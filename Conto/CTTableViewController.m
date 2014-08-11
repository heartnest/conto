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

@interface CTTableViewController ()
@property (strong,nonatomic) NSMutableArray *bills;
@end

@implementation CTTableViewController

static NSString *segueAddID = @"add";
static NSString *segueCellID = @"detail";

static NSString *dbID = @"billsUserDefaultID";



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bills = [[[NSUserDefaults standardUserDefaults] objectForKey: dbID] mutableCopy];
    
//    NSString *cn = [[NSUserDefaults standardUserDefaults] objectForKey:@"thedictionarykeyforbillcontent1407717343.501618"];
//    
//    NSLog(@"%@",cn);
    
}

-(NSMutableArray *) bills{
    if (_bills == nil) {
        _bills = [[NSMutableArray alloc]init];
    }
    return _bills;
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
    
    NSString * timeStampString =[self.bills objectAtIndex:inversedIdx];
    NSTimeInterval _interval=[timeStampString doubleValue];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
    NSDateFormatter *_formatter=[[NSDateFormatter alloc]init];
    [_formatter setDateFormat:@"dd/MM/yyyy HH:mm"];
    NSString *_date=[_formatter stringFromDate:date];
    
    
    cell.textLabel.text = _date;
    
    
    //NSLog(@"%@",[BILL_DICCONTENT stringByAppendingString:timeStampString]);
    
    return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger cellnum = (long)indexPath.row;
    NSString *ts = [self.bills objectAtIndex:[self.bills count]-1-cellnum];
    [self.bills removeObjectAtIndex:[self.bills count]-1-cellnum];
   
    NSUserDefaults *ud = [[NSUserDefaults alloc]init];
    [ud setObject:self.bills forKey:dbID];
    [ud removeObjectForKey:[BILL_DICCONTENT stringByAppendingString:ts]];
    [ud synchronize];
    

    [self.tableView reloadData];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    
    NSIndexPath *indexPath = nil;
    
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
            indexPath = [self.tableView indexPathForCell:sender];
    }

    if ([segue.identifier isEqualToString:segueAddID]) {
        NSString *timestamp = [NSString stringWithFormat: @"%f", [[NSDate date]timeIntervalSince1970]];
        
        [self.bills addObject:timestamp];
        
        NSUserDefaults *sd = [NSUserDefaults standardUserDefaults];
        [sd setObject:[self.bills copy] forKey:dbID];
        [sd synchronize];

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
