//
//  DownloadFileTool.m
//  SHDownload
//
//  Created by iOS_sun on 2017/4/26.
//  Copyright © 2017年 nil. All rights reserved.
//

#import "DownloadFileTool.h"
#import "AFNetworking.h"

#define LOCAL_SAVE_PATH @"sh"

@implementation DownloadFileTool

+ (instancetype)getInstance
{
    static DownloadFileTool *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DownloadFileTool alloc] init];
        manager.serializer = [AFHTTPRequestSerializer serializer];
    });
    return manager;
}

/**
 *  根据url判断是否已经保存到本地了
 *
 *  @param url 文件的url
 *
 *  @return YES：本地已经存在，NO：本地不存在
 */
- (BOOL)isSavedFileToLocalWithCreated:(NSString *)created fileName:(NSString *)fileName
{
    // 判断是否已经离线下载了
    NSString *localSavePath = [self setPathOfDocumentsByCreated:created fileName:fileName];
    localSavePath = [localSavePath stringByAppendingString:fileName];
    
    NSFileManager *filemanager = [NSFileManager defaultManager];
    
    if ([filemanager fileExistsAtPath:localSavePath]) {
        return YES;
    }
    return NO;
}

/**
 *  根据文件的类型 设置保存到本地的路径
 *
 *  @param created  创建时间
 *  @param fileName 名字
 *
 *  @return 本地地址
 */
-(NSString *)setPathOfDocumentsByCreated:(NSString *)created fileName:(NSString *)fileName
{
    // 获取cache目录路径
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) firstObject];
    
    NSString *path = [cachesDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/", LOCAL_SAVE_PATH]];
    path = [path stringByAppendingString:@"/"];
    
    NSFileManager *filemanager = [NSFileManager defaultManager];
    if (![filemanager fileExistsAtPath:path]) {
        [filemanager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

/**
 *  根据文件类型、名字、创建时间获得本地文件的路径，当文件不存在时，返回nil
 *
 *  @param fileName 文件名字
 *  @param created  文件在服务器创建的时间
 *
 *  @return 本地文件的路径
 */
- (NSURL *)getLocalFilePathWithCreated:(NSString *)created fileName:(NSString *)fileName
{
    NSString *localSavePath = [self setPathOfDocumentsByCreated:created fileName:fileName];
    
    NSFileManager *filemanager = [NSFileManager defaultManager];
    NSArray *fileList = [filemanager subpathsOfDirectoryAtPath:localSavePath error:nil];
    
    if ([fileList containsObject:fileName]) {
        NSString *fileUrltemp = [localSavePath stringByAppendingString:fileName];
        NSURL *url = [NSURL fileURLWithPath:fileUrltemp];
        return url;
    }
    return nil;
}

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
{
    //默认配置,硬盘存储
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    // 1. 创建会话管理者
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    BOOL isAlreadyExist = [self isSavedFileToLocalWithCreated:created fileName:fileName];
    if (isAlreadyExist) {//如果已经存在 取出展现
        
        //删除后重新下载
        [self cancleDownLoadFileWithCreated:created fileName:fileName];
    }
    
    // 2. 创建下载路径和请求对象
    NSURL *URL = [NSURL URLWithString:requestURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
//    NSMutableURLRequest *request = [_serializer requestWithMethod:@"POST" URLString:requestURL parameters:paramDic error:nil];
    
    // 3.创建下载任务
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        // 下载进度
        float progressPer = 1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount;
        NSLog(@"下载进度>>>>>>>>>>>>>>>%.2f\n",progressPer);
        if (progress) {
            progress(progressPer, downloadProgress.completedUnitCount, downloadProgress.totalUnitCount);
        }
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
//        NSLog(@"TargetPath downloaded to: %@\n",targetPath);
        
        NSString *cachesPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *customPath = [cachesPath stringByAppendingPathComponent:LOCAL_SAVE_PATH];
        customPath = [customPath stringByAppendingString:@"/"];
        NSString *path = [customPath stringByAppendingPathComponent:fileName];
        
//        NSLog(@"Path downloaded to: %@\n",path);
        
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        NSLog(@"File downloaded to: %@\n", [filePath path]);
        
        //下载完毕 将文件写入文件夹
        NSData *data = [NSData dataWithContentsOfURL:filePath];
        [data writeToURL:filePath atomically:YES];
        
        NSInteger statusCode = 0;
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if ([httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
            statusCode = httpResponse.statusCode;
        }
        if (statusCode == 200) {
            if (success) {
                success(_downLoadOperation, response);
            }
        } else if (failure){
            failure(_downLoadOperation, error);
        }
        
    }];
    self.downLoadOperation = downloadTask;
    
    // 4. 开启下载任务
    [downloadTask resume];
    
}

/**
 *  取消下载，并删除本地已经下载了的部分
 *
 *  @param created  文件在服务器创建的时间
 *  @param fileName 文件的名字
 */
- (void)cancleDownLoadFileWithCreated:(NSString *)created fileName:(NSString *)fileName
{
    [_downLoadOperation cancel];
    
    // 删除本地文件
    NSString *localSavePath = [self setPathOfDocumentsByCreated:created fileName:fileName];
    localSavePath = [localSavePath stringByAppendingString:fileName];
    
    NSFileManager *filemanager = [NSFileManager defaultManager];
    
    if ([filemanager fileExistsAtPath:localSavePath]) {
        [filemanager removeItemAtPath:localSavePath error:nil];
    }
}

// 正在下载中
- (BOOL)isDownLoadExecuting
{
    NSURLSessionTaskState state = _downLoadOperation.state;
    if (state == NSURLSessionTaskStateRunning) {
        return YES;
    }
    return NO;
}

// 下载暂停
- (void)downLoadPause
{
    [_downLoadOperation suspend];
}
// 下载继续
- (void)downLoadResume
{
    [_downLoadOperation resume];
}

/**
 放弃下载
 */
- (void)downloadDiscard
{
    [_downLoadOperation cancel];
}

@end
