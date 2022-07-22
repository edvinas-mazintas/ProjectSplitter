//
//  ViewController.h
//  ProjectSplitter
//
//  Created by Edvinas Mažintas on 2022-07-21.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (weak) IBOutlet NSButton *chooseFolderButton;
@property (weak) IBOutlet NSTextField *pathToFolder;
@property (unsafe_unretained) IBOutlet NSTextView *editorVersions;

@property (weak) IBOutlet NSButton *nukeLibrary;
@property (weak) IBOutlet NSButton *nukeCacheFolders;


@end

