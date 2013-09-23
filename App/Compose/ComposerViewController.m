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
#import "TRAddressBookSource+GoogleContacts.h"
#import "UIPopoverController+FlatUI.h"
#import "FUIButton.h"
#import "UTIFunctions.h"

#import "MCOMessageView.h"

#import <FPPicker/FPPicker.h>
#import "DelayedAttachment.h"
#import "FPMimetype.h"

typedef enum
{
    ToTextFieldTag,
    CcTextFieldTag,
    SubjectTextFieldTag
}TextFildTag;

@interface ComposerViewController () <FPPickerDelegate, UIPopoverControllerDelegate>
@property (nonatomic, strong) UIPopoverController *filepickerPopover;
@property (weak, nonatomic) IBOutlet FUIButton *attachButton;
@property (weak, nonatomic) IBOutlet UIView *attachmentSeparatorView;
@property (weak, nonatomic) IBOutlet UILabel *attachmentsTitleLabel;
@end

@implementation ComposerViewController {
    NSString *_toString;
    NSString *_ccString;
    NSString *_bccString;
    NSString *_subjectString;
    NSString *_bodyString;
    NSMutableArray *_attachmentsArray;
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
    _attachmentsArray = [NSMutableArray arrayWithArray:attachments];//attachments;
    _delayedAttachmentsArray = delayedAttachments;
    
    return self;
}



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    toField.text = _toString;
    ccField.text = _ccString;
    subjectField.text = _subjectString;
    messageBox.text = _bodyString;
    
    TRAddressBookSource *source = [[TRAddressBookSource alloc] initWithMinimumCharactersToTrigger:2];
    [source useGoogleContacts:YES];
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
    
    self.attachButton.buttonColor = [UIColor cloudsColor];
    self.attachButton.shadowColor = [UIColor peterRiverColor];
    
    self.navigationItem.leftBarButtonItem = backButton;
    self.navigationItem.rightBarButtonItem = sendButton;
    self.navigationItem.title = @"Compose";
    
    [self configureViewForAttachments];
    
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

- (void)configureViewForAttachments
{
    if (([_attachmentsArray count] + [_delayedAttachmentsArray count]) > 0)
    {
        NSMutableArray *attachmentLabels = [[NSMutableArray alloc] init];
        
        int tag = 0;
        for (MCOAttachment* a in _attachmentsArray)
        {
            UIButton *label = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            label.frame = CGRectMake(0, 0, 300, 60);
            label.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            label.contentEdgeInsets = UIEdgeInsetsMake(10, 50, 10, 0);
            [label.titleLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
            [label setTitle:[a filename] forState:UIControlStateNormal];
            [label setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [label.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
            label.tag = tag;
            tag++;
            
            [label addTarget:self action:@selector(attachmentTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(10, 13, 32, 32)];
            NSString *pathToIcon = [FPMimetype iconPathForMimetype:[a mimeType] Filename:[a filename]];
            imageview.image = [UIImage imageNamed:pathToIcon];
            imageview.contentMode = UIViewContentModeScaleAspectFit;
            [label addSubview:imageview];
            
            [attachmentLabels addObject:label];
        }
        
        for (DelayedAttachment* da in _delayedAttachmentsArray)
        {
            UIButton *label = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            label.frame = CGRectMake(0, 0, 300, 60);
            label.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            label.contentEdgeInsets = UIEdgeInsetsMake(10, 50, 10, 0);
            [label.titleLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
            [label setTitle:[da filename] forState:UIControlStateNormal];
            [label setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            [label.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
            label.tag = tag;
            tag++;
            
            [label addTarget:self action:@selector(attachmentTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(10, 13, 32, 32)];
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
                if (!_attachmentsArray)
                {
                    _attachmentsArray = [NSMutableArray new];
                }
                [_attachmentsArray addObject:attachment];
                
                @synchronized(self) {
                    NSMutableArray *delayedMut = [NSMutableArray arrayWithArray:_delayedAttachmentsArray];
                    [delayedMut removeObject:da];
                    _delayedAttachmentsArray = delayedMut;
                }
                [self updateSendButton];
            }];
            
            [attachmentLabels addObject:label];
        }
        
        int startingHeight = self.attachmentsTitleLabel.frame.origin.y + self.attachmentsTitleLabel.frame.size.height/2;
        for (UIButton *attachmentLabel in attachmentLabels)
        {
            attachmentLabel.frame = CGRectMake(30, startingHeight, self.view.frame.size.width - 60, attachmentLabel.frame.size.height);
            [self.view addSubview:attachmentLabel];
            startingHeight += attachmentLabel.frame.size.height + 5;
        }
        
        CGRect lastAttachRect = [[attachmentLabels lastObject] frame];
        
        [UIView animateWithDuration:0.5
                              delay:0.1
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.attachButton.frame = CGRectMake(self.attachButton.frame.origin.x,
                                                                  lastAttachRect.origin.y + lastAttachRect.size.height,
                                                                  self.attachButton.frame.size.width,
                                                                  self.attachButton.frame.size.height);
                             
                             self.attachmentSeparatorView.frame = CGRectMake(self.attachmentSeparatorView.frame.origin.x,
                                                                             lastAttachRect.origin.y + lastAttachRect.size.height + self.attachButton.frame.size.height + 8,
                                                                             self.attachmentSeparatorView.frame.size.width,
                                                                             self.attachmentSeparatorView.frame.size.height);
                             
                             self.messageBox.frame = CGRectMake(self.messageBox.frame.origin.x,
                                                                self.attachmentSeparatorView.frame.origin.y + 9,
                                                                self.messageBox.frame.size.width,
                                                                self.messageBox.frame.size.height);
                         }
                         completion:^(BOOL finished) {
                             [self updateSendButton];
                         }];
        
        
    }
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
        self.navigationItem.rightBarButtonItem.enabled = [self isEmailTextFieldValid];//[toField.text isEmailValid];
    }
    
    [self.navigationController.navigationBar layoutSubviews];
}

- (BOOL)isEmailTextFieldValid
{
    NSString *emailTextFieldText = toField.text;
    
    if ([emailTextFieldText isEmailValid])
    {
        return YES;
    }
    
    NSArray *emails = [emailTextFieldText componentsSeparatedByString:@", "];
    
    if (emails.count == 0)
    {
        return NO;
    }
    else
    {
        __block BOOL isValid = NO;
        [emails enumerateObjectsUsingBlock:^(NSString *email, NSUInteger idx, BOOL *stop)
        {
            if (email.length != 0)
            {
                isValid = [email isEmailValid];
                if (!isValid)
                {
                    *stop = YES;
                }
            }
        }];
        
        return isValid;
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

- (IBAction)attachButtonPressed:(FUIButton *)sender
{
    FPPickerController *fpController = [[FPPickerController alloc] init];
    [fpController.navigationBar configureFlatNavigationBarWithColor:[UIColor colorFromHexCode:@"f1f1f1"]];
    
    fpController.fpdelegate = self;
    
    UIPopoverController *popoverControllerA = [UIPopoverController alloc];
    self.filepickerPopover = [popoverControllerA initWithContentViewController:fpController];
    [_filepickerPopover configureFlatPopoverWithBackgroundColor:[UIColor colorFromHexCode:@"f1f1f1"]
                                                   cornerRadius:5.f];
    _filepickerPopover.popoverContentSize = CGSizeMake(320, 520);
    _filepickerPopover.delegate = self;
    [_filepickerPopover presentPopoverFromRect:[sender frame]
                                        inView:self.view
                      permittedArrowDirections:UIPopoverArrowDirectionAny
                                      animated:YES];
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

#pragma mark - FPPickerControllerDelegate Methods

- (void)FPPickerController:(FPPickerController *)picker didPickMediaWithInfo:(NSDictionary *)info
{
    
}

- (void)FPPickerController:(FPPickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSLog(@"FILE CHOSEN: %@", info);
    
    MCOAttachment *attachment = [[MCOAttachment alloc] init];
    attachment.data = UIImageJPEGRepresentation([info objectForKey:@"FPPickerControllerOriginalImage"], 1);
    attachment.filename = [info objectForKey:@"FPPickerControllerFilename"];
    
    CFStringRef pathExtension = (__bridge_retained CFStringRef)[[info objectForKey:@"FPPickerControllerFilename"] pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    CFRelease(pathExtension);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    
    attachment.mimeType = mimeType;
    
    if (!_attachmentsArray)
    {
        _attachmentsArray = [NSMutableArray new];
    }
    [_attachmentsArray addObject:attachment];
    
    [self.filepickerPopover dismissPopoverAnimated:YES];
    
    [self configureViewForAttachments];
}

- (void)FPPickerControllerDidCancel:(FPPickerController *)picker
{
    NSLog(@"FP Cancelled Open");
    [self.filepickerPopover dismissPopoverAnimated:YES];
}

@end
