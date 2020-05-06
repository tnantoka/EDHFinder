//
//  EDHFinderItem.h
//  EDHFinder
//
//  Created by Tatsuya Tobioka on 10/1/14.
//  Copyright (c) 2014 tnantoka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EDHFinderItem : NSObject

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *mimeType;
@property (nonatomic) BOOL isFile;
@property (nonatomic) BOOL isDirectory;
@property (nonatomic) NSDate *modificationDate;
@property (nonatomic, copy) NSNumber *fileSize;
@property (nonatomic) int folderFileCount;

- (id)initWithPath:(NSString *)path;

- (NSString *)relativePath;
- (BOOL)isEditable;

- (NSMutableArray *)children;

- (void)createFileWithName:(NSString *)name success:(void (^)(EDHFinderItem *item))success failure:(void (^)(NSError *error))failure;
- (void)createDirectoryWithName:(NSString *)name success:(void (^)(EDHFinderItem *item))success failure:(void (^)(NSError *error))failure;
- (void)downloadWithURL:(NSString *)urlString success:(void (^)(EDHFinderItem *item))success failure:(void (^)(NSError *error))failure;

- (void)renameTo:(NSString *)name success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)moveTo:(EDHFinderItem *)toItem success:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)destroy:(void (^)())success failure:(void (^)(NSError *error))failure;
- (void)duplicate:(void (^)(EDHFinderItem *newItem))success failure:(void (^)(NSError *error))failure;
- (void)compress:(void (^)(EDHFinderItem *newItem))success failure:(void (^)(NSError *error))failure;
- (void)uncompress:(void (^)(EDHFinderItem *newItem))success failure:(void (^)(NSError *error))failure;

- (NSURL *)fileURL;
- (NSString *)content;
- (void)updateContent:(NSString *)content;

- (EDHFinderItem *)parent;

@end
