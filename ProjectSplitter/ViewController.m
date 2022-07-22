//
//  ViewController.m
//  ProjectSplitter
//
//  Created by Edvinas Mažintas on 2022-07-21.
//

#import "ViewController.h"


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)onClick:(NSButton *)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setTitle: @"Choose Project Folder"];
    [panel setCanChooseFiles: NO];
    [panel setCanChooseDirectories: YES];
    [panel setAllowsMultipleSelection: NO];
    
    [panel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            NSURL* folderURL = [[panel URLs] objectAtIndex:0];
            NSLog(@"%@", folderURL);
            NSString *path = [folderURL absoluteString];
            path = [path substringFromIndex:7];
            
            [_pathToFolder setStringValue: path];
        }
    }];
}

- (NSString *)removeNewLines:(NSString *)editorVersionsString {
    return [editorVersionsString stringByReplacingOccurrencesOfString:@"[\r\n]+" withString:@"\n" options:NSRegularExpressionSearch range:NSMakeRange(0, editorVersionsString.length)];
}

- (IBAction)onClone:(NSButton *)sender {
    
    if(![_editorVersions.string isEqual: @""] && _editorVersions.string.length != 0){
        NSString *editorVersionsString = [_editorVersions string];
        
        editorVersionsString = [self removeNewLines:editorVersionsString];
        
        NSArray *editorVersions = [editorVersionsString componentsSeparatedByString: @"\n"];
        
        for(int i = 0; i < [editorVersions count]; i++){
            NSLog(@"%@",editorVersions[i]);
        }
    }
    
}

- (IBAction)nukeLibraryChecked:(NSButton *)sender {
    _nukeCacheFolders.enabled = !_nukeLibrary.state;
}


- (IBAction)nukeCacheFoldersChecked:(NSButton *)sender {
    _nukeLibrary.enabled = !_nukeCacheFolders.state;
}

@end
