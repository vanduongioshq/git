#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "../Core/GameLogic.h"

typedef struct {
    CGPoint pos;                 // ✅ 2D screen position
    CGFloat width;
    CGFloat height;
    int curHP;                   // ✅ HP hiện tại
    int maxHP;                   // ✅ HP tối đa
    float distance;              // ✅ Khoảng cách
    __unsafe_unretained NSString *name; // ✅ Tên player
} ESPBox;

@interface ESP_View : UIView

- (instancetype)initWithFrame:(CGRect)frame;
- (void)setBoxes:(NSArray<NSValue *> *)boxes;
- (void)updateBoxes;
- (void)update_data;

@end