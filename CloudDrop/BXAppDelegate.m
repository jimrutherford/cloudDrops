//
//  BXAppDelegate.m
//  CloudDrop
//
//  Created by James Rutherford on 12-04-26.
//  Copyright (c) 2012 Taptoincs. All rights reserved.
//

#import <DropboxOSX/DropboxOSX.h>
#import <Growl/Growl.h>
#import "BXAppDelegate.h"
#import "DragStatusView.h"
#import "URLShortener.h"
#import "URLShortenerCredentials.h"
#import "NSFileManager+DirectoryLocations.h"
#import "NSDate+TimeIntervals.h"
#import "GeneralPreferencesViewController.h"
#import "AccountsPreferencesViewController.h"
#import "MASPreferencesWindowController.h"
#import "DropDataModel.h"
#import "Drop.h"

@implementation BXAppDelegate

@synthesize window = _window;
@synthesize linkDropBoxMenuItem;
@synthesize requestToken;
@synthesize queryResults;
@synthesize preferencesWindowController;

NSString *currentClipboardUrl;
NSString *currentFilename;
NSString *currentIconImageName;

DragStatusView* dragView;
NSTimer * doneIconTimer;
NSArray * mruArray;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // initialize Dropbox API
    [self initializeDropbox];
    
    // screenshot detector  
    [self startScreenshotDetection];
    
    // setup the Most Recuently Used list
    // will grab the 5 most recently dropped items
    // and display them in menu
    // Backed by coredata sqlite store to persist across sessions 
    [self populateMRUList];
}


#pragma mark Startup initialization items
- (void) initializeDropbox {
    NSString *appKey = @"ophw3cqsya3seq0";
    NSString *appSecret = @"b8rtyprvaxxg309";
    NSString *root = kDBRootAppFolder; // Should be either kDBRootDropbox or kDBRootAppFolder
    
    DBSession *session = [[DBSession alloc] initWithAppKey:appKey appSecret:appSecret root:root];
    session.delegate = self;
    
    [DBSession setSharedSession:session];
    
    NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
    NSString *actualScheme = [[[[plist objectForKey:@"CFBundleURLTypes"] objectAtIndex:0] objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
    NSString *desiredScheme = [NSString stringWithFormat:@"db-%@", appKey];
    NSString *alertText = nil;
    if ([appKey isEqual:@"APP_KEY"] || [appSecret isEqual:@"APP_SECRET"] || root == nil) {
        alertText = @"Fill in appKey, appSecret, and root in AppDelegate.m to use this app";
    } else if (![actualScheme isEqual:desiredScheme]) {
        alertText = [NSString stringWithFormat:@"Set the url scheme to %@ for the OAuth authorize page to work correctly", desiredScheme];
    }
    
    if (alertText) {
        NSAlert *alert = [NSAlert alertWithMessageText:nil defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", alertText];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(authHelperStateChangedNotification:) name:DBAuthHelperOSXStateChangedNotification object:[DBAuthHelperOSX sharedHelper]];
    
    [self updateLinkMenuTitle];
    
    NSAppleEventManager *em = [NSAppleEventManager sharedAppleEventManager];
    [em setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:)
          forEventClass:kInternetEventClass andEventID:kAEGetURL];
    
    
    [self.restClient loadMetadata:@""];

}

- (void) startScreenshotDetection {
    startDate = [NSDate date];
    query = [[NSMetadataQuery alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryUpdated:) name:NSMetadataQueryDidStartGatheringNotification object:query];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryUpdated:) name:NSMetadataQueryDidUpdateNotification object:query];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryUpdated:) name:NSMetadataQueryDidFinishGatheringNotification object:query];
    
    [query setDelegate:self];
    [query setPredicate:[NSPredicate predicateWithFormat:@"kMDItemIsScreenCapture = 1"]];
    [query startQuery];

}

#pragma mark NSMetadataQueryDelegate

- (void)queryUpdated:(NSNotification *)note {
    
    NSArray * results = [query results];
    [self setQueryResults:[query results]];
 
    if ([results count] < 1) 
    {
        return;
    }
    
    NSMetadataItem * result = [results objectAtIndex:[results count] - 1];
    
    // Check dates (NSPredicate fails to do so)
    NSDate *fsCreationDate   = [result valueForAttribute:@"kMDItemFSCreationDate"];
    NSDate *modificationDate = [result valueForAttribute:@"kMDItemContentModificationDate"];
    NSDate *creationDate     = [result valueForAttribute:@"kMDItemContentCreationDate"];
    NSDate *lastUsedDate     = [result valueForAttribute:@"kMDItemLastUsedDate"];
    if ([fsCreationDate timeIntervalSinceDate:startDate] < 0.0f || modificationDate != nil || creationDate != nil || lastUsedDate != nil) {
        return;
    }
    
    NSString * path = [result valueForAttribute:@"kMDItemPath"];
    NSLog(@"result array %@", path);
    [self uploadFile:path];
    
}

#pragma mark DragStatusViewDelegate

- (void) droppedURL:(NSString *)withURL
{
    [self shortenURL:withURL];
}


- (void) droppedSingleFile: (NSString*) withFile {
    [self uploadFile:withFile];
    }


- (void) uploadFile : (NSString*) withFile {
    NSString * thePath = withFile;
    
    NSString * theExt = [thePath pathExtension];
    
    NSString * unique = [self genRandStringLength:10];
    
    NSString * newFileName = [NSString stringWithFormat:@"%@.%@", unique, theExt];

    currentFilename = [thePath lastPathComponent];
    currentIconImageName = [self getUTIString:thePath];
    [restClient uploadFile:newFileName toPath:@"/" withParentRev:@"" fromPath:thePath]; 
    
    [dragView startThumper];
    NSLog(@"UTI Type is %@", [self getUTIString:thePath]);
    NSLog(@"starting upload");

}

- (void) droppedMultipleFiles {
    NSLog(@"uploading multiple files");
}

- (void) shortenURL:(NSString*)withURL
{
    [dragView startThumper];
    
    currentFilename = withURL;
    currentIconImageName = @"link";
    
    URLShortenerCredentials * creds = [URLShortenerCredentials new];
    creds.login = @"rutherfj";
    creds.key = @"R_c90680509d0a1891c2386d3698d25658";
    
    URLShortener* shortener = [URLShortener new];
    if (shortener != nil) {
        shortener.delegate = self;
        shortener.credentials = creds;;
        shortener.url = [NSURL URLWithString: withURL];
        [shortener execute];
    }
}


-(void)awakeFromNib{
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:statusMenu];
    [statusItem setHighlightMode:YES];

    dragView = [[DragStatusView alloc] initWithFrame:NSMakeRect(0, 0, 24, 24)];
    
    dragView.statusItem = statusItem;
    dragView.delegate = self;
    [dragView setMenu:statusMenu];
    
    [statusItem setView:dragView];
    
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [query stopQuery];
    [query setDelegate:nil];
    query = nil;
    
    [self setQueryResults:nil];
}


- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    // This gets called when the user clicks Show "App name" from the web authentication page. Nothing needs to do be done for Dropbox here - simply a dummy method
}

- (void)authHelperStateChangedNotification:(NSNotification *)notification {
    [self updateLinkMenuTitle];
    if ([[DBSession sharedSession] isLinked]) {

    }
}


- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError *)error
{
    // stop timer
    [dragView stopThumper];
    
    
    // show toast with error message
    NSString * toastMessage = @"There was an error uploading your file to Dropbox.";
    [self showNotification:toastMessage];
}



#pragma mark DBRestClientDelegate

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath {
    NSLog(@"file uploaded");
    [self.restClient loadSharableLinkForFile:destPath];
}

- (void) restClient:(DBRestClient *)client loadedSharableLink:(NSString *)link forFile:(NSString *)path {
    
    [self copyResultsToPasteboard:link];
    
    [dragView stopThumper];
   
    NSString * toastMessage = @"Your file has been uploaded and is ready to be shared.  A link to the file on DrobBox has been placed in your clipboard.";
    [self showNotification:toastMessage];
}

- (void)sessionDidReceiveAuthorizationFailure:(DBSession *)session userId:(NSString *)userId
{
    NSString * toastMessage = @"Unable to authenticate with Dropbox.";
    [self showNotification:toastMessage];
}



- (void) copyResultsToPasteboard: (NSString *) result {
    NSLog(@" link to file is : %@", result);
    
    // add to pasteboard
    NSPasteboard *pasteBoard = [NSPasteboard generalPasteboard];
    [pasteBoard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
    [pasteBoard setString:result forType:NSStringPboardType];
    
    currentClipboardUrl = result;
    
    [self saveDrop];
    [self populateMRUList];
}

- (void) saveDrop {
   
    NSManagedObjectContext *context = [[DropDataModel sharedDataModel] mainContext];
    Drop *drop = [Drop insertInManagedObjectContext:context];
    drop.clipboardURL = currentClipboardUrl;
    drop.filename = currentFilename;
    drop.iconImageName = currentIconImageName;
    drop.timestamp = [NSDate LongTimeIntervalSince1970];
    
    [context save:nil];
}

- (void) populateMRUList
{
   [self clearMRUList];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[Drop entityName]];
    [fetchRequest setPropertiesToFetch:[NSArray arrayWithObjects:@"filename", @"iconImageName", @"clipboardURL", nil]];
    
    NSSortDescriptor *sortByTimestamp = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortByTimestamp]];
    
    [fetchRequest setFetchLimit:5];
    
    NSError *error = nil;
    mruArray = [[[DropDataModel sharedDataModel] mainContext] executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"ERROR: %@ %@", [error localizedDescription], [error userInfo]);
        exit(1);
    }
    
    int menuIndex = 0;
    
    for (NSManagedObject *item in mruArray)
    {
        
        NSString * title = [item valueForKey:@"filename"];
        
        // push item to menu    
        NSMenuItem* newItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:title action:@selector(didClickMruItem:) keyEquivalent:@""];
        
        [newItem setTag:1000 + menuIndex];
        [newItem setEnabled:YES];
        
        NSString *iconName = [item valueForKey:@"iconImageName"];
        
        NSString * utiType = [NSString stringWithFormat:@"uti_%@.png", iconName];
        
        NSImage * itemImage = [NSImage imageNamed:utiType];
        [newItem setImage:itemImage];
        
        
        [statusMenu insertItem:newItem atIndex:3 + menuIndex];
        menuIndex++;
    }
}

- (void) clearMRUList {
    // clear all menu items where tag is greater than 999
    NSArray * menuItems = [statusMenu itemArray];
    
    for (NSMenuItem *menu in menuItems) {
        if (menu.tag > 999)
        {
            [statusMenu removeItem:menu];
        }
    }

}


- (IBAction) didClickMruItem:(id)sender
{
    // get tag from menu and subtract 1000 - this will tell us the corresponding array index in the mru array
    int itemIndex = (int)[sender tag] - 1000;
    NSManagedObject *drop = [mruArray objectAtIndex:itemIndex];
    NSString *url = [drop valueForKey:@"clipboardURL"];
    
    // open url in default browser
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (void) showNotification:(NSString*) message {
    
    [GrowlApplicationBridge notifyWithTitle:@"Upload Complete"
                                description:message
                           notificationName:@"uploadSuccessToDropbox"
                                   iconData:nil
                                   priority:0
                                   isSticky:NO
                               clickContext:nil];
    
    [dragView showDoneIcon];
    
    // start timer
    NSLog(@"Timer starting");
    doneIconTimer = [NSTimer scheduledTimerWithTimeInterval:4.0
                                     target:self
                                   selector:@selector(resetDoneIcon:)
                                   userInfo:nil
                                    repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:doneIconTimer forMode:NSRunLoopCommonModes];
    
}

- (void) resetDoneIcon: (NSTimer*) theTimer
{
    [dragView resetIcon];
    NSLog(@"Timer timed out");
    
    [doneIconTimer invalidate];
    doneIconTimer = nil;
    
    
}
   

- (void)restClient:(DBRestClient*)restClient loadSharableLinkFailedWithError:(NSError*)error{
    NSLog(@"Error %@",error);
}

- (IBAction)didPressLinkDropBox:(id)sender {
    if ([[DBSession sharedSession] isLinked]) {
        // The link button turns into an unlink button when you're linked
        [[DBSession sharedSession] unlinkAll];
        restClient = nil;
        [self updateLinkMenuTitle];
    } else {
        [[DBAuthHelperOSX sharedHelper] authenticate];
    }
}

- (IBAction)didPressQuit:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)didPressPreferences:(id)sender {
    [[NSDate date] timeIntervalSince1970];
    
    if (preferencesWindowController == nil)
    {
        NSViewController *generalViewController = [[GeneralPreferencesViewController alloc] init];
        NSViewController *accountViewController = [[AccountsPreferencesViewController alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, accountViewController, nil];
        
        NSString *title = NSLocalizedString(@"Preferences", @"CloudDrops Preferences");
        preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
    }
    
    [self.preferencesWindowController selectControllerAtIndex:0];
    [NSApp activateIgnoringOtherApps:YES];
    [self.preferencesWindowController showWindow:self];
    [self.preferencesWindowController.window makeKeyAndOrderFront:self];
}

- (void)updateLinkMenuTitle {
    if ([[DBSession sharedSession] isLinked]) {
        self.linkDropBoxMenuItem.title = @"Unlink Dropbox Account";
    } else {
        self.linkDropBoxMenuItem.title = @"Link Dropbox Account";
        self.linkDropBoxMenuItem.enabled = ![[DBAuthHelperOSX sharedHelper] isLoading];
    }
}


#pragma mark URLShortener delegate methods

- (void) shortener: (URLShortener*) shortener didSucceedWithShortenedURL: (NSURL*) shortenedURL
{
    NSLog(@"shortener didSucceedWithShortenedURL: %@", [shortenedURL absoluteString]);
    
    
    [self copyResultsToPasteboard:[shortenedURL absoluteString]];
    
    [dragView stopThumper];
    NSString * toastMessage = @"Your shortened link has been placed in your clipboard.";
    [self showNotification:toastMessage];
    
}

/**
 * URLShortener delegate method that will be called when the bit.ly service returned a non-200
 * status code to our request.
 */

- (void) shortener: (URLShortener*) shortener didFailWithStatusCode: (int) statusCode
{
    NSLog(@"shortener: %@ didFailWithStatusCode: %d", self, statusCode);
}

/**
 * URLShortener delegate method that will be called when a lower level error has occurred. Like
 * network timeouts or host lookup failures.
 */

- (void) shortener: (URLShortener*) shortener didFailWithError: (NSError*) error
{
    NSLog(@"shortener didFailWithError: %@", error);
}



#pragma mark Utility Functions  

- (NSString *) pathForDataFile
{
    NSString *path = [[NSFileManager defaultManager] applicationSupportDirectory];
    
    
    NSString *fileName = [path stringByAppendingPathComponent: @"MRUList.archive"];
    NSLog(@"applicationSupportDirectory: '%@'", fileName);
    
    return fileName;    
}


- (NSString *) getUTIString: (NSString *) forFile
{
    NSString * presentationType = @"public.presentation";
    NSString *iconType = @"generic";
    
    CFStringRef fileExtension = CFBridgingRetain([forFile pathExtension]);
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    CFRelease(fileExtension);
    
    if (UTTypeConformsTo(fileUTI, kUTTypeImage)) iconType =  @"image";
    else if (UTTypeConformsTo(fileUTI, kUTTypeMovie)) iconType = @"movie";
    else if (UTTypeConformsTo(fileUTI, (__bridge_retained CFStringRef)presentationType)) iconType = @"presentation";
    
    else if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) iconType = @"music";
    
    
    // archive based file
    // beware of heirarchy and precendence
    // specific ordering below
    else if (UTTypeConformsTo(fileUTI, kUTTypeDiskImage)) iconType = @"dmg";
    else if (UTTypeConformsTo(fileUTI, kUTTypeArchive)) iconType = @"archive";
    
    // text based documents
    // beware of heirarchy and precendence
    // specific ordering below
    else if (UTTypeConformsTo(fileUTI, kUTTypeSourceCode)) iconType = @"sourcecode";
    else if (UTTypeConformsTo(fileUTI, kUTTypeText)) iconType = @"document";
    
    
    else if (UTTypeConformsTo(fileUTI, kUTTypeData)) iconType = @"data";

    CFRelease(fileUTI);
    
    return iconType;
}


#pragma mark Getter/Setters

- (DBRestClient *)restClient {
    if (!restClient) {
        restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

- (NSString *)screenCaptureLocation
{
	NSString *location = [[self screenCapturePrefs] objectForKey:@"location"];
	if (location) {
		location = [location stringByExpandingTildeInPath];
		if (![location hasSuffix:@"/"]) {
			location = [location stringByAppendingString:@"/"];
		}
		return location;
	}
    
	return [[@"~/Desktop" stringByExpandingTildeInPath] stringByAppendingString:@"/"];
}

- (NSDictionary *)screenCapturePrefs
{
	return [[NSUserDefaults standardUserDefaults] persistentDomainForName:@"com.apple.screencapture"];
}


#pragma mark Utility methods
NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

-(NSString *) genRandStringLength: (int) len {
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random()%[letters length]]];
    }
    
    return randomString;
}

@end