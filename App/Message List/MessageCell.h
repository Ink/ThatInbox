//
//  MessageCell.h
//  ThatInbox
//
//  Created by Andrey Yastrebov on 20.09.13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MCOIMAPMessage;

@interface MessageCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *fromTextField;
@property (weak, nonatomic) IBOutlet UILabel *subjectTextField;
@property (weak, nonatomic) IBOutlet UILabel *attachmentTextField;
@property (weak, nonatomic) IBOutlet UIImageView *attachementIcon;

- (void)setMessage:(MCOIMAPMessage *)message;

@end
