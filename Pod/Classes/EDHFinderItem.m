//
//  EDHFinderItem.m
//  EDHFinder
//
//  Created by Tatsuya Tobioka on 10/1/14.
//  Copyright (c) 2014 tnantoka. All rights reserved.
//

#import "EDHFinderItem.h"

#import "EDHFinder.h"
#import "EDHUtility.h"

#import "FCFileManager.h"

#import <MobileCoreServices/MobileCoreServices.h>

#import "SSZipArchive.h"

typedef NS_ENUM(NSUInteger, EDHFinderItemCreateType) {
    EDHFinderItemCreateTypeFile,
    EDHFinderItemCreateTypeDirectory,
};

@implementation EDHFinderItem

- (id)initWithPath:(NSString *)path{
    if (self = [super init]) {
        self.path = path;
        self.name = path.lastPathComponent;
        
        self.mimeType = [self detectMimeType];
        
        NSDictionary *attributes = [FCFileManager attributesOfItemAtPath:self.path];
        self.isFile = [attributes[NSFileType] isEqualToString:NSFileTypeRegular];
        self.isDirectory = [attributes[NSFileType] isEqualToString:NSFileTypeDirectory];
        self.modificationDate = attributes[NSFileModificationDate];
        self.fileSize = attributes[NSFileSize];
        if (self.isDirectory) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSArray *fileList = [fileManager contentsOfDirectoryAtPath:self.path error:nil];
            self.folderFileCount = fileList.count;
        }
        
//        if (self.isDirectory) {
//            self.name = [self.name stringByAppendingString:@"/"];
//        }
    }
    return self;
}

- (NSString *)relativePath {
    return [[EDHFinder sharedFinder] relativePathFromRoot:self.path];
}

- (BOOL)isEditable {
    NSError *error = nil;
    [NSString stringWithContentsOfFile:self.path encoding:NSUTF8StringEncoding error:&error];
    return error == nil;
}

- (NSMutableArray *)children {
    NSMutableArray *items = @[].mutableCopy;
    for (NSString *path in [FCFileManager listItemsInDirectoryAtPath:self.path deep:NO]) {
        EDHFinderItem *item = [[EDHFinderItem alloc] initWithPath:path];
        [items addObject:item];
    }
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"modificationDate" ascending:NO];
    [items sortUsingDescriptors:@[descriptor]];
    
    return items;
}

- (void)createFileWithName:(NSString *)name success:(void (^)(EDHFinderItem *item))success failure:(void (^)(NSError *error))failure {
    [self createWithType:EDHFinderItemCreateTypeFile name:name success:success failure:failure];
}

- (void)createDirectoryWithName:(NSString *)name success:(void (^)(EDHFinderItem *item))success failure:(void (^)(NSError *error))failure {
    [self createWithType:EDHFinderItemCreateTypeDirectory name:name success:success failure:failure];
}

- (void)downloadWithURL:(NSString *)urlString success:(void (^)(EDHFinderItem *item))success failure:(void (^)(NSError *error))failure {
    NSString *path = [self.path stringByAppendingPathComponent:urlString.lastPathComponent];
    
    if ([FCFileManager existsItemAtPath:path]) {
        if (failure) {
            failure(nil);
        }
        return;
    }    

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [NSURL URLWithString:urlString];
        NSError *error = nil;
        NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [FCFileManager createFileAtPath:path withContent:data];
                EDHFinderItem *item = [[EDHFinderItem alloc] initWithPath:path];
                if (success) {
                    success(item);
                }
            } else {
                if (failure) {
                    failure(error);
                }
            }
        });
    });
}

- (void)renameTo:(NSString *)name success:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSString *path = [self pathWithRename:name];
    
    if ([self existsItemAtPath:path failure:failure]) {
        return;
    }
    
    NSError *error = nil;
    [FCFileManager renameItemAtPath:self.path withName:name error:&error];
    
    if (error) {
        if (failure) {
            failure(error);
        }
        return;
    }
    
    self.name = name;
    self.path = path;
    
    if (success) {
        success();
    }
}

- (void)moveTo:(EDHFinderItem *)toItem success:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSString *path = [toItem.path stringByAppendingPathComponent:self.name];
    
    NSLog(@"%@ -> %@", self.path, path);
    
    if ([self existsItemAtPath:path failure:failure]) {
        return;
    }
    
    NSError *error = nil;
    [FCFileManager moveItemAtPath:self.path toPath:path error:&error];
    
    if (error) {
        if (failure) {
            failure(error);
        }
        return;
    }
    
    self.path = path;
    if (success) {
        success();
    }
}

- (void)destroy:(void (^)())success failure:(void (^)(NSError *error))failure {
    NSError *error = nil;
    [FCFileManager removeItemAtPath:self.path error:&error];
    
    if (error) {
        if (failure) {
            failure(error);
        }
        return;
    }
    
    if (success) {
        success();
    }
}

- (void)duplicate:(void (^)(EDHFinderItem *newItem))success failure:(void (^)(NSError *error))failure {
    int i = 2;
    NSString *copyOfName = [NSString stringWithFormat:[EDHUtility localizedString:@"Copy of %@" withScope:EDHFinderPodName], self.name];
    NSString *newName = copyOfName;
    while ([FCFileManager existsItemAtPath: [self pathWithRename:newName]]) {
        newName = [NSString stringWithFormat:@"%@ %d", copyOfName, i];
        i++;
    }
    
    NSString *path = [self pathWithRename:newName];
    
    NSError *error = nil;
    [FCFileManager copyItemAtPath:self.path toPath:path error:&error];
    
    if (error) {
        if (failure) {
            failure(error);
        }
        return;
    }
    
    EDHFinderItem *item = [[EDHFinderItem alloc] initWithPath:path];
    if (success) {
        success(item);
    }
}

- (void)compressWithPassword:(NSString *)pwd success:(void (^)(EDHFinderItem *newItem))success failure:(void (^)(NSError *error))failure {
    NSString *newName = [NSString stringWithFormat:@"%@.zip", self.path];
    NSError *error = nil;
        
    //Folder compress
    if (self.isDirectory) {
        //[SSZipArchive createZipFileAtPath:newName withContentsOfDirectory:self.path];
        [SSZipArchive createZipFileAtPath:newName withContentsOfDirectory:self.path withPassword:pwd];
    } else if (self.isFile){//File compress
        NSArray *fileArray = @[self.path];
        //[SSZipArchive createZipFileAtPath:newName withFilesAtPaths:fileArray];
        [SSZipArchive createZipFileAtPath:newName withFilesAtPaths:fileArray withPassword:pwd];
    }
        
    if (error) {
        if (failure) {
            failure(error);
        }
        return;
    }
    
    EDHFinderItem *item = [[EDHFinderItem alloc] initWithPath:newName];
    if (success) {
        success(item);
    }
}

- (void)uncompressWithPassword:(NSString *)pwd success:(void (^)(EDHFinderItem *newItem))success failure:(void (^)(NSError *error))failure {
    
    NSString *newName = @"";
    NSString *filePath = [self.path stringByDeletingLastPathComponent];
    if ([self.path hasSuffix:@".zip"]) {
        NSString *fileName = [[self.path lastPathComponent] stringByDeletingPathExtension];
        newName = [NSString stringWithFormat:@"%@/_%@", filePath, fileName];
    } else {
        NSString *fileName = [self.path lastPathComponent];
        newName = [NSString stringWithFormat:@"%@/_%@", filePath, fileName];
    }
     
    //[SSZipArchive unzipFileAtPath:self.path toDestination:newName];
    [SSZipArchive unzipFileAtPath:self.path toDestination:newName
                  progressHandler:^(NSString * _Nonnull entry, unz_file_info zipInfo, long entryNumber, long total) {
        
    } completionHandler:^(NSString * _Nonnull path, BOOL succeeded, NSError * _Nullable error) {
        if (error) {
            if (failure) {
                failure(error);
            }
            return;
        }
        
        EDHFinderItem *item = [[EDHFinderItem alloc] initWithPath:newName];
        if (success) {
            success(item);
        }
    }];
}

- (NSURL *)fileURL {
    return self.isDirectory ? nil : [NSURL fileURLWithPath:self.path];
}

- (NSString *)content {
    return [FCFileManager readFileAtPath:self.path];
}

- (void)updateContent:(NSString *)content {
    if (self.isEditable) {
        [FCFileManager writeFileAtPath:self.path content:content];
    }
}

- (EDHFinderItem *)parent {
    NSString *path = self.path.stringByDeletingLastPathComponent;
    return [[EDHFinderItem alloc] initWithPath:path];
}

# pragma mark - Utilities

- (NSString *)pathWithRename:(NSString *)name {
    return [[self.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
}

- (void)createWithType:(EDHFinderItemCreateType)type name:(NSString *)name success:(void (^)(EDHFinderItem *item))success failure:(void (^)(NSError *error))failure {
    NSString *path = [self.path stringByAppendingPathComponent:name];
    
    if ([self existsItemAtPath:path failure:failure]) {
        return;
    }

    NSError *error = nil;
    switch (type) {
        case EDHFinderItemCreateTypeFile:
            [FCFileManager createFileAtPath:path error:&error];
            break;
        case EDHFinderItemCreateTypeDirectory:
            [FCFileManager createDirectoriesForPath:path error:&error];
            break;
        default:
            break;
    }
    
    if (error) {
        if (failure) {
            failure(error);
        }
        return;
    }
    
    EDHFinderItem *item = [[EDHFinderItem alloc] initWithPath:path];
    if (success) {
        success(item);
    }
}

- (BOOL)existsItemAtPath:(NSString *)path failure:(void (^)(NSError *error))failure {
    if ([FCFileManager existsItemAtPath:path]) {
        if (failure) {
            failure([EDHUtility errorWithDescription:[EDHUtility localizedString:@"Already exists." withScope:EDHFinderPodName]]);
        }
        return YES;
    }
    return NO;
}

- (NSString *)detectMimeType {
    NSString *ext = self.path.pathExtension;

    if ([ext isEqualToString:@"md"] || [ext isEqualToString:@"markdown"]) {
        return @"text/markdown";
    }
    
    CFStringRef extRef = CFBridgingRetain(ext);
    CFStringRef utiRef = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extRef, NULL);
    NSString *type = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(utiRef, kUTTagClassMIMEType));
    return type;
}

@end
