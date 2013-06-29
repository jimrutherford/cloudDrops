//
//  AccountsPreferencesViewController.m
//  CloudDrops
//
//  Created by James Rutherford on 2012-08-21.
//  Copyright (c) 2012 Malaspina University-College. All rights reserved.
//

#import "AccountsPreferencesViewController.h"

@interface AccountsPreferencesViewController ()

@end

@implementation AccountsPreferencesViewController

- (id)init
{
    return [super initWithNibName:@"AccountsPreferencesView" bundle:nil];
}

#pragma mark -
#pragma mark MASPreferencesViewController

- (NSString *)identifier
{
    return @"AdvancedPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNameUserAccounts];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Accounts", @"Toolbar item name for the Advanced preference pane");
}



@end
