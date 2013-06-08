//
//  BTCommentBadge.m
//  Stetho
//
//  Created by Rich Henderson on 3/26/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import "BTCommentBadge.h"

@implementation BTCommentBadge

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* fillColor = [UIColor colorWithRed: 1 green: 1 blue: 1 alpha: 1];
    UIColor* strokeColor = [UIColor colorWithRed: 0.667f green: 0.667f blue: 0.667f alpha: 1];
    UIColor* strokeColor2 = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];
    
    //// Shadow Declarations
    UIColor* shadow = strokeColor2;
    CGSize shadowOffset = CGSizeMake(0.1f, -0.1f);
    CGFloat shadowBlurRadius = 2.5;
    
    //// Bezier 2 Drawing
    UIBezierPath* bezier2Path = [UIBezierPath bezierPath];
    [bezier2Path moveToPoint: CGPointMake(22.5, 5.29f)];
    [bezier2Path addLineToPoint: CGPointMake(22.5, 10.03f)];
    [bezier2Path addCurveToPoint: CGPointMake(18.5, 13.82f) controlPoint1: CGPointMake(22.5, 12.12f) controlPoint2: CGPointMake(20.71f, 13.82f)];
    [bezier2Path addLineToPoint: CGPointMake(11.93f, 13.82f)];
    [bezier2Path addLineToPoint: CGPointMake(8.5, 19.5)];
    [bezier2Path addLineToPoint: CGPointMake(8.5, 13.82f)];
    [bezier2Path addLineToPoint: CGPointMake(5.5, 13.82f)];
    [bezier2Path addCurveToPoint: CGPointMake(1.5, 10.03f) controlPoint1: CGPointMake(3.29f, 13.82f) controlPoint2: CGPointMake(1.5, 12.12f)];
    [bezier2Path addLineToPoint: CGPointMake(1.5, 5.29f)];
    [bezier2Path addCurveToPoint: CGPointMake(5.5, 1.5) controlPoint1: CGPointMake(1.5, 3.2f) controlPoint2: CGPointMake(3.29f, 1.5)];
    [bezier2Path addLineToPoint: CGPointMake(18.5, 1.5)];
    [bezier2Path addCurveToPoint: CGPointMake(22.5, 5.29f) controlPoint1: CGPointMake(20.71f, 1.5) controlPoint2: CGPointMake(22.5, 3.2f)];
    [bezier2Path closePath];
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
    [strokeColor setFill];
    [bezier2Path fill];
    CGContextRestoreGState(context);
    
    [strokeColor setStroke];
    bezier2Path.lineWidth = 1;
    [bezier2Path stroke];
    
    
    //// Oval Drawing
    UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(4, 6, 4, 4)];
    [fillColor setFill];
    [ovalPath fill];
    
    
    //// Oval 2 Drawing
    UIBezierPath* oval2Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(10, 6, 4, 4)];
    [fillColor setFill];
    [oval2Path fill];
    
    
    //// Oval 3 Drawing
    UIBezierPath* oval3Path = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(16, 6, 4, 4)];
    [fillColor setFill];
    [oval3Path fill];
}


@end
