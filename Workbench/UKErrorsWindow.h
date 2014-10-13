//
//  UKErrorsWindow.h
//  CocoaTADS
//
//  Created by Uli Kusterer on 13.11.04.
//  Copyright 2004 M. Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKNibOwner.h"


@class ErrorListEntry;


@interface UKErrorsWindow : UKNibOwner
{
	IBOutlet NSWindow*					errorWindow;		// Window used to display errors from t3make.
	IBOutlet NSTextField*				errCountField;
	IBOutlet NSTextField*				warnCountField;
	IBOutlet NSTextField*				noteCountField;
	IBOutlet NSTableView*				errorList;			// View for displaying list of errors from t3make.
	NSMutableArray*						errorListStore;		// Here we keep our error list.
    int                                 errorCount;
    int                                 warningCount;
    int                                 noteCount;
    NSObject*                           delegate;
}

-(IBAction)     showErrorWindow: (id) sender;

// Add an entry to the list (type ErrorListEntry):
-(void)         addObject: (id)errorListEntry;
-(void)         removeObject: (id)errorListEntry;
-(void)         removeAllObjects;

// Specify a delegate:
-(void)         setDelegate: (NSObject*)del;
-(NSObject*)    delegate;

// Errors & Warnings Table:
-(int)          numberOfRowsInTableView:(NSTableView *)tableView;
-(id)           tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;
-(void)         doubleClickErrorList:(id)sender;

// Private:
-(void)         updateGUI;

@end


@interface NSObject (UKErrorsWindowDelegate)

-(void) errorsWindow: (UKErrorsWindow*)errWin itemDoubleClicked: (ErrorListEntry*)itm;

@end