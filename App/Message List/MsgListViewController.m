//
//  MsgListViewController.m
//  ThatInbox
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "MsgListViewController.h"
#import <MailCore/MailCore.h>
#import "FXKeychain.h"
#import "MCTMsgViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "UINavigationBar+FlatUI.h"

#import "ComposerViewController.h"
#import "AuthManager.h"

#import "AppDelegate.h"
#import "StandaloneStatsEmitter.h"

@interface MsgListViewController ()

@property (nonatomic, strong) NSMutableDictionary *cache;

@property (nonatomic, strong) NSArray *messages;

@property (nonatomic, strong) MCOIMAPOperation *imapCheckOp;
@property (nonatomic, strong) MCOIMAPFetchMessagesOperation *imapMessagesFetchOp;

@end

@implementation MsgListViewController

- (void)viewDidLoad {
	[super viewDidLoad];
    
    if (!self.folder){
        self.folder = @"INBOX";
    }
    self.cache = [[NSMutableDictionary alloc] init];
	
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor cloudsColor]];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor asbestosColor];
    [refreshControl addTarget:self action:@selector(loadEmails:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    self.detailViewController = (MessageDetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    for (UIBarButtonItem *bb in @[self.navigationItem.rightBarButtonItem, self.navigationItem.leftBarButtonItem]){
        [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor peterRiverColor], UITextAttributeTextColor, [UIColor clearColor], UITextAttributeTextShadowColor, nil] forState:UIControlStateNormal];
        [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor belizeHoleColor], UITextAttributeTextColor, nil] forState:UIControlStateHighlighted];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedAuth) name:@"Finished_OAuth" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedFirstAuth) name:@"Finished_FirstOAuth" object:nil];
    
    [AuthManager sharedManager];
    
    [self.refreshControl beginRefreshing];
}

- (void) finishedAuth {
    [self loadAccount];
}

- (void) finishedFirstAuth {
    //For the first time you're here, we add a fake email to your account
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self sendInkEmails];
    });
}

- (void) sendInkEmails {
    MCOSMTPSession *smtpSession = [[AuthManager sharedManager] getSmtpSession];
    if (!smtpSession) {
        return;
    }
    
    NSString *username = smtpSession.username;
    
    MCOMessageBuilder * builder = [[MCOMessageBuilder alloc] init];
    [[builder header] setFrom:[MCOAddress addressWithDisplayName:@"Ink" mailbox:@"contact@inkmobility.com"]];
    [[builder header] setTo:@[[MCOAddress addressWithMailbox:username]]];
    [[builder header] setSubject:@"Getting started with Ink"];
    NSString *emailBody = @"<img src='https://www.filepicker.io/api/file/OzsadPDnQWeMIQMgs3lo' width=500 alt='A sample file to get you started with Ink'/><p>Enjoy! Let us know if you have any feedback at <a href='mailto:contact@inkmobility.com'>contact@inkmobility.com</a>.</p>";
    [builder setHTMLBody:emailBody];
    
    /* Sending attachments */
    MCOAttachment *attachment = [[MCOAttachment alloc] init];
    UIImage *photo = [UIImage imageNamed:@"InkSampleImage.jpg"];
    NSData *imageData = UIImageJPEGRepresentation(photo, 0.9);
    [attachment setData:imageData];
    [attachment setMimeType:@"image/jpeg"];
    [attachment setFilename:@"Ink Sample.jpg"];
    
    [builder setAttachments:@[attachment]];
    
    NSData * rfc822Data = [builder data];
    
    MCOSMTPSendOperation *sendOperation = [smtpSession sendOperationWithData:rfc822Data];
    [sendOperation start:^(NSError *error) {
        if(error) {
            NSLog(@"%@ Error sending email:%@", username, error);
        } else {
            NSLog(@"%@ Successfully sent email!", username);
        }
    }];
}

- (void)loadAccount
{
    MsgListViewController * __weak weakSelf = self;
	NSLog(@"checking account");
	self.imapCheckOp = [[[AuthManager sharedManager] getImapSession] checkAccountOperation];
	[self.imapCheckOp start:^(NSError *error) {
		MsgListViewController *strongSelf = weakSelf;
		NSLog(@"finished checking account.");
		if (error == nil) {
			[strongSelf loadEmailsWithCache:NO];
		} else {
			NSLog(@"error loading account: %@", error);
            [[AuthManager sharedManager] logout];
            [[AuthManager sharedManager] refresh];
		}
		
		strongSelf.imapCheckOp = nil;
	}];
}

- (void)loadEmailsWithCache:(BOOL)allowed {
    NSString *folderName = self.folder;
    
    if (allowed){
        NSArray *lookup = [self.cache objectForKey:folderName];
        if (lookup){
            NSLog(@"CACHE HIT %@", folderName);
            self.messages = lookup;
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
            return;
        }
        NSLog(@"CACHE MISS %@", folderName);
    }
    
    void(^completionWithLoad)(NSError*, NSArray*, MCOIndexSet*) =
    ^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages){
        self.messages = messages;
        [self.cache setValue:messages forKey:folderName];
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    };
    
    [self loadEmailsFromFolder:folderName WithCompletion:completionWithLoad];
}

- (void)loadEmails:(id)sender {
    [self loadEmailsWithCache:NO];
}

- (void)loadEmailsFromFolder:(NSString*)folderName WithCompletion:(void(^)(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages))block {
    
    if ([folderName isEqualToString:@"ATTACHMENTS"]){
        return [self loadEmailsWithAttachmentsWithCompletion:block];
    }
    

	MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)
	(MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure |
	 MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject |
	 MCOIMAPMessagesRequestKindFlags);
    
    //Get inbox information. Then grab the 50 most recent mails.
    MCOIMAPFolderInfoOperation *folderInfo = [[[AuthManager sharedManager] getImapSession] folderInfoOperation:self.folder];
    
    [folderInfo start:^(NSError *error, MCOIMAPFolderInfo *info) {
        
        int messageCount = [info messageCount];
        int numberOfMessages = 50;
        if (messageCount <= numberOfMessages){
            numberOfMessages = messageCount-1;
        }
        MCOIndexSet *numbers = [MCOIndexSet indexSetWithRange:MCORangeMake(messageCount - numberOfMessages, numberOfMessages)];
        
        self.imapMessagesFetchOp = [[[AuthManager sharedManager] getImapSession]
                                    fetchMessagesByNumberOperationWithFolder:folderName
                                    requestKind:requestKind
                                    numbers:numbers];
        
        [self.imapMessagesFetchOp start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
            block(error, [messages sortedArrayUsingDescriptors:@[sort]], vanishedMessages);
        }];
    }];
}


- (void)loadEmailsWithAttachmentsWithCompletion:(void(^)(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages))block {

    NSString *folderParent = self.folderParent;
    if (!folderParent){
        folderParent = @"[Gmail]/All Mail";
    }
    
	MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)
	(MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure |
	 MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject |
	 MCOIMAPMessagesRequestKindFlags);
    
    MCOIMAPFolderInfoOperation *folderInfo = [[[AuthManager sharedManager] getImapSession] folderInfoOperation:folderParent];
    
    [folderInfo start:^(NSError *error, MCOIMAPFolderInfo *info) {
        
        int messageCount = [info messageCount];
        int numberOfMessages = 200;
        if (messageCount <= numberOfMessages){
            numberOfMessages = messageCount-1;
        }
        MCOIndexSet *numbers = [MCOIndexSet indexSetWithRange:MCORangeMake(messageCount - numberOfMessages, numberOfMessages)];
        
        self.imapMessagesFetchOp = [[[AuthManager sharedManager] getImapSession]
                                    fetchMessagesByNumberOperationWithFolder:folderParent
                                    requestKind:requestKind
                                    numbers:numbers];
        [self.imapMessagesFetchOp start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"attachments.@count > 0"];
            NSArray *filteredMessages  = [messages filteredArrayUsingPredicate:predicate];
            
            
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
            block(error, [filteredMessages sortedArrayUsingDescriptors:@[sort]], vanishedMessages);
        }];
    }];
}

- (void)archiveMessage:(uint64_t)msgUID {
    
    // Should remove from ui to be more responsive.
    [self removeMessage:msgUID];

    MCOIMAPOperation *op = [[[AuthManager sharedManager] getImapSession] storeFlagsOperationWithFolder:self.folder uids:[MCOIndexSet indexSetWithIndex:msgUID] kind:MCOIMAPStoreFlagsRequestKindSet flags:MCOMessageFlagDeleted];
        
    [op start:^(NSError * error) {
        if(!error) {
            NSLog(@"Updated flags!");
        } else {
            NSLog(@"Error updating flags:%@", error);
        }
        //Must also expunge for the archive to happen
        MCOIMAPOperation *deleteOp = [[[AuthManager sharedManager] getImapSession] expungeOperation:self.folder];
        [deleteOp start:^(NSError *error) {
            if(error) {
                //TODO: should undo if it fails.
                NSLog(@"Error expunging folder:%@", error);
            } else {
                NSLog(@"Successfully expunged folder");
            }
        }];
    }];
}

- (void)removeMessage:(uint64_t) msgUID {
    NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid != %d", msgUID];
    self.messages = [self.messages filteredArrayUsingPredicate:predicate];
    [self.tableView reloadData];

    //Last row issue.
    if (indexPath.row >= [self.messages count]){
        indexPath = [NSIndexPath indexPathForItem:[self.messages count]-1 inSection:indexPath.section];
    }
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:0];
    [self selectRowAtIndexPath:indexPath];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	NSLog(@"%s",__PRETTY_FUNCTION__);
}

- (void)composeEmail:(id)sender {
    ComposerViewController *vc = [[ComposerViewController alloc] initWithTo:@[] CC:@[] BCC:@[] subject:@"" message:@"" attachments:@[] delayedAttachments:@[]];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:nc animated:YES completion:nil];
}

#pragma mark - PKRevealController

- (void)showLeftView:(id)sender
{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.revealController.focusedController == appDelegate.revealController.leftViewController)
    {
        [appDelegate.revealController showViewController:appDelegate.revealController.frontViewController];
    }
    else
    {
        [appDelegate.revealController showViewController:appDelegate.revealController.leftViewController];
    }
}

- (void)hideLeftView:(id)sender
{
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.revealController.focusedController == appDelegate.revealController.leftViewController)
    {
        [appDelegate.revealController showViewController:appDelegate.revealController.frontViewController];
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.messages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor peterRiverColor];
    bgColorView.layer.masksToBounds = YES;
    [cell setSelectedBackgroundView:bgColorView];
    
	MCOIMAPMessage *message = self.messages[indexPath.row];

    cell.textLabel.text = message.header.from.displayName ? message.header.from.displayName : message.header.from.mailbox;
    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    cell.textLabel.textColor = [UIColor grayColor];

    cell.detailTextLabel.text = message.header.subject ? message.header.subject : @"No Subject";
    cell.detailTextLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    cell.detailTextLabel.textColor = [UIColor blackColor];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([[message attachments] count] > 0){
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"attachment.png"]];
    } else {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"blank.png"]];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self selectRowAtIndexPath:indexPath];
}

- (void)selectRowAtIndexPath:(NSIndexPath*)indexPath {
    [[StandaloneStatsEmitter sharedEmitter] sendStat:@"message_selected" withAdditionalStatistics:nil];
    [self hideLeftView:nil];
    
    NSString *folder = self.folder;
    if ([self.folder isEqualToString:@"ATTACHMENTS"]){
        folder = self.folderParent;
    }
    
    MCOIMAPMessage *msg = self.messages[indexPath.row];
    
    self.detailViewController.folder = folder;
    self.detailViewController.message = msg;
    self.detailViewController.session = [[AuthManager sharedManager] getImapSession];
    self.detailViewController.delegate = self;
    [self.detailViewController viewDidLoad];
}

#pragma mark MenuViewDelegate

- (void)loadMailFolder:(NSString *)folderPath withHR:(NSString*) name {
    [self.refreshControl beginRefreshing];
    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
    
    self.title = name;
    if ([name isEqualToString:@"Attachments"]){
        self.folder = @"ATTACHMENTS";
        self.folderParent = folderPath;
    } else {
        self.folder = folderPath;
    }
    [self loadEmailsWithCache:YES];
}

- (void)loadFolderIntoCache:(NSString*)imapPath {
    if (![[AuthManager sharedManager] getImapSession]){
        return;
    }

    NSString *folderName = imapPath;
    if ([folderName isEqualToString:@"Attachments"]) {
        folderName = @"ATTACHMENTS";
    }

    NSLog(@"Loading Folder: %@", folderName);
    NSArray *lookup = [self.cache objectForKey:folderName];
    if (lookup){
        return;
    }
    
    void(^completionNoLoad)(NSError*, NSArray*, MCOIndexSet*) =
    ^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages){
        NSLog(@"CACHE WARM: %@", folderName);
        [self.cache setValue:messages forKey:folderName];
    };
    
    [self loadEmailsFromFolder:folderName WithCompletion:completionNoLoad];
}

- (void)clearMessages {
    self.detailViewController.folder = self.folder;
    self.detailViewController.message = nil;
    self.detailViewController.session = [[AuthManager sharedManager] getImapSession];
    self.detailViewController.delegate = self;
    [self.detailViewController viewDidLoad];
    
    self.messages = @[];
    [self.cache removeAllObjects];
    [self.tableView reloadData];
    
    self.folder = @"INBOX";
}

@end
