//
//  ActionPickerViewController.h
//  ThatInbox
//
//  Created by Andrey Yastrebov on 22.09.13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
    ActionOpenWithInk,
    ActionSaveImage,
    ActionCopy,
    ActionPreview
}Action;

@protocol ActionPickerDelegate;

@interface ActionPickerViewController : UITableViewController
@property (nonatomic, strong) NSArray *actionNames;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) NSString *imageMimeType;
@property (nonatomic, weak) id<ActionPickerDelegate> delegate;
@end

@protocol ActionPickerDelegate <NSObject>
@required
- (void)actionPicker:(ActionPickerViewController *)picker didSelectedAction:(Action)action;
@end