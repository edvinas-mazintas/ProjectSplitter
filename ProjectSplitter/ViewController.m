//
//  ViewController.m
//  ProjectSplitter
//
//  Created by Edvinas Mažintas on 2022-07-21.
//

#import "ViewController.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

#if DEBUG
    static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
    static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _foldersToExclude = [self readFoldersToExclude];
    [self setPathTextFieldTooltip:[_pathToFolder stringValue]];
    [self setupLogger];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void) setPathTextFieldTooltip: (NSString *) string {
    [_pathToFolder setToolTip:string];
}

- (NSOpenPanel *)getOpenPanel:(NSString *) title  {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setTitle: title];
    [panel setCanChooseFiles: NO];
    [panel setCanChooseDirectories: YES];
    [panel setAllowsMultipleSelection: NO];
    return panel;
}

- (void) openDirectorySelectionPanel {
    NSOpenPanel * selectedDirectory = [self getOpenPanel: @"Choose Project Folder"];
    
    [selectedDirectory beginWithCompletionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            self -> _folderURL = [[selectedDirectory URLs] objectAtIndex:0];
            self->_path = [self -> _folderURL absoluteString];
            self->_path = [self->_path substringFromIndex:7];
            [self->_pathToFolder setStringValue: self->_path];
            [self setPathTextFieldTooltip: self->_path];
        }
    }];
    
}

- (IBAction)onClickInputButton:(NSButton *)sender {
    [self openDirectorySelectionPanel];
}

- (NSString *)removeNewLines:(NSString *)string {
    return [string stringByReplacingOccurrencesOfString:@"[\r\n]+" withString:@"\n" options:NSRegularExpressionSearch range:NSMakeRange(0, string.length)];
}

- (NSArray *)filterArrayUsingLastPathComponent:(NSMutableArray *)fileURLS foldersToExclude:(NSMutableArray *)foldersToExclude {
    return [fileURLS filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"!(lastPathComponent) IN %@", foldersToExclude]];
}

static void updateFilterOption(ViewController *object, NSMutableArray *arr, NSMutableArray *fileURLS, NSArray **filteredURLS) {
    switch (FilterOption) {
        case NO_FILTERING:
            *filteredURLS = fileURLS;
            break;
        case FILTER_LIBRARY:
            *filteredURLS = [object filterArrayUsingLastPathComponent:fileURLS foldersToExclude:arr];
            break;
        case FILTER_CONTENTS_OF_LIBRARY:
            *filteredURLS = [object filterArrayUsingLastPathComponent:fileURLS foldersToExclude:object->_foldersToExclude];
            break;
    }
}

- (void)removeItemIfExistsAtURL:(NSFileManager *)fileManager url:(NSURL *)url {
    if ([fileManager fileExistsAtPath: url.path]) {
        [fileManager removeItemAtURL:url error:nil];
    }
}

- (void)createBaseDirectories:(NSMutableArray *)baseFolderURLS editorVersions:(NSArray *)editorVersions error:(NSError **)error fileManager:(NSFileManager *)fileManager outputURL:(NSURL *)outputURL {
    for(NSString* version in editorVersions){
        NSURL* url = [outputURL URLByAppendingPathComponent: [self->_folderURL lastPathComponent]];
        NSMutableString* lastPathComponent = [[self->_folderURL lastPathComponent] mutableCopy];
        [lastPathComponent appendString: @"_"];
        [lastPathComponent appendString: version];
        
        url = [url URLByAppendingPathComponent:lastPathComponent];
        [baseFolderURLS addObject:url];
        
        [self removeItemIfExistsAtURL:fileManager url:url];
        
        if(![fileManager createDirectoryAtPath: url.path withIntermediateDirectories:YES attributes:nil error:error]) {
            DDLogError(@"Failed to create directory: %@", *error);
        }
    }
}

- (IBAction)onClickOutputButton:(NSButton *)sender {
    __block NSError *error;
    
    if([_editorVersions.string isNotEqualTo: @""] && _editorVersions.string.length != 0){
        __block NSURL* outputURL;
        NSString *editorVersionsString = [_editorVersions string];
        editorVersionsString = [self removeNewLines:editorVersionsString];
        NSArray *editorVersions = [editorVersionsString componentsSeparatedByString: @"\n"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSOpenPanel* selectedDirectory = [self getOpenPanel:@"Choose Output Folder"];
        NSMutableArray *baseFolderURLS;
        
        if (!baseFolderURLS) {
            baseFolderURLS = [[NSMutableArray alloc] init];
        }
        
        [selectedDirectory beginWithCompletionHandler:^(NSInteger result){
            if (result == NSModalResponseOK && self->_folderURL != NULL) {
                outputURL = [[selectedDirectory URLs] objectAtIndex:0];
                
                NSArray *theFiles = [fileManager contentsOfDirectoryAtURL:self->_folderURL includingPropertiesForKeys:nil options:0 error:nil];
                NSArray *libraryFiles = [fileManager contentsOfDirectoryAtURL:[self->_folderURL URLByAppendingPathComponent:@"Library"] includingPropertiesForKeys:nil options:0 error:nil];
                
                if(libraryFiles == NULL){
                    FilterOption = NO_FILTERING;
                }
                
                NSMutableArray *fileURLS = [theFiles mutableCopy];
                NSArray *filteredURLS;
                
                NSMutableArray *arr = [NSMutableArray array];
                [arr addObject:@"Library"];
                
                updateFilterOption(self, arr, fileURLS, &filteredURLS);
                
                [self createBaseDirectories:baseFolderURLS editorVersions:editorVersions error:&error fileManager:fileManager outputURL:outputURL];
                
                for(NSURL *baseURL in baseFolderURLS){
                    for(NSURL *fileURL in filteredURLS){
                        NSURL *URLWithComponenent = [baseURL URLByAppendingPathComponent:[fileURL lastPathComponent]];

                        [self removeItemIfExistsAtURL:fileManager url:URLWithComponenent];

                        if(![fileManager copyItemAtURL:fileURL toURL: URLWithComponenent error: &error]){
                            DDLogError(@"Failed to copy file: %@", error);
                        }
                    }
                }
            }
        }];
    }
}

- (IBAction)nukeLibraryChecked:(NSButton *)sender {
    _nukeCacheFolders.enabled = !_nukeLibrary.state;
    FilterOption = FILTER_LIBRARY;
}

- (IBAction)nukeCacheFoldersChecked:(NSButton *)sender {
    _nukeLibrary.enabled = !_nukeCacheFolders.state;
    FilterOption = FILTER_CONTENTS_OF_LIBRARY;
}

- (NSMutableArray*)readFoldersToExclude{
    NSError *dataError;
    NSError *serializationError;
    
    NSString *key = @"CacheFolders";
    
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"Config" withExtension:@"plist"];
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&dataError];
    
    NSDictionary *dictionary = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:&serializationError];
    NSMutableArray *folderNames= [dictionary valueForKeyPath: key];
    
    if (folderNames == NULL) {
        DDLogError(@"Failed to read key \"CacheFolders\" from plist");
    }
    
    if(dataError){
        DDLogError(@"Failed to read data from URL: %@ ", dataError);
    }
    
    if(serializationError){
        DDLogError(@"Failed to serialize plist: %@ ", serializationError);
    }
    
    return folderNames;
}

- (void)setupLogger{
    [DDLog addLogger:[DDOSLogger sharedInstance]];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24;
    [DDLog addLogger:fileLogger];
}

@end
