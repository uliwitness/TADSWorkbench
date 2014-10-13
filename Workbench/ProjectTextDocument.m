//
//  ProjectTextDocument.m
//  CocoaTADS
//
//  Created by Uli Kusterer on Fri Feb 13 2004.
//  Copyright (c) 2004 M. Uli Kusterer. All rights reserved.
//

#import "ProjectTextDocument.h"
#import "ProjectDocument.h"


@implementation ProjectTextDocument

/* -----------------------------------------------------------------------------
	validateMenuItem:
		If we have a project open and the text file has been saved, let the
		user choose the "add to current project" menu item for this file.
	
	REVISIONS:
		2004-10-17	UK	Fixed documentation.
   -------------------------------------------------------------------------- */

-(BOOL)	validateMenuItem:(NSMenuItem*)menuItem
{
	if( [menuItem action] == @selector(addToCurrentProject:) )
		return( ([self fileName] != nil) && ([ProjectDocument currentProject] != nil) );
	else if( [menuItem action] == @selector(buildGame:)
                || [menuItem action] == @selector(buildAndRunGame:)
                || [menuItem action] == @selector(buildAndDebugGame:)
                || [menuItem action] == @selector(cleanGame:)
                || [menuItem action] == @selector(debugGame:)
                || [menuItem action] == @selector(runGame:)
                || [menuItem action] == @selector(extractGameText:)
                || [menuItem action] == @selector(addSourceFile:)
                || [menuItem action] == @selector(addLibrary:)
                || [menuItem action] == @selector(showSettings:)
                || [menuItem action] == @selector(showErrorWindow:) )
		return( [ProjectDocument currentProject] != nil && [[ProjectDocument currentProject] validateMenuItem: menuItem] );
	if( [menuItem action] == @selector(openQuickly:) )
        return( ([textView selectedRange].length > 0) && ([ProjectDocument currentProject] != nil) );
    else
		return [super validateMenuItem: menuItem];
}


/* -----------------------------------------------------------------------------
	openQuickly:
		Open a window for a file named like the selection.
    
    REVISIONS:
        2004-11-14  UK  Created.
   -------------------------------------------------------------------------- */

-(void) openQuickly: (id)sender
{
    NSRange             sel = [textView selectedRange];
    NSString*           currPath;
    
    currPath = [[textView string] substringWithRange: sel];
    
    [[ProjectDocument currentProject] openWindowForFile: currPath];
}


/* -----------------------------------------------------------------------------
	addToCurrentProject:
		Add this project's file to the current project.
   -------------------------------------------------------------------------- */

-(IBAction)		addToCurrentProject: (id)sender
{
	[[ProjectDocument currentProject] addSourceFileAtPath: [self fileName]];
}


// Methods that call through to current doc:
//  Not very OO, we'd probably want to fake some sort of delegation instead...
-(IBAction)	showSettings: (id) sender
{
    [[ProjectDocument currentProject] showSettings: sender];
}


-(IBAction)	showErrorWindow: (id) sender
{
    [[ProjectDocument currentProject] showErrorWindow: sender];
}


-(IBAction)	addSourceFile: (id)sender
{
    [[ProjectDocument currentProject] addSourceFile: sender];
}


-(IBAction)	addLibrary: (id)sender
{
    [[ProjectDocument currentProject] addLibrary: sender];
}


-(IBAction)	buildGame: (id)sender
{
    [[ProjectDocument currentProject] buildGame: sender];
}


-(IBAction)	buildAndRunGame: (id)sender
{
    [[ProjectDocument currentProject] buildAndRunGame: sender];
}


-(IBAction)	buildAndDebugGame: (id)sender
{
    [[ProjectDocument currentProject] buildAndDebugGame: sender];
}


-(IBAction)	cleanGame: (id)sender
{
    [[ProjectDocument currentProject] cleanGame: sender];
}


-(IBAction)	debugGame: (id)sender
{
    [[ProjectDocument currentProject] debugGame: sender];
}


-(IBAction)	runGame: (id)sender
{
    [[ProjectDocument currentProject] runGame: sender];
}


-(IBAction)	extractGameText: (id)sender
{
    [[ProjectDocument currentProject] extractGameText: sender];
}


@end
