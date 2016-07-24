@import UIKit;

#pragma mark - GGRect Related
CG_INLINE CGRect CGRectFromCGSize( CGSize size ) {
    return CGRectMake( 0, 0, size.width, size.height );
};

CG_INLINE CGRect CGRectMakeWithCenterAndSize( CGPoint center, CGSize size ) {
    return CGRectMake( center.x - size.width * 0.5, center.y - size.height * 0.5, size.width, size.height );
};

CG_INLINE CGRect CGRectMakeWithOriginAndSize( CGPoint origin, CGSize size ) {
    return CGRectMake( origin.x, origin.y, size.width, size.height );
};

CG_INLINE CGPoint CGRectCenter( CGRect rect ) {
    return CGPointMake( CGRectGetMidX( rect ), CGRectGetMidY( rect ) );
};

CG_INLINE CGFloat DegreeToRadian( CGFloat degree ) {
    return (M_PI * (degree) / 180.0);
};

CG_INLINE CGFloat RadianToDegrees( CGFloat radian ) {
    return (radian*180.0)/(M_PI);
};

#define SCREEN_WIDTH CGRectGetWidth([UIScreen mainScreen].bounds);
#define SCREEN_HEIGHT CGRectGetHeight([UIScreen mainScreen].bounds);

#define isiPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

@interface UIView (PiAdditions)

@property (assign,nonatomic) float x;
@property (assign,nonatomic) float y;
@property (assign,nonatomic) float width;
@property (assign,nonatomic) float height;
@property (assign,nonatomic) float boundWidth;
@property (assign,nonatomic) float boundHeight;
@property (assign,nonatomic) float centerX;
@property (assign,nonatomic) float centerY;
@end
