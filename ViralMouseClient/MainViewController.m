//
//  MainViewController.m
//  ViralMouseClient
//
//  Created by leng on 2018/3/28.
//  Copyright © 2018年 leng. All rights reserved.
//

#import "MainViewController.h"
#import "UDPUtil.h"
#import "TCPUtil.h"
#import "MouseViewController.h"
#import "FileViewController.h"
#import "CircleLayout.h"
#import "RadarLayer.h"

@interface MainViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>
@property(weak,nonatomic)UICollectionView *collectionView;
@property(strong,nonatomic)NSMutableArray *array;
@property(weak,nonatomic)RadarLayer *layer;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"搜索局域网设备";
    self.array = [NSMutableArray array];
    // Do any additional setup after loading the view.
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:imageView];
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.image = [UIImage imageNamed:@"bg_wood"];
    [self.view addSubview:imageView];
    
    //
    //collectionView
    CircleLayout * layout = [[CircleLayout alloc]init];
    UICollectionView * collect  = [[UICollectionView alloc]initWithFrame:self.view.frame collectionViewLayout:layout];
    collect.backgroundColor = [UIColor clearColor];
    collect.delegate=self;
    collect.dataSource=self;
    [collect registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cellid"];
    [self.view addSubview:collect];
    self.collectionView = collect;
    //创建按钮
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    //btn.backgroundColor = [UIColor greenColor];
    btn.frame = CGRectMake(0, 0, 80, 80);
    [btn setImage:[UIImage imageNamed:@"radar"] forState:UIControlStateNormal];
    btn.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height-100);
    [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    RadarLayer *layer = [[RadarLayer alloc] init];
    [imageView.layer addSublayer:layer];
    self.layer = layer;
    layer.frame = imageView.bounds;
    
    [self btnClick:nil];
}

-(void)btnClick:(UIButton*)button
{
    [self.array removeAllObjects];
    [self.collectionView reloadData];
    __weak typeof(self) weakSelf = self;
    [[UDPUtil share] broadcast:^(NSDictionary *diction) {
        [weakSelf.array addObject:diction];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [weakSelf.collectionView reloadData];
        });
    }];
    //layer 动画
    if(button)
        [self.layer tap:button.center];
    else
        [self.layer tap:CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height-100)];
}
#pragma mark -
#pragma mark collectionView dataSouce
-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.array.count;
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell * cell  = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellid" forIndexPath:indexPath];
//    cell.layer.masksToBounds = YES;
//    cell.layer.cornerRadius = 25;
    //cell.backgroundColor = [UIColor colorWithRed:arc4random()%255/255.0 green:arc4random()%255/255.0 blue:arc4random()%255/255.0 alpha:1];
    for (UIView *v in cell.contentView.subviews)[v removeFromSuperview];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.width)];
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    imgView.image = [UIImage imageNamed:@"mac"];
    [cell.contentView addSubview:imgView];
    
    NSDictionary *dic = self.array[indexPath.row];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0,cell.contentView.frame.size.height-40, cell.contentView.frame.size.width, 40)];
    label.numberOfLines = 2;
    label.adjustsFontSizeToFitWidth = true;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = dic[@"name"];
    [cell.contentView addSubview:label];
    
    [self shakeToShow:cell];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *dic = self.array[indexPath.row];
    
    [[TCPUtil share] connect:dic[@"ip"] port:TCP_PORT block:^(BOOL bsuccess) {
        if(bsuccess)
        {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"远程桌面" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    MouseViewController *vc = [[MouseViewController alloc] init];
                    vc.diction = self.array[indexPath.row];
                    [self.navigationController presentViewController:vc animated:YES completion:nil];
                });
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"文件管理" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    FileViewController *vc = [[FileViewController alloc] init];
                    vc.diction = self.array[indexPath.row];
                    vc.currentDirect = @"/";
                    [self.navigationController pushViewController:vc animated:YES];
                });
            }]];
            
                
            UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            popPresenter.sourceView = cell; // 这就是挂靠的对象
            popPresenter.sourceRect = cell.bounds;
            [self presentViewController:alert animated:YES completion:nil];
            
            
        }
        else
        {
            NSLog(@"连接失败");
        }
    }];
    
}

- (void) shakeToShow:(UIView*)aView
{
    
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.duration = 1.5;// 动画时间
    
    NSMutableArray *values = [NSMutableArray array];
    
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 1.0)]];
    
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9, 0.9, 1.0)]];
    
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 1.0)]];
    
    animation.values = values;
    animation.repeatCount = 99999;

    [aView.layer addAnimation:animation forKey:@"shake"];
    
}
@end
