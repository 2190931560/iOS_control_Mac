//
//  FileViewController.m
//  ViralMouseClient
//
//  Created by dlleng on 2018/3/29.
//  Copyright © 2018年 leng. All rights reserved.
//

#import "FileViewController.h"
#import "defines.h"
#define ident @"cellid"
@interface FileViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>
@property(nonatomic,weak)UICollectionView* collectionView;
@property(nonatomic,strong)NSArray *array;
@end

@implementation FileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:imageView];
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.image = [UIImage imageNamed:@"bg_wood"];
    [self.view addSubview:imageView];
    
    self.array = [NSArray array];
    // Do any additional setup after loading the view.
    //创建一个layout布局类
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc]init];
    //设置布局方向为垂直流布局
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    //设置每个item的大小为100*100
    layout.itemSize = CGSizeMake(100, 120);
    //创建collectionView 通过一个布局策略layout来创建
    UICollectionView * collect = [[UICollectionView alloc]initWithFrame:self.view.frame collectionViewLayout:layout];
    collect.backgroundColor = [UIColor clearColor];
    //代理设置
    collect.delegate=self;
    collect.dataSource=self;
    //注册item类型 这里使用系统的类型
    [collect registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:ident];
    self.collectionView = collect;
    [self.view addSubview:collect];
    
    [self getRemoteFileInDirect:self.currentDirect];
}
-(void)getRemoteFileInDirect:(NSString*)direct
{
    __weak typeof(self) weakSelf = self;
    NSString *strUrl = [NSString stringWithFormat:@"http://%@:%d%@",self.diction[@"ip"],HTTP_PORT,direct];
    strUrl = [strUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:strUrl] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error){
            NSLog(@"(%@)error:%@",strUrl,error);
            return ;
        }
        NSError *err;
        NSArray *arr = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
        if(err){
            NSLog(@"NSJSONSerialization error:%@",error);
            return ;
        }
        weakSelf.array = arr;
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf.collectionView reloadData];
        });
    }] resume];
}

#pragma mark collectionView delegate
//返回分区个数
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
//返回每个分区的item个数
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.array.count;
}
//返回每个item
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell * cell  = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellid" forIndexPath:indexPath];
    NSDictionary *diction = self.array[indexPath.row];
    
    for(UIView *v in cell.contentView.subviews)[v removeFromSuperview];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.height-20)];
    NSData *imgData = [[NSData alloc] initWithBase64EncodedString:diction[@"icon"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
    imgView.image = [UIImage imageWithData:imgData];
    [cell.contentView addSubview:imgView];
    //NSLog(@"%f %f",imgView.image.size.width,imgView.image.size.height);
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, cell.contentView.frame.size.height-20, cell.contentView.frame.size.width, 20)];
    label.text = diction[@"name"];
    //label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.textColor = [UIColor whiteColor];
    [cell.contentView addSubview:label];
    
    return cell;
}
-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *diction = self.array[indexPath.row];
    BOOL isDirect = [diction[@"isdirect"] boolValue];
    if(isDirect){
        NSString *path = self.currentDirect;
        path = [path stringByAppendingPathComponent:diction[@"name"]];
        FileViewController *vc = [[FileViewController alloc] init];
        vc.diction = self.diction;
        vc.currentDirect = path;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else
    {
        UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.frame];
        NSString *strUrl = [self.currentDirect stringByAppendingPathComponent:diction[@"name"]];
        strUrl = [strUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        strUrl = [NSString stringWithFormat:@"http://%@:%d%@",self.diction[@"ip"],HTTP_PORT,strUrl];
        NSLog(@"%@",strUrl);
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
        [webView loadRequest:request];
        webView.scalesPageToFit = true;
        [self.view addSubview: webView];
    }
}
@end
