# mega_mutex

A distributed mutex for Ruby.

## Why

Sometimes I need to do this:

    unless enough_things?
      make_more_things
    end
    
If I'm running several processes in parallel, I can get a race condition that means two of the processes both think there are not enough things. So we go and make some more, even though we don't need to.

## How

Suppose you have a ThingMaker:

    class ThingMaker
      include MegaMutex
      
      def ensure_just_enough_things  
        with_distributed_mutex("ThingMaker Mutex ID") do
          unless enough_things?
            make_more_things
          end
        end
      end
    end

Now, thanks to the magic of MegaMutex, you can be sure that all processes trying to run this code will wait their turn, so each one will have the chance to make exactly the right number of things, without anyone else poking their nose in.

## Install

    sudo gem install mega_mutex


## Configure

MegaMutex uses Dalii to store the mutex, so your infrastructure must be set up to use memcache servers.

By default, MegaMutex will attempt to connect to a memcache on the local machine, but you can configure any number of servers like so:

    MegaMutex.configure do |config|
      config.memcache_servers = ['mc1', 'mc2']
    end

## Help

MegaMutex was built by the [Songkick.com](http://www.songkick.com) development team. Come chat to us on [#songkick](irc://chat.freenode.net/#songkick) on freenode.net.

## Copyright

Copyright (c) 2009 Songkick.com. See LICENSE for details.
