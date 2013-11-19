//
//  MAPlacePersistent.m
//  MatesAccounting
//
//  Created by Lee on 13-11-19.
//  Copyright (c) 2013年 Lee. All rights reserved.
//

#import "MAPlacePersistent.h"

#import "MPlace.h"
#import "MAContextAPI.h"
#import "MACommonPersistent.h"

@implementation MAPlacePersistent

+ (MAPlacePersistent *)instance
{
    static MAPlacePersistent     *sharedInstance;
    static dispatch_once_t       onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (MPlace *)createPlaceWithCoordinate:(CLLocationCoordinate2D)coordinate name:(NSString *)name
{
    MPlace *place = [MACommonPersistent createObject:NSStringFromClass([MPlace class])];

    if (place) {
        NSDate *currentData = [NSDate date];
        place.createDate = currentData;
        place.placeName = name;
        place.longitude = @(coordinate.longitude);
        place.latitude = @(coordinate.latitude);
        place.placeID = @([currentData timeIntervalSince1970]);
        [[MAContextAPI sharedAPI] saveContextData];
    }

    return place;
}

- (BOOL)deletePlace:(MPlace *)place
{
    BOOL isSucceed = [MACommonPersistent deleteObject:place];

    return isSucceed;
}

- (NSArray *)fetchPlace:(NSFetchRequest *)request
{
    NSArray *result = [MACommonPersistent fetchObjects:request entityName:NSStringFromClass([MPlace class])];
    
    return result;
}

@end