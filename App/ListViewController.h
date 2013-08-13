//
//  ListViewController.h
//  Mailer
//
//  Created by Liyan David Chang on 8/1/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SettingsViewController.h"

@protocol ListViewDelegate;


@interface ListViewController : UITableViewController
@property (nonatomic, weak) id<ListViewDelegate> delegate;

@property (nonatomic, strong) NSDictionary *folderNameLookup;
@end

@protocol ListViewDelegate <NSObject>

- (void)loadMailFolder:(NSString *)folderPath withHR:(NSString*) name;
- (void)loadFolderIntoCache:(NSString*)imapPath;
- (void)clearMessages;
@property (strong) NSString *folderParent;
@end
