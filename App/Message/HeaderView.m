//
//  HeaderView.m
//  ThatInbox
//
//  Created by Liyan David Chang on 8/4/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "HeaderView.h"
#import "UIColor+FlatUI.h"
#import "FPMimetype.h"
#import "DelayedAttachment.h"
#import "ComposerViewController.h"
#import <INK/INK.h>
#import "UTIFunctions.h"


@interface HeaderView ()

@property MCOIMAPMessage *message;
@property NSArray* attachments;
@end

@implementation HeaderView


- (id)initWithFrame:(CGRect)frame message:(MCOIMAPMessage*)message delayedAttachments:(NSArray*)attachments{
    self = [super initWithFrame:frame];
    if (self) {
        self.message = message;
        self.attachments = attachments;
        [self render];
    }
    return self;
}

- (UIView *)generateSpacer {
    UIView *spacer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 15)];
    spacer.backgroundColor = [UIColor clearColor];
    return spacer;
}

- (UIView *)generateHR {
    UIView *hr = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 1)];
    hr.backgroundColor = [UIColor cloudsColor];
    return hr;
}

- (void)render {
    
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    MCOMessageHeader *header = [self.message header];
    
    NSMutableArray *headerLabels = [[NSMutableArray alloc] init];
    
    NSString *fromString = [[header from] displayName] ? [[header from] displayName] : [[header from] mailbox];
    if (fromString){
        fromString = [NSString stringWithFormat:@"From: %@", fromString];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
        label.text = fromString;
        label.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
        [headerLabels addObject:label];
    }
    
    if ([self displayNamesFromAddressArray:[header to]]){
        NSString *toString = [NSString stringWithFormat:@"To: %@", [self displayNamesFromAddressArray:[header to]]];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
        label.text = toString;
        label.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
        label.textColor = [UIColor grayColor];
        [headerLabels addObject:label];
    }
    
    if ([self displayNamesFromAddressArray:[header cc]]){
        NSString *ccString = [NSString stringWithFormat:@"CC: %@", [self displayNamesFromAddressArray:[header cc]] ];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
        label.text = ccString;
        label.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
        label.textColor = [UIColor grayColor];
        [headerLabels addObject:label];
    }
    
    [headerLabels addObject:[self generateSpacer]];
    [headerLabels addObject:[self generateHR]];
    [headerLabels addObject:[self generateSpacer]];
    
    
    if ([header subject]){
        NSString *subjectString = [header subject];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
        label.text = subjectString;
        label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18];
        [headerLabels addObject:label];
        
    }
    
    if ([header date]){
        NSString *dateString = [NSDateFormatter localizedStringFromDate:[header date]
                                                              dateStyle:NSDateFormatterMediumStyle
                                                              timeStyle:NSDateFormatterMediumStyle];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 30)];
        label.text = dateString;
        label.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
        label.textColor = [UIColor grayColor];
        [headerLabels addObject:label];
    }
    
    [headerLabels addObject:[self generateSpacer]];
    [headerLabels addObject:[self generateHR]];
    
    int tag = 0;
    if ([self.attachments count] > 0){
        [headerLabels addObject:[self generateSpacer]];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 20)];
        label.text = @"Attachments:";
        label.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
        label.textColor = [UIColor grayColor];
        [headerLabels addObject:label];
    }
    
    for (DelayedAttachment *da in self.attachments) {
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
        
        NSString *uti = [UTIFunctions UTIFromMimetype:[da mimeType]];
        
        [label addTarget:self action:@selector(attachmentTapped:) forControlEvents:UIControlEventTouchUpInside];
        [label INKEnableWithUTI:uti dynamicBlob:^INKBlob *{
            NSData *data = [da getData];
            INKBlob *blob = [[INKBlob alloc] init];
            blob.data = data;
            blob.filename = [da filename];
            blob.uti = uti;
            return blob;
            
        } returnBlock:^(INKBlob *result, INKAction *action, NSError *error) {
            if ([action.type isEqualToString:INKActionType_ReturnCancel]) {
                NSLog(@"Return Cancel");
                return;
            }
            
            MCOAttachment *attachment = [[MCOAttachment alloc] init];
            [attachment setData:[result data]];
            [attachment setMimeType:[UTIFunctions mimetypeFromUTI:[result uti]]];
            [attachment setFilename:[UTIFunctions filenameFromFilename:[result filename] UTI:[result uti]]];
            
            ComposerViewController *vc = [[ComposerViewController alloc] initWithMessage:_message ofType:@"Reply" content:[self.delegate msgContent] attachments:@[attachment] delayedAttachments:@[]];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
            nc.modalPresentationStyle = UIModalPresentationPageSheet;
            [self.delegate presentViewController:nc animated:YES completion:nil];
            
            NSLog(@"Reply");
        }];
        
        
        UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(10, 13, 32, 32)];
        NSString *pathToIcon = [FPMimetype iconPathForMimetype:[da mimeType]];
        imageview.image = [UIImage imageNamed:pathToIcon];
        imageview.contentMode = UIViewContentModeScaleAspectFit;
        [label addSubview:imageview];
                
        [self grabDataWithBlock:^NSData *{
            return [da getData];
        } completion:^(NSData *data) {
            if ([pathToIcon isEqualToString:@"page_white_picture.png"]){
                imageview.image = [UIImage imageWithData:data];
            }
        }];
        [headerLabels addObject:label];
        
        UIView *sp = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 5)];
        sp.backgroundColor = [UIColor clearColor];
        [headerLabels addObject:sp];
    }
    
    if ([self.attachments count] > 0){
        [headerLabels addObject:[self generateHR]];
        [headerLabels addObject:[self generateSpacer]];
    }

    int startingHeight = 30;
    for (UIView *l in headerLabels){
        l.frame = CGRectMake(30, startingHeight, self.frame.size.width-60, l.frame.size.height);
        [self addSubview:l];
        startingHeight += l.frame.size.height;
    }
    
    self.frame = CGRectMake(0, 0, self.frame.size.width, startingHeight);
    
    self.backgroundColor = [UIColor whiteColor];
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (NSString *)displayNamesFromAddressArray:(NSArray*)addresses {
    if ([addresses count] == 0){
        return nil;
    }
    NSMutableArray *names = [[NSMutableArray alloc] initWithArray:@[]];
    for (MCOAddress *a in addresses){
        if ([a displayName]){
            [names addObject:[a displayName]];
        } else {
            [names addObject:[a mailbox]];
        }
    }
    return [names componentsJoinedByString:@", "];
}

- (void)grabDataWithBlock: (NSData* (^)(void))dataBlock completion:(void(^)(NSData *data))callback {
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
        NSData *data = dataBlock();
        callback(data);
    });
}

- (void) attachmentTapped:(id)sender {
    
    DelayedAttachment *da = [self.attachments objectAtIndex:[sender tag]];
    NSString *uti = [UTIFunctions UTIFromMimetype:[da mimeType]];

    [Ink showWorkspaceWithUTI:uti dynamicBlob:^INKBlob *{
        NSData *data = [da getData];
        INKBlob *blob = [[INKBlob alloc] init];
        blob.data = data;
        blob.filename = [da filename];
        blob.uti = uti;
        return blob;
    } onReturn:^(INKBlob *result, INKAction *action, NSError *error) {
        if ([action.type isEqualToString:INKActionType_ReturnCancel]) {
            NSLog(@"Return Cancel");
            return;
        }
        
        MCOAttachment *attachment = [[MCOAttachment alloc] init];
        [attachment setData:[result data]];
        [attachment setMimeType:[UTIFunctions mimetypeFromUTI:[result uti]]];
        [attachment setFilename:[UTIFunctions filenameFromFilename:[result filename] UTI:[result uti]]];
        
         ComposerViewController *vc = [[ComposerViewController alloc] initWithMessage:_message ofType:@"Reply" content:[self.delegate msgContent] attachments:@[attachment] delayedAttachments:@[]];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:vc];
        nc.modalPresentationStyle = UIModalPresentationPageSheet;
        [self.delegate presentViewController:nc animated:YES completion:nil];
        
        NSLog(@"Reply");
    }];
    
}
@end
