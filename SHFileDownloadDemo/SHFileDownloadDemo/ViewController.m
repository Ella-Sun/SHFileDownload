//
//  ViewController.m
//  SHFileDownloadDemo
//
//  Created by iOS_sun on 2017/5/15.
//  Copyright © 2017年 nil. All rights reserved.
//

#import "ViewController.h"

#import "DownloadFileTool.h"

static NSString *identifier = @"collection";
static NSInteger DefaultItemCount = 8;
static CGFloat ITEMWIDTH = 120.f;
static NSString *D_REMOTE_ADDRESS = @"https://raw.githubusercontent.com/Sun-Hong/SHDownload/master/SHDownload/attachImages/";

@interface ViewController ()<UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;

/**<  存放文件地址的数组  >**/
@property (nonatomic, strong) NSMutableArray *imageUrlAry;
/**<  标记点击位置  >**/
//@property (nonatomic, assign) NSInteger currentIndex;
/**<  下载进度  >**/
@property (nonatomic, strong) UILabel *progressLabel;

/**<  实现预览  >**/
@property (nonatomic, strong) UIDocumentInteractionController *documentController;

@end

@implementation ViewController


- (NSMutableArray *)imageUrlAry
{
    if (!_imageUrlAry) {
        
        _imageUrlAry = [NSMutableArray array];
        for (int i = 0; i < DefaultItemCount; i++) {
            [_imageUrlAry addObject:@"timg.jpeg"];
        }
        //[NSMutableArray arrayWithObjects:<#(const id  _Nonnull __unsafe_unretained *)#> count:<#(NSUInteger)#>];//返回包含前count个objects的数组
    }
    return _imageUrlAry;
}

- (UILabel *)progressLabel
{
    if (!_progressLabel) {
        
        CGFloat minY = ITEMWIDTH * DefaultItemCount * 0.5 + 50;
        CGRect labelFrame = CGRectMake(0, minY, self.view.bounds.size.width, 50);
        _progressLabel = [[UILabel alloc] initWithFrame:labelFrame];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.text = @"下载进度";
    }
    return _progressLabel;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        CGFloat viewWidth = self.view.bounds.size.width;
        CGFloat viewHeight = self.view.bounds.size.height;
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        // 设置最小行间距
        layout.minimumLineSpacing = 0;
        //设置Cell之间的最小间距
        layout.minimumInteritemSpacing = 0;
        //设置布局方向
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        
        CGFloat navHeight = 50.f;
        CGRect flame = CGRectMake(40, navHeight, viewWidth-80, viewHeight-navHeight);
        self.collectionView = [[UICollectionView alloc] initWithFrame:flame collectionViewLayout:layout];
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        //    self.collView.scrollEnabled = NO;
        self.collectionView.alwaysBounceVertical = YES;
        [self.view addSubview:self.collectionView];
        
        //注册
        [self.collectionView registerClass:[UICollectionViewCell class]
                forCellWithReuseIdentifier:identifier];
    }
    return _collectionView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //1.创建collectionview
    [self.view addSubview:self.collectionView];
    [self.view addSubview:self.progressLabel];
    
    //2.点击对应位置 下载图片
}

#pragma mark - collectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return DefaultItemCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    NSString *imageName = self.imageUrlAry[indexPath.row];
    
    UIImage *showImage = [UIImage imageNamed:imageName];
    
    NSURL *bundleImageUrl = [[DownloadFileTool getInstance] getLocalFilePathWithCreated:nil fileName:imageName];
    if (bundleImageUrl) {//下载 去沙盒找
        showImage = (UIImage *)[UIImage imageWithData:[NSData dataWithContentsOfURL:bundleImageUrl] scale:1.0];
    }
    
    cell.layer.contents = (__bridge id)showImage.CGImage;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 设置每个item的大小
    return CGSizeMake(ITEMWIDTH, ITEMWIDTH);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
//    self.currentIndex = indexPath.row;
    
    NSInteger index = indexPath.row + 1;
    
    NSString *imageName = [NSString stringWithFormat:@"%ld.png",index];
    NSString *remoteUrlStr = [D_REMOTE_ADDRESS stringByAppendingString:imageName];
    [self tapCollecitonViewWithDownloadUrl:remoteUrlStr complate:^(NSString *fileName) {
        ;
        self.imageUrlAry[indexPath.row] = fileName;
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }];
    
}

/**
 下载并展示
 "html_url": "https://github.com/octokit/octokit.rb/blob/master/README.md",
 "download_url": "https://raw.githubusercontent.com/octokit/octokit.rb/master/README.md",
 
 @param remoteUrl 图片地址
 */
- (void)tapCollecitonViewWithDownloadUrl:(NSString *)remoteUrl complate:(void(^)(NSString *fileName))complate
{
    NSArray *partsArray = [remoteUrl componentsSeparatedByString:@"/"];
    NSString *fileName = [partsArray lastObject];
    NSLog(@"远程地址：%@",remoteUrl);
    [[DownloadFileTool getInstance] downloadFileWithOption:nil withFileUrl:remoteUrl created:nil fileName:fileName downloadSuccess:^(NSURLSessionTask *operation, id responseObject) {
        NSLog(@"成功");
//        [self fileSuccessDownQuickLock:fileName];
        if (complate) {
            complate(fileName);
        }
    } downloadFailure:^(NSURLSessionTask *operation, NSError *error) {
        //        NSLog(@"失败");
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressLabel.text = [NSString stringWithFormat:@"网速太慢，换个稍微快点的呗~"];
        });
        
    } progress:^(float progress, long long downloadLength, long long totalLength) {
        //        NSLog(@"进度");
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressLabel.text = [NSString stringWithFormat:@"下载进度：%0.2f",progress];
        });
        
    }];
}

- (void)fileSuccessDownQuickLock:(NSString *)fileName
{
    NSURL *localFileUrl = [[DownloadFileTool getInstance] getLocalFilePathWithCreated:nil fileName:fileName];
    
    _documentController = [UIDocumentInteractionController interactionControllerWithURL:localFileUrl];
    _documentController.delegate = self;
    //实现预览
    [self.documentController presentOptionsMenuFromRect:self.view.bounds  inView:self.view animated:YES];
    
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller
{
    return self;
}


@end
