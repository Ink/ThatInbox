//
//  MenuViewController.h
//  ThatInbox
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlatUIKit.h"

@protocol MenuViewDelegate <NSObject>

@property (strong) NSString *folderParent;

- (void)loadMailFolder:(NSString *)folderPath withHR:(NSString*) name;
- (void)loadFolderIntoCache:(NSString*)imapPath;
- (void)clearMessages;

@end


@interface MenuViewController : UITableViewController <FUIAlertViewDelegate>

@property (nonatomic, weak) id<MenuViewDelegate> delegate;
@property (nonatomic, strong) NSDictionary *folderNameLookup;

@end


