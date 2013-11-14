//
//  MARootContextManager.m
//  MatesAccounting
//
//  Created by Lee on 13-11-15.
//  Copyright (c) 2013年 Lee. All rights reserved.
//

#import "MARootContextManager.h"

@implementation MARootContextManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

+ (MARootContextManager *)sharedInstance
{
    static MARootContextManager *sharedInstance;
    static dispatch_once_t      onceToken;

    dispatch_once(&onceToken, ^{
            sharedInstance = [[self alloc] init];
        });
    return sharedInstance;
}

- (BOOL)saveContext
{
    BOOL isSucceed = NO;

    NSError                *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;

    if ([managedObjectContext hasChanges]) {
        isSucceed = [managedObjectContext save:&error];

        if (!isSucceed) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }

    } else {
        isSucceed = YES;
    }

    return isSucceed;
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];

    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }

    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MatesAccounting" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }

    NSURL *storeURL = [[MAUtilityTools applicationDocumentsDirectory] URLByAppendingPathComponent:@"MatesAccounting.sqlite"];

    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         *   Replace this implementation with code to handle the error appropriately.
         *
         *   abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         *
         *   Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         *   Check the error message to determine what the actual problem was.
         *
         *
         *   If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         *
         *   If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         *   [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         *
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         *   @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         *
         *   Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         *
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _persistentStoreCoordinator;
}

@end