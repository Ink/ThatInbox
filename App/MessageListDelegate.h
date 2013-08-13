//
//  MessageListDelegate.h
//  Mailer
//
//  Created by Liyan David Chang on 7/20/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MessageListDelegate <NSObject>
@required
-(void)archiveMessage:(uint64_t)msgId;
@end
