require 'rubygems'
$:.push File.expand_path(File.dirname(__FILE__)) unless $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'mega_mutex/cross_process_mutex'

# == Why
# 
# Sometimes I need to do this:
# 
#     unless enough_things?
#       make_more_things
#     end
#     
# Sometimes though, if I'm running lots of processes in parallel, I get a race condition that means two of the processes both think there are not enough things. So we go and make some more, even though we don't need to.
# 
# == How
# 
# Suppose you have a ThingMaker:
# 
#     class ThingMaker
#       include MegaMutex
#       
#       def ensure_just_enough_things  
#         with_cross_process_mutex("ThingMaker Mutex ID") do
#           unless enough_things?
#             make_more_things
#           end
#         end
#       end
#     end
# 
# Now, thanks to the magic of MegaMutex, you can be sure that all processes trying to run this code will wait their turn, so each one will have the chance to make exactly the right number of things, without anyone else poking their nose in.
# 
# == Configuration
# 
# MegaMutex uses http://seattlerb.rubyforge.org/memcache-client/ to store the mutex, so your infrastructure must be set up to use memcache servers.
# 
# By default, MegaMutex will attempt to connect to a memcache on the local machine, but you can configure any number of servers like so:
# 
#     MegaMutex.configure do |config|
#       config.memcache_servers = ['mc1', 'mc2']
#     end
module MegaMutex

  ## 
  # Wraps code that should only be run when the mutex has been obtained.
  # 
  # The mutex_id uniquely identifies the section of code being run.
  #
  # You can optionally specify a :timeout to control how long to wait for the lock to be released
  # before raising a MegaMutex::TimeoutError
  #
  #   with_cross_process_mutex('my_mutex_id_1234', :timeout => 20) do
  #     do_something!
  #   end
  def with_cross_process_mutex(mutex_id, options = {}, &block)
    mutex = CrossProcessMutex.new(mutex_id, options[:timeout])
    mutex.run(&block)
  end
  
  class Configuration
    attr_accessor :memcache_servers

    def initialize
      @memcache_servers = 'localhost'
    end
  end

  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end
end

