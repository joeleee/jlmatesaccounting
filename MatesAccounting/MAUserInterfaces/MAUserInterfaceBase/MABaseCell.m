//
//  MABaseCell.m
//  MatesAccounting
//
//  Created by Lee on 13-12-15.
//  Copyright (c) 2013年 Lee. All rights reserved.
//

#import "MABaseCell.h"

@implementation MABaseCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.status = 0;
    }

    return self;
}

- (void)reuseCellWithData:(id)data
{
    NSAssert(NO, @"If you want call this method, you must overwrite it. - reuseCellWithData");
}

+ (CGFloat)cellHeight:(id)data
{
    NSAssert(NO, @"If you want call this method, you must overwrite it. - cellHeight");
    return 0.0f;
}

+ (NSString *)reuseIdentifier
{
    NSAssert(NO, @"If you want call this method, you must overwrite it. - reuseIdentifier");
    return @"";
}

@end