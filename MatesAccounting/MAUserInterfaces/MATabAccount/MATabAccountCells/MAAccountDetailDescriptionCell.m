//
//  MAAccountDetailDescriptionCell.m
//  MatesAccounting
//
//  Created by Lee on 13-12-1.
//  Copyright (c) 2013年 Lee. All rights reserved.
//

#import "MAAccountDetailDescriptionCell.h"

@interface MAAccountDetailDescriptionCell () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *accountDescriptionTextView;

@end

@implementation MAAccountDetailDescriptionCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
    }

    return self;
}

- (void)reuseCellWithData:(NSString *)data
{
    [self.accountDescriptionTextView setText:data];
    if (self.status) {
        self.accountDescriptionTextView.userInteractionEnabled = YES;
        self.accountDescriptionTextView.backgroundColor = UIColorFromRGB(222, 222, 222);
    } else {
        self.accountDescriptionTextView.userInteractionEnabled = NO;
        self.accountDescriptionTextView.backgroundColor = [UIColor clearColor];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self.actionDelegate actionWithData:nil cell:self type:0];
}

+ (CGFloat)cellHeight:(id)data
{
    return 110.0f;
}

+ (NSString *)reuseIdentifier
{
    return [self className];
}

@end