//
//  BXAppDelegate.h
//  CloudDrop
//
//  Created by James Rutherford on 12-04-26.
//  Copyright (c) 2012 Taptoincs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DropboxOSX/DropboxOSX.h>
#import "DragStatusView.h"
#import "URLShortener.h"
#import "MASPreferencesWindowController.h"

@interface BXAppDelegate : NSObject <NSApplicationDelegate, DBSessionDelegate, DBRestClientDelegate, DragStatusViewDelegate, NSMetadataQueryDelegate, URLShortenerDelegate> {
    NSWindow *window;
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
    DBRestClient *restClient;
    NSMetadataQuery *query;
    NSDate *startDate;
}

@property (nonatomic, retain) NSString *requestToken;
@property (nonatomic, readonly) DBRestClient *restClient;
@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenuItem *linkDropBoxMenuItem;
@property (nonatomic, copy) NSArray *queryResults;
@property (nonatomic, readonly) MASPreferencesWindowController *preferencesWindowController;

- (IBAction)didPressLinkDropBox:(id)sender;
- (IBAction)didPressQuit:(id)sender;
- (IBAction)didPressPreferences:(id)sender;

- (void) uploadFile:(NSString *)withFile;
- (void) shortenURL:(NSString *)withURL;
@end
