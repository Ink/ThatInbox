//
//  ComposerViewController.h
//  ThatInbox
//
//  Created by Liyan David Chang on 7/31/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MailCore/MailCore.h>

@interface ComposerViewController : UIViewController <UITextViewDelegate, UITextFieldDelegate>


@property(nonatomic, weak) IBOutlet UITextField *toField;
@property(nonatomic, weak) IBOutlet UITextField *ccField;
@property(nonatomic, weak) IBOutlet UITextField *subjectField;

@property(nonatomic, weak) IBOutlet UITextView *messageBox;


- (id)initWithMessage:(MCOIMAPMessage *)msg
               ofType:(NSString*)type
              content:(NSString*)content
          attachments:(NSArray *)attachments
   delayedAttachments:(NSArray *)delayedAttachments;

- (id)initWithTo:(NSArray *)to
              CC:(NSArray *)cc
             BCC:(NSArray *)bcc
         subject:(NSString *)subject
         message:(NSString *)message
     attachments:(NSArray *)attachments
delayedAttachments:(NSArray *)delayedAttachments;


@end
