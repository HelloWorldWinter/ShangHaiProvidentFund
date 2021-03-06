//
//  CDADLoopDisplayScrollView.h
//  CDADLoopDisplayScrollView
//
//  Created by cdd on 15/9/14.
//  Copyright (c) 2015年 cd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^CDImageClickBlock)(NSInteger index);

@interface CDADLoopDisplayScrollView : UIView

@property (nonatomic, copy) NSString *placeHolderImage;

/**
 *  广告位图片链接
 */
@property (nonatomic, copy) NSArray *arrImageLink;

/**
 *  自动滚动间隔时间,默认4s
 */
@property (nonatomic, assign) NSInteger autoScrollTimeInterval;

/**
 *  自动滚动，默认关闭
 */
@property (nonatomic, getter=isOpenAutoScroll) BOOL openAutoScroll;

/**
 *  图片点击回调
 */
@property (nonatomic, copy) CDImageClickBlock imageClickBlock;

/**
 *  是否显示PageControl,默认隐藏
 */
@property (nonatomic, getter=isShowPageControl) BOOL showPageControl;

/**
 *  pageControl的当前IndicatorTintColor,默认系统指定
 */
@property (nonatomic, strong) UIColor *pageCtrlSelectColor;

/**
 *  pageControl的非当前IndicatorTintColor，默认系统指定
 */
@property (nonatomic, strong) UIColor *pageCtrlNormalColor;

/**
 *  开始滚动
 */
- (void)startScroll;

@end
