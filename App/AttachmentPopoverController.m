//
//  AttachmentPopoverController.m
//  Mailer
//
//  Created by Liyan David Chang on 8/2/13.
//  Copyright (c) 2013 com.inkmobility. All rights reserved.
//

#import "AttachmentPopoverController.h"
#import "FlatUIKit.h"

@interface AttachmentPopoverController ()

@end

@implementation AttachmentPopoverController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    FUIButton *remove = [[FUIButton alloc] initWithFrame:CGRectMake(0,0,150,30)];
    remove.buttonColor = [UIColor alizarinColor];
    remove.shadowColor = [UIColor pomegranateColor];
    remove.shadowHeight = 2.0f;
    remove.cornerRadius = 3.0f;
    [remove setTitle:@"Remove" forState:UIControlStateNormal];
    [remove addTarget:self action:@selector(buttonPushed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:remove];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)buttonPushed {
    NSLog(@"Button Pushed");
}

@end
