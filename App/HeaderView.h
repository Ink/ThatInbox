//
//  HeaderView.h
//  ThatInbox
//
//  Created by Liyan David Chang on 8/4/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MailCore/MailCore.h>

@protocol HeaderViewDelegate;

@interface HeaderView : UIView

- (id)initWithFrame:(CGRect)frame message:(MCOIMAPMessage*)message delayedAttachments:(NSArray*)attachments;
- (void)render;
@property (nonatomic, weak) id<HeaderViewDelegate> delegate;


@end


@protocol HeaderViewDelegate <NSObject>

- (NSString *) msgContent;
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)())completion;


@end