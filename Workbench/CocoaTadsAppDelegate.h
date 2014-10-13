//
//  CocoaTadsAppDelegate.h
//  CocoaTADS
//
//  Created by Uli Kusterer on Sun Jun 01 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>


#define NEW_VERSIONS_PLIST @"http://www.zathras.de/new_versions.plist"
#define BUNDLE_VERSION [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]
#define BUNDLE_IDENTIFIER [[NSBundle mainBundle] bundleIdentifier]



@interface CocoaTadsAppDelegate : NSObject
{
}


-(id)	init;
-(void)	applicationWillFinishLaunching:(NSNotification *)notification;

-(IBAction)	newTextFile: (id)sender;

@end
