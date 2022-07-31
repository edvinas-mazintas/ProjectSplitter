//
//  ViewController.h
//  ProjectSplitter
//
//  Created by Edvinas Mažintas on 2022-07-21.
//

#import <Cocoa/Cocoa.h>

//enum
//{
//    NO_FILTERING,
//    FILTER_LIBRARY,
//    FILTER_CONTENTS_OF_LIBRARY
//} FilterOption;

@interface ViewController : NSViewController

typedef NS_ENUM(NSUInteger, FilterOption) {
    NO_FILTERING,
    FILTER_LIBRARY,
    FILTER_CONTENTS_OF_LIBRARY
};

@property (weak) IBOutlet NSButton *chooseFolderButton;
@property (weak) IBOutlet NSTextField *pathToFolder;
@property (weak) IBOutlet NSButton *nukeLibrary;
@property (weak) IBOutlet NSButton *nukeCacheFolders;
@property (unsafe_unretained) IBOutlet NSTextView *editorVersions;
@property NSString *path;
@property NSURL *folderURL;
@property NSMutableArray *foldersToExclude;
@property FilterOption filterOption;

- (void) setPathTextFieldTooltip: (NSString *) aString;
- (void) openDirectorySelectionPanel;

@end

