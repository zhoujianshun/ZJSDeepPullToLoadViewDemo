//
//  ZJSHomeViewController.m
//  ZJSDeepPullToLoadViewDemo
//
//  Created by 周建顺 on 2019/5/21.
//  Copyright © 2019 周建顺. All rights reserved.
//

#import "ZJSHomeViewController.h"

#import <Masonry/Masonry.h>
#import <KVOController/KVOController.h>

#import <MJRefresh/MJRefresh.h>

#import "ViewController.h"

#define kIdentify @"kIdentify"

#define ASWeakSelf(type)  __weak typeof(type) weak##type = type;
#define ASStrongSelf(type)  __strong typeof(type) type = weak##type;

#define SCREEN_HEIGHT      [[UIScreen mainScreen] bounds].size.height
#define SCREEN_WIDTH       [[UIScreen mainScreen] bounds].size.width

#define ASKNavigation_StatusBarHeight          (44 + ([[UIApplication sharedApplication] statusBarFrame].size.height) )

#define AS_TOP_OUTSIDE_SPACE 54
#define AS_TOP_OUTSIDE_INVOKE_OFFSET (-130 - ASKNavigation_StatusBarHeight )



@interface ZJSHomeViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIView *topOutsideView;
@property (nonatomic, assign) BOOL startGotoNewVC;
@property (nonatomic, assign) CGPoint lastDraggingOffset;

@end

@implementation ZJSHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self commonInit];
    [self setupDeepPullGotoNext];
    
 
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}


-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    
    [self resetDeepPullGotoNext];
}



-(void)commonInit{
    
//    if (@available(iOS 11.0, *)) {
//        [self.tableView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentAutomatic];
//    }else{
//        self.automaticallyAdjustsScrollViewInsets = NO;
//    }
    
    self.title = @"home";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self.tableView addSubview:self.topOutsideView];
    
    self.topOutsideView.frame = CGRectMake(0, -SCREEN_HEIGHT - AS_TOP_OUTSIDE_SPACE, SCREEN_WIDTH, SCREEN_HEIGHT);
    [self.tableView bringSubviewToFront:self.tableView.mj_header];
}

#pragma mark - pull goto next

-(void)resetDeepPullGotoNext{
    
    if (self.startGotoNewVC) {
        self.startGotoNewVC = NO;
        
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        self.topOutsideView.frame = CGRectMake(0, -SCREEN_HEIGHT - AS_TOP_OUTSIDE_SPACE, SCREEN_WIDTH, SCREEN_HEIGHT);
        
        self.lastDraggingOffset = CGPointZero;
        self.tabBarController.tabBar.frame = CGRectOffset(self.tabBarController.tabBar.frame, 0, -CGRectGetHeight( self.tabBarController.tabBar.frame));
    }
}

-(void)setupDeepPullGotoNext{
    ASWeakSelf(self)
    [self.KVOController observe:self.tableView keyPath:@"contentOffset" options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        
        if (weakself.tableView.isDragging) {
            NSLog(@"offset isDragging:%@",@(weakself.tableView.contentOffset));
            weakself.lastDraggingOffset = weakself.tableView.contentOffset;
            if (weakself.tableView.contentOffset.y < AS_TOP_OUTSIDE_INVOKE_OFFSET) {
                weakself.tableView.mj_header.userInteractionEnabled = NO;
            }else{
                weakself.tableView.mj_header.userInteractionEnabled = YES;
            }
        }else{
            
            NSLog(@"offset:%@",@(weakself.tableView.contentOffset));
            if (weakself.lastDraggingOffset.y < AS_TOP_OUTSIDE_INVOKE_OFFSET) {
                [weakself gotoNewVC:weakself.lastDraggingOffset.y];
                
            }else{
                
            }
        }
        
        
    }];
}

-(void)gotoNewVC:(CGFloat)offset{
    
    if (self.startGotoNewVC) {
        return;
    }
    self.startGotoNewVC = YES;
    
    // 1.设置contentInsetcontentInset和contentOffset,防止手松开时tableView中的UI上移跳动
    UIEdgeInsets scrollViewOriginalInset = self.tableView.contentInset;
    //    self.scrollViewOriginalInset.top
    CGFloat top =  scrollViewOriginalInset.top + (-offset);
    // 增加滚动区域top
    self.tableView.contentInset = UIEdgeInsetsMake(top, 0, 0, 0);
    // 设置滚动位置
    CGPoint contentOffset = self.tableView.contentOffset;
    contentOffset  = CGPointMake(contentOffset.x, -top);
    [self.tableView setContentOffset:contentOffset animated:NO];
    
    // 开始动画
    // 动画分两部分执行
    // 1.hidden navigationBar & tabBar
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view);
        make.trailing.equalTo(self.view);
        make.height.equalTo(self.view);
        make.top.equalTo(self.view).offset(ASKNavigation_StatusBarHeight);
    }];
    
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        
        self.tabBarController.tabBar.frame = CGRectOffset(self.tabBarController.tabBar.frame, 0, CGRectGetHeight( self.tabBarController.tabBar.frame));
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        
        // 2. image slide down
        [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(self.view);
            make.trailing.equalTo(self.view);
            make.height.equalTo(self.view);
            make.top.equalTo(self.view.mas_bottom).offset(CGRectGetHeight(self.tabBarController.tabBar.frame)-top + AS_TOP_OUTSIDE_SPACE);
        }];
        
        [UIView animateWithDuration:1.f animations:^{

            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.tableView.contentInset = scrollViewOriginalInset;
            
            // push viewController
            ViewController *vc = [[ViewController alloc] init];
            [self.navigationController pushViewController:vc animated:NO];
        }];
        
    }];
    
}

#pragma mark -

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 10;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
   UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kIdentify forIndexPath:indexPath];
    
//    if (!cell) {
//        cell = [UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:<#(nullable NSString *)#>;
//    }
    cell.textLabel.text = @"text";
    return cell;
}


-(UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kIdentify];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.tableFooterView = [UIView new];
        
        ASWeakSelf(self)
        MJRefreshGifHeader *refreshHeader =  [MJRefreshGifHeader headerWithRefreshingBlock:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakself.tableView.mj_header endRefreshing];
            });
        }];
        refreshHeader.backgroundColor = [UIColor lightGrayColor];
        refreshHeader.lastUpdatedTimeLabel.hidden = YES;
        [refreshHeader setTitle:@"松开即可刷新" forState:MJRefreshStatePulling];
        [refreshHeader setTitle:@"正在刷新数据中.." forState:MJRefreshStateRefreshing];
        [refreshHeader setTitle:@"下拉可以刷新" forState:MJRefreshStateIdle];
        refreshHeader.gifView.image = [UIImage imageNamed:@"home_refresh_icon"];
        //  - (void)setTitle:(NSString *)title forState:(MJRefreshState)state;
        
        _tableView.mj_header = refreshHeader;
        _tableView.mj_header.automaticallyChangeAlpha = YES;
        _tableView.layer.masksToBounds = NO;
    }
    return _tableView;
}



-(UIView *)topOutsideView{
    if (!_topOutsideView) {
        _topOutsideView = [[UIView alloc] init];
        //        _topOutsideView.backgroundColor = [UIColor redColor];
        UIImageView *imageView = [[UIImageView alloc] init];
        [_topOutsideView addSubview:imageView];
        [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(imageView.superview);
        }];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.image = [UIImage imageNamed:@"1"];
        
        
        UIView *containerView = [[UIView alloc] init];
        [_topOutsideView addSubview:containerView];
        [containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(containerView.superview);
            make.bottom.equalTo(containerView.superview).offset(-12);
            make.height.equalTo(@12);
        }];
        
        UIImageView *icon = [[UIImageView alloc] init];
        icon.image = [UIImage imageNamed:@"home_pull_get_more"];
        [containerView addSubview:icon];
        [icon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(icon.superview);
            make.centerY.equalTo(icon.superview);
            make.height.equalTo(@12);
            make.width.equalTo(@12);
            
        }];
        
        UILabel *label = [[UILabel alloc] init];
        [containerView addSubview:label];
        label.text = @"继续下拉，探索更多商品";
        label.textColor = [UIColor blueColor];
        label.font = [UIFont systemFontOfSize:12.f];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.equalTo(icon.mas_trailing).offset(6);
            make.centerY.equalTo(label.superview);
            make.trailing.equalTo(label.superview);
        }];
        
    }
    return _topOutsideView;
}
@end
