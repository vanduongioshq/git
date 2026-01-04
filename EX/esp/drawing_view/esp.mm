#import "esp.h"

#define sWidth  [UIScreen mainScreen].bounds.size.width
#define sHeight [UIScreen mainScreen].bounds.size.height

#pragma mark - ESP Container

@interface ESPContainer : NSObject
@property CALayer *boxLayer;
@property CALayer *hpBgLayer;
@property CALayer *hpLayer;
@property CATextLayer *nameLayer;
@property CAShapeLayer *lineLayer;
@end

@implementation ESPContainer
@end

#pragma mark - ESP View

@interface ESP_View ()
@property NSMutableArray<ESPContainer *> *containers;
@property NSArray<NSValue *> *boxesData;
@property CADisplayLink *displayLink;
@property CADisplayLink *displayLinkDATA;
@end

uint64_t Moudule_Base = -1;

@implementation ESP_View

#pragma mark - Init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.containers = [NSMutableArray array];

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Moudule_Base = (uint64_t)GetGameModule_Base((char*)"freefireth");
        });

        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateBoxes)];
        [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];

        self.displayLinkDATA = [CADisplayLink displayLinkWithTarget:self selector:@selector(update_data)];
        [self.displayLinkDATA addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.frame = self.superview.bounds;
}

#pragma mark - Set Boxes

- (void)setBoxes:(NSArray<NSValue *> *)boxes {
    _boxesData = [boxes copy];
}

#pragma mark - ESP DRAW

- (void)updateBoxes {
    if (!self.window) return;

    NSUInteger count = self.boxesData.count;

    if (count == 0) {
        for (ESPContainer *c in self.containers) {
            [c.boxLayer removeFromSuperlayer];
            [c.hpBgLayer removeFromSuperlayer];
            [c.hpLayer removeFromSuperlayer];
            [c.nameLayer removeFromSuperlayer];
            [c.lineLayer removeFromSuperlayer];
        }
        [self.containers removeAllObjects];
        return;
    }

    while (self.containers.count < count) {
        ESPContainer *c = [ESPContainer new];

        c.boxLayer = [CALayer layer];
        c.boxLayer.borderWidth = 2;
        c.boxLayer.borderColor = UIColor.redColor.CGColor;
        c.boxLayer.cornerRadius = 3;

        c.hpBgLayer = [CALayer layer];
        c.hpBgLayer.backgroundColor = UIColor.blackColor.CGColor;

        c.hpLayer = [CALayer layer];

        c.nameLayer = [CATextLayer layer];
        c.nameLayer.fontSize = 10;
        c.nameLayer.alignmentMode = kCAAlignmentCenter;
        c.nameLayer.foregroundColor = UIColor.whiteColor.CGColor;
        c.nameLayer.contentsScale = UIScreen.mainScreen.scale;

        c.lineLayer = [CAShapeLayer layer];
        c.lineLayer.strokeColor = UIColor.redColor.CGColor;
        c.lineLayer.lineWidth = 1;

        [self.layer addSublayer:c.lineLayer];
        [self.layer addSublayer:c.boxLayer];
        [self.layer addSublayer:c.hpBgLayer];
        [self.layer addSublayer:c.hpLayer];
        [self.layer addSublayer:c.nameLayer];

        [self.containers addObject:c];
    }

    for (int i = 0; i < self.containers.count; i++) {
        ESPContainer *c = self.containers[i];

        if (i >= count) {
            c.boxLayer.hidden = YES;
            c.hpBgLayer.hidden = YES;
            c.hpLayer.hidden = YES;
            c.nameLayer.hidden = YES;
            c.lineLayer.hidden = YES;
            continue;
        }

        ESPBox box;
        [self.boxesData[i] getValue:&box];

        CGFloat x = box.pos.x;
        CGFloat y = box.pos.y;
        CGFloat w = box.width;
        CGFloat h = box.height;

        c.boxLayer.hidden = NO;
        c.boxLayer.frame = CGRectMake(x, y, w, h);

        float hpPercent = (float)box.curHP / (float)box.maxHP;
        hpPercent = MAX(0, MIN(1, hpPercent));

        CGFloat hpH = h * hpPercent;
        c.hpBgLayer.frame = CGRectMake(x - 6, y, 4, h);
        c.hpLayer.frame = CGRectMake(x - 6, y + (h - hpH), 4, hpH);

        UIColor *hpColor =
        hpPercent > 0.6 ? UIColor.greenColor :
        hpPercent > 0.3 ? UIColor.yellowColor :
        UIColor.redColor;
        c.hpLayer.backgroundColor = hpColor.CGColor;

        c.nameLayer.hidden = NO;
        c.nameLayer.frame = CGRectMake(x - 20, y - 14, w + 40, 12);
        c.nameLayer.string =
        [NSString stringWithFormat:@"%@ [%.0fm]", box.name, box.distance];

        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(sWidth / 2, sHeight)];
        [path addLineToPoint:CGPointMake(x + w / 2, y + h)];
        c.lineLayer.path = path.CGPath;
    }
}

#pragma mark - GAME DATA

- (void)update_data {
    if (Moudule_Base == -1) return;

    NSMutableArray *boxes = [NSMutableArray array];

    uint64_t matchGame = getMatchGame(Moudule_Base);
    uint64_t camera = CameraMain(matchGame);
    if (!isVaildPtr(camera)) return;

    uint64_t match = getMatch(matchGame);
    if (!isVaildPtr(match)) return;

    uint64_t myPawn = getLocalPlayer(match);
    if (!isVaildPtr(myPawn)) return;

    uint64_t camTrans = ReadAddr<uint64_t>(myPawn + 0x2B0);
    Vector3 myPos = getPositionExt(camTrans);

    uint64_t playerList = ReadAddr<uint64_t>(match + 0xC8);
    uint64_t tValue = ReadAddr<uint64_t>(playerList + 0x28);
    int count = ReadAddr<int>(tValue + 0x18);

    float *matrix = GetViewMatrix(camera);

    for (int i = 0; i < count; i++) {
        uint64_t pawn = ReadAddr<uint64_t>(tValue + 0x20 + 8 * i);
        if (!isVaildPtr(pawn)) continue;
        if (isLocalTeamMate(myPawn, pawn)) continue;

        NSString *name = GetNickName(pawn);
        if (name.length == 0) continue;

        Vector3 head = getPositionExt(getHead(pawn));
        Vector3 toe  = getPositionExt(getRightToeNode(pawn));
        head.y += 0.2f;

        Vector3 sHead = WorldToScreen(head, matrix, sWidth, sHeight);
        Vector3 sToe  = WorldToScreen(toe, matrix, sWidth, sHeight);

        float dist = Vector3::Distance(myPos, head);
        if (dist > 220) continue;

        float h = fabs(sHead.y - sToe.y);
        float w = h * 0.5f;

        ESPBox box;
        box.pos = CGPointMake(sHead.x - w / 2, sHead.y);
        box.width = w;
        box.height = h;
        box.curHP = get_CurHP(pawn);
        box.maxHP = get_MaxHP(pawn);
        box.distance = dist;
        box.name = name;

        [boxes addObject:[NSValue valueWithBytes:&box objCType:@encode(ESPBox)]];
    }

    self.boxes = boxes;
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.displayLink invalidate];
    [self.displayLinkDATA invalidate];
}

@end