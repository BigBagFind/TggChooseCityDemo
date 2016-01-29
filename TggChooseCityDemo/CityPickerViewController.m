//
//  CityPickerViewController.m
//  TggChooseCityDemo
//
//  Created by 吴玉铁 on 16/1/27.
//  Copyright © 2016年 铁哥. All rights reserved.
//

#import "CityPickerViewController.h"
#import "City.h"

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
    _vertion = 8.0;
    [self initData];
    [self configViews];
    
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
    _hotCity = [NSArray arrayWithObjects:@"北京",@"上海",@"广州",@"深圳",@"杭州",@"武汉",@"天津",@"南京", nil];
    
    //先写到本地
//    //获取应用沙盒的Douch
//    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
//    NSString* plist1 = [paths objectAtIndex:0];
//    //获取一个plist文件
//    NSString* filename = [plist1 stringByAppendingString:@"cityCode.plist"];
//    // [data writeToFile:filename atomically:YES];
//    NSLog(@"%@",filename);
//    NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
    //NSMutableArray *cityData = [NSMutableArray array];
    //[cityData addObject:dic];
   //[cityData writeToFile:filename atomically:YES];
    
    
}
- (void)configViews{
    //注册单元格
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:identifier];
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    //搜索框使用
    //需要先判断版本 8.0
    if (_vertion >= 8.0) {
        _searchHighCrtl = [[UISearchController alloc] initWithSearchResultsController: nil];
        _searchHighCrtl.searchResultsUpdater = self;
        _searchHighCrtl.dimsBackgroundDuringPresentation = NO;
        _searchHighCrtl.hidesNavigationBarDuringPresentation = YES;
        _searchHighCrtl.searchBar.placeholder = @"输入城市名或拼音";
        _searchHighCrtl.searchBar.delegate = self;
        [_searchHighCrtl.searchBar sizeToFit];
        _searchHighCrtl.searchBar.frame = CGRectMake(_searchHighCrtl.searchBar.frame.origin.x, _searchHighCrtl.searchBar.frame.origin.y, _searchHighCrtl.searchBar.frame.size.width, 44.0);
        self.tableView.tableHeaderView = _searchHighCrtl.searchBar;
        //添加noresult标签
        UILabel *noResult = [[UILabel alloc]init];
        noResult.frame = CGRectMake(0, 44 * 3 + 64, self.view.frame.size.width, 44);
        noResult.text = @"无结果";
        noResult.textColor = [UIColor lightGrayColor];
        noResult.textAlignment = NSTextAlignmentCenter;
        noResult.font = [UIFont systemFontOfSize:23];
        [_searchHighCrtl.view addSubview:noResult];
    }else{
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
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_vertion >= 8.0) {
        if (_searchHighCrtl.active) {
            return 1;
        }else{
           return _keys.count;
        }
    }else{
        if (tableView == self.tableView) {
            return _keys.count;
        }else{
            return 1;
        }
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    /*
        大判断 先对version进行
    */
    if (_vertion >= 8.0) {
        if (_searchHighCrtl.active) {
            return _filterData.count;
        }else{
            if (section < 3) {
                return 1;
            }
            NSString *key = [_keys objectAtIndex:section];
            NSArray *array = [_sectionData objectForKey:key];
            return array.count;
        }
    }else{
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
    }
    return 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView{
    if (_vertion >= 8.0) {
        if (_searchHighCrtl.active) {
            return 0;
        }else{
            return _indexKeys;
        }
    }else{
        if (tableView == self.tableView) {
            return _indexKeys;
        }
        else
            return 0;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index{
    if (_vertion >= 8.0) {
        if (_searchHighCrtl.active) {
            return 0;
        }else{
            [tableView
             scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]
             atScrollPosition:UITableViewScrollPositionTop animated:YES];
            [self showScaleTipWithTitle:_indexKeys[index]];
            return index;
        }
    }else{
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
   return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (_vertion >= 8.0) {
        if (_searchHighCrtl.active) {
            return nil;
        }else
            return _keys[section];
    }else{
        if (tableView == self.tableView) {
            return _keys[section];
        }else
            return nil;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_vertion >= 8.0) {
        if (_searchHighCrtl.active) {
            return 44.f;
        }else{
            if (indexPath.section < 2) {
                return 60.f;
            }
            else if (indexPath.section == 2)
                return 160.f;
            else
                return 44.f;
        }
    }else{
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
    }
    return 0;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    /*
     大判断 先对version进行
     */
   
    if (_vertion >= 8.0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        }
        if (_searchHighCrtl.active) {
            if (_filterData.count > 0) {
                for (UIView *view in cell.contentView.subviews) {
                    [view removeFromSuperview];
                }
                cell.textLabel.text = [[_filterData objectAtIndex:indexPath.row]cityName];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                UIView *bgView = [[UIView alloc]init];
                bgView.backgroundColor = [UIColor colorWithRed:248 / 255.0 green:248 / 255.0 blue:248 / 255.0 alpha:1.0];
                cell.selectedBackgroundView = bgView;
            }
        }else{
            [self configCell:cell IndexPath:indexPath];
            if (indexPath.section < 3) {
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }else{
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                UIView *bgView = [[UIView alloc]init];
                bgView.backgroundColor = [UIColor colorWithRed:248 / 255.0 green:248 / 255.0 blue:248 / 255.0 alpha:1.0];
                cell.selectedBackgroundView = bgView;
            }
        }
        return cell;
    }else{
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
    
    return nil;
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
            [btn setTitle:@"杭州市" forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            btn.layer.borderWidth = 0.5;
            [btn addTarget:self action:@selector(button1BackGroundHighlighted:) forControlEvents:UIControlEventTouchDown];
            [btn addTarget:self action:@selector(button1BackGroundNormal:) forControlEvents:UIControlEventTouchUpInside];
            btn.layer.borderWidth = 0.5;
            btn.layer.borderColor = [UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:230 / 255.0 alpha:1.0].CGColor;
            btn.layer.cornerRadius = 3;
            btn.backgroundColor = [UIColor colorWithRed:248 / 255.0 green:248 / 255.0 blue:248 / 255.0 alpha:1.0];
            [cell.contentView addSubview:btn];
        }
            break;
        case 1: // 最近城市
        {
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(spaceWidth, 10, 80, 40);
            [btn setTitle:@"杭州市" forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            btn.layer.borderWidth = 0.5;
            [btn addTarget:self action:@selector(button1BackGroundHighlighted:) forControlEvents:UIControlEventTouchDown];
            [btn addTarget:self action:@selector(button1BackGroundNormal:) forControlEvents:UIControlEventTouchUpInside];
            btn.layer.borderWidth = 0.5;
            btn.layer.borderColor = [UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:230 / 255.0 alpha:1.0].CGColor;
            btn.layer.cornerRadius = 3;
            btn.backgroundColor = [UIColor colorWithRed:248 / 255.0 green:248 / 255.0 blue:248 / 255.0 alpha:1.0];
            [cell.contentView addSubview:btn];
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
    [UIView animateWithDuration:0.8 animations:^{
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

#warning 缺点：8.0以上的版本未添加单独的resultController，搜索视图没有backgroundView，8.0改进请添加resultViewController



@end
