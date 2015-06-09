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
    CMTime _estimatedDuration;
}

-(NSMutableArray *)itemsForPlayer {
    return _itemsForPlayer;
}

-(void)setItemsForPlayer:(NSMutableArray *)itemsForPlayer {
    [self removeAllItems];
    _itemsForPlayer = [itemsForPlayer mutableCopy];
    for (AVPlayerItem * item in itemsForPlayer) {
        [super insertItem:item afterItem:nil];
    }
    _estimatedDuration = kCMTimeInvalid;
}
// CONSTRUCTORS

-(id)initWithItems:(NSArray *)items
{
    // This function calls the constructor for AVQueuePlayer, then sets up the nowPlayingIndex to 0 and saves the array that the player was generated from as itemsForPlayer
    self = [super initWithItems:items];
    if (self){
        self.itemsForPlayer = [NSMutableArray arrayWithArray:items];
        _estimatedDuration = kCMTimeInvalid;
    }
    return self;
}

-(id)init {
    self = [super init];
    if (self) {
        self.itemsForPlayer = [NSMutableArray new];
        _estimatedDuration = kCMTimeZero;
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

    if (tempNowPlayingIndex>0 && tempNowPlayingIndex != NSNotFound){
            // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        float currentrate = self.rate;
        if (currentrate>0)
            [self pause];
            // Note: it is necessary to have seekToTime called twice in this method, once before and once after re-making the area. If it is not present before, the player will resume from the same spot in the next item when the previous item finishes playing; if it is not present after, the previous item will be played from the same spot that the current item was on.
        [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            // The next two lines are necessary since RemoveAllItems resets both the nowPlayingIndex and _itemsForPlayer
        NSArray *tempPlaylist = [[NSArray alloc]initWithArray:_itemsForPlayer];
        [super removeAllItems];

        NSInteger offset = 1;
        while (true) {
            AVPlayerItem * _it = [tempPlaylist objectAtIndex:tempNowPlayingIndex - offset] ;
            if (_it.error)
                offset++;
            break;
        }
        for (NSUInteger i = tempNowPlayingIndex - offset; i < [tempPlaylist count]; i++) {
            AVPlayerItem * item = [tempPlaylist objectAtIndex:i];
            NSLog(@"Inserting item %@ at %i of %i", item, i, [tempPlaylist count]);
            [super insertItem:item afterItem:nil];
        }
            // Not a typo; see above comment
        [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
        self.rate = currentrate;
            // });
    }
}


-(BOOL)isAtBeginning
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

-(void)setCurrentIndex:(NSUInteger)currentIndex {
    [self setCurrentIndex:currentIndex completionHandler:nil];
}
-(void)setCurrentIndex:(NSUInteger)newCurrentIndex   completionHandler:(void (^)(BOOL)) completionHandler {
    NSUInteger tempNowPlayingIndex = [_itemsForPlayer indexOfObject: self.currentItem];

    if (tempNowPlayingIndex != NSNotFound){
        [self pause];
            // Note: it is necessary to have seekToTime called twice in this method, once before and once after re-making the area. If it is not present before, the player will resume from the same spot in the next item when the previous item finishes playing; if it is not present after, the previous item will be played from the same spot that the current item was on.
        [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            // The next two lines are necessary since RemoveAllItems resets both the nowPlayingIndex and _itemsForPlayer
        NSArray *tempPlaylist = [[NSArray alloc]initWithArray:_itemsForPlayer];
        [super removeAllItems];
        for (NSUInteger i = newCurrentIndex; i < [tempPlaylist count]; i++) {
            [super insertItem:[tempPlaylist objectAtIndex:i] afterItem:nil];
        }
            // Not a typo; see above comment
        [self seekToTime:kCMTimeZero toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
    }

}
// OVERRIDDEN AVQUEUEPLAYER METHODS

-(void)removeAllItems
{
    // This does the same thing as the normal AVQueuePlayer removeAllItems, but also sets the
    // nowPlayingIndex to 0.
    [super removeAllItems];
    _estimatedDuration = kCMTimeZero;
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
    if (CMTIME_IS_VALID(item.duration))
        _estimatedDuration = CMTimeSubtract(_estimatedDuration, item.duration);
    [_itemsForPlayer removeObject:item];
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerItemDidRemoveItem object:self  userInfo:@{@"item":item}];

}

-(void)insertItem:(AVPlayerItem *)item afterItem:(AVPlayerItem *)afterItem
{
    // This method calls the superclass to add the new item to the AVQueuePlayer, then adds that item to the
    // proper location in the itemsForPlayer array and increments the nowPlayingIndex if necessary.
    [super insertItem:item afterItem:afterItem];
    if (CMTIME_IS_NUMERIC(item.duration)) {
        NSLog(@"duration: %5.2f", (double) CMTimeGetSeconds(item.duration));
        if (CMTimeCompare(_estimatedDuration, kCMTimeZero) == 0)
            _estimatedDuration = item.duration;
        else
            _estimatedDuration = CMTimeAdd(_estimatedDuration, item.duration);
    }
    if ([_itemsForPlayer containsObject:afterItem]){ // AfterItem is non-nil
        if ([_itemsForPlayer indexOfObject:afterItem] < [_itemsForPlayer count] - 1){
            [_itemsForPlayer insertObject:item atIndex:[_itemsForPlayer indexOfObject:afterItem] + 1];
        } else {
            [_itemsForPlayer addObject:item];
        }
    } else { // afterItem is nil
        [_itemsForPlayer addObject:item];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:AVPlayerItemDidAddItem object:self userInfo:@{@"item":item}];
}

-(CMTime)estimatedTotalDuration {
    if (!CMTIME_IS_VALID(self->_estimatedDuration)) {
            //NSTimeInterval dur  = 0.0;
        CMTime duration = kCMTimeZero;
        for (AVPlayerItem * item in _itemsForPlayer) {
            if (CMTIME_IS_VALID(item.duration))
                duration = CMTimeAdd(duration, item.duration);
        }
        self->_estimatedDuration = duration;
    }
    return self->_estimatedDuration;
}

-(CMTime)currentTimeOffsetInQueue {
    CMTime timeOffset = kCMTimeZero;
    NSUInteger currentIndex = self.currentIndex;
    if (currentIndex == NSNotFound)
        return kCMTimeInvalid;
    AVPlayerItem * item = nil;
    NSInteger idx;
    for (idx = 0; idx < (NSInteger) currentIndex;idx++) {
        item = _itemsForPlayer[idx];
        timeOffset = CMTimeAdd(timeOffset, item.duration);
    };
    if (_itemsForPlayer.count > idx) {
        item = _itemsForPlayer[idx];
        timeOffset = CMTimeAdd(timeOffset, item.currentTime);
    }
    return timeOffset;
}

-(void)seekToTimeInQueue:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler {
    CMTime marker = kCMTimeZero;
    AVPlayerItem * item ;
    NSUInteger idx=0;
    for (item in _itemsForPlayer) {
        if (CMTIME_COMPARE_INLINE(CMTimeAdd(marker, item.duration), >=, time))
            break;
        marker = CMTimeAdd(marker, item.duration);
        idx++;
    };
    if (item) {
        CMTime offset = CMTimeSubtract(time,marker);
        [item seekToTime:offset completionHandler:nil];
        [self setCurrentIndex:idx completionHandler:completionHandler];
    }
}
@end
