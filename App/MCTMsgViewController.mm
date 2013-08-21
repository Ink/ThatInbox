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
#import <MobileCoreServices/MobileCoreServices.h>

#import "ComposerViewController.h"
#import "AuthManager.h"

#import "EmailParser.h"
#import "MBProgressHUD.h"
#import "DelayedAttachment.h"

@interface MCTMsgViewController ()
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

    /*
    if ([[[self message] attachments] count] > 0){

        
        NSString* filename = [[[[self message] attachments] objectAtIndex:0] filename];
        
        CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([filename pathExtension]), NULL);
        NSString *uti = (__bridge NSString *)UTI;
        
        NSString* partUniqueID = [[[[self message] attachments] objectAtIndex:0] uniqueID];
        NSData * data = [self MCOMessageView:_messageView dataForPartWithUniqueID:partUniqueID];


        
        if (!data){
            [self MCOMessageView:_messageView fetchDataForPartWithUniqueID:partUniqueID downloadedFinished:^(NSError * error) {
                NSData * data = [self MCOMessageView:_messageView dataForPartWithUniqueID:partUniqueID];
                INKBlob *blob = [INKBlob blobFromData:data];
                blob.filename = filename;
                blob.uti = uti;
                [self displayAttachmentWithBlob:blob];
            }];
        } else {
            INKBlob *blob = [INKBlob blobFromData:data];
            blob.filename = filename;
            blob.uti = uti;
            [self displayAttachmentWithBlob:blob];
        }
    }
     */
    
    if (_message){
        [self showSpinner];
    }
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    //Update the underlying webview with the new bounds
    //We don't know it yet for sure, but we can predict it
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)){
        _messageView.frame = CGRectMake(0, 0, 703, 724);
    } else {
        //You don't want to do this as it will flash the underlying content
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

- (void) displayAttachmentWithBlob: (INKBlob*)blob {
    [_messageContentsView INKEnableWithBlob:blob returnBlock:^(INKBlob *result, INKAction *action, NSError *error) {
        if ([action.type isEqualToString:INKActionType_ReturnCancel]) {
            NSLog(@"Return Cancel");
            return;
        }
        
        NSData* attachmentData = [result data];
        
        //NSString* pathToFile = @"http://liyanchang.com/public/IMSA%20Learning%20Facilities%20Report.pdf";
        //NSData* attachmentData = [NSData dataWithContentsOfURL:[NSURL URLWithString:pathToFile]];
        //NSString* attachmentName = @"learning.pdf";
                
        //TODO: HARDCODED PDF!!!!
        NSString* attachmentName = [result filename];
        if (attachmentName == nil){
            NSDate *currDate = [NSDate date];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
            [dateFormatter setDateFormat:@"dd.MM.YY HH:mm:ss"];
            NSString *dateString = [dateFormatter stringFromDate:currDate];
            attachmentName = [NSString stringWithFormat:@"%@.pdf", dateString];
        }
        
        MCOAttachment *attachment = [[MCOAttachment alloc] init];
        [attachment setData:attachmentData];
        NSString* attachmentType = [result uti];
        NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)attachmentType, kUTTagClassMIMEType);
        [attachment setMimeType:contentType];
        [attachment setFilename:attachmentName];
        
        ComposerViewController *vc = [[ComposerViewController alloc] initWithMessage:_message ofType:@"Reply" content:[self msgContent] attachments:@[attachment] delayedAttachments:@[]];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
        nc.modalPresentationStyle = UIModalPresentationPageSheet;
        [self presentViewController:nc animated:YES completion:nil];
        
        NSLog(@"Reply");
    }];
    [_messageContentsView INKAddLaunchButton];
    
    
    
    /*
    UIImage *image = [UIImage imageWithData:data];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.backgroundColor = [UIColor redColor];
    imageView.frame = CGRectMake(0,100,self.view.bounds.size.width,10000);
    
    [_scrollView addSubview:imageView];
    
    NSString* filename = [[[[self message] attachments] objectAtIndex:0] filename];
    
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)([filename pathExtension]), NULL);
    NSString *uti = (__bridge NSString *)UTI;
    
    INKBlob *blob = [INKBlob blobFromData:data];
    blob.filename = filename;
    blob.uti = uti;
    
    [imageView INKEnableWithBlob:blob returnBlock:^(INKBlob * resultBlob, INKAction * returnAction) {
        if ([returnAction.type isEqualToString:INKActionType_ReturnCancel]) {
            NSLog(@"Return Cancel");
            return;
        }
        
        NSData* attachmentData = [blob data];
        
        //NSString* pathToFile = @"http://liyanchang.com/public/IMSA%20Learning%20Facilities%20Report.pdf";
        //NSData* attachmentData = [NSData dataWithContentsOfURL:[NSURL URLWithString:pathToFile]];
        //NSString* attachmentName = @"learning.pdf";
        
        //TODO: UTI TO MIMETYPE
        //NSString* attachmentType = [blob uti];
        
        //TODO: HARDCODED PDF!!!!
        NSString* attachmentName = [blob filename];
        if (attachmentName == nil){
            NSDate *currDate = [NSDate date];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
            [dateFormatter setDateFormat:@"dd.MM.YY HH:mm:ss"];
            NSString *dateString = [dateFormatter stringFromDate:currDate];
            attachmentName = [NSString stringWithFormat:@"%@.pdf", dateString];
        }
        
        MCOAttachment *attachment = [[MCOAttachment alloc] init];
        [attachment setData:attachmentData];
        //[attachment setMimeType:@"image/png"];
        [attachment setMimeType:@"adobe/pdf"];
        [attachment setFilename:attachmentName];
        
        
        ComposerViewController *vc = [[ComposerViewController alloc] initWithMessage:_message ofType:@"Reply" content:[self msgContent] attachments:@[attachment] delayedAttachments:@[]];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
        nc.modalPresentationStyle = UIModalPresentationPageSheet;
        [self presentViewController:nc animated:YES completion:nil];
        
        NSLog(@"Reply");
    }];
    [imageView INK_addLaunchButton];
    */
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

- (NSString *) MCOMessageView_templateForAttachmentSeparator:(MCOMessageView *)view {
    return @"";
}

- (NSString *) MCOMessageView_templateForAttachment:(MCOMessageView *)view
{
    return @"";    
    //return @"<div><img src=\"http://www.iconshock.com/img_jpg/OFFICE/general/jpg/128/attachment_icon.jpg\"/></div>\
{{#HASSIZE}}\
<div>- {{FILENAME}}, {{SIZE}}</div>\
{{/HASSIZE}}\
{{#NOSIZE}}\
<div>- {{FILENAME}}</div>\
{{/NOSIZE}}";
}

- (NSString *) MCOMessageView_templateForMainHeader:(MCOMessageView *)view {
    
    return @"";
    /*
    return @"\
    {{#HASFROM}}\
    <div style='padding-bottom:10px;'>\
    <div style='font-weight:600; font-size: 1.05em;padding-bottom:5px;'>{{FROM}}</div>\
    {{/HASFROM}}\
    {{#HASTO}}\
    To: {{TO}}\
    <br/>\
    {{/HASTO}}\
    {{#NORECIPIENT}}\
    To: Undisclosed recipient\
    {{/NORECIPIENT}}\
    {{#HASCC}}\
    CC: {{CC}}\
    <br/>\
    {{/HASCC}}\
    {{#HASBCC}}\
    BCC: {{BCC}}\
    <br/>\
    {{/HASBCC}}\
    </div>\
    <hr/>\
    <div style='font-weight:600; font-size: 1.05em;padding-bottom:5px;padding-top:10px;'>{{SUBJECT}}</div>\
    <div style='padding-bottom:10px;'>{{LONGDATE}}</div>\
    <hr/>\
    ";
     */
}

- (NSString *) MCOMessageView_templateForImage:(MCOMessageView *)view {
    //Disable inline image attachments
    return @"";
}

- (NSString *) MCOMessageView_templateForMessage:(MCOMessageView *)view
{
    //return @"<div style='padding:30px 30px 0 30px;text-align:left;background-color:#ffffff;'>{{HEADER}}</div><div style='padding:30px;'>{{BODY}}</div>";
    return @"{{BODY}}";
}

- (NSString *) MCOMessageView:(MCOMessageView *)view filteredHTMLForMessage:(NSString *)html {
    
    /*
    //Collapsing responses
    NSString *format = @"%@<a href='#hide1' class='hide' id='hide1'>Show Conversation</a>\
                        <a href='#show1' class='show' id='show1'>Hide Conversation</a><br/>\
                        <div class='content'>%@</div>";
    
    NSArray *parts =[EmailParser parseMessage:html];
    if ([[parts objectAtIndex:1] length] >0){
        return [NSString stringWithFormat:format, [parts objectAtIndex:0], [parts objectAtIndex:1] ];
    } else {
        return [parts objectAtIndex:0];
    }
     */
    return html;
}

- (BOOL) MCOMessageView:(MCOMessageView *)view canPreviewPart:(MCOAbstractPart *)part
{
    return NO;
    /*
    // tiff, tif, pdf
    NSString * mimeType = [[part mimeType] lowercaseString];
    if ([mimeType isEqualToString:@"image/tiff"]) {
        return YES;
    }
    else if ([mimeType isEqualToString:@"image/tif"]) {
        return YES;
    }
    else if ([mimeType isEqualToString:@"application/pdf"]) {
        return YES;
    }
    
    NSString * ext = nil;
    if ([part filename] != nil) {
        if ([[part filename] pathExtension] != nil) {
            ext = [[[part filename] pathExtension] lowercaseString];
        }
    }
    if (ext != nil) {
        if ([ext isEqualToString:@"tiff"]) {
            return YES;
        }
        else if ([ext isEqualToString:@"tif"]) {
            return YES;
        }
        else if ([ext isEqualToString:@"pdf"]) {
            return YES;
        }
    }
    
    return NO;
     */
}

- (NSString *) MCOMessageView:(MCOMessageView *)view filteredHTML:(NSString *)html
{
    return html;
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
    contentHeight = contentHeight > (self.view.bounds.size.height - _headerView.bounds.size.height)? contentHeight : (self.view.bounds.size.height - _headerView.bounds.size.height);

    _messageContentsView.frame = CGRectMake(_messageContentsView.frame.origin.x, _messageContentsView.frame.origin.y, _messageContentsView.frame.size.width, contentHeight);
    
    for (UIView *v in webView.scrollView.subviews){
        [_messageContentsView addSubview:v];
    }
    
    _scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, _headerView.bounds.size.height + _messageContentsView.bounds.size.height);

}

@end
