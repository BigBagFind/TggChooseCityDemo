//
//  CityPickerViewController.m
//  TggChooseCityDemo
//
//  Created by 吴玉铁 on 16/1/27.
//  Copyright © 2016年 铁哥. All rights reserved.
//

#warning 用前须知：👇👇👇👇👇
/*
    缺点：
    1） 8.0以上的版本未添加单独的resultController，效果为搜索视图没有backgroundView，8.0改进请添加resultViewController
    2） city列表为死数据，如需更新，参考ViewController中重新配置导入
    3） 最近访问城市如是登录用户的私有信息，则需存到服务器用户帐号下，不能直接存于本地
    注意事项：
    1）Cllocation需先配置plist（复制本工程(NSLocaito...)2条即可）
    2）最近访问城市纪录于NSUserDefault中，key为@"kTggUserDefalutRecentCity"
    3) 最近访问城市只处理了3个，即最多存3个最近访问的，新加的覆盖之前的
    4) city对应的code版本不同会出现略不同，尤其是港澳台
 
    github:https://github.com/BigBagFind/TggChooseCityDemo
    issues:https://github.com/BigBagFind/TggChooseCityDemo/issues
*/

#import "CityPickerViewController.h"
#import "City.h"
#define kTggUserDefalutRecentCity   @"kTggUserDefalutRecentCity"

static NSString *identifier = @"identifierKey";

@interface CityPickerViewController (){
    CGFloat _vertion;
    NSMutableArray *_keys;       //组key
    NSMutableArray *_indexKeys;  //索引key
    NSDictionary *_sectionData;  //总数据
    NSMutableArray *_filterData; //过滤数据
    NSMutableArray *_cityNames;  //过滤所需城市
    NSArray *_hotCity;           // 热门城市
    NSMutableArray *_recentCity; //最近访问城市
    NSString *_currentCity;      //当前定位city
    UISearchController *_searchHighCrtl;
    UISearchDisplayController *_searchLowCrtl;
    UILabel *_scaleTip;
    CLLocationManager *_locationManager;
}

@end

@implementation CityPickerViewController
- (IBAction)dismissVc:(id)sender {
    //必须马上消失
    _scaleTip.hidden = YES;
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //模拟版本判断,即此处设置版本
    _vertion = 7.0;
    [self initData];
    [self configViews];
    [self initLocation];
    self.title = @"PickCity";
}

- (void)initData{
    //城市plist
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"CityDic" ofType:@"plist"];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    //总字典
    _sectionData = [data objectForKey:@"totalCity"];
    //将key排序
    _keys = [NSMutableArray arrayWithArray:[[_sectionData allKeys] sortedArrayUsingSelector:@selector(compare:)]];
    _indexKeys = [NSMutableArray arrayWithArray:_keys];
    [_indexKeys insertObjects:@[@"定",@"近",@"热"] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
    [_keys insertObjects:@[@"定位城市",@"最近访问城市",@"热门城市"] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
    //过滤城市名和拼音
    NSString *plistPath1 = [[NSBundle mainBundle] pathForResource:@"CityFilter" ofType:@"plist"];
    NSMutableArray *filterData = [[NSMutableArray alloc] initWithContentsOfFile:plistPath1];
    _cityNames = [NSMutableArray array];
    for (NSDictionary *dic in filterData) {
        City *city = [[City alloc] init];
        city.cityName = [dic objectForKey:@"name"];
        city.cityLetter = [dic objectForKey:@"letter"];
        [_cityNames addObject:city];
    }
    //热门城市
    _hotCity = [NSArray arrayWithObjects:@"北京市",@"上海市",@"广州市",@"深圳市",@"杭州市",@"武汉市",@"天津市",@"南京市", nil];
    //最近访问城市,从本地读取
    _recentCity = [NSMutableArray array];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _recentCity = [NSMutableArray arrayWithArray:[userDefaults objectForKey:kTggUserDefalutRecentCity]];
}

- (void)configViews{
    //注册单元格
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:identifier];
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    //搜索框使用
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    searchBar.placeholder = @"输入城市名或拼音";
    self.tableView.tableHeaderView = searchBar;
    _searchLowCrtl = [[UISearchDisplayController alloc] initWithSearchBar:searchBar contentsController:self];
    searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    _searchLowCrtl.delegate = self;
    _searchLowCrtl.searchResultsDelegate = self;
    _searchLowCrtl.searchResultsDataSource = self;
    searchBar.delegate = self;
    
}

#pragma mark-配置locationManager
- (void)initLocation{
    //判断定位操作是否被允许
    if([CLLocationManager locationServicesEnabled]) {
        //1.创建CLLocationManage
        _locationManager = [[CLLocationManager alloc] init] ;
        //2.设置CLLocationManage实例委托和精度
        _locationManager.delegate = self;
        if (_vertion >= 8.0) {
            [_locationManager requestWhenInUseAuthorization];
        }
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        //3.设置距离筛选器distanceFilter，下面表示设备至少移动1000米，才通知delegate
        //_locationManager.distanceFilter = 1000.0f;
    }else {
        //提示用户无法进行定位操作
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"定位不成功 ,请确认开启定位" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:^{
            
        }];
    }
    //4.启动请求
    [_locationManager startUpdatingLocation];
    //5.停止请求
    //[_locationManager stopUpdatingLocation];
}

#pragma mark - UITableViewDatasource&Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableView) {
        NSString *key = [_keys objectAtIndex:indexPath.section];
        NSDictionary *dic = [[_sectionData objectForKey:key] objectAtIndex:indexPath.row];
        NSLog(@"name:%@ code:%@",dic[@"name"],dic[@"code"]);
    }else{
        NSString *cityName = [[_filterData objectAtIndex:indexPath.row] cityName];
        [self ergodicCityWith:cityName];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return _keys.count;
    }else{
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section < 3) {
            return 1;
        }
        NSString *key = [_keys objectAtIndex:section];
        NSArray *array = [_sectionData objectForKey:key];
        return array.count;
    }else {
        //7.0
        // c忽略大小写，d忽略重音 根据中文和拼音筛选
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cityName contains [cd] %@ OR cityLetter BEGINSWITH [cd] %@", _searchLowCrtl.searchBar.text,_searchLowCrtl.searchBar.text];
        _filterData = [[NSMutableArray alloc] initWithArray:[_cityNames filteredArrayUsingPredicate:predicate]];
        return _filterData.count;
    }

    return 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    if (tableView == self.tableView) {
        return _indexKeys;
    }
    else
        return 0;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    //点击索引，列表跳转到对应索引的行
    if (tableView == self.tableView) {
        
        [tableView
         scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]
         atScrollPosition:UITableViewScrollPositionTop animated:YES];
        [self showScaleTipWithTitle:_indexKeys[index]];
        return index;
        
    }else
       return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (tableView == self.tableView) {
        return _keys[section];
    }else
        return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.tableView) {
        if (indexPath.section < 2) {
            return 60.f;
        }
        else if (indexPath.section == 2)
            return 160.f;
        else
            return 44.f;
    }else{
        return 44.f;
    }
    return 0;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    if (tableView == self.tableView) {
        [self configCell:cell IndexPath:indexPath];
        if (indexPath.section < 3) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }else{
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            UIView *bgView = [[UIView alloc]init];
            bgView.backgroundColor = [UIColor colorWithRed:248 / 255.0 green:248 / 255.0 blue:248 / 255.0 alpha:1.0];
            cell.selectedBackgroundView = bgView;
        }
    }else{
        cell.textLabel.text = [[_filterData objectAtIndex:indexPath.row]cityName];
    }
    return cell;
}

#pragma mark-配置不同cell
- (void)configCell:(UITableViewCell *)cell IndexPath:(NSIndexPath *)indexPath
{
    CGFloat spaceWidth = (self.view.frame.size.width - 80 * 3 - 20) / 4;
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    cell.textLabel.text = nil;
    switch (indexPath.section) {
        case 0: // 定位城市
        {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(spaceWidth, 10, 80, 40);
            [btn setTitle:@"定位中..." forState:UIControlStateNormal];
            if (_currentCity && _currentCity.length > 0) {
                [btn setTitle:_currentCity forState:UIControlStateNormal];
            }
            [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            btn.layer.borderWidth = 0.5;
            [btn addTarget:self action:@selector(button1BackGroundHighlighted:) forControlEvents:UIControlEventTouchDown];
            [btn addTarget:self action:@selector(button1BackGroundNormal:) forControlEvents:UIControlEventTouchUpInside];
            btn.layer.borderWidth = 0.5;
            btn.layer.borderColor = [UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:230 / 255.0 alpha:1.0].CGColor;
            btn.layer.cornerRadius = 3;
            btn.backgroundColor = [UIColor colorWithRed:248 / 255.0 green:248 / 255.0 blue:248 / 255.0 alpha:1.0];
            btn.tag = 100;
            [cell.contentView addSubview:btn];
        }
            break;
        case 1: // 最近城市
        {
            for (NSInteger i = 0; i < _recentCity.count; i++) {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                btn.frame = CGRectMake(spaceWidth + (80 + spaceWidth ) * ( i % 3), 10 + (40 + 10 ) * ( i / 3), 80, 40);
                [btn setTitle:_recentCity[i] forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
                btn.layer.borderWidth = 0.5;
                btn.layer.borderColor = [UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:230 / 255.0 alpha:1.0].CGColor;
                btn.layer.cornerRadius = 3;
                [btn addTarget:self action:@selector(button1BackGroundHighlighted:) forControlEvents:UIControlEventTouchDown];
                [btn addTarget:self action:@selector(button1BackGroundNormal:) forControlEvents:UIControlEventTouchUpInside];
                [cell.contentView addSubview:btn];
                btn.backgroundColor = [UIColor colorWithRed:248 / 255.0 green:248 / 255.0 blue:248 / 255.0 alpha:1.0];
            }

        }
            break;
        case 2: // 热门城市
        {
            for (NSInteger i = 0; i < _hotCity.count; i++) {
                UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
                btn.frame = CGRectMake(spaceWidth + (80 + spaceWidth ) * ( i % 3), 10 + (40 + 10 ) * ( i / 3), 80, 40);
                [btn setTitle:_hotCity[i] forState:UIControlStateNormal];
                [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
                btn.layer.borderWidth = 0.5;
                btn.layer.borderColor = [UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:230 / 255.0 alpha:1.0].CGColor;
                btn.layer.cornerRadius = 3;
                [btn addTarget:self action:@selector(button1BackGroundHighlighted:) forControlEvents:UIControlEventTouchDown];
                [btn addTarget:self action:@selector(button1BackGroundNormal:) forControlEvents:UIControlEventTouchUpInside];
                [cell.contentView addSubview:btn];
                btn.backgroundColor = [UIColor colorWithRed:248 / 255.0 green:248 / 255.0 blue:248 / 255.0 alpha:1.0];
            }
        }
            break;
        default: // 城市列表
        {
            NSString *key = [_keys objectAtIndex:indexPath.section];
            cell.textLabel.text = [[[_sectionData objectForKey:key] objectAtIndex:indexPath.row]objectForKey:@"name"];
        }
            break;
    }
}

#pragma mark-按钮事件
//  button1普通状态下的背景色
- (void)button1BackGroundNormal:(UIButton *)sender{
    sender.backgroundColor = [UIColor colorWithRed:248 / 255.0 green:248 / 255.0 blue:248 / 255.0 alpha:1.0];
    //如果是第定位按钮，又是定位失败，点击即可充新定位
    if (sender.tag == 100) {
        if ([sender.titleLabel.text isEqualToString:@"重新定位"]) {
            [_locationManager startUpdatingLocation];
            return;
        }
    }
    //过滤的城市找出code
    [self ergodicCityWith:sender.titleLabel.text];
}

//  button1高亮状态下的背景色
- (void)button1BackGroundHighlighted:(UIButton *)sender{
    sender.backgroundColor = [UIColor colorWithRed:220 / 255.0 green:220 / 255.0 blue:220 / 255.0 alpha:1.0];
}

#pragma mark-放大视图
- (void)showScaleTipWithTitle:(NSString *)title{
    if (_scaleTip == nil) {
        CGFloat width = self.view.frame.size.width;
        CGFloat height = self.view.frame.size.height;
        _scaleTip = [[UILabel alloc]initWithFrame:CGRectMake((width - 80) / 2, (height - 80) / 2, 80, 80)];
    }
    [[UIApplication sharedApplication].keyWindow addSubview:_scaleTip];
    _scaleTip.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"light_blur"]];
    _scaleTip.text = title;
    _scaleTip.textColor = [UIColor lightGrayColor];
    _scaleTip.font = [UIFont fontWithName:@"ChalkboardSE-Bold" size:40];
    _scaleTip.textAlignment = NSTextAlignmentCenter;
    _scaleTip.layer.masksToBounds = YES;
    _scaleTip.layer.cornerRadius = 10;
    _scaleTip.alpha = 1.0;
    [UIView animateWithDuration:1.0 animations:^{
        _scaleTip.alpha = 0.0;
    }];
}

#pragma mark-updateSearchResultsDeleagte即8.0sarchBar刷新数据
- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = [searchController.searchBar text];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cityName contains [cd] %@ OR cityLetter BEGINSWITH [cd] %@", searchString,searchString];
    
    if (_filterData!= nil) {
        [_filterData removeAllObjects];
    }
    
    //过滤数据
    _filterData = [[NSMutableArray alloc] initWithArray:[_cityNames filteredArrayUsingPredicate:predicate]];
    //添加noresult提示
    if (searchString.length > 0) {
        if (_filterData.count == 0) {
            for (UIView *view in _searchHighCrtl.view.subviews) {
                if ([view isKindOfClass:[UILabel class]]) {
                    view.hidden = NO;
                }
            }
        }else{
            for (UIView *view in _searchHighCrtl.view.subviews) {
                if ([view isKindOfClass:[UILabel class]]) {
                    view.hidden = YES;
                }
            }
        }
    }else{
        for (UIView *view in _searchHighCrtl.view.subviews) {
            if ([view isKindOfClass:[UILabel class]]) {
                view.hidden = YES;
            }
        }
    }
    //刷新表格
    [self.tableView reloadData];
}


#pragma mark-searchBarDeleagte
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    //将cancel改为取消
    searchBar.showsCancelButton = YES;
    for(id cc in [searchBar.subviews[0] subviews])
    {
        if([cc isKindOfClass:[UIButton class]])
        {
            UIButton *btn = (UIButton *)cc;
            [btn setTitle:@"取消"  forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
    }
}

//8.0以下将noresult标签改为 无结果
- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString

{
    //去除 No Results 标签
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.001);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        
        for (UIView *subview in _searchLowCrtl.searchResultsTableView.subviews) {
            
            if ([subview isKindOfClass:[UILabel class]] && [[(UILabel *)subview text] isEqualToString:@"No Results"]) {
                
                UILabel *label = (UILabel *)subview;
                
                label.text = @"无结果";
                
                break;
            }
        }
    });
    return YES;
}


#pragma mark - CoreLocation Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    //此处locations存储了持续更新的位置坐标值，取最后一个值为最新位置，如果不想让其持续更新位置，则在此方法中获取到一个值之后让locationManager stopUpdatingLocation
    CLLocation *currentLocation = [locations lastObject];
    // 获取当前所在的城市名
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    //根据经纬度反向地理编译出地址信息
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *array, NSError *error){
         if (array.count > 0){
             CLPlacemark *placemark = [array objectAtIndex:0];
             //将获得的所有信息显示到label上
             NSLog(@"%@",placemark.name);
             //获取城市
             NSString *city = placemark.locality;
             if (!city){
                 //四大直辖市的城市信息无法通过locality获得，只能通过获取省份的方法来获得（如果city为空，则可知为直辖市）
                 city = placemark.administrativeArea;
                 
             }
             //或得最终当前城市
             _currentCity = city;
             //纪录城市到本地,如果重复即已存在，则不保存
             [self filterCityWithCity:city];
             //刷新 定位城市和最新访问城市的组
             [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationNone];
         }else if (error == nil && [array count] == 0){
             
             NSLog(@"No results were returned.");
             
         }else if (error != nil){
             
             NSLog(@"An error occurred = %@", error);
             
         }
         
     }];
    //系统会一直更新数据，直到选择停止更新，因为我们只需要获得一次经纬度即可，所以获取之后就停止更新
    [manager stopUpdatingLocation];
    
}

- (void)locationManager:(CLLocationManager *)manager
didFailWithError:(NSError *)error {
    if (error.code == kCLErrorDenied) {
        NSLog(@"%@",error);
        // 提示用户出错原因，可按住Option键点击 KCLErrorDenied的查看更多出错信息，可打印error.code值查找原因所在
        //提示用户无法进行定位操作
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"定位不成功,请进入设置仔细确认是否开启定位" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:action];
        [self presentViewController:alert animated:YES completion:^{
            
        }];
        //刷新定位城市组ui
        _currentCity = @"重新定位";
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
}

#pragma mark-过滤重复的city
- (void)filterCityWithCity:(NSString *)city{
    for (NSString *cityName in _recentCity) {
        if ([city isEqualToString:cityName]) {
            return;
        }
    }
    //如为新数据则添加进来
    [_recentCity addObject:city];
    
    //大于3个进行覆盖
    if (_recentCity.count > 3) {
        [_recentCity removeObjectAtIndex:0];
    }
    //同步本地数据
    [[NSUserDefaults standardUserDefaults]setObject:_recentCity forKey:kTggUserDefalutRecentCity];
    [[NSUserDefaults standardUserDefaults]synchronize];
}

#pragma mark-遍历城市找出Code
- (void)ergodicCityWith:(NSString *)cityName{
    
    //过滤的城市还需要code
    for (NSArray *array in [_sectionData allValues]) {
        for (NSDictionary *dic in array) {
            if ([dic[@"name"] isEqualToString:cityName]) {
                NSLog(@"name:%@ code:%@",cityName,dic[@"code"]);
                return;
            }
        }
    }
}


@end
