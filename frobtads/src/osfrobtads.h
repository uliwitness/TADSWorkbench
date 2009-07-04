/* OS-layer functions and macros.
 *
 * This file does not introduce any curses (or other screen-API)
 * dependencies; it can be used for both the interpreter as well as the
 * compiler.
 */
#ifndef OSFROBTADS_H
#define OSFROBTADS_H

#include "common.h"

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

/* We don't support the Atari 2600. */
#include "osbigmem.h"

/* Provide some non-standard functions (memicmp(), etc). */
#include "missing.h"

/* Our Tads OEM identifier. */
#define TADS_OEM_NAME PACKAGE_MAINTAINER " <" PACKAGE_BUGREPORT ">"

/* We assume that the C-compiler is mostly ANSI compatible. */
#define OSANSI

/* Special function qualifier needed for certain types of callback
 * functions.  This is for old 16-bit systems; we don't need it and
 * define it to nothing. */
#define OS_LOADDS

/* Unices don't suffer the near/far pointers brain damage (thank God) so
 * we make this a do-nothing macro. */
#define osfar_t

/* This is used to explicitly discard computed values (some compilers
 * would otherwise give a warning like "computed value not used" in some
 * cases).  Casting to void should work on every ANSI-Compiler. */
#define DISCARD (void)

/* Copies a struct into another.  ANSI C allows the assignment operator
 * to be used with structs. */
#define OSCPYSTRUCT(x,y) ((x)=(y))

/* Link error messages into the application. */
#define ERR_LINK_MESSAGES

/* Program Exit Codes. */
#define OSEXSUCC 0 /* Successful completion. */
#define OSEXFAIL 1 /* Failure. */

/* The default size for the UNDO-buffer is quite small; the player is
 * only allowed to UNDO about 5 or 6 times.  We'll make the size of this
 * buffer configurable by the user.
 *
 * See tads3/vmparam.h for more info.
 *
 * We achieve this by redefining the macro that TADS uses to store the
 * buffer-size as a normal variable.  Fortunately, TADS3 allocates this
 * buffer either through 'new' or malloc(), never as a static array, so
 * this approach works on every compiler no matter if dynamically-sized
 * arrays are supported or not (ISO C++ forbids things like
 * "int a[variable];").
 *
 * This stuff is only useful for the interpreter, so we omit it when
 * building the compiler.
 */
#ifdef RUNTIME
/* First, we need to know what TADS3 uses as default.  This is defined
 * in vmparam.h. */
#include "vmparam.h"
/* We store the default in a static variable since the macro-expansion
 * needs to happen right now as we redefine this macro later. */
static const int defaultVmUndoMaxRecords = VM_UNDO_MAX_RECORDS;
/* Since we'll redefine this macro, we must undefine it first, as is
 * required by standard C and C++. */
#undef VM_UNDO_MAX_RECORDS
#undef VM_UNDO_MAX_SAVEPTS
/* Now we'll turn the macro into a normal variable. */
#define VM_UNDO_MAX_RECORDS frobVmUndoMaxRecords
extern int frobVmUndoMaxRecords;
/* The maximum number of allowed savepoints has a hard-coded upper-limit
 * of 255 in the TADS3 base code.  Since this value has no direct effect
 * on memory consumption (it's the max undo records that matters) we'll
 * just use the maximum and won't provide a way to change it. */
#define VM_UNDO_MAX_SAVEPTS 255
#endif /* RUNTIME */

/* Here we configure the osgen layer; refer to tads2/osgen3.c for more
 * information about the meaning of these macros. */
#define USE_DOSEXT
#define USE_NULLSTYPE
#define USE_NULL_SET_TITLE
/* STD_OSCLS is undocumented; it enables a standard oscls()
 * implementation. */
#define STD_OSCLS
/* Undocumented; enables a standard implementation of the highlighting &
 * colors routines.  It also enables the osgen3 banner API
 * implementation. */
#define STD_OS_HILITE
/* The following osgen configuration macros aren't needed by the
 * compiler, so we only define them if we are building the interpreter.
 */
#ifdef RUNTIME
#  define USE_STATLINE
#  define USE_SCROLLBACK
#  define USE_HISTORY
   /* OS_SBSTAT is undocumented, but needed by osgen3; it should contain
    * the string to print when scrollback-mode is activated. */
#  define OS_SBSTAT "Review Mode - Keys: Up/Down/PageUp/PageDown - F1 to exit"
   /* Undocumented; size of the command-history buffer. */
#  define HISTBUFSIZE 1000
   /* status_mode is an undocumented variable, but needed by osgen3.  It
    * keeps track of where game-text should go (statusline, game window,
    * nowhere).  We don't need to know anything about that though; we just
    * define it so that osgen3.c compiles and links without errors, as it
    * doesn't define it itself for some reason. */
   extern int status_mode;
#else
   /* Tell osgen to use stdio-routines for certain functions (the
    * compiler doesn't need anything more than that). */
#  define USE_STDIO
   /* Use a do-nothing os_score() function. */
#  define USE_NULLSCORE
   /* The compiler doesn't actually use os_xlat_html4(); we just define
    * it as an empty macro so the linker won't bark. */
#  define os_xlat_html4(html4_char,result,result_buf_len)
#endif

/* Override the default makefile for the TADS 3 compiler.  We'll
 * capitalize the fist letter (as is usual in Unix). */
#ifdef T3_DEFAULT_PROJ_FILE
# undef T3_DEFAULT_PROJ_FILE
# define T3_DEFAULT_PROJ_FILE "Makefile.t3m"
#endif

/* System identifier and system descriptive name.  We also state
 * "Windows" since we compile and run just fine under MS Windows.  We
 * ommit "curses" in the compilers, as only the interpreter uses
 * curses. */
#ifdef RUNTIME
#  define OS_SYSTEM_NAME "CURSES"
#  define OS_SYSTEM_LDESC "curses (POSIX/Unix/MS-Windows)"
#else
#  define OS_SYSTEM_NAME "POSIX_UNIX_MSWINDOWS"
#  define OS_SYSTEM_LDESC "POSIX/Unix/MS-Windows"
#endif

/* Theoretical maximum osmalloc() size.
 * Unix systems have at least a 32-bit memory space.  Even on 64-bit
 * systems, 2^32 is a good value, so we don't bother trying to find out
 * an exact value. */
#define OSMALMAX 0xffffffffL

/* Maximum length of a filename. */
#ifdef HAVE_LONG_FILE_NAMES
#define OSFNMAX 255
#else
#define OSFNMAX 14
#endif

#ifndef OSPATHALT
/* Other path separator characters. */
#define OSPATHALT ""
#endif

#ifndef OSPATHURL
/* Path separator characters for URL conversions. */
#define OSPATHURL "/"
#endif

#ifndef OSPATHCHAR
/* Normal path separator character. */
#define OSPATHCHAR '/'
#endif

/* Directory separator for PATH-style environment variables. */
#define OSPATHSEP ':'

/* File handle structure for osfxxx functions. */
typedef FILE osfildef;

/* The maximum width of a line of text.
 *
 * We ignore this, but the base code needs it defined.  If the
 * interpreter is run inside a console or terminal with more columns
 * than the value defined here, weird things will happen, so we go safe
 * and use a large value. */
#define OS_MAXWIDTH 255

/* Disable the Tads swap file; computers have plenty of RAM these days.
 */
#define OS_DEFAULT_SWAP_ENABLED 0

/* TADS 2 macro/function configuration.  Modern configurations always
 * use the no-macro versions, so these definitions should always be set
 * as shown below. */
#define OS_MCM_NO_MACRO
#define ERR_NO_MACRO

/* Not really needed; just a dummy. */
#define OS_TR_USAGE "usage: frob [options] file"

/* TADS 2 compiler usage message.  We should actually use the name the
 * user used to invoke the compiler, but the base code doesn't provide
 * for that. */
#define OS_TC_USAGE "Usage: tadsc [options] file"

/* File timestamp type.
 *
 * Needed by the TADS 3 compiler. */
struct os_file_time_t {
	time_t t;
};

/* These values are used for the "mode" parameter of osfseek() to
 * indicate where to seek in the file. */
#define OSFSK_SET SEEK_SET /* Set position relative to the start of the file. */
#define OSFSK_CUR SEEK_CUR /* Set position relative to the current file position. */
#define OSFSK_END SEEK_END /* Set position relative to the end of the file. */


/* ============= Functions follow ================ */

/* Allocate a block of memory of the given size in bytes. */
#define osmalloc malloc

/* Free memory previously allocated with osmalloc(). */
#define osfree free

/* Reallocate memory previously allocated with osmalloc() or osrealloc(),
 * changing the block's size to the given number of bytes. */
#define osrealloc realloc

/* Open text file for reading. */
#define osfoprt(fname,typ) (fopen((fname),"r"))

/* Open text file for writing. */
#define osfopwt(fname,typ) (fopen((fname),"w"))

/* Open text file for reading and writing, keeping the file's existing
 * contents if the file already exists or creating a new file if no
 * such file exists. */
osfildef*
osfoprwt( const char* fname, os_filetype_t typ );

/* Open text file for reading/writing.  If the file already exists,
 * truncate the existing contents.  Create a new file if it doesn't
 * already exist. */
#define osfoprwtt(fname,typ) (fopen((fname),"w+"))

/* Open binary file for writing. */
#define osfopwb(fname,typ) (fopen((fname),"wb"))

/* Open source file for reading - use the appropriate text or binary
 * mode. */
#define osfoprs osfoprt

/* Open binary file for reading. */
#define osfoprb(fname,typ) (fopen((fname),"rb"))

/* Open binary file for reading/writing.  If the file already exists,
 * keep the existing contents.  Create a new file if it doesn't already
 * exist. */
osfildef*
osfoprwb( const char* fname, os_filetype_t typ );

/* Open binary file for reading/writing.  If the file already exists,
 * truncate the existing contents.  Create a new file if it doesn't
 * already exist. */
#define osfoprwtb(fname,typ) (fopen((fname),"w+b"))

/* Get a line of text from a text file. */
#define osfgets fgets

/* Write a line of text to a text file. */
#define osfputs fputs

/* Write bytes to file. */
#define osfwb(fp,buf,bufl) (fwrite((buf),(bufl),1,(fp))!=1)

/* Read bytes from file. */
#define osfrb(fp,buf,bufl) (fread((buf),(bufl),1,(fp))!=1)

/* Read bytes from file and return the number of bytes read. */
#define osfrbc(fp,buf,bufl) (fread((buf),1,(bufl),(fp)))

/* Get the current seek location in the file. */
#define osfpos ftell

/* Seek to a location in the file. */
#define osfseek fseek

/* Close a file. */
#define osfcls fclose

/* Delete a file. */
#define osfdel remove

/* Access a file - determine if the file exists.
 *
 * We map this to the access() function.  It should be available in
 * virtually every system out there, as it appears in many standards
 * (SVID, AT&T, POSIX, X/OPEN, BSD 4.3, DOS, MS Windows, maybe more). */
#define osfacc(fname) (access((fname), F_OK))

/* Get a character from a file. */
#define osfgetc fgetc

/* Set busy cursor.
 *
 * We don't have a mouse cursor so there's no need to implement this. */
#define os_csr_busy(a)

/* Update progress display.
 *
 * We don't provide any kind of "compilation progress display", so we
 * just define this as an empty macro.
 */
#define os_progress(fname,linenum)

/* Initialize the time zone.
 *
 * We don't need this (I think). */
#define os_tzset()

#endif /* OSFROBTADS_H */
