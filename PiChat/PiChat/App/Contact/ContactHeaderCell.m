//
//  ContactHeaderCell.m
//  PiChat
//
//  Created by pi on 16/3/17.
//  Copyright © 2016年 pi. All rights reserved.
//

#import "ContactHeaderCell.h"

NSString *const kContactHeaderCellID=@"ContactHeaderCell";

@implementation ContactHeaderCell
-(void)awakeFromNib{
    self.selectionStyle=UITableViewCellSelectionStyleNone;
}
@end
