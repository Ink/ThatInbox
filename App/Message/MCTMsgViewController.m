//
//  MCTMsgViewController.m
//  testUI
//
//  Created by DINH Viêt Hoà on 1/20/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#import "MCTMsgViewController.h"
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>

#import <INK/UIView+Ink.h>
#import <INK/InkCore.h>
#import <INK/INK.h>
//#import "UTIFunctions.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "ComposerViewController.h"
#import "AuthManager.h"
#import "ActionPickerViewController.h"
#import "UIPopoverController+FlatUI.h"
#import "UIColor+FlatUI.h"

#import "MBProgressHUD.h"
#import "DelayedAttachment.h"
#import "UTIFunctions.h"

@interface MCTMsgViewController () <UIGestureRecognizerDelegate, UIPopoverControllerDelegate, ActionPickerDelegate>
{
    UIPopoverController *_actionPickerPopover;
    ActionPickerViewController *_actionPicker;
}
@end

@implementation MCTMsgViewController

@synthesize folder = _folder;
@synthesize session = _session;


- (void) awakeFromNib
{
    _storage = [[NSMutableDictionary alloc] init];
    _ops = [[NSMutableArray alloc] init];
    _pending = [[NSMutableSet alloc] init];
    _callbacks = [[NSMutableDictionary alloc] init];
}

- (id)init {
    self = [super init];
    
    if(self) {
        [self awakeFromNib];
        _session = [[AuthManager sharedManager] getImapSession];
    }
    
    return self;
}

- (void)viewDidLoad {
    if (!self.message){
        return;
    }

    //Remove all the underlying subviews;
    [[self.view subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.scrollEnabled = YES;
    _scrollView.directionalLockEnabled = YES;
    
    NSMutableArray *delayed = [[NSMutableArray alloc] init];
    for (MCOIMAPPart *a in [self.message attachments]) {
        DelayedAttachment *da = [[DelayedAttachment alloc] initWithMCOIMAPPart:a];
        da.fetchData = ^(void){
            __block NSData *data = [self MCOMessageView:_messageView dataForPartWithUniqueID:[a uniqueID]];
            if (data){
                return data;
            } else {
                __block NSConditionLock* fetchLock;
                fetchLock = [[NSConditionLock alloc] initWithCondition:1];
                
                [self MCOMessageView:_messageView fetchDataForPartWithUniqueID:[a uniqueID] downloadedFinished:^(NSError * error) {
                    data = [self MCOMessageView:_messageView dataForPartWithUniqueID:[a uniqueID]];
                    [fetchLock lock];
                    [fetchLock unlockWithCondition:0];
                }];
                
                [fetchLock lockWhenCondition:0];
                [fetchLock unlock];
                return data;
            }
        };
        [delayed addObject:da];
    };
    
    _headerView = [[HeaderView alloc] initWithFrame:self.view.bounds message:_message delayedAttachments:delayed];
    _headerView.delegate = self;
    [_scrollView addSubview:_headerView];

    
    //Placeholder
    _messageContentsView = [[UIView alloc] initWithFrame:CGRectMake(0, _headerView.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height-_headerView.frame.size.height)];
    _messageContentsView.backgroundColor = [UIColor whiteColor];
    [_scrollView addSubview:_messageContentsView];
    
    _messageView = [[MCOMessageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    [_messageView setDelegate:self];
    [_messageView setFolder:_folder];
    [_messageView setMessage:_message];
    //Dont show message view. use the messageContesntsView
    
    [self.view addSubview:_scrollView];
    
    if (_message){
        [self showSpinner];
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(didLongPressOnMessageContentsView:)];
    [longPress setDelegate:self];
    [longPress setMinimumPressDuration:0.8f];
    
    [_messageContentsView addGestureRecognizer:longPress];
}

-(void)didLongPressOnMessageContentsView:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer && recognizer.state == UIGestureRecognizerStateRecognized)
    {
        CGPoint point = [recognizer locationInView:_messageContentsView];
        [_messageView handleTapAtpoint:point];
    }
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //Update the underlying webview with the new bounds
    //We don't know it yet for sure, but we can predict it
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)){
        _messageView.frame = CGRectMake(0, 0, 703, 724);
    } else {
        //You don't want to do this as it will flash the underlying content. Just wait it out.
        //_messageView.frame = CGRectMake(0, 0, 447, 980);
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    //Update the underlying webview with the new bounds;
    _messageView.frame = self.view.bounds;
    [_headerView render];
}


- (void) showSpinner {
    [MBProgressHUD showHUDAddedTo:[self view] animated:YES];
}

- (void) hideSpinner {
    [MBProgressHUD hideAllHUDsForView:[self view] animated:NO];
}

- (void) setMessage:(MCOIMAPMessage *)message
{
	MCLog("set message : %s", message.description.UTF8String);
    for(MCOOperation * op in _ops) {
        [op cancel];
    }
    [_ops removeAllObjects];
    
    [_callbacks removeAllObjects];
    [_pending removeAllObjects];
    [_storage removeAllObjects];
    _message = message;
}

- (NSString *) msgContent {
    return [[[_messageView getMessage] mco_flattenHTML] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (MCOIMAPMessage *) message
{
    return _message;
}

- (MCOIMAPFetchContentOperation *) _fetchIMAPPartWithUniqueID:(NSString *)partUniqueID folder:(NSString *)folder
{
    MCLog("%s is missing, fetching", partUniqueID.description.UTF8String);
    
    if ([_pending containsObject:partUniqueID]) {
        return nil;
    }
    
    MCOIMAPPart * part = (MCOIMAPPart *) [_message partForUniqueID:partUniqueID];
    //NSAssert(part != nil, @"part != nil");
    
    [_pending addObject:partUniqueID];
    
    MCOIMAPFetchContentOperation * op = [_session fetchMessageAttachmentByUIDOperationWithFolder:folder uid:[_message uid] partID:[part partID] encoding:[part encoding]];
    [_ops addObject:op];
    [op start:^(NSError * error, NSData * data) {
        if ([error code] != MCOErrorNone) {
            [self _callbackForPartUniqueID:partUniqueID error:error];
            return;
        }
        
        NSAssert(data != NULL, @"data != nil");
        [_ops removeObject:op];
        [_storage setObject:data forKey:partUniqueID];
        [_pending removeObject:partUniqueID];
        MCLog("downloaded %s", partUniqueID.description.UTF8String);
        
        [self _callbackForPartUniqueID:partUniqueID error:nil];
    }];
    
    return op;
}

typedef void (^DownloadCallback)(NSError * error);

- (void) _callbackForPartUniqueID:(NSString *)partUniqueID error:(NSError *)error
{
    NSArray * blocks;
    blocks = [_callbacks objectForKey:partUniqueID];
    for(DownloadCallback block in blocks) {
        block(error);
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return _messageView.gestureRecognizerEnabled;
}

#pragma mark - ActionPickerDelegate

- (void)actionPicker:(ActionPickerViewController *)picker didSelectedAction:(Action)action
{
    switch (action)
    {
        case ActionOpenWithInk:
        {
            NSString *uti = [UTIFunctions UTIFromMimetype:picker.imageMimeType Filename:picker.imageName];
            
            [Ink showWorkspaceWithUTI:uti dynamicBlob:^INKBlob *
            {
                NSData *data = UIImagePNGRepresentation(picker.image);
                INKBlob *blob = [[INKBlob alloc] init];
                blob.data = data;
                blob.filename = picker.imageName;
                blob.uti = uti;
                return blob;
            }
                              onReturn:^(INKBlob *result, INKAction *action, NSError *error)
            {
                if ([action.type isEqualToString:INKActionType_ReturnCancel])
                {
                    NSLog(@"Return Cancel");
                    return;
                }

            }];
        }
            break;
            
        case ActionSaveImage:
        {
            UIImageWriteToSavedPhotosAlbum(picker.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
            break;
            
        case ActionCopy:
        {
            [[UIPasteboard generalPasteboard] setImage:picker.image];
        }
            break;
            
        case ActionPreview:
        {
            // TODO: make preview
        }
            break;
    }
    
    //Dismiss the popover if it's showing.
    if (_actionPicker)
    {
        [_actionPickerPopover dismissPopoverAnimated:YES];
        _actionPickerPopover = nil;
    }
}

- (void)image:(UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo
{
    NSLog(@"SAVE IMAGE COMPLETE");
    if(error)
    {
        NSLog(@"ERROR SAVING:%@",[error localizedDescription]);
    }
}

#pragma mark - MCOMessageViewDelegate

- (NSString *) MCOMessageView_templateForAttachmentSeparator:(MCOMessageView *)view {
    return @"";
}

- (NSString *) MCOMessageView_templateForAttachment:(MCOMessageView *)view
{
    // No need for attachments to be displayed. Using Native HeaderView instead.
    return @"";    
}

- (NSString *) MCOMessageView_templateForMainHeader:(MCOMessageView *)view {
    // No need for main header. Using Native HeaderView instead.
    return @"";
}

- (NSString *) MCOMessageView_templateForImage:(MCOMessageView *)view {
    // Disable inline image attachments. Using Native HeaderView instead.
    return @"";
}

- (NSString *) MCOMessageView_templateForMessage:(MCOMessageView *)view
{
    return @"{{BODY}}";
}

- (BOOL) MCOMessageView:(MCOMessageView *)view canPreviewPart:(MCOAbstractPart *)part
{
    return NO;
}

- (NSData *) MCOMessageView:(MCOMessageView *)view dataForPartWithUniqueID:(NSString *)partUniqueID
{
    NSData * data = [_storage objectForKey:partUniqueID];
    return data;
}

- (void) MCOMessageView:(MCOMessageView *)view fetchDataForPartWithUniqueID:(NSString *)partUniqueID
     downloadedFinished:(void (^)(NSError * error))downloadFinished
{
    MCOIMAPFetchContentOperation * op = [self _fetchIMAPPartWithUniqueID:partUniqueID folder:_folder];
    [op setProgress:^(unsigned int current, unsigned int maximum) {
        MCLog("progress content: %u/%u", current, maximum);
    }];
    if (op != nil) {
        [_ops addObject:op];
    }
    if (downloadFinished != NULL) {
        NSMutableArray * blocks;
        blocks = [_callbacks objectForKey:partUniqueID];
        if (blocks == nil) {
            blocks = [NSMutableArray array];
            [_callbacks setObject:blocks forKey:partUniqueID];
        }
        [blocks addObject:[downloadFinished copy]];
    }
}

- (void) MCOMessageView:(MCOMessageView *)view handleMailtoUrlString:(NSString *)mailtoAddress
{
    ComposerViewController *vc = [[ComposerViewController alloc] initWithTo:@[mailtoAddress]
                                                                         CC:@[]
                                                                        BCC:@[]
                                                                    subject:@""
                                                                    message:@""
                                                                attachments:@[]
                                                         delayedAttachments:@[]];
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
    nc.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:nc animated:YES completion:nil];
}

- (void) MCOMessageView:(MCOMessageView *)view
   didTappedInlineImage:(UIImage *)inlineImage
                atPoint:(CGPoint)point
              imageRect:(CGRect)rect
              imagePath:(NSString *)path
              imageName:(NSString *)imgName
          imageMimeType:(NSString *)mimeType
{    
    if (!_actionPicker)
    {
        _actionPicker = [[ActionPickerViewController alloc] initWithStyle:UITableViewStylePlain];
        _actionPicker.delegate = self;
    }
    
    _actionPicker.image = inlineImage;
    _actionPicker.imagePath = path;
    _actionPicker.imageName = imgName;
    _actionPicker.imageMimeType = mimeType;
    
    if (!_actionPickerPopover)
    {
        _actionPickerPopover = [[UIPopoverController alloc] initWithContentViewController:_actionPicker];
        [_actionPickerPopover setDelegate:self];
        
        [_actionPickerPopover configureFlatPopoverWithBackgroundColor:[UIColor colorFromHexCode:@"f1f1f1"]
                                                         cornerRadius:5.f];
    }
    
    [_actionPickerPopover presentPopoverFromRect:rect
                                          inView:_messageContentsView
                        permittedArrowDirections:UIPopoverArrowDirectionAny
                                        animated:YES];
}

- (NSData *) MCOMessageView:(MCOMessageView *)view previewForData:(NSData *)data isHTMLInlineImage:(BOOL)isHTMLInlineImage
{
    if (isHTMLInlineImage) {
        return data;
    }
    else {
        return [self _convertToJPEGData:data];
    }
}

#define IMAGE_PREVIEW_HEIGHT 300
#define IMAGE_PREVIEW_WIDTH 500

- (NSData *) _convertToJPEGData:(NSData *)data {
    CGImageSourceRef imageSource;
    CGImageRef thumbnail;
    NSMutableDictionary * info;
    int width;
    int height;
    float quality;

    width = IMAGE_PREVIEW_WIDTH;
    height = IMAGE_PREVIEW_HEIGHT;
    quality = 1.0;

    imageSource = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);
    if (imageSource == NULL)
        return nil;

    info = [[NSMutableDictionary alloc] init];
    [info setObject:(id) kCFBooleanTrue forKey:(id) kCGImageSourceCreateThumbnailWithTransform];
    [info setObject:(id) kCFBooleanTrue forKey:(id) kCGImageSourceCreateThumbnailFromImageAlways];
    [info setObject:(id) [NSNumber numberWithFloat:(float) IMAGE_PREVIEW_WIDTH] forKey:(id) kCGImageSourceThumbnailMaxPixelSize];
    thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef) info);

    CGImageDestinationRef destination;
    NSMutableData * destData = [NSMutableData data];

    destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef) destData,
                                                   (CFStringRef) @"public.jpeg",
                                                   1, NULL);
    
    CGImageDestinationAddImage(destination, thumbnail, NULL);
    CGImageDestinationFinalize(destination);

    CFRelease(destination);

    CFRelease(thumbnail);
    CFRelease(imageSource);

    return destData;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {

    [self hideSpinner];
    
    CGFloat contentHeight = webView.scrollView.contentSize.height;
    CGFloat contentWidth = webView.scrollView.contentSize.width;
    contentHeight = contentHeight > (self.view.bounds.size.height - _headerView.bounds.size.height) ? contentHeight : (self.view.bounds.size.height - _headerView.bounds.size.height);

    _messageContentsView.frame = CGRectMake(_messageContentsView.frame.origin.x, _messageContentsView.frame.origin.y, contentWidth, contentHeight);
    
    for (UIView *v in webView.scrollView.subviews){
        [_messageContentsView addSubview:v];
    }
    
    _scrollView.contentSize = CGSizeMake(_messageContentsView.bounds.size.width, _headerView.bounds.size.height + _messageContentsView.bounds.size.height);
}

@end
