//
//  MessageCell.m
//  ThatInbox
//
//  Created by Andrey Yastrebov on 20.09.13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "MessageCell.h"
#import "UIColor+FlatUI.h"
#import <MailCore/MailCore.h>
#import <QuartzCore/QuartzCore.h>

@implementation MessageCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        UIView *bgColorView = [[UIView alloc] init];
        bgColorView.backgroundColor = [UIColor peterRiverColor];
        bgColorView.layer.masksToBounds = YES;
        [self setSelectedBackgroundView:bgColorView];

    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setMessage:(MCOIMAPMessage *)message
{
    self.fromTextField.text = message.header.from.displayName ? message.header.from.displayName : message.header.from.mailbox;
    self.subjectTextField.text = message.header.subject ? message.header.subject : @"No Subject";
    
    NSArray *attachments = [message attachments];
    
    if ([attachments count] > 0)
    {
        [self.attachementIcon setImage:[UIImage imageNamed:@"attachment"]];
        MCOAttachment *firstAttachment = message.attachments[0];
        
        if (attachments.count == 1)
        {
            self.attachmentTextField.text = firstAttachment.filename;
        }
        else
        {
            self.attachmentTextField.text = [NSString stringWithFormat:@"%@ + %d more", firstAttachment.filename, attachments.count - 1];
        }
    }
    else
    {
        [self.attachementIcon setImage:[UIImage imageNamed:@"blank"]];
        self.attachmentTextField.text = nil;
    }

}

@end
