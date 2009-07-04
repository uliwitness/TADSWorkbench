//
//  ErrorListEntry.m
//  CocoaTADS
//
//  Created by Uli Kusterer on Fri May 30 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import "ErrorListEntry.h"


@implementation ErrorListEntry

/* -----------------------------------------------------------------------------
	initWithString:
		Initialize a new ErrorListEntry from one line of the output of the
		TADS compiler. This parses the error message and makes sure we get
		a proper icon for it and extracts the line number and file name that
		this error message refers to.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(id)	initWithString: (NSString*)str
{
	NSRange		range,
				range2,
				msgRange;
	NSString*	numStr;
	
	if( self = [super init] )
	{
		//NSLog(@"ErrorListElement: %@",str);
	
		range = [str rangeOfString: @"("];
		if( (range.location != NSNotFound) || (range.length != 0) )
		{
			file = [[str substringToIndex: range.location] retain];
			range2 = [str rangeOfString: @")" options:0 range: NSMakeRange( range.location +range.length, ([str length]) -range.location -range.length )];
			if( (range2.location != NSNotFound) || (range2.length != 0) )
			{
				numStr = [str substringWithRange: NSMakeRange( range.location +range.length, range2.location -(range.location +range.length) )];
				line = [numStr intValue];
				msgRange = NSMakeRange( range2.location +range2.length, [str length] -range2.location -range2.length );
				if( (msgRange.location != NSNotFound) || (msgRange.length != 0) )
				{
					message = [str substringWithRange: msgRange];
					if( [message hasPrefix: @": "] )
						message = [message substringFromIndex:2];
				}
				else
					message = str;
			}
			else
				message = str;
		}
		else
			message = str;
		[message retain];
		if( [message hasPrefix: @"error"] )
			type = ERROR_TYPE_ERROR;
		else if( [message hasPrefix: @"warning"] )
			type = ERROR_TYPE_WARNING;
		else
			type = ERROR_TYPE_NOTE;
	}
	
	return self;
}


/* -----------------------------------------------------------------------------
	initWithMessage:
		Initialize a new ErrorListEntry that is just an informational message
		to add to the error log. Used e.g. to display "Finished." in the log
		so the user notices the app did something when there are no warnings
		or errors.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(id)	initWithMessage: (NSString*)msg
{
	if( self = [super init] )
	{
		file = nil;
		line = 0;
		message = [msg retain];
		type = ERROR_TYPE_NONE;
	}
	
	return self;
}


/* -----------------------------------------------------------------------------
	dealloc:
		clean up.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(void)	dealloc
{
	[message release];
	[file release];
	
	[super dealloc];
}


/* -----------------------------------------------------------------------------
	message:
		Accessor for the actual message part to display to the user.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(NSString*)	message
{
	return message;
}


/* -----------------------------------------------------------------------------
	file:
		Full file path of the file the error refers to, as reported by TADS.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(NSString*)	file
{
	return file;
}


/* -----------------------------------------------------------------------------
	shortFileName:
		Display name of the file the error refers to. You'll usually want to
		display this in the error log, if at all.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(NSString*)	shortFileName
{
	return [[NSFileManager defaultManager] displayNameAtPath: file];
}


/* -----------------------------------------------------------------------------
	line:
		Line number the error occurred on, as reported by TADS.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(int)	line
{
	return line;
}


/* -----------------------------------------------------------------------------
	lineNumber:
		Same as line, but wraps things up in an NSNumber so you can use this
		for key-value coding in an NSTableView.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(NSNumber*)	lineNumber
{
	if( line == 0 )
		return nil;
	else
		return [NSNumber numberWithInt: line];
}


/* -----------------------------------------------------------------------------
	icon:
		Icon to display for this entry in the list. Right now we have errors
		(fatal), warnings (possibly bad) and notes, which are usually just
		informational or best-practice advice.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(NSImage*)		icon
{
	NSImage*		img = nil;
	
	switch( type )
	{
		case ERROR_TYPE_ERROR:
			img = [NSImage imageNamed: @"ErrorIcon"];
			break;

		case ERROR_TYPE_WARNING:
			img = [NSImage imageNamed: @"WarningIcon"];
			break;

		case ERROR_TYPE_NOTE:
			img = [NSImage imageNamed: @"NoteIcon"];
			break;

		default:
			break;
	}
	
	return img;
}

-(int)          messageType
{
    return type;
}

@end
