//
//  JSDraggableTableView.m
//  Pods
//
//  Created by Chuck Shen on 2/29/16.
//
//
#import "JSDraggableTableView.h"

@interface JSDraggableTableView ()

@property (nonatomic, strong) CADisplayLink *scrollDisplayLink;
@property (nonatomic, assign) CGFloat scrollRate;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;

@end

@implementation JSDraggableTableView

static UIView *snapshot;

- (void)scrollTableWithCell:(NSTimer *)timer
{
    CGPoint location  = [_longPressRecognizer locationInView:self];
    
    CGPoint currentOffset = self.contentOffset;
    CGPoint newOffset = CGPointMake(currentOffset.x, currentOffset.y + self.scrollRate * 10);
    
    if (newOffset.y < -self.contentInset.top) {
        newOffset.y = -self.contentInset.top;
    } else if (self.contentSize.height + self.contentInset.bottom < self.frame.size.height) {
        newOffset = currentOffset;
    } else if (newOffset.y > (self.contentSize.height + self.contentInset.bottom) - self.frame.size.height) {
        newOffset.y = (self.contentSize.height + self.contentInset.bottom) - self.frame.size.height;
    }
    
    [self setContentOffset:newOffset];
    
    if (location.y >= 0 && location.y <= self.contentSize.height + 50) {
        snapshot.center = CGPointMake(self.center.x, location.y);
    }
}

- (void)updateScrollRateWithLocation:(CGPoint)location
{
    CGRect rect = self.bounds;
    rect.size.height -= self.contentInset.top;
    
    CGFloat scrollZoneHeight = rect.size.height / 6;
    CGFloat bottomScrollBeginning = self.contentOffset.y + self.contentInset.top + rect.size.height - scrollZoneHeight;
    CGFloat topScrollBeginning = self.contentOffset.y + self.contentInset.top  + scrollZoneHeight;
    
    //下滑
    if (location.y >= bottomScrollBeginning) {
        self.scrollRate = (location.y - bottomScrollBeginning) / (2 * scrollZoneHeight);
    } else if (location.y <= topScrollBeginning) {
        //上滑
        self.scrollRate = (location.y - topScrollBeginning) / (2 * scrollZoneHeight);
    } else {
        self.scrollRate = 0;
    }
}

- (void)setDraggable:(BOOL)draggable {
    _draggable = draggable;
    if (_draggable) {
        self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
        [self addGestureRecognizer:self.longPressRecognizer];
    } else {
        if (self.longPressRecognizer) {
            [self removeGestureRecognizer:self.longPressRecognizer];
            self.longPressRecognizer = nil;
        }
    }
}

- (void)longPressGestureRecognized:(id)sender {
    
    UILongPressGestureRecognizer *longPress = (UILongPressGestureRecognizer *)sender;
    UIGestureRecognizerState state = longPress.state;
    
    CGPoint location = [longPress locationInView:self];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:location];
    
    ///< A snapshot of the row user is moving.
    static NSIndexPath  *sourceIndexPath = nil; ///< Initial index path, where gesture begins.
    
    switch (state) {
        case UIGestureRecognizerStateBegan: {
            if ([self.draggableDelegate respondsToSectionHeaderLongPressed]) {
                for (NSInteger i = 0; i < [self numberOfSections]; i++) {
                    CGRect headerRect = [self rectForHeaderInSection:i];
                    if (CGRectContainsPoint(headerRect, location)) {
                        if ([self.draggableDelegate respondsToSelector:@selector(didLongPressSectionHeader:)]) {
                            [self.draggableDelegate didLongPressSectionHeader:i];
                        }
                        return;
                    }
                }
            }
            if (indexPath) {
                if (![self.draggableDelegate cellCanDraggAtIndexPath:indexPath]) {
                    return;
                }
                sourceIndexPath = indexPath;
                UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
                // Take a snapshot of the selected row using helper method.
                UIView *prototypeView = cell;
                if ([self.draggableDelegate respondsToSelector:@selector(draggableViewAtIndexPath:)]) {
                    prototypeView = [self.draggableDelegate draggableViewAtIndexPath:indexPath];
                }
                snapshot = [self customSnapshoFromView:prototypeView];
                
                // Add the snapshot as subview, centered at cell's center...
                __block CGPoint center = cell.center;
                snapshot.center = center;
                snapshot.alpha = 0.0;
                [self addSubview:snapshot];
                [UIView animateWithDuration:0.25 animations:^{
                    
                    // Offset for gesture location.
                    center.y = location.y;
                    snapshot.center = center;
                    snapshot.transform = CGAffineTransformMakeScale(1.05, 1.05);
                    snapshot.alpha = 0.98;
                    cell.alpha = 0.0;
                    cell.hidden = YES;
                    
                }];
                self.scrollDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(scrollTableWithCell:)];
                [self.scrollDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
                if ([self.draggableDelegate needDuplicateIndexPath:indexPath]) {
                    [self reloadData];
                    UITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
                    cell.hidden = YES;
                }
            }
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            if (!snapshot) {
                return;
            }
            CGPoint center = snapshot.center;
            center.y = location.y;
            snapshot.center = center;
            
            [self updateScrollRateWithLocation:location];
            //      check section is able to dragged in
            NSInteger cantDragIntoSection = [self.draggableDelegate cantDragIntoSection];
            if (cantDragIntoSection != NSNotFound && cantDragIntoSection == indexPath.row) {
                return;
            }
            for (NSInteger i = 0; i < [self numberOfSections]; i++) {
                CGRect headerRect = [self rectForHeaderInSection:i];
                if (CGRectContainsPoint(headerRect, location)) {
                    NSInteger sourceSection = sourceIndexPath.section;
                    if (sourceIndexPath.section < i) {
                        sourceSection++;
                        indexPath = [NSIndexPath indexPathForRow:0 inSection:sourceSection];
                    } else if (sourceIndexPath.section > i) {
                        sourceSection--;
                        if (sourceSection < 0){
                            sourceSection = 0;
                        }
                        indexPath = [NSIndexPath indexPathForRow:0 inSection:sourceSection];
                    }
                    
                }
            }
            
            // Is destination valid and is it different from source?
            if (indexPath && ![indexPath isEqual:sourceIndexPath]) {
                
                if ([self.draggableDelegate exchangeDataFrom:sourceIndexPath to:indexPath]) {
                    // ... move the rows.
                    [self moveRowAtIndexPath:sourceIndexPath toIndexPath:indexPath];
                    // ... and update source so it is in sync with UI changes.
                    sourceIndexPath = indexPath;
                }
                
                
            }
            break;
        }
            
        default: {
            
            [self.scrollDisplayLink invalidate];
            self.scrollDisplayLink = nil;
            self.scrollRate = 0;
            
            // Clean up.
            UITableViewCell *cell = [self cellForRowAtIndexPath:sourceIndexPath];
            cell.alpha = 0.0;
            
            [UIView animateWithDuration:0.25 animations:^{
                
                snapshot.center = cell.center;
                snapshot.transform = CGAffineTransformIdentity;
                snapshot.alpha = 0.0;
                cell.alpha = 1.0;
                
            } completion:^(BOOL finished) {
                
                cell.hidden = NO;
                sourceIndexPath = nil;
                [snapshot removeFromSuperview];
                snapshot = nil;
                
            }];
            if ([self.draggableDelegate respondsToSelector:@selector(dragDidEnd)]) {
                [self.draggableDelegate dragDidEnd];
            }
            [self reloadData];
            break;
        }
    }
}

- (UIView *)customSnapshoFromView:(UIView *)inputView {
    
    UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, NO, 0);
    [inputView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIView *snapshot = [[UIImageView alloc] initWithImage:image];
    snapshot.layer.masksToBounds = NO;
    snapshot.layer.cornerRadius = 0.0;
    snapshot.layer.shadowOffset = CGSizeMake(-5.0, 0.0);
    snapshot.layer.shadowRadius = 5.0;
    snapshot.layer.shadowOpacity = 0.4;
    
    return snapshot;
    
}


@end