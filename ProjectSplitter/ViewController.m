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
    [self setFoldersToExclude:[self readFoldersToExclude]];
    [self setPathTextFieldTooltip:[_pathToFolder stringValue]];
    [self setupLogger];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void)setPathTextFieldTooltip:(NSString *)aString {
    [_pathToFolder setToolTip:aString];
}

- (NSOpenPanel *)directorySelectionPanel:(NSString *)title {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setTitle: title];
    [panel setCanChooseFiles: NO];
    [panel setCanChooseDirectories: YES];
    [panel setAllowsMultipleSelection: NO];
    return panel;
}

- (void)openDirectorySelectionPanel {
    NSOpenPanel *selectedDirectory = [self directorySelectionPanel: @"Choose Project Folder"];
    
    [selectedDirectory beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            self->_folderURL = [[selectedDirectory URLs] objectAtIndex:0];
            self->_path = [self ->_folderURL absoluteString];
            self->_path = [self->_path substringFromIndex:7];
            [self->_pathToFolder setStringValue: self->_path];
            [self setPathTextFieldTooltip: self->_path];
        }
    }];
}

- (IBAction)selectProjectDirectory:(NSButton *)sender {
    [self openDirectorySelectionPanel];
}

- (NSString *)removeNewLines:(NSString *)string {
    return [string stringByReplacingOccurrencesOfString:@"[\r\n]+" withString:@"\n" options:NSRegularExpressionSearch range:NSMakeRange(0, string.length)];
}

- (NSArray *)filterArrayUsingLastPathComponent:(NSMutableArray *)fileURLS foldersToExclude:(NSArray *)foldersToExclude {
    return [fileURLS filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"!(lastPathComponent) IN %@", foldersToExclude]];
}

- (void)removeItemIfExistsAtURL:(NSFileManager *)fileManager url:(NSURL *)url {
    if ([fileManager fileExistsAtPath: url.path]) {
        [fileManager removeItemAtURL:url error:nil];
    }
}

- (void)createBaseDirectories:(NSMutableArray *)baseFolderURLS editorVersions:(NSArray *)editorVersions error:(NSError **)error fileManager:(NSFileManager *)fileManager outputURL:(NSURL *)outputURL {
    for (NSString *version in editorVersions) {
        NSURL *url = [outputURL URLByAppendingPathComponent: [self->_folderURL lastPathComponent]];
        NSMutableString* lastPathComponent = [[self->_folderURL lastPathComponent] mutableCopy];
        [lastPathComponent appendString: @"_"];
        [lastPathComponent appendString: version];
        
        url = [url URLByAppendingPathComponent:lastPathComponent];
        [baseFolderURLS addObject:url];
        
        [self removeItemIfExistsAtURL:fileManager url:url];
        
        if (![fileManager createDirectoryAtPath: url.path withIntermediateDirectories:YES attributes:nil error:error]) {
            DDLogError(@"Failed to create directory: %@", *error);
        }
    }
}

- (void)updateFilteredURLS:(NSArray<NSString *> *)arr fileURLS:(NSMutableArray *)fileURLS filteredURLS:(NSArray **)filteredURLS {
    switch (self->_filterOption) {
        case NO_FILTERING:
            *filteredURLS = fileURLS;
            break;
        case FILTER_LIBRARY:
            *filteredURLS = [self filterArrayUsingLastPathComponent:fileURLS foldersToExclude:arr];
            break;
        case FILTER_CONTENTS_OF_LIBRARY:
            *filteredURLS = [self filterArrayUsingLastPathComponent:fileURLS foldersToExclude:self->_foldersToExclude];
            break;
        default:
            break;
    }
}

- (NSArray *)versionArray {
    NSString *editorVersionsString = [_editorVersions string];
    editorVersionsString = [self removeNewLines:editorVersionsString];
    NSArray *editorVersions = [editorVersionsString componentsSeparatedByString: @"\n"];
    return editorVersions;
}

- (void)copyItemsToBaseFolderURLS:(NSMutableArray *)baseFolderURLS error:(NSError **)error fileManager:(NSFileManager *)fileManager filteredURLS:(NSArray *)filteredURLS {
    for (NSURL *baseURL in baseFolderURLS) {
        for (NSURL *fileURL in filteredURLS) {
            NSURL *URLWithComponenent = [baseURL URLByAppendingPathComponent:[fileURL lastPathComponent]];
            
            [self removeItemIfExistsAtURL:fileManager url:URLWithComponenent];
            
            if (![fileManager copyItemAtURL:fileURL toURL: URLWithComponenent error: error]) {
                DDLogError(@"Failed to copy file: %@", *error);
            }
        }
    }
}

- (IBAction)selectOutputDirectory:(NSButton *)sender {
    __block NSError *error;
    __block NSURL* outputURL;
    
    if ([_editorVersions.string isNotEqualTo: @""] && _editorVersions.string.length != 0) {
        NSArray *editorVersions = [self versionArray];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSOpenPanel *selectedDirectory = [self directorySelectionPanel:@"Choose Output Folder"];
        NSMutableArray *baseFolderURLS = [[NSMutableArray alloc] init];
        
        [selectedDirectory beginWithCompletionHandler:^(NSInteger result) {
            if (result == NSModalResponseOK && self->_folderURL != NULL) {
                outputURL = [[selectedDirectory URLs] objectAtIndex:0];
                
                NSArray *theFiles = [fileManager contentsOfDirectoryAtURL:self->_folderURL includingPropertiesForKeys:nil options:0 error:nil];
                NSArray *libraryFiles = [fileManager contentsOfDirectoryAtURL:[self->_folderURL URLByAppendingPathComponent:@"Library"] includingPropertiesForKeys:nil options:0 error:nil];
                
                if (libraryFiles == NULL) {
                    [self setFilterOption:NO_FILTERING];
                }
                
                NSMutableArray *fileURLS = [theFiles mutableCopy];
                NSArray *filteredURLS;
                NSArray<NSString *> *arr = @[@"Library"];
                
                [self updateFilteredURLS:arr fileURLS:fileURLS filteredURLS:&filteredURLS];
                [self createBaseDirectories:baseFolderURLS editorVersions:editorVersions error:&error fileManager:fileManager outputURL:outputURL];
                [self copyItemsToBaseFolderURLS:baseFolderURLS error:&error fileManager:fileManager filteredURLS:filteredURLS];
            }
        }];
    }
}

- (IBAction)nukeLibraryChecked:(NSButton *)sender {
    _nukeCacheFolders.enabled = !_nukeLibrary.state;
    [self setFilterOption:FILTER_LIBRARY];
}

- (IBAction)nukeCacheFoldersChecked:(NSButton *)sender {
    _nukeLibrary.enabled = !_nukeCacheFolders.state;
    [self setFilterOption:FILTER_CONTENTS_OF_LIBRARY];
}

- (NSMutableArray*)readFoldersToExclude {
    NSError *dataError;
    NSError *serializationError;
    
    NSString *key = @"CacheFolders";
    
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"Config" withExtension:@"plist"];
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&dataError];
    
    NSDictionary *dictionary = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:&serializationError];
    NSMutableArray *folderNames= [dictionary valueForKeyPath: key];
    
    if (folderNames == NULL) {
        DDLogError(@"Failed to read key %@ from plist", key);
    }
    
    if (dataError) {
        DDLogError(@"Failed to read data from URL: %@", dataError);
    }
    
    if (serializationError) {
        DDLogError(@"Failed to serialize plist: %@", serializationError);
    }
    
    return folderNames;
}

- (void)setupLogger {
    [DDLog addLogger:[DDOSLogger sharedInstance]];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24;
    [DDLog addLogger:fileLogger];
}

@end
