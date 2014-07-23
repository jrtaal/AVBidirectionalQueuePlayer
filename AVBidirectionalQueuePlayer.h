//
//  AVQueuePlayerPrevious.h
//  IntervalPlayer
//
//  Created by Daniel Giovannelli on 2/18/13.
//  This class subclasses AVQueuePlayer to create a class with the same functionality as AVQueuePlayer
//  but with the added ability to go backwards in the queue - a function that is impossible in a normal 
//  AVQueuePlayer since items on the queue are destroyed when they are finished playing.
//
//  IMPORTANT NOTE: This version of AVQueuePlayer assumes that ARC IS ENABLED. If ARC is NOT enabled and you
//  use this library, you'll get memory leaks on the two fields that have been added to the class, int
//  nowPlayingIndex and NSArray itemsForPlayer. 
//
//  Note also that this classrequires that the AVFoundation framework be included in your project.
//
//  2014/07/16  (JRTaal) Greatly simplified and cleaned up code, meanwhile fixed number of bugs.
//                       Renamed to more apt AVBidirectionalQueuePlayer

#import <AVFoundation/AVFoundation.h>

#define AVPlayerItemDidAddItem @"com.bitnomica.AVBidirectionalQueuePlayer.DidAddItem"
#define AVPlayerItemDidRemoveItem @"com.bitnomica.AVBidirectionalQueuePlayer.DidRemoveItem"

@interface AVBidirectionalQueuePlayer : AVQueuePlayer


@property (nonatomic, strong) NSMutableArray *itemsForPlayer;

@property () NSUInteger currentIndex;
// Two methods need to be added to the AVQueuePlayer: one which will play the last item in the queue, and one which will return if the queue is at the beginning (in case the user wishes to implement special behavior when a queue is at its first item, such as restarting a item). A getIndex method to return the current index is also provided.

-(void)playPreviousItem;

-(BOOL)isAtBeginning;


-(CMTime) estimatedTotalDuration;

-(CMTime) currentTimeOffsetInQueue;
-(void) seekToTimeInQueue:(CMTime)time completionHandler:(void (^)(BOOL))completionHandler;

-(void)setCurrentIndex:(NSUInteger)currentIndex   completionHandler:(void (^)(BOOL)) completionHandler;

/* The following methods of AVQueuePlayer are overridden by AVQueuePlayerPrevious:
 – initWithItems: to keep track of the array used to create the player
 + queuePlayerWithItems: to keep track of the array used to create the player
 – advanceToNextItem to update the now playing index
 – insertItem:afterItem: to update the now playing index
 – removeAllItems to update the now playing index
 – removeItem:  to update the now playing index
 */


@end
