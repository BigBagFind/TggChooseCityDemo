//
//  ViewController.m
//  TggChooseCityDemo
//
//  Created by 吴玉铁 on 16/1/27.
//  Copyright © 2016年 铁哥. All rights reserved.
//

#import "ViewController.h"
#import "CityPickerViewController.h"
@interface ViewController ()

@end

@implementation ViewController

//- (IBAction)pick:(id)sender {
//    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:[[CityPickerViewController alloc]init]];
//    
//    [self presentViewController:nav animated:YES completion:^{
//        
//    }];
//   
//}

- (void)viewDidLoad {
    [super viewDidLoad];


    //NSString *lastStr = [NSString stringWithFormat:@"%.1lf",[result[@"data"] doubleValue]];
    //NSLog(@"%@",lastStr);
    //[self changePinyin];
    //[self sortData];
    
//    //读取plist
//    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"CityList" ofType:@"plist"];
//    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
//    //打印出字典里的数据
//    NSLog(@"%@", data);
//    [data setObject:@"add some content" forKey:@"c_key"];
//    //获取应用沙盒的Douch
//    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
//    NSString* plist1 = [paths objectAtIndex:0];
//    //获取一个plist文件
//    NSString* filename = [plist1 stringByAppendingString:@"test.plist"];
//    [data writeToFile:filename atomically:YES];
//    NSMutableDictionary* data1 = [[NSMutableDictionary alloc]initWithContentsOfFile:filename];
//    //打印出字典里的数据
//    NSLog(@"%@",data1);
//    NSLog(@"%@",filename);
//    //修改一个plist文件的数据
//    [data1 setObject:@"要修改的数值 "forKey:@"name"];
//    [data1 writeToFile:filename atomically:YES];
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"file" ofType:@"xml"];
    
}

- (void)alterPlist{
    //先把plist写进来 然后加一个字段
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"CityDic" ofType:@"plist"];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    
    
    //获取应用沙盒的Douch
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString* plist1 = [paths objectAtIndex:0];
    //获取一个plist文件
    NSString* filename = [plist1 stringByAppendingString:@"cityCode.plist"];
    // [data writeToFile:filename atomically:YES];
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
   

    //总字典
    NSMutableDictionary *sectionData = [data objectForKey:@"totalCity"];
    NSMutableArray *pinyins = [NSMutableArray array];
    for (NSArray *array in [sectionData allValues]) {
        for (NSDictionary *dic in array) {
            // 转换为拼音
            NSMutableString *ms = [[NSMutableString alloc] initWithString:[dic objectForKey:@"name"]];
            if (CFStringTransform((__bridge CFMutableStringRef)ms, 0, kCFStringTransformMandarinLatin, NO)) {
            }
            if (CFStringTransform((__bridge CFMutableStringRef)ms, 0, kCFStringTransformStripDiacritics, NO)) {
                for (NSInteger i = 0; i < ms.length; i ++) {
                    NSString *subStr = [ms substringWithRange:NSMakeRange(i, 1)];
                    if ([subStr isEqualToString:@" "]) {
                        [ms deleteCharactersInRange:NSMakeRange(i, 1)];
                    }
                }
                
                //NSLog(@"%@",city.cityLetter);
            }
            //[pinyins addObject:city];
        }
    }
//    [data1 setObject:codeArray forKey:@"code"];
//    [data1 setObject:citys forKey:@"city"];
//    [data1 setObject:dataDic forKey:@"totalCity"];
//    [data1 writeToFile:filename atomically:YES];

}

- (void)sortData{
    //读取plist
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"ProvinceList" ofType:@"plist"];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    //打印出字典里的数据
    //NSLog(@"%@", data);
    NSMutableArray *citys = [NSMutableArray array];
    NSMutableArray *pinyins = [NSMutableArray array];
    for (NSDictionary *dic in [data objectForKey:@"area"]) {
        for (NSDictionary *cityDic in [dic objectForKey:@"citys"]) {
            //转换成拼音
            NSMutableString *ms = [[NSMutableString alloc] initWithString:cityDic[@"name"]];
            if (CFStringTransform((__bridge CFMutableStringRef)ms, 0, kCFStringTransformMandarinLatin, NO)) {
                NSLog(@"pinyin: %@", ms);
            }
//            if (CFStringTransform((__bridge CFMutableStringRef)ms, 0, kCFStringTransformStripDiacritics, NO)) {
//                NSLog(@"pinyin: %@", ms);
//            }
            [pinyins addObject:ms];
            NSDictionary *newDic = @{@"code":cityDic[@"code"],
                                     @"name":cityDic[@"name"],
                                     @"pinyin":ms};
            NSLog(@"%@:\n",newDic);
            [citys addObject:newDic];
        }
    }
    
    NSMutableArray *lastPinyins = [NSMutableArray arrayWithArray:[pinyins sortedArrayUsingSelector:@selector(compare:)]];
    NSLog(@"last:\n%@",lastPinyins);
    NSMutableArray *codeArray = [NSMutableArray array];
    NSMutableArray *nameArray = [NSMutableArray array];
    for (NSString *string in lastPinyins) {
        NSInteger index = 0;
        for (NSDictionary *dic in citys) {
            if ([string isEqualToString:dic[@"pinyin"]]){
                [codeArray addObject:dic[@"code"]];
                [nameArray addObject:dic[@"name"]];
                index++;
            }
        }
        if (index > 1) {
            NSLog(@"拼音是：%@，一共有%ld个",string,index);
        }
    }
    
    //获取应用沙盒的Douch
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString* plist1 = [paths objectAtIndex:0];
    //获取一个plist文件
    NSString* filename = [plist1 stringByAppendingString:@"cityCode.plist"];
   // [data writeToFile:filename atomically:YES];
    NSMutableDictionary* data1 = [[NSMutableDictionary alloc]initWithContentsOfFile:filename];
    NSMutableDictionary *dataDic = [NSMutableDictionary dictionary];
    char c ='a';
    for (int i = 0; i<26; i++) {
        NSLog(@"%c",c);
        
        NSString *key = [NSString stringWithFormat:@"%c",c];
        NSMutableArray *array = [NSMutableArray array];
        for (NSString *string in lastPinyins) {
            NSMutableDictionary *tempDic = [NSMutableDictionary dictionary];
            if (CFStringTransform((__bridge CFMutableStringRef)string, 0, kCFStringTransformStripDiacritics, NO)) {
                
                NSLog(@"pinyin: %@", string);
            }
            if ([[string substringToIndex:1] isEqualToString:key]) {
                for (NSDictionary *dic in citys) {
                    if ([dic[@"pinyin"] isEqualToString:string]) {
                        [tempDic setObject:dic[@"code"] forKey:@"code"];
                        [tempDic setObject:dic[@"name"] forKey:@"name"];
                        
                        [array addObject:tempDic];
                    }
                }
            }
        }
        if (array.count > 0) {
           [dataDic setObject:array forKey:[NSString stringWithFormat:@"%c",c-32]];
        }
        c++;
    }
    [data1 setObject:codeArray forKey:@"code"];
    [data1 setObject:citys forKey:@"city"];
    [data1 setObject:dataDic forKey:@"totalCity"];
    [data1 writeToFile:filename atomically:YES];

   // NSLog(@"%@,%@",codeArray,nameArray);


//    //打印出字典里的数据
//    NSLog(@"%@",data1);
    NSLog(@"%@",filename);
    //修改一个plist文件的数据


   
    
}

- (void)changePinyin{
    NSString *hanziText = @"我是中国人";
    if ([hanziText length]) {
        //带音标 很重要
        NSMutableString *ms = [[NSMutableString alloc] initWithString:hanziText];
        if (CFStringTransform((__bridge CFMutableStringRef)ms, 0, kCFStringTransformMandarinLatin, NO)) {
            NSLog(@"pinyin: %@", ms);
        }
        //不带音标
        if (CFStringTransform((__bridge CFMutableStringRef)ms, 0, kCFStringTransformStripDiacritics, NO)) {
            NSLog(@"pinyin: %@", ms);
        }  
    }
}


@end
