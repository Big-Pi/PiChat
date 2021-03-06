//
//  MomentCell.h
//  PiChat
//
//  Created by pi on 16/3/20.
//  Copyright © 2016年 pi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommentsView.h"
#import "MomentPhotosView.h"
@class Moment;
@class NewMomentPhotoViewerController;
@class MomentCell;

@protocol MomentCellDelegate <NSObject>
-(void)momentEditMenuWillShowForCell:(MomentCell*)cell likeBtn:(UIButton*)likeBtn commentBtn:(UIButton*)commentBtn;
-(void)momentCellDidLikeBtnClick:(MomentCell*)cell;
-(void)momentCellDidCommentBtnClick:(MomentCell*)cell;

@end

@interface MomentCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastModifyTimeLabel;
@property (strong,nonatomic) CommentsView *commentsView;
@property (strong,nonatomic) MomentPhotosView *photosView;
@property(nonatomic,weak) IBOutlet id<MomentCellDelegate> delegate;
//
-(void)configWithMoment:(Moment*)moment collectionView:(UICollectionView*)collectionView;
-(CGSize)calcSizeWithMoment:(Moment*)moment collectionView:(UICollectionView*)collectionView;
//
-(void)forceDismissCommentMeun;
@end
