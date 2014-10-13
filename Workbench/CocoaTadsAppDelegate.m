//
//  CocoaTadsAppDelegate.m
//  CocoaTADS
//
//  Created by Uli Kusterer on Sun Jun 01 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import "CocoaTadsAppDelegate.h"
#import "UKSyntaxColoredTextDocument.h"


@implementation CocoaTadsAppDelegate

/* -----------------------------------------------------------------------------
	init:
		Load our Preferences.plist containing our default values for
		NSUserDefaults.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(id)	init
{
	if( self = [super init] )
	{
		NSUserDefaults*	prefs = [NSUserDefaults standardUserDefaults];
		[prefs registerDefaults: [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"Preferences" ofType: @"plist"]]];
	}
	
	return self;
}

/* -----------------------------------------------------------------------------
	applicationWillFinishLaunching:
		Show our splash screen and if this is the first time a user is
		launching this app, show our help so they don't feel too lost.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(void)	applicationWillFinishLaunching:(NSNotification *)notification
{
	if( [[NSUserDefaults standardUserDefaults] objectForKey: @"WasLaunchedBefore"] == nil )
	{
		[NSApp showHelp: nil];
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithBool: YES] forKey: @"WasLaunchedBefore"];
	}
}


/* -----------------------------------------------------------------------------
	newTextFile:
		Create a new text (i.e. source file) document, as opposed to a project
		document, which is the default doc type opened when Cocoa creates a new
		document.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(IBAction)	newTextFile: (id)sender
{
	[[NSDocumentController sharedDocumentController] openUntitledDocumentOfType:@"TADS Source File" display:YES];
}

@end
