//
//  MenuViewCell.m
//  ThatInbox
//
//  Created by Liyan David Chang on 8/2/13.
//  Copyright (c) 2013 Ink. All rights reserved.
//

#import "MenuViewCell.h"
#import "FlatUIKit.h"

@implementation MenuViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    NSDictionary *colors = @{@"Inbox": [UIColor pomegranateColor],
                             @"Attachments": [UIColor carrotColor],
                             @"Starred": [UIColor sunflowerColor],
                             @"Sent": [UIColor greenSeaColor],
                             @"All Mail": [UIColor peterRiverColor]
                             };
    
    if (selected) {
        UIColor* color = [colors objectForKey:self.textLabel.text];
        if (!color){
            color = [UIColor cloudsColor];
        }
        self.textLabel.textColor = color;
    } else {
        self.textLabel.textColor = [UIColor cloudsColor];
    }
    
    self.backgroundColor = [UIColor blackColor];
}

@end
