This project and the files in it are (c) 2003-07 by M. Uli Kusterer, all rights
reserved.
Just because you are looking at the source code to Workbench for Macintosh and
the application is distributed as freeware, doesn't mean it's in the Public
Domain. If you want to sell this or use the sources in one of your projects,
contact witness_dot_of_dot_teachtext_at_zathras_dot_de to work out a deal.


COMPILING WORKBENCH
-------------------

Read the *complete* contents of this file to find out about getting Workbench to
compile. Also, after checking out this project from the SVN repository, make
sure you've done a "clean" on the project before the first build. This will
ensure you don't get odd errors from xCode.


WHAT GOES WHERE?
----------------

This project has been set up so it expects the TADS Unix distribution folder
and the folder containing this project in a "Programming" folder in your home
directory. I.e.:

	~/Programming/Workbench/CocoaTADS.xcodeproj
	~/Programming/tads/tads2/
	~/Programming/tads/tads3/
	
If you want to put it somewhere else, be prepared to change a lot of file
paths, especially in the TADS 2 and TADS 3 targets.

The end-user distribution usually also includes the TADS 3 docs (from the
tads3/doc/ folder) and TADS 3 articles from tads.org, which go as t3_doc in the
"Workbench Help" folder. To get the T3 how-tos, you'll want to heed the
instructions in t3doc/articles.html.


ABOUT THE DIFFERENT TARGETS IN THIS PROJECT
-------------------------------------------

There are four targets in this project. Two are legacy targets that simply
make TADS 2 and TADS 3 using their makefiles (so, if you haven't done so
already, get Suzanne Skinner's Unix TADS distro from http://www.tads.org
and uncomment the MacOS X ("Darwin") parts of the makefiles). Then there's
the CocoaTADS target that compiles the stuff specific to Workbench.

The final target is aptly named "All Targets" and simply compiles first TADS
2, then TADS 3, and finally CocoaTADS. When you're first launching this
project, this last target is the only one you want to build. After that, you'll
typically not want to touch the T2/T3 targets (except when Suzanne, Matt and Co.
release a new TADS Unix distro). The advantage of this set-up is that you can
"clean" the CocoaTADS target without also having to recompile the T2/T3 stuff.

Once you have built TADS 3, t3make and t3run should also stop being red in the
Resources group of the project.


THE MORE ARCANE DETAILS OF COMPILING TCCMDUTIL
----------------------------------------------

Mike's TCCmdUtil module for parsing t3m Makefiles used by TADS 3 needs some
massaging to compile from inside an Xcode project. This is already set
up properly in this poject file, but in case you want to know what's going on
'under the hood', here is the rationale I jotted down so I don't forget it:

First, you have to define a few preprocessor constants, which you do by passing
the -D flag to GCC in the "CocoaTADS" target's Target Settings:

-DOS_ANSI -DNEXT -DUNIX -DHAVE_STRCASECMP -Dmemicmp=strncmp 

OS_ANSI	- We're not compiling for Windows or some other non-ANSI OS
NEXT	- We can't define DARWIN (which would be more correct), as that
		  causes Cocoa's headers to exclude all the GUI stuff, which we
		  need. So I picked NEXT, which is the closest thing to Darwin
		  that exists in the unmodified Unix distro.
UNIX	- We're compiling for a Unix, so use Unix-specific stuff if
		  you can.
HAVE_STRCASECMP - Darwin (and thus OS X) implements the strcasecmp()
		  function, no need for TADS to roll its own or fake it.
memicmp=strncmp - The Darwin version does this as well. Since Darwin
		  and thus OS X don't define memicmp(), we substitute it with
		  strncmp(), which has the same signature and does pretty much
		  the same.

After that, we also need to pass -lncurses as a linker setting to ld
by specifying it in the linker flags of the Target Settings. Apparently,
the TADS source code depends on some functions in the ncurses library
for console output, even though the stuff we're actually using never
calls it ...

If the compiler complains about "wchar.h" being missing, copy the file
"wchar.h" into your tads/tads3/ directory and add "|| defined(NEXT)" to the
similar statements at the top of tads/tads3/wcs.cpp.

You may have noticed that this is rather messy. It would probably be smart to
get in touch with Suzanne and get permission to add a MACOSX target to the Unix
distro, which would simply be a copy of the DARWIN target Matt Herberg is
maintaining that doesn't use the DARWIN constant. Then all of the above would
turn into a nice, small -DMACOSX or whatever.


