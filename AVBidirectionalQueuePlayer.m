//
//  AVQueuePlayerPrevious.m
//  IntervalPlayer
//
//  Created by Daniel Giovannelli on 2/18/13.
//
//  2014/07/16  (JRTaal) Greatly simplified and cleaned up code, meanwhile fixed number of bugs.
//                       Renamed to more apt AVBidirectionalQueuePlayer

#import "AVBidirectionalQueuePlayer.h"

@implementation AVBidirectionalQueuePlayer {

    NSMutableArray * _itemsForPlayer;
}

-(NSMutableArray *)itemsForPlayer {
    return _itemsForPlayer;
}

-(void)setItemsForPlayer:(NSMutableArray *)itemsForPlayer {
    [self removeAllItems];
    _itemsForPlayer = itemsForPlayer;
    for (AVPlayerItem * item in itemsForPlayer) {
        [super insertItem:item afterItem:nil];
    }
}
// CONSTRUCTORS

-(id)initWithItems:(NSArray *)items
{
    // This function calls the constructor for AVQueuePlayer, then sets up the nowPlayingIndex to 0 and saves the array that the player was generated from as itemsForPlayer
    self = [super initWithItems:items];
    if (self){
        self.itemsForPlayer = [NSMutableArray arrayWithArray:items];
    }
    return self;
}

+ (AVBidirectionalQueuePlayer *)queuePlayerWithItems:(NSArray *)items
{
    // This function just allocates space for, creates, and returns an AVQueuePlayerPrevious from an array.
    // Honestly I think having it is a bit silly, but since its present in AVQueuePlayer it needs to be
    // overridden here to ensure compatability.
    AVBidirectionalQueuePlayer *playerToReturn = [[AVBidirectionalQueuePlayer alloc] initWithItems:items];
    return playerToReturn;
}

// NEW METHODS


-(void)playPreviousItem
{
    // This function is the meat of this library: it allows for going backwards in an AVQueuePlayer,
    // basically by clearing the player and repopulating it from the index of the last item played.
    // It should be noted that if the player is on its first item, this function will do nothing. It will
    // not restart the item or anything like that; if you want that functionality you can implement it
    // yourself fairly easily using the isAtBeginning method to test if the player is at its start.
    NSUInteger tempNowPlayingIndex = [_itemsForPlayer indexOfObject: self.currentItem];

    if (tempNowPlayingIndex>0){
        [self pause];
        // Note: it is necessary to have seekToTime called twice in this method, once before and once after re-making the area. If it is not present before, the player will resume from the same spot in the next item when the previous item finishes playing; if it is not present after, the previous item will be played from the same spot that the current item was on.
        [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        // The next two lines are necessary since RemoveAllItems resets both the nowPlayingIndex and _itemsForPlayer
        NSMutableArray *tempPlaylist = [[NSMutableArray alloc]initWithArray:_itemsForPlayer];
        [super removeAllItems];
        for (int i = tempNowPlayingIndex - 1; i < [tempPlaylist count]; i++) {
            [super insertItem:[tempPlaylist objectAtIndex:i] afterItem:nil];
        }
        // Not a typo; see above comment
        [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        [self play];
    }
}

-(Boolean)isAtBeginning
{
    // This function simply returns whether or not the AVQueuePlayerPrevious is at the first item. This is
    // useful for implementing custom behavior if the user tries to play a previous item at the start of
    // the queue (such as restarting the item).
    if ([self currentIndex] == 0){
        return YES;
    } else {
        return NO;
    }
}

-(NSUInteger)currentIndex
{
    // This method simply returns the now playing index
    return [_itemsForPlayer indexOfObject:self.currentItem];
}

// OVERRIDDEN AVQUEUEPLAYER METHODS

-(void)removeAllItems
{
    // This does the same thing as the normal AVQueuePlayer removeAllItems, but also sets the
    // nowPlayingIndex to 0.
    [super removeAllItems];
    [_itemsForPlayer removeAllObjects];
}

-(void)removeItem:(AVPlayerItem *)item
{
    // This method calls the superclass to remove the items from the AVQueuePlayer itself, then removes
    // any instance of the item from the itemsForPlayer array. This mimics the behavior of removeItem on
    // AVQueuePlayer, which removes all instances of the item in question from the queue.
    // It also subtracts 1 from the nowPlayingIndex for every time the item shows up in the itemsForPlayer
    // array before the current value.
    [super removeItem:item];
    [_itemsForPlayer removeObject:item];
}

-(void)insertItem:(AVPlayerItem *)item afterItem:(AVPlayerItem *)afterItem
{
    // This method calls the superclass to add the new item to the AVQueuePlayer, then adds that item to the
    // proper location in the itemsForPlayer array and increments the nowPlayingIndex if necessary.
    [super insertItem:item afterItem:afterItem];
    if ([_itemsForPlayer containsObject:afterItem]){ // AfterItem is non-nil
        if ([_itemsForPlayer indexOfObject:afterItem] < [_itemsForPlayer count] - 1){
            [_itemsForPlayer insertObject:item atIndex:[_itemsForPlayer indexOfObject:afterItem] + 1];
        } else {
            [_itemsForPlayer addObject:item];
        }
    } else { // afterItem is nil
        [_itemsForPlayer addObject:item];
    }
}

@end
