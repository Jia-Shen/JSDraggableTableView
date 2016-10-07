//
//  JSDraggableTableView.h
//  Pods
//
//  Created by Chuck Shen on 2/29/16.
//
//

@protocol JSDraggleTableViewDelegate <NSObject>

/**
 *  check pressed cell is draggable
 *
 *  @param indexPath pressed indexpath
 *
 *  @return is draggable
 */
- (BOOL)cellCanDraggAtIndexPath:(NSIndexPath *)indexPath;

/**
 *
 *  exchange data and cells
 *
 *  @param sourceIndexPath
 *  @param targetIndexPath
 *
 *  @return YES exchange data, NO does not
 */
- (BOOL)exchangeDataFrom:(NSIndexPath *)sourceIndexPath to:(NSIndexPath *)targetIndexPath;

/**
 *  duplicate current dragged cell, need change data source, if did duplicate cell will reload data after this method
 *
 *  @param currentIndexPath
 *
 *  @return need duplicate dragged cell
 */
- (BOOL)needDuplicateIndexPath:(NSIndexPath *)currentIndexPath;

/**
 *  stop dragged cell to section
 *
 *  @return section number, NSNotFound means can drag in all sections
 */
- (NSInteger)cantDragIntoSection;

/**
 *  check section header long pressed need to respond or not
 *
 *  @return need respond or not
 */
- (BOOL)respondsToSectionHeaderLongPressed;

@optional

/**
 *  end drag action, can reorganize data in this method, will reload data after this method
 *
 */
- (void)dragDidEnd;

/**
 *  responds to section header long pressed event
 *
 *  @param section pressed section
 */
- (void)didLongPressSectionHeader:(NSInteger)section;

/**
 *  provide a customize draggable view
 *
 *  @param indexPath
 *
 *  @return draggable View
 */
- (UIView *)draggableViewAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface JSDraggableTableView : UITableView

@property (nonatomic, assign) BOOL draggable;
@property (nonatomic, weak) id<JSDraggleTableViewDelegate> draggableDelegate;

@end