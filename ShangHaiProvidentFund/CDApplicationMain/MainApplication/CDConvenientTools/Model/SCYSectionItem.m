//
//  SCYSectionItem.m
//  ProvidentFund
//
//  Created by cdd on 16/2/29.
//  Copyright © 2016年 9188. All rights reserved.
//

#import "SCYSectionItem.h"
#import "SCYRowItem.h"

@implementation SCYSectionItem

+ (NSDictionary *)mj_objectClassInArray{
    return @{
             @"sectionData" : @"SCYRowItem",
             };
}

@end
