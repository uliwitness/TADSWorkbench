/* ================================================================================
	PROJECT:	UlisTADS
	FILE:		NSTadsOptFileHelper.mm
	PURPOSE:	Cocoa wrapper around Mike Roberts' C++ code for parsing
				TADS 3 Makefiles (.t3m).
   ============================================================================= */

/* --------------------------------------------------------------------------------
	Headers:
   ----------------------------------------------------------------------------- */

#ifdef __cplusplus
extern "C" {
#endif

#include "osifctyp.h"
#include "osfrobtads.h"
#include "tccmdutl.h"

#ifdef __cplusplus
}
#endif

#include "NSTadsOptFileHelper.h"


/* --------------------------------------------------------------------------------
	CTadsOptFileHelper:
		C++ class being passed internally.
   ----------------------------------------------------------------------------- */

class CTadsOptFileHelper: public CTcOptFileHelper
{
	id		mDelegate;

public:
	CTadsOptFileHelper( id delegate );
	virtual ~CTadsOptFileHelper();

    // These two are used fo allocating our argument array:
    virtual char *alloc_opt_file_str(size_t len) 						{ return (char*) malloc(len + 1); };
    virtual void free_opt_file_str(char *str)							{ free(str); };

    /* process a comment line */
    virtual void process_comment_line(const char *theline);

    /* process a non-comment line */
    virtual void process_non_comment_line(const char *theline);

    /* process a configuration line */
    virtual void process_config_line(const char *configid, const char *theline, int newsection );
	
	id			getDelegate()	{ return mDelegate; };
};


/* --------------------------------------------------------------------------------
	CTadsOptFileHelper:
		C++ class being passed internally.
   ----------------------------------------------------------------------------- */

CTadsOptFileHelper::CTadsOptFileHelper( id delegate )
{
	mDelegate = delegate;
}

CTadsOptFileHelper::~CTadsOptFileHelper()
{
	
}


/* process a comment line */
void	CTadsOptFileHelper::process_comment_line( const char *theline )
{
	[mDelegate tadsProcessCommentLine: [NSString stringWithCString: theline]];
}

/* process a non-comment line */
void	CTadsOptFileHelper::process_non_comment_line( const char *theline )
{
	[mDelegate tadsProcessNonCommentLine: [NSString stringWithCString: theline]];
}

/* process a configuration line */
void	CTadsOptFileHelper::process_config_line( const char *configid, const char *theline,
														int newsection )
{
	[mDelegate tadsProcessConfigLine: [NSString stringWithCString: theline]
					withID: [NSString stringWithCString: configid]
					newSection: (newsection ? YES : NO)];
}


#ifdef __cplusplus
extern "C" {
#endif

/* -----------------------------------------------------------------------------
    StripExcessSpacesFromNSString:
        Removes spaces from the beginning and end of a string.
    
    REVISIONS:
        2002-10-03	UK	Created.
   -------------------------------------------------------------------------- */

void	StripExcessSpacesFromNSString( NSMutableString* str )
{
	[str setString: [str stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]];
}


/* -----------------------------------------------------------------------------
    EscapeCharInNSString:
        Find all occurences of the specified character in a string and prefix
		them with a backslash each.
    
    REVISIONS:
        2002-10-03	UK	Created.
   -------------------------------------------------------------------------- */

void	EscapeCharInNSString( char pattern, NSMutableString* outstr )
{
	NSRange		vFoundChunk,
				vSearchArea = { 0, [outstr length] };
	
	while( true )
	{
		vFoundChunk = [outstr rangeOfString:[NSString stringWithCString:&pattern length:1] options:0 range:vSearchArea];
		if( (vFoundChunk.location == NSNotFound) && (vFoundChunk.length == 0) )
			break;
		[outstr insertString:@"\\" atIndex: vFoundChunk.location];
		vSearchArea.location = vFoundChunk.location +vFoundChunk.length +1;
		vSearchArea.length = [outstr length] -vSearchArea.location;
	}
}


/* -----------------------------------------------------------------------------
    EscapeNSStringForCommandline:
        Escape all critical characters in a string so we can use it unquoted
		on the command line.
    
    REVISIONS:
        2002-10-03	UK	Created.
   -------------------------------------------------------------------------- */

void	EscapeNSStringForCommandline( NSMutableString* outstr )
{
	EscapeCharInNSString( '\\', outstr );
	EscapeCharInNSString( ' ', outstr );
	EscapeCharInNSString( '\t', outstr );
	EscapeCharInNSString( '\n', outstr );
	EscapeCharInNSString( '\r', outstr );
	EscapeCharInNSString( '|', outstr );
}


/* -----------------------------------------------------------------------------
    EscapeNSStringForT3m:
        Wrap a string in quotes and replace all quote characters with two.
		("stutter" the quotes)
    
    REVISIONS:
        2002-10-03	UK	Created.
   -------------------------------------------------------------------------- */

NSString*	EscapeNSStringForT3m( NSString* inStr )
{
	NSRange				vFoundChunk,
						vSearchArea = { 0, [inStr length] };
	NSMutableString*	outstr = [[inStr mutableCopy] autorelease];
	
	while( true )
	{
		vFoundChunk = [outstr rangeOfString:@"\"" options:0 range:vSearchArea];
		if( (vFoundChunk.location == NSNotFound) && (vFoundChunk.length == 0) )
			break;
		[outstr insertString:@"\"" atIndex: vFoundChunk.location];
		vSearchArea.location = vFoundChunk.location +vFoundChunk.length+1;
	}
	
	[outstr setString: [NSMutableString stringWithFormat:@"\"%@\"", outstr]];
	
	return outstr;
}


/* -----------------------------------------------------------------------------
    UnstutterT3mNSString:
        Revert the result of escape_str_for_t3m().
		Does nothing if the string isn't at least enclosed in quotes, to avoid
		mangling of strings that weren't stuttered to begin with.
    
    REVISIONS:
		2003-05-29	UK	Changed to ignore unquoted strings
        2002-10-03	UK	Created.
   -------------------------------------------------------------------------- */

void	UnstutterT3mNSString( NSMutableString* outstr )
{
	NSRange		vFoundChunk,
				vSearchArea;
	
	// String is quoted?
	if( [outstr characterAtIndex:0] != '"' )
		return;
	if( [outstr characterAtIndex:([outstr length] -1)] != '"' )
		return;
	
	// Delete leading & trailing quotes:
	[outstr deleteCharactersInRange: NSMakeRange(0,1)];
	[outstr deleteCharactersInRange: NSMakeRange([outstr length]-1,1)];
	
	vSearchArea = NSMakeRange(0, [outstr length]);
	
	// Turn double quotes into single quotes again:
	while( true )
	{
		vFoundChunk = [outstr rangeOfString:@"\"\"" options:0 range:vSearchArea];
		if( (vFoundChunk.location == NSNotFound) && (vFoundChunk.length == 0) )
			break;
		vFoundChunk.location++;
		vFoundChunk.length = 1;
		[outstr deleteCharactersInRange:vFoundChunk];
		vSearchArea.location = vFoundChunk.location +vFoundChunk.length+1;
		vSearchArea.length = [outstr length] -vFoundChunk.location;
	}
}


#ifdef __cplusplus
}
#endif


/* --------------------------------------------------------------------------------
	NSObject (NSTadsOptFileHelperDelegate):
		Implement these in your delegate.
   ----------------------------------------------------------------------------- */

@implementation NSObject (NSTadsOptFileHelperDelegate)

-(void)	tadsPrepareParsing: (NSTadsOptFileHelper*)sender
{
	
}


-(void)	tadsProcessCommentLine: (NSMutableString*)theline
{
	
}


-(void)	tadsProcessNonCommentLine: (NSMutableString*)theline
{
	
}


-(void) tadsProcessConfigLine: (NSMutableString*)theline withID: (NSString*)configID newSection: (BOOL)newsection
{
	
}

@end


/* --------------------------------------------------------------------------------
	NSTadsOptFileHelper:
   ----------------------------------------------------------------------------- */

@implementation NSTadsOptFileHelper

-(id)	initWithDelegate: (id)delegate
{
	if( self = [super init] )
	{
		helper = new CTadsOptFileHelper( delegate );
	}
	
	return self;
}


-(void)	dealloc
{
	if( helper )
		delete ((CTadsOptFileHelper*)helper);
	[super dealloc];
}


/* -----------------------------------------------------------------------------
	processFile:
		Parse the specified file using the very same code Mike uses in t3make
		and return YES on success, NO on failure. The actual processing has to
		be done by this object's delegate.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(BOOL)	processFile: (NSString*)pathname
{
	int				argc;
	osfildef*		vFile;
	
	if( !helper )
		return NO;
	
	// Open makefile:
	vFile = osfoprwt( [pathname cString], 0 );
	if( !vFile )
		return NO;
	
	// Count how many options it has:
	argc = CTcCommandUtil::parse_opt_file( vFile, NULL, NULL );
	if( argc > 0 )
	{
		progressMax = argc +1;
		
		// Tell delegate to get ready:
		[((CTadsOptFileHelper*)helper)->getDelegate() tadsPrepareParsing:self];		// YEAH BABY!!! Objective C++!!!
		
		// Rewind file and now parse in earnest:
		osfseek( vFile, 0, OSFSK_SET );
		CTcCommandUtil::parse_opt_file( vFile, NULL, (CTadsOptFileHelper*)helper );
	}
	osfcls( vFile );
	
	return YES;
}


/* -----------------------------------------------------------------------------
	progressMax:
		An int that gives you a nice maximum value for any progress bar you
		may want to put up wile processFile: is running. You have to maintain
		a counter yourself which you can increase from your delegate callbacks.
	
	REVISIONS:
		2004-10-17	UK	Documented.
   -------------------------------------------------------------------------- */

-(int)	progressMax
{
	return progressMax;
}

@end






