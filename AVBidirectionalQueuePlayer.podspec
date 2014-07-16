Pod::Spec.new do |spec|
  spec.name         = 'AVBidirectionalQueuePlayer'
  spec.version      = '1.0'
  spec.license      = { :type => 'BSD' }
  spec.homepage     = 'http://github.com/jrtaal/AVQueuePlayerPrevious'
  spec.authors      = { 'Daniel Giovannelli' => 'dangiovannelli@gmail.com',
  		      	'Jacco Taal' => 'jacco.taal@gmail.com' }
  spec.summary      = <<-EOF
This is a basic library to extend AVQueuePlayer to provide the ability to play previous items (IE move backwards in the queue). This is impossible with the normal AVQueuePlayer, since when an item is finished playing it is removed from the queue for good. This class gets around that by maintaining a copy of the array of the array used to initialize the queue and keeping an index integer, and re-populating the queue from the previous item when the 'play previous song' message is sent. This is useful if you want a more-or-less fully fledged music player, but do not want to use MPMediaPlayer for whatever reason.

It should be noted that since this class both maintains a copy of the array used to create it and re-creates the queue when necessary, this class uses a bit more memory than the normal AVQueuePlayer, and requesting a previous song can be slow. In testing we have found this imperceptible unless the array of items you're initializing is gigantic, but if it's vital that your app squeezes out every bit of performance possible; or you do not need to be able to play a previous song, we recommend that you use AVQueuePlayer instead

This class works the same way as AVQueuePlayer, but with the following methods added:

-(void)playPreviousItem
This method pauses the AVQueuePlayer, clears the queue, and re-populates the queue using the array that the player was generated with, from the prior song on. It then re-sets the seek time to 0 and plays the player. The overall effect is that of playing the previous song in the queue.

-(Boolean)isAtBeginning
This method simply returns true if the player is playing its first item, and false if it is not.

-(int)getIndex
This method returns the index in the queue of the currently playing element.

LICENSING INFORMATION: This code is released under a 2-clause BSD license. In a nutshell, that means that you're free to modify or use this code in any project you want (including commercial products). You don't need to release the code of any project in which you use this library and your code does not itself need to be licensed under the BSD license. However, you may not remove the license text from the source code of this library, and you must credit this library (and me, Daniel Giovannelli, as its creator) somewhere in the app. 

Also, though it's not required, if you do wind up using this library feel free to drop me an email at dangiovannelli@gmail.com and let me know what you're using it for - I'm always interested in seeing how people use the things I make.

______

CHANGES
2014/07/16  (JRTaal) Greatly simplified and cleaned up code, meanwhile fixed number of bugs.
                     Renamed to more apt AVBidirectionalQueuePlayer'
EOF
  spec.source       = { :git => 'https://github.com/jrtaal/AVQueuePlayerPrevious.git', :tag => '1.0' }
  spec.source_files = '*.{h,m}'
  spec.framework    = 'AVFoundation'
  spec.requires_arc = true
end