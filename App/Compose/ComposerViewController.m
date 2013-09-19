//
//  ComposerViewController.m
//  ThatInbox
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "ComposerViewController.h"
#import "FlatUIKit.h"
#import "UIPopoverController+FlatUI.h"
#import "AuthManager.h"
#import "TRAutocompleteView.h"
#import "TRAddressBookSource.h"
#import "TRAddressBookCellFactory.h"
#import "NSString+Email.h"

#import "MCOMessageView.h"

#import "DelayedAttachment.h"
#import "FPMimetype.h"

typedef enum
{
    ToTextFieldTag,
    CcTextFieldTag,
    SubjectTextFieldTag
}TextFildTag;

@interface ComposerViewController ()

@end

@implementation ComposerViewController {
    NSString *_toString;
    NSString *_ccString;
    NSString *_bccString;
    NSString *_subjectString;
    NSString *_bodyString;
    NSArray *_attachmentsArray;
    NSArray *_delayedAttachmentsArray;
    TRAutocompleteView *_autocompleteView;
    TRAutocompleteView *_autocompleteViewCC;
    
    UIPopoverController *pop;
    
    BOOL keyboardState;
}

@synthesize toField, ccField, subjectField, messageBox;

- (id)initWithMessage:(MCOIMAPMessage *)msg
               ofType:(NSString*)type
              content:(NSString*)content
          attachments:(NSArray *)attachments
   delayedAttachments:(NSArray *)delayedAttachments
{
    self = [super init];
    
    NSArray *recipients = @[];
    NSArray *cc = @[];
    NSArray *bcc = @[];
    NSString *subject = [[msg header] subject];
    
    if ([type isEqual: @"Forward"]){
        //TODO: Will crash if subject is null
        if (subject){
            subject = [[[msg header] forwardHeader] subject];
        }
    }
    
    if ( [@[@"Reply", @"Reply All"] containsObject:type]){
        
        subject = [[[msg header] replyHeaderWithExcludedRecipients:@[]] subject];
        recipients = @[[[[[msg header] replyHeaderWithExcludedRecipients:@[]] to] mco_nonEncodedRFC822StringForAddresses]];
        //recipients = @[[[[msg header] from] RFC822String]];
    }
    if ( [@[@"Reply All"] containsObject:type]){
        cc = @[[[[[msg header] replyAllHeaderWithExcludedRecipients:@[]] cc] mco_nonEncodedRFC822StringForAddresses]];
    }
    
    NSString *body = @"";
    if (content){
        NSString *date = [NSDateFormatter localizedStringFromDate:[[msg header] date]
                                                        dateStyle:NSDateFormatterMediumStyle
                                                        timeStyle:NSDateFormatterMediumStyle];
        
        NSString *replyLine = [NSString stringWithFormat:@"On %@, %@ wrote:", date, [[[msg header] from]nonEncodedRFC822String] ];
        body = [NSString stringWithFormat:@"\n\n\n%@\n> %@", replyLine, [content stringByReplacingOccurrencesOfString:@"\n" withString:@"\n> "]];
    }
    return [self initWithTo:recipients CC:cc BCC:bcc subject:subject message:body attachments:attachments delayedAttachments:delayedAttachments];
}

- (id)initWithTo:(NSArray *)to
              CC:(NSArray *)cc
             BCC:(NSArray *)bcc
         subject:(NSString *)subject
         message:(NSString *)message
     attachments:(NSArray *)attachments
delayedAttachments:(NSArray *)delayedAttachments
{
    self = [super init];
    
    _toString = [self emailStringFromArray:to];
    _ccString = [self emailStringFromArray:cc];
    _bccString = [self emailStringFromArray:bcc];
    _subjectString = subject;
    if ([message length] > 0){
        _bodyString = message;
    } else {
        _bodyString = @"";
    }
    _attachmentsArray = attachments;
    _delayedAttachmentsArray = delayedAttachments;
    
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    toField.text = _toString;
    ccField.text = _ccString;
    subjectField.text = _subjectString;
    messageBox.text = _bodyString;
    
    TRAddressBookSource *source = [[TRAddressBookSource alloc] initWithMinimumCharactersToTrigger:2];
    TRAddressBookCellFactory *cellFactory = [[TRAddressBookCellFactory alloc] initWithCellForegroundColor:[UIColor blackColor] fontSize:16];
    _autocompleteView = [TRAutocompleteView autocompleteViewBindedTo:toField
                                                         usingSource:source
                                                         cellFactory:cellFactory
                                                        presentingIn:self.navigationController];
    
    _autocompleteViewCC = [TRAutocompleteView autocompleteViewBindedTo:ccField
                                                         usingSource:source
                                                         cellFactory:cellFactory
                                                        presentingIn:self.navigationController];

    for (TRAutocompleteView *av in @[_autocompleteView, _autocompleteViewCC]){
        av.separatorColor = [UIColor whiteColor];
    }

    
    
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController.navigationBar configureFlatNavigationBarWithColor:[UIColor cloudsColor]];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Discard"
                                                                   style:UIBarButtonItemStyleDone target:self action:@selector(closeWindow:)];
    
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send"
                                                                   style:UIBarButtonItemStyleDone target:self action:@selector(sendEmail:)];
    
    for (UIBarButtonItem *bb in @[backButton, sendButton]){
        [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor peterRiverColor], UITextAttributeTextColor, [UIColor clearColor], UITextAttributeTextShadowColor, nil] forState:UIControlStateNormal];
        [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor belizeHoleColor], UITextAttributeTextColor, nil] forState:UIControlStateHighlighted];
        [bb setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"HelveticaNeue" size:16.0], UITextAttributeFont, [UIColor lightGrayColor], UITextAttributeTextColor, [UIColor clearColor], UITextAttributeTextShadowColor, nil] forState:UIControlStateDisabled];

    }
    
    self.navigationItem.leftBarButtonItem = backButton;
    self.navigationItem.rightBarButtonItem = sendButton;
    self.navigationItem.title = @"Compose";
    [self updateSendButton];
    
    if (([_attachmentsArray count] + [_delayedAttachmentsArray count]) > 0) {
    
        self.navigationController.toolbarHidden = NO;
        [self.navigationController.toolbar setBackgroundImage:[UIImage imageWithColor:[UIColor cloudsColor] cornerRadius:3] forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
        
        
        
        NSMutableArray *attachmentLabels = [[NSMutableArray alloc] init];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 32)];
        label.font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
        label.backgroundColor = [UIColor clearColor];
        label.text = @"Attachments";
        UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView: label];
        [attachmentLabels addObject:title];

        
        for (MCOAttachment* a in _attachmentsArray){
            
            UIButton *label = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 150, 32)];
            [label setTitleColor:[UIColor midnightBlueColor] forState:UIControlStateNormal];
            [label.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0]];
            //TODO: hack to scoot the text over to the right to make room for image view.
            [label setTitle:[NSString stringWithFormat:@"         %@", a.filename] forState:UIControlStateNormal];
            [label addTarget:self action:@selector(attachmentTapped:) forControlEvents:UIControlEventTouchUpInside];

            UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
            NSString *pathToIcon = [FPMimetype iconPathForMimetype:[a mimeType] Filename:[a filename]];
            if ([pathToIcon isEqualToString:@"page_white_picture.png"]){
                    imageview.image = [UIImage imageWithData:[a data]];
            } else {
                imageview.image = [UIImage imageNamed:pathToIcon];
            }
            imageview.contentMode = UIViewContentModeScaleAspectFit;
            [label addSubview:imageview];

            UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView: label];
            [attachmentLabels addObject:title];

        }
        
        for (DelayedAttachment* da in _delayedAttachmentsArray){
            UIButton *label = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 150, 32)];
            [label setTitleColor:[UIColor midnightBlueColor] forState:UIControlStateNormal];
            [label.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:14.0]];
            //TODO: hack to scoot the text over to the right to make room for image view.
            [label setTitle:[NSString stringWithFormat:@"         %@", da.filename] forState:UIControlStateNormal];
            [label addTarget:self action:@selector(attachmentTapped:) forControlEvents:UIControlEventTouchUpInside];

            
            UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
            NSString *pathToIcon = [FPMimetype iconPathForMimetype:[da mimeType] Filename:[da filename]];
            imageview.image = [UIImage imageNamed:pathToIcon];
            imageview.contentMode = UIViewContentModeScaleAspectFit;
            [label addSubview:imageview];
        
            [self grabDataWithBlock:^NSData *{
                return [da getData];
            } completion:^(NSData *data) {
                if ([pathToIcon isEqualToString:@"page_white_picture.png"]){
                    imageview.image = [UIImage imageWithData:data];
                }
                
                MCOAttachment *attachment = [[MCOAttachment alloc] init];
                attachment.data = data;
                attachment.filename = da.filename;
                attachment.mimeType = da.mimeType;
                _attachmentsArray = [_attachmentsArray arrayByAddingObject:attachment];
                
                @synchronized(self) {
                    NSMutableArray *delayedMut = [NSMutableArray arrayWithArray:_delayedAttachmentsArray];
                    [delayedMut removeObject:da];
                    _delayedAttachmentsArray = delayedMut;
                }
                [self updateSendButton];
            }];
            
            UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView: label];
            [attachmentLabels addObject:title];
        }
        
        [self setToolbarItems:attachmentLabels];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    keyboardState = NO;
 
    [toField becomeFirstResponder];
}

- (void)grabDataWithBlock: (NSData* (^)(void))dataBlock completion:(void(^)(NSData *data))callback {
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
        NSData *data = dataBlock();
        callback(data);
    });
}

- (void)updateSendButton {
    if ([_delayedAttachmentsArray count] > 0)
    {
        self.navigationItem.rightBarButtonItem.title = @"Sending disabled while loading attachments";
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    else
    {
        self.navigationItem.rightBarButtonItem.title = @"Send";
        self.navigationItem.rightBarButtonItem.enabled = [toField.text isEmailValid];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIKeyboardDidShowNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIKeyboardWillHideNotification
     object:nil];
}

- (void) closeWindow:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) sendEmail:(id)sender {
    
    //Additional check
    if (![toField.text isEmailValid])
    {
        FUIAlertView *alertView = [[FUIAlertView alloc] initWithTitle:@"Invalid Email Address"
                                                              message:@"Please enter a valid email address for a recipient"
                                                             delegate:nil
                                                    cancelButtonTitle:@"Dismiss"
                                                    otherButtonTitles:nil,
         nil];
        
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
        
        [self updateSendButton];
        return;
    }
    
    [self sendEmailto:[self emailArrayFromString:toField.text]
                   cc:[self emailArrayFromString:ccField.text]
                  bcc:@[]
          withSubject:subjectField.text
             withBody:[messageBox.text stringByReplacingOccurrencesOfString:@"\n" withString:@"<br />"]
      withAttachments:_attachmentsArray];
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Keyboard Listeners

- (int) keyboardHeight {
    int adjustment = 0;
    if (([_attachmentsArray count] + [_delayedAttachmentsArray count]) > 0) {
        adjustment = 44;
    }
    
    //44 is an adjustment for the attachments bar.
    if(UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        return 264 - adjustment;
    } else {
        return 352 - adjustment;
    }
}

- (void) keyboardWasShown:(id)sender {
    keyboardState = YES;
    self.view.frame = CGRectMake(self.view.frame.origin.x,
                                  self.view.frame.origin.y,
                                  self.view.frame.size.width,
                                  self.view.frame.size.height-[self keyboardHeight]);
    NSLog(@"Keyboard shown");
}

- (void) keyboardWillHide:(id)sender {
    keyboardState = NO;
    NSLog(@"Keyboard hiding");
    self.view.frame = CGRectMake(self.view.frame.origin.x,
                                 self.view.frame.origin.y,
                                 self.view.frame.size.width,
                                 self.view.frame.size.height+[self keyboardHeight]);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (keyboardState){
        if(UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
            self.view.frame = CGRectMake(self.view.frame.origin.x,
                                         self.view.frame.origin.y,
                                         self.view.frame.size.width,
                                         self.view.frame.size.height+264-352);
        } else {
            self.view.frame = CGRectMake(self.view.frame.origin.x,
                                         self.view.frame.origin.y,
                                         self.view.frame.size.width,
                                         self.view.frame.size.height+352-264);
        }

    }
}

#pragma mark - EMAIL HELPERS

- (NSString*) emailStringFromArray:(NSArray*) emails {
    return [emails componentsJoinedByString:@", "];
}

- (NSArray *) emailArrayFromString:(NSString*) emailstring {
    //Need to remove empty emails with trailing ,
    NSArray *emails = [emailstring componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
    NSPredicate *notBlank = [NSPredicate predicateWithFormat:@"length > 0 AND SELF != ' '"];
    
    return [emails filteredArrayUsingPredicate:notBlank];
}

- (void)sendEmailto:(NSArray*)to
                 cc:(NSArray*)cc
                bcc:(NSArray*)bcc
        withSubject:(NSString*)subject
           withBody:(NSString*)body
    withAttachments:(NSArray*)attachments
{
    MCOSMTPSession *smtpSession = [[AuthManager sharedManager] getSmtpSession];
    
    NSString *username = smtpSession.username;
    
    MCOMessageBuilder * builder = [[MCOMessageBuilder alloc] init];
    [[builder header] setFrom:[MCOAddress addressWithDisplayName:nil mailbox:username]];
    NSMutableArray *toma = [[NSMutableArray alloc] init];
    for(NSString *toAddress in to) {
        MCOAddress *newAddress = [MCOAddress addressWithMailbox:toAddress];
        [toma addObject:newAddress];
    }
    [[builder header] setTo:toma];
    NSMutableArray *ccma = [[NSMutableArray alloc] init];
    for(NSString *ccAddress in cc) {
        MCOAddress *newAddress = [MCOAddress addressWithMailbox:ccAddress];
        [ccma addObject:newAddress];
    }
    [[builder header] setCc:ccma];
    NSMutableArray *bccma = [[NSMutableArray alloc] init];
    for(NSString *bccAddress in bcc) {
        MCOAddress *newAddress = [MCOAddress addressWithMailbox:bccAddress];
        [bccma addObject:newAddress];
    }
    [[builder header] setBcc:bccma];
    [[builder header] setSubject:subject];
    [builder setHTMLBody:body];
    
    NSLog(@"Body: %@", body);
    
    /* Sending attachments */
    if ([attachments count] > 0){
        [builder setAttachments:attachments];
    }
    
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

- (IBAction)attachmentTapped:(id)sender
{
    //TODO: Implement delete, preview.
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField.tag == ToTextFieldTag)
    {
        [self updateSendButton];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.tag == ToTextFieldTag)
    {
        [self updateSendButton];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSUInteger nextTextFieldTag = textField.tag + 1;
    [textField resignFirstResponder];
    if (nextTextFieldTag < 3)
    {
        UITextField *newTextField = (UITextField *)[self.view viewWithTag:nextTextFieldTag];
        [newTextField becomeFirstResponder];
    }
    else if (nextTextFieldTag == 3)
    {
        [messageBox becomeFirstResponder];
        return NO;
    }
    
    return YES;
}

@end
