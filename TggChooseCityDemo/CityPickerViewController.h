//
//  CityPickerViewController.h
//  TggChooseCityDemo
//
//  Created by 吴玉铁 on 16/1/27.
//  Copyright © 2016年 铁哥. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface CityPickerViewController : UITableViewController<UISearchBarDelegate,UISearchResultsUpdating,UISearchDisplayDelegate,CLLocationManagerDelegate>

@end
