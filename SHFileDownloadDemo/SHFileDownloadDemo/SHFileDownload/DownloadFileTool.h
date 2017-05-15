//
//  DownloadFileTool.h
//  SHDownload
//
//  Created by iOS_sun on 2017/4/26.
//  Copyright © 2017年 nil. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AFHTTPRequestSerializer;
@interface DownloadFileTool : NSObject

@property (nonatomic, strong) AFHTTPRequestSerializer *serializer;
@property (nonatomic, strong) NSURLSessionDownloadTask *downLoadOperation;

+ (instancetype)getInstance;

#pragma mark -下载文件
/**
 *  根据url判断是否已经保存到本地了
 *
 *  @param created 文件的创建时间  通过和fileName拼接成完整的文件路径
 *
 *  @param fileName 文件的名字
 *
 *  @return YES：本地已经存在，NO：本地不存在
 */
- (BOOL)isSavedFileToLocalWithCreated:(NSString *)created fileName:(NSString *)fileName;

/**
 *  根据文件的创建时间 设置保存到本地的路径
 *
 *  @param created  创建时间
 *  @param fileName 名字
 *
 *  @return 本地路径
 */
-(NSString *)setPathOfDocumentsByCreated:(NSString *)created fileName:(NSString *)fileName;

/**
 *  根据文件类型、名字获得本地文件的路径，当文件不存在时，返回nil
 *
 *  @param fileName 文件名字
 *  @param created  文件在服务器创建的时间
 *
 *  @return 本地文件的路径
 */
- (NSURL *)getLocalFilePathWithCreated:(NSString *)created fileName:(NSString *)fileName;

/**
 *  @brief 下载文件
 *
 *  @param paramDic   额外的参数
 *  @param requestURL 下载的url
 *  @param created    创建时间
 *  @param fileName   文件名字
 *  @param success    成功回调函数
 *  @param failure    失败回调函数
 *  @param progress   进度block
 */
- (void)downloadFileWithOption:(NSDictionary *)paramDic
                   withFileUrl:(NSString*)requestURL
                      created:(NSString *)created
                      fileName:(NSString *)fileName
               downloadSuccess:(void (^)(NSURLSessionTask *operation, id responseObject))success
               downloadFailure:(void (^)(NSURLSessionTask *operation, NSError *error))failure
                      progress:(void (^)(float progress, long long downloadLength, long long totalLength))progress;

/**
 *  取消下载，并删除本地已经下载了的部分
 *
 *  @param created  文件在服务器创建的时间
 *  @param fileName 文件的名字
 */
- (void)cancleDownLoadFileWithCreated:(NSString *)created fileName:(NSString *)fileName;

/**
 *  正在下载中
 *
 *  @return 是否
 */
- (BOOL)isDownLoadExecuting;

/**
 *  下载暂停
 */
- (void)downLoadPause;

/**
 *  下载继续
 */
- (void)downLoadResume;

/**
 放弃下载
 */
- (void)downloadDiscard;

@end
