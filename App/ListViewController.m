//
//  ListViewController.m
//  Mailer
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <MailCore/MailCore.h>
#import "ListViewController.h"
#import "AuthManager.h"
#import "UIColor+FlatUI.h"
#import "ListViewCell.h"
#import "FlatUIKit.h"

#import "ATConnect.h"


#import "AppDelegate.h"


@interface ListViewController ()

@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, strong) NSArray* contents;

@end

@implementation ListViewController

@synthesize folderNameLookup;
bool firstLoad = YES;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        folderNameLookup = @{@"Inbox": @"INBOX",
                             @"Sent": @"[Gmail]/Sent Mail",
                             @"All Mail": @"[Gmail]/All Mail",
                             @"Starred": @"[Gmail]/Starred"
                             };
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.clearsSelectionOnViewWillAppear = NO;
 
    

    
    [self setTableContents];
}

- (void)viewDidAppear:(BOOL)animated {
    //Set the selection to inbox if first time.
    if (firstLoad){
        NSIndexPath *indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES  scrollPosition:UITableViewScrollPositionBottom];
        
        MCOIMAPFetchFoldersOperation *fetchFolders = [[[AuthManager sharedManager] getImapSession]  fetchAllFoldersOperation];
        [fetchFolders start:^(NSError *error, NSArray *folders) {
            
            if (error){
                firstLoad = YES;
            }
            
            NSLog(@"Folders: %@", folders);
            NSMutableDictionary *updatedFolderNames = [[NSMutableDictionary alloc] initWithDictionary:folderNameLookup];
            for (MCOIMAPFolder *f in folders){
                if (f.flags == MCOIMAPFolderFlagAll){
                    [updatedFolderNames setObject:f.path forKey:@"All Mail"];
                    [self.delegate setFolderParent:f.path];
                } else if (f.flags& MCOIMAPFolderFlagInbox){
                    [updatedFolderNames setObject:f.path forKey:@"Inbox"];
                } else if (f.flags& MCOIMAPFolderFlagSentMail){
                    [updatedFolderNames setObject:f.path forKey:@"Sent"];
                } else if (f.flags & MCOIMAPFolderFlagStarred){
                    [updatedFolderNames setObject:f.path forKey:@"Starred"];
                }
            }
            folderNameLookup = [NSDictionary dictionaryWithDictionary:updatedFolderNames];
            NSLog(@"New dictionary: %@", updatedFolderNames);
            
            for (NSString* HRName in self.contents){
                if ([HRName isEqualToString:@"Attachments"]){
                    [[self delegate] loadFolderIntoCache:HRName];
                } else {
                    [[self delegate] loadFolderIntoCache:[self pathFromName:HRName]];
                }
            }
        }];

        firstLoad = NO;
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setTableContents {
    
    //TODO: HACK: NOTE: So Gmail allows you to turn on if folders show up or not in imap, so
    //some of these folders might not actually exist...
    self.contents = @[@"Inbox", @"Attachments", @"Sent", @"All Mail", @"Starred"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return [self.contents count];
    } else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ListViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (indexPath.section == 0){
    
        NSInteger idx = indexPath.row;
        NSString *name = [self.contents objectAtIndex:idx];
        cell.textLabel.text = name;
        cell.imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", name]];
        cell.textLabel.textColor = [UIColor cloudsColor];
        
        return cell;
    } else if (indexPath.section == 1) {
        cell.textLabel.text = @"Log Out";
        cell.imageView.image = [UIImage imageNamed:@"Settings.png"];
        cell.textLabel.textColor = [UIColor cloudsColor];
        cell.textLabel.highlightedTextColor = [UIColor asbestosColor];
        
        return cell;
    } else {
        cell.textLabel.text = @"Give Feedback";
        cell.imageView.image = [UIImage imageNamed:@"Settings.png"];
        cell.textLabel.textColor = [UIColor cloudsColor];
        cell.textLabel.highlightedTextColor = [UIColor asbestosColor];
        
        return cell;
    }
}

#pragma mark - Table view delegate

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0){
        return 50;
    } else {
        return 20;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        if (self.delegate){
            NSInteger idx = indexPath.row;
            NSString *HRName = [self.contents objectAtIndex:idx];
            [self.delegate loadMailFolder:[self pathFromName:HRName] withHR:HRName];
        }
    } else if (indexPath.section == 1) {
        FUIAlertView *alertView = [[FUIAlertView alloc] initWithTitle:@"Logout" message:@"Are you sure you want to log out?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Logout", nil];
        alertView.titleLabel.textColor = [UIColor blackColor];
        alertView.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        alertView.messageLabel.textColor = [UIColor asbestosColor];
        alertView.messageLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        alertView.backgroundOverlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        alertView.alertContainer.backgroundColor = [UIColor cloudsColor];
        alertView.defaultButtonColor = [UIColor cloudsColor];
        alertView.defaultButtonShadowColor = [UIColor cloudsColor];
        alertView.defaultButtonFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        alertView.defaultButtonTitleColor = [UIColor belizeHoleColor];
        [alertView show];
        

    } else {
        ATConnect *connection = [ATConnect sharedConnection];
        [connection presentMessageCenterFromViewController:self];
    }
}

- (void)alertView:(FUIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0){
        [self logoutPressed];
    }
}


- (void) logoutPressed {
    //[self showSettingsViewController];
    [self.delegate clearMessages];
    firstLoad = YES;
    [self hideLeftView:nil];
    [[AuthManager sharedManager] logout];
    [[AuthManager sharedManager] refresh];
    
}
- (NSString *)pathFromName:(NSString*) name {
    NSString *imapPath = [self.folderNameLookup objectForKey:name];
    if (!imapPath){
        if ([name isEqualToString:@"Attachments"]){
            imapPath = [self.folderNameLookup objectForKey:@"All Mail"];
        } else {
            imapPath = name;
        }
    }
    return imapPath;
}

- (void)hideLeftView:(id)sender
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.revealController.focusedController == appDelegate.revealController.leftViewController)
    {
        [appDelegate.revealController showViewController:appDelegate.revealController.frontViewController];
    }
}

/*
- (void)showSettingsViewController {
	SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithNibName:nil bundle:nil];
	settingsViewController.delegate = self;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;

    
    [self presentViewController:navigationController animated:YES completion:nil];
    //[self.navigationController pushViewController:settingsViewController animated:NO];
}

- (void)settingsViewControllerFinished:(SettingsViewController *)viewController {
	[self dismissViewControllerAnimated:YES completion:nil];
}
*/

@end
