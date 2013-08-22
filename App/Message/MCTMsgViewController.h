//
//  MCTMsgViewController.h
//  testUI
//
//  Created by DINH Viêt Hoà on 1/20/13.
//  Copyright (c) 2013 MailCore. All rights reserved.
//

#include <MailCore/MailCore.h>
#import "HeaderView.h"
#import "MCOMessageView.h"

@class MCOMessageView;
@class MCOIMAPAsyncSession;
@class MCOMAPMessage;

@interface MCTMsgViewController : UIViewController <MCOMessageViewDelegate, HeaderViewDelegate> {
    IBOutlet MCOMessageView * _messageView;
    HeaderView *_headerView;
    UIScrollView * _scrollView;
    UIView * _messageContentsView;

    NSMutableDictionary * _storage;
    NSMutableSet * _pending;
    NSMutableArray * _ops;
    MCOIMAPSession * _session;
    MCOIMAPMessage * _message;
    NSMutableDictionary * _callbacks;
    NSString * _folder;
}

@property (nonatomic, copy) NSString * folder;
@property (nonatomic, strong) MCOIMAPSession * session;
@property (nonatomic, strong) MCOIMAPMessage * message;

- (NSString *) msgContent;

@end
