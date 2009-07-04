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
		splashWindow = nil;
	
		NSUserDefaults*	prefs = [NSUserDefaults standardUserDefaults];
		[prefs registerDefaults: [NSDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"Preferences" ofType: @"plist"]]];
		
		splashVisible = NO;
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
	[self showSplash];
	
	if( [[NSUserDefaults standardUserDefaults] objectForKey: @"WasLaunchedBefore"] == nil )
	{
		[NSApp showHelp: nil];
		[[NSUserDefaults standardUserDefaults] setObject: [NSNumber numberWithBool: YES] forKey: @"WasLaunchedBefore"];
	}
}


/* -----------------------------------------------------------------------------
	applicationDidBecomeActive:
		Called after applicationDidFinishLaunching:. If the splash screen is
		still visible, we let it fade out now that the app has completely
		launched and the menu bar is up.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(void)	applicationDidBecomeActive:(NSNotification *)notification
{
	if( [self splashVisible] )
		[NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(hideSplash:) userInfo:nil repeats:NO];
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


/* -----------------------------------------------------------------------------
	showSplash:
		Fade in our (hopefully) cool splash screen graphic.
		
		Sets splashVisible to YES.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(void)	showSplash
{
	int x;
	
	splashVisible = YES;
	
	[splashWindow center];
	[splashWindow setLevel: NSFloatingWindowLevel];
	[splashWindow setAlphaValue:0.0];
	[splashWindow makeKeyAndOrderFront:nil];
	
	for( x = 0; x <= 10; x++ )
		[splashWindow setAlphaValue:(0.1 * ((double)x))];
}


/* -----------------------------------------------------------------------------
	hideSplash:
		Fade out our (hopefully) cool splash screen graphic.
		
		Sets splashVisible to NO.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(void)	hideSplash: (NSTimer*) timer
{
	[timer invalidate];
	splashVisible = NO;

	int x;
	
	for( x = 9; x > 0; x-- )
		[splashWindow setAlphaValue:(0.1 * ((double)x))];
	[splashWindow setAlphaValue:0.0];
	[splashWindow orderOut:nil];
}


/* -----------------------------------------------------------------------------
	splashVisible:
		Return whether the splash screen is still showing.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(BOOL)	splashVisible
{
	return splashVisible;
}


@end
