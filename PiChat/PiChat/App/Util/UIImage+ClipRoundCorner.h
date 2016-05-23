//
//  UIImage+ClipRoundCorner.h
//  PiChat
//
//  Created by pi on 16/4/26.
//  Copyright © 2016年 pi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ClipRoundCorner)
-(instancetype)clipRoundCornerWithRadius:(NSInteger)radius;

/**
 *  圆角裁剪
 *
 *  @param radius
 *  @param size
 *
 *  @return
 */
-(instancetype)clipRoundCornerWithRadius:(NSInteger)radius size:(CGSize)size;
@end
